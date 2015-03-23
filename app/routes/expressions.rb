require 'bel'
require 'uri'
require 'pry'

module OpenBEL
  module Routes

    class Expressions < Base

      def initialize(app)
        super
        @namespace_api  = OpenBEL::Settings["namespace-api"].create_instance
        @annotation_api = OpenBEL::Settings["annotation-api"].create_instance
      end

      options '/api/expressions/*/completions' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/expressions/*/ortholog' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/expressions/*/ortholog/:species' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/expressions/*/completions/?' do
        bel = params[:splat].first
        caret_position = (params[:caret_position] || bel.length).to_i
        halt 400 unless bel and caret_position

        begin
          completions = BEL::Completion.complete(bel, @namespace_api, caret_position)
        rescue IndexError => ex
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({ :status => 400, :msg => ex.to_s })
          )
        end
        halt 404 if completions.empty?

        render_collection(
          completions,
          :completion,
          :bel => bel,
          :caret_position => caret_position
        )
      end

      get '/api/expressions/*/ortholog/:species' do
        bel      = params[:splat].first
        species  = params[:species]
        species  = @annotation_api.find_annotation_value(
          'taxon',
          params[:species].to_s
        )
        if species
          species = species.identifier.to_s
        else
          halt(
            400,
            { 'Content-Type' => 'application/json' },
            render_json({
              :status => 400,
              :msg    => %Q{Could not find species "#{params[:species]}"}
            })
          )
        end

        bel_ast = BEL::Parser.parse(bel)

        transformed_ast = bel_ast.transform_tree([
          ParameterOrthologTransform.new(
            OrthologAdapter.new(@namespace_api, @annotation_api, species)
          )
        ])

        puts "#{LibBEL::bel_ast_as_string(transformed_ast)}"

        # serialize AST to BEL
        bel_serialization = BELSerializationTransform.new
        transformed_ast.transform_tree([bel_serialization])

        # write response
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump({
          :original     => bel,
          :species      => params[:species],
          :orthologized => bel_serialization.bel_string
        })
      end

      # BEL Syntax Validation
      # TODO Move out to a separate route.
      get '/api/expressions/*/syntax-validations/?' do
        halt 501
      end

      # BEL Semantic Validations
      # TODO Move out to a separate route.
      get '/api/expressions/*/semantic-validations/?' do
        halt 501
      end

      class ParameterOrthologTransform
        include LibBEL

        NAMESPACE_PREFERENCE = [
          "hgnc",
          "mgi",
          "rgd",
          "gocc",
          "scomp",
          "meshcs",
          "sfam",
          "gobp",
          "meshpp",
          "chebi",
          "schem",
          "do",
          "meshd",
          "sdis",
          "sp",
          "affx",
          "egid",
        ]

        def initialize(orthology)
          @orthology = orthology
        end

        def call(ast_node)
          if ast_node.is_a?(BelAstNodeToken) &&
              ast_node.token_type == :BEL_TOKEN_NV

            orthologs = @orthology[
              [
                ast_node.left.to_typed_node.value,
                ast_node.right.to_typed_node.value
              ]
            ]
            if !orthologs.empty?
              orthologs.sort_by! { |ortholog| namespace_preference(ortholog) }
              ortholog = orthologs.first
              LibBEL::bel_free_ast_node(ast_node.left.pointer)
              ast_node.left  = BelAstNode.new(
                bel_new_ast_node_value(:BEL_VALUE_PFX, ortholog[0].upcase)
              )

              LibBEL::bel_free_ast_node(ast_node.right.pointer)
              ast_node.right = BelAstNode.new(
                bel_new_ast_node_value(:BEL_VALUE_VAL, ortholog[1])
              )
            end
          end
        end

        private

        def namespace_preference(ortholog)
          NAMESPACE_PREFERENCE.index(ortholog[0])
        end
      end

      class BELSerializationTransform
        include LibBEL

        attr_reader :bel_string

        def initialize
          @bel_string = ""
        end

        def call(ast_node)
          if ast_node.is_a?(BelAstNodeToken)
            case ast_node.token_type
            when :BEL_TOKEN_STATEMENT
            when :BEL_TOKEN_SUBJECT
            when :BEL_TOKEN_OBJECT
            when :BEL_TOKEN_REL
            when :BEL_TOKEN_TERM
            when :BEL_TOKEN_ARG
            when :BEL_TOKEN_NV
            end
          else
            case ast_node.value_type
            when :BEL_VALUE_FX
              function(ast_node.value)
            when :BEL_VALUE_REL
              relationship(ast_node.value)
            when :BEL_VALUE_PFX
              namespace_prefix(ast_node.value)
            when :BEL_VALUE_VAL
              namespace_value(ast_node.value)
            end
          end
        end

        def between(ast_node)
          if ast_node.is_a?(BelAstNodeToken)
            case ast_node.token_type
            when :BEL_TOKEN_STATEMENT
            when :BEL_TOKEN_SUBJECT
            when :BEL_TOKEN_OBJECT
            when :BEL_TOKEN_REL
            when :BEL_TOKEN_TERM
            when :BEL_TOKEN_ARG
              token_arg(ast_node)
            when :BEL_TOKEN_NV
            end
          end
        end

        def after(ast_node)
          if ast_node.is_a?(BelAstNodeToken)
            case ast_node.token_type
            when :BEL_TOKEN_STATEMENT
            when :BEL_TOKEN_SUBJECT
            when :BEL_TOKEN_OBJECT
            when :BEL_TOKEN_REL
            when :BEL_TOKEN_TERM
              @bel_string.concat(')')
            when :BEL_TOKEN_ARG
            when :BEL_TOKEN_NV
            end
          end
        end

        private

        def token_arg(ast_node)
          chained_arg_node = ast_node.right
          if !chained_arg_node.pointer.null?
            chained_arg_node = chained_arg_node.to_typed_node
            if !chained_arg_node.left.pointer.null? ||
               !chained_arg_node.right.pointer.null?
              @bel_string.concat(', ')
            end
          end
        end

        def function(fx)
          @bel_string.concat(fx).concat('(')
        end

        def relationship(rel)
          @bel_string.concat(" #{rel} ")
        end

        def namespace_prefix(prefix)
          return unless prefix
          @bel_string.concat(prefix).concat(':')
        end

        def namespace_value(value)
          @bel_string.concat(value)
        end
      end

      # Hash-like
      class OrthologAdapter

        EMPTY = [].freeze

        def initialize(namespace_api, annotation_api, species_tax_id)
          @namespace_api = namespace_api
          @species_tax_id = species_tax_id
        end

        def [](key)
          namespace, value = key

          if value.start_with?('"') && value.end_with?('"')
            value = value[1...-1]
          end
          puts value
          orthologs = @namespace_api.find_ortholog(
            namespace,
            value,
            :species => @species_tax_id
          )
          if !orthologs
            EMPTY
          else
            orthologs.map! { |ortholog_value|
              [
                @namespace_api.find_namespace(URI(ortholog_value.inScheme)).prefix,
                ortholog_value.prefLabel
              ]
            }
          end
        end
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
