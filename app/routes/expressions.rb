require 'cgi'
require 'bel'
require 'uri'

module OpenBEL
  module Routes

    class Expressions < Base

      def initialize(app)
        super

        # RdfRepository using Jena
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(
            :tdb_directory => 'biological-concepts-rdf'
        )

        # Annotations using RdfRepository
        @annotations = BEL::Resource::Annotations.new(@rr)
        # Namespaces using RdfRepository
        @namespaces = BEL::Resource::Namespaces.new(@rr)

        @sequence_variation = SequenceVariationFunctionHasLocationPredicate.new
      end

      options '/api/expressions/*/completions' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/expressions/*/components/?' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/expressions/*/components/terms?' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/expressions/*/syntax-validations/?' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/expressions/*/semantic-validations/?' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      # options '/api/expressions/*/ortholog' do
      #   response.headers['Allow'] = 'OPTIONS,GET'
      #   status 200
      # end

      # options '/api/expressions/*/ortholog/:species' do
      #   response.headers['Allow'] = 'OPTIONS,GET'
      #   status 200
      # end

      helpers do

        def normalize_relationship(relationship)
          return nil unless relationship
          BEL::Language::RELATIONSHIPS[relationship.to_sym]
        end

        def statement_components(bel_statement, flatten = false)
          obj = {}
          if flatten
            obj[:subject]      = bel_statement ? bel_statement.subject.to_bel : nil
            obj[:relationship] = normalize_relationship(bel_statement.relationship)
            obj[:object]       = bel_statement ? bel_statement.object.to_bel : nil
          else
            obj[:subject]      = term_components(bel_statement.subject)
            obj[:relationship] = normalize_relationship(bel_statement.relationship)
            obj[:object]       = term_components(bel_statement.object)
          end
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

        def parameter_components(bel_parameter)
          return nil unless bel_parameter

          {
            :parameter => {
              :ns        => bel_parameter.ns ? bel_parameter.ns.prefix : nil,
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
          completions = BEL::Completion.complete(bel, @namespaces, caret_position)
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
        bel     = params[:splat].first
        flatten = as_bool(params[:flatten])

        statement = BEL::Script.parse(bel).find { |obj|
          obj.is_a? BEL::Model::Statement
        }
        halt 404 unless statement

        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump({
          :expression_components => statement_components(statement, flatten),
          :statement_short_form  => statement.to_s
        })
      end

      get '/api/expressions/*/components/terms?' do
        bel         = params[:splat].first
        functions   = CGI::parse(env["QUERY_STRING"])['function']
        flatten     = as_bool(params[:flatten])
        inner_terms = as_bool(params[:inner_terms])

        terms = BEL::Script.parse(bel).select { |obj|
          obj.is_a? BEL::Model::Term
        }

        if !functions.empty?
          functions = functions.map(&:to_sym)
          terms = terms.select { |term|
            functions.any? { |match|
              term.fx.short_form == match || term.fx.long_form == match
            }
          }
        end

        if inner_terms
          terms = terms.flat_map { |term|
            term.arguments.select { |arg| arg.is_a? BEL::Model::Term }
          }
        end

        terms = terms.to_a
        halt 404 if terms.empty?

        response.headers['Content-Type'] = 'application/json'
        if flatten
          MultiJson.dump({
            :terms => terms.map { |term| term.to_bel }
          })
        else
          MultiJson.dump({
            :terms => terms.map { |term| term_components(term) }
          })
        end
      end

      # TODO Relies on LibBEL.bel_parse_statement which is not currently supported.
      # get '/api/expressions/*/ortholog/:species' do
      #   bel              = params[:splat].first
      #   species          = params[:species]
      #   taxon_annotation = @annotations.find('taxon').first
      #
      #   unless taxon_annotation
      #     halt(
      #       404,
      #       { 'Content-Type' => 'application/json' },
      #       render_json({
      #         :status => 404,
      #         :msg    => 'Could not find NCBI Taxonomy annotation.'
      #       })
      #     )
      #   end
      #
      #   species = taxon_annotation.find(species).first
      #
      #   if species
      #     species = species.identifier.to_s
      #   else
      #     halt(
      #       400,
      #       { 'Content-Type' => 'application/json' },
      #       render_json({
      #         :status => 400,
      #         :msg    => %Q{Could not find species "#{params[:species]}"}
      #       })
      #     )
      #   end
      #
      #   bel_ast = BEL::Parser.parse(bel)
      #
      #   if bel_ast.any?([@sequence_variation])
      #     msg = 'Could not orthologize sequence variation terms with location'
      #     halt(
      #       404,
      #       { 'Content-Type' => 'application/json' },
      #       render_json({
      #         :status => 404,
      #         :msg    => msg
      #       })
      #     )
      #   end
      #
      #   param_transform = ParameterOrthologTransform.new(
      #       @namespaces, @annotations, species
      #   )
      #   transformed_ast = bel_ast.transform_tree([param_transform])
      #
      #   if !param_transform.parameter_errors.empty?
      #     parameters = param_transform.parameter_errors.map { |p|
      #       p.join(':')
      #     }.join(', ')
      #     halt(
      #       404,
      #       { 'Content-Type' => 'application/json' },
      #       render_json({
      #         :status => 404,
      #         :msg    => "Could not orthologize #{parameters}"
      #       })
      #     )
      #   end
      #
      #   # serialize AST to BEL
      #   bel_serialization = BELSerializationTransform.new
      #   transformed_ast.transform_tree([bel_serialization])
      #
      #   # write response
      #   response.headers['Content-Type'] = 'application/json'
      #   MultiJson.dump({
      #     :original     => bel,
      #     :species      => params[:species],
      #     :orthologized => bel_serialization.bel_string
      #   })
      # end

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

        def initialize(namespaces, annotations, species_tax_id)
          @namespaces = namespaces
          @orthology = OrthologAdapter.new(
            namespaces, species_tax_id
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
                namespace, value = ns_value
                namespace        = @namespaces.find(namespace).first
                if namespace
                  value = namespace.find(value).first
                  if !value || value.fromSpecies != @species_tax_id
                    @parameter_errors << value
                  end
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

        def initialize(namespaces, species_tax_id)
          @namespaces = namespaces
          @species_tax_id = species_tax_id
        end

        def [](key)
          namespace, value = key

          if value.start_with?('"') && value.end_with?('"')
            value = value[1...-1]
          end

          namespace = @namespaces.find(namespace).first
          return EMPTY unless namespace
          value     = namespace.find(value).first
          return EMPTY unless value
          orthologs = value.orthologs.select { |orth|
            orth.fromSpecies == @species_tax_id
          }.to_a
          return EMPTY if orthologs.empty?

          orthologs.map! { |ortholog_value|
            [
              ortholog_value.namespace.prefix,
              ortholog_value.prefLabel
            ]
          }
          orthologs
        end
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
