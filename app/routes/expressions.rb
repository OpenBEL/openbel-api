require 'bel'
require 'uri'

module OpenBEL
  module Routes

    class Expressions < Base

      def initialize(app)
        super
        @namespace_api  = OpenBEL::Settings["namespace-api"].create_instance
        @annotation_api = OpenBEL::Settings["annotation-api"].create_instance
        @sequence_variation = SequenceVariationFunctionHasLocationPredicate.new
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

      helpers do

        def normalize_relationship(relationship)
          match = BEL::RDF::RELATIONSHIP_TYPE.select { |k, v|
            v == BEL::RDF::RELATIONSHIP_TYPE[relationship.to_s]
          }.
          find { |k, v|
            k =~ /^[a-z]/
          }

          match ? match.first : nil
        end

        def statement_components(bel_statement, obj = {})
          obj[:subject]      = term_components(bel_statement.subject)
          obj[:relationship] = normalize_relationship(bel_statement.relationship)
          obj[:object]       = term_components(bel_statement.object)
          obj
        end

        def arg_components(bel_argument)
          if bel_argument.respond_to? :fx
            term_components(bel_argument)
          elsif bel_argument.respond_to? :ns
            parameter_components(bel_argument)
          else
            nil
          end
        end

        def term_components(bel_term)
          return nil unless bel_term

          {
            :term => {
              :fx        => bel_term.fx,
              :arguments => bel_term.arguments.map { |a| arg_components(a) }
            }
          }
        end

        def parameter_components(bel_parameter, obj = {})
          return nil unless bel_parameter

          {
            :parameter => {
              :ns        => bel_parameter.ns,
              :value     => bel_parameter.value.to_s
            }
          }
        end
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

      get '/api/expressions/*/components/?' do
        bel = params[:splat].first

        statement = BEL::Script.parse(bel).find { |obj|
          obj.is_a? BEL::Model::Statement
        }
        halt 404 unless statement

        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump({
          :expression_components => statement_components(statement),
          :statement_short_form  => statement.to_s
        })
      end

      get '/api/expressions/*/ortholog/:species' do
        bel           = params[:splat].first
        species       = params[:species]
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

        if bel_ast.any?([@sequence_variation])
          msg = 'Could not orthologize sequence variation terms with location'
          halt(
            404,
            { 'Content-Type' => 'application/json' },
            render_json({
              :status => 404,
              :msg    => msg
            })
          )
        end

        param_transform = ParameterOrthologTransform.new(
          @namespace_api, @annotation_api, species
        )
        transformed_ast = bel_ast.transform_tree([param_transform])

        if !param_transform.parameter_errors.empty?
          parameters = param_transform.parameter_errors.map { |p|
            p.join(':')
          }.join(', ')
          halt(
            404,
            { 'Content-Type' => 'application/json' },
            render_json({
              :status => 404,
              :msg    => "Could not orthologize #{parameters}"
            })
          )
        end

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

      class SequenceVariationFunctionHasLocationPredicate
        include BEL::LibBEL

        SEQUENCE_VARIATION_FX = [
          'fus', 'fusion',
          'pmod', 'proteinModification',
          'sub', 'substitution',
          'trunc', 'truncation'
        ]

        def call(ast_node)
          # check if AST node is a TERM
          if !ast_node.is_a?(BelAstNodeToken) || ast_node.token_type != :BEL_TOKEN_TERM
            return false
          end

          # check if AST node is a pmod TERM
          if !SEQUENCE_VARIATION_FX.include?(ast_node.left.to_typed_node.value)
            return false
          end

          # walk arg AST nodes until terminal
          arg_node = ast_node.right.to_typed_node
          while !(arg_node.left.pointer.null? && arg_node.right.pointer.null?)
            # check if NV token child
            arg_token = arg_node.left.to_typed_node

            if arg_token.token_type == :BEL_TOKEN_NV
              # true if namespace value is an integer
              node_value = arg_token.right.to_typed_node.value
              if integer?(node_value)
                return true
              end
            end

            # advance to the next ARG
            arg_node = arg_node.right.to_typed_node
          end

          return false
        end

        private

        def integer?(value)
          begin
            Integer(value)
            return true
          rescue ArgumentError
            return false
          end
        end
      end

      class ParameterOrthologTransform
        include BEL::LibBEL

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

        def initialize(namespace_api, annotation_api, species_tax_id)
          @namespace_api = namespace_api
          @orthology = OrthologAdapter.new(
            namespace_api, annotation_api, species_tax_id
          )
          @species_tax_id = species_tax_id
          @parameter_errors = []
        end

        def parameter_errors
          @parameter_errors.uniq
        end

        def call(ast_node)
          if ast_node.is_a?(BelAstNodeToken) &&
              ast_node.token_type == :BEL_TOKEN_NV

            ns_value = [
              ast_node.left.to_typed_node.value,
              ast_node.right.to_typed_node.value
            ]
            orthologs = @orthology[ns_value]
            if !orthologs.empty?
              orthologs.sort_by! { |ortholog| namespace_preference(ortholog) }
              ortholog = orthologs.first
              BEL::LibBEL::bel_free_ast_node(ast_node.left.pointer)
              ast_node.left  = BelAstNode.new(
                bel_new_ast_node_value(:BEL_VALUE_PFX, ortholog[0].upcase)
              )

              BEL::LibBEL::bel_free_ast_node(ast_node.right.pointer)
              ast_node.right = BelAstNode.new(
                bel_new_ast_node_value(:BEL_VALUE_VAL, ortholog[1])
              )
            else
              # flag as ortholog error if this parameter has a namespace and
              # the namespace value is either not known or its species differs
              # from our target
              if ns_value[0] != nil
                nsv_object = @namespace_api.find_namespace_value(*ns_value)
                if !nsv_object || nsv_object.fromSpecies != @species_tax_id
                  @parameter_errors << ns_value
                end
              end
            end
          end
        end

        private

        def namespace_preference(ortholog)
          NAMESPACE_PREFERENCE.index(ortholog[0])
        end
      end

      class BELSerializationTransform
        include BEL::LibBEL

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
