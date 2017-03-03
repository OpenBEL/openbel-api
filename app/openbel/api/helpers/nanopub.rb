require          'bel/util'
require_relative 'base'
require_relative 'translators'

module OpenBEL
  module Helpers

    def render_nanopub_collection(
      name, page_results, start, size, filters,
      filtered_total, collection_total, nanopub_api
    )
      # see if the user requested a BEL translator (Accept header or ?format)
      translator        = Translators.requested_translator(request, params)
      translator_plugin = Translators.requested_translator_plugin(request, params)

      halt 404 unless page_results[:cursor].has_next?

      # Serialize to HAL if they [Accept]ed it, specified it as ?format, or
      # no translator was found to match request.
      if wants_default? || !translator
        facets   = page_results[:facets]
        pager    = Pager.new(start, size, filtered_total)
        nanopub = page_results[:cursor].map { |item|
                     item.delete('facets')
                     item
                   }.to_a

        options = {
          :facets   => facets,
          :start    => start,
          :size     => size,
          :filters  => filters,
          :metadata => {
            :collection_paging => {
              :total                  => collection_total,
              :total_filtered         => pager.total_size,
              :total_pages            => pager.total_pages,
              :current_page           => pager.current_page,
              :current_page_size      => nanopub.size,
            }
          }
        }

        # pager links
        options[:previous_page] = pager.previous_page
        options[:next_page]     = pager.next_page

        render_collection(nanopub, :nanopub, options)
      else
        extension = translator_plugin.file_extensions.first

        response.headers['Content-Type'] = translator_plugin.media_types.first
        status 200
        attachment "#{name}.#{extension}"
        stream :keep_open do |response|
          cursor             = page_results[:cursor]
          dataset_nanopub = cursor.lazy.map { |nanopub|
            nanopub.delete('facets')
            nanopub.delete('_id')
            nanopub = BEL::Nanopub::Nanopub.create(BEL.keys_to_symbols(nanopub))
            nanopub
          }

          translator.write(
            dataset_nanopub, response,
            :annotation_reference_map => nanopub_api.find_all_annotation_references,
            :namespace_reference_map  => nanopub_api.find_all_namespace_references
          )
        end
      end
    end

    def validate_experiment_context(experiment_context)
      valid_annotations   = []
      invalid_annotations = []
      experiment_context.values.each do |annotation|
        name, value = annotation.values_at(:name, :value)
        found_annotation  = @annotations.find(name).first

        if found_annotation
          if found_annotation.find(value).first == nil
            # structured annotations, without a match, is invalid
            invalid_annotations << annotation
          else
            # structured annotations, with a match, is invalid
            valid_annotations << annotation
          end
        else
          # free annotations considered valid
          valid_annotations << annotation
        end
      end

      [
        invalid_annotations.empty? ? :valid : :invalid,
        {
          :valid               => invalid_annotations.empty?,
          :valid_annotations   => valid_annotations,
          :invalid_annotations => invalid_annotations,
          :message             =>
            invalid_annotations
              .map { |annotation|
                name, value = annotation.values_at(:name, :value)
                %Q{The value "#{value}" was not found in annotation "#{name}".}
              }
              .join("\n")
        }
      ]
    end

    def validate_statement(bel)
      filter =
        BELParser::ASTFilter.new(
          BELParser::ASTGenerator.new("#{bel}\n"),
          :simple_statement,
          :observed_term,
          :nested_statement
        )
      _, _, ast = filter.each.first

      if ast.nil? || ast.empty?
        return [
          :syntax_invalid,
          {
            valid_syntax:    false,
            valid_semantics: false,
            message:         'Invalid syntax.',
            warnings:        [],
            term_signatures: []
          }
        ]
      end

      urir      = BELParser::Resource.default_uri_reader
      urlr      = BELParser::Resource.default_url_reader
      validator = BELParser::Language::ExpressionValidator.new(@spec, @supported_namespaces, urir, urlr)
      message   = ''
      terms     = ast.first.traverse.select { |node| node.type == :term }.to_a

      semantics_functions =
        BELParser::Language::Semantics.semantics_functions.reject { |fun|
          fun == BELParser::Language::Semantics::SignatureMapping
        }

      result        = validator.validate(ast.first)
      syntax_errors = result.syntax_results.map(&:to_s)

      semantic_warnings =
        ast
          .first
          .traverse
          .flat_map { |node|
            semantics_functions.flat_map { |func|
              func.map(node, @spec, @supported_namespaces)
            }
          }
          .compact

      if syntax_errors.empty? && semantic_warnings.empty?
        valid = true
      else
        valid   = false
        message = ''
        message +=
          syntax_errors.reduce('') { |msg, error|
            msg << "#{error}\n"
          }
        message +=
          semantic_warnings.reduce('') { |msg, warning|
            msg << "#{warning}\n"
          }
        message << "\n"
      end

      term_semantics =
        terms.map { |term|
          term_result = validator.validate(term)
          valid      &= term_result.valid_semantics?
          bel_term    = serialize(term)

          unless valid
            message << "Term: #{bel_term}\n"
            term_result.invalid_signature_mappings.map { |m|
              message << "  #{m}\n"
            }
            message << "\n"
          end

          {
            term:               bel_term,
            valid:              term_result.valid_semantics?,
            errors:             term_result.syntax_results.map(&:to_s),
            valid_signatures:   term_result.valid_signature_mappings.map(&:to_s),
            invalid_signatures: term_result.invalid_signature_mappings.map(&:to_s)
          }
        }

      [
        valid ? :valid : :semantics_invalid,
        {
          expression:      bel,
          valid_syntax:    true,
          valid_semantics: valid,
          message:         valid ? 'Valid semantics' : message,
          errors:          syntax_errors,
          warnings:        semantic_warnings.map(&:to_s),
          term_signatures: term_semantics
        }
      ]
    end

    def validate_nanopub!(bel_statement, experiment_context)

      STDERR.puts "DBG: Variable config is #{bel_statement.inspect}"

      stmt_result, stmt_validation     = validate_statement(bel_statement)
      expctx_result, expctx_validation = validate_experiment_context(experiment_context)

      return nil if stmt_result == :valid && expctx_result == :valid

      halt(
        422,
        {'Content-Type' => 'application/json'},
        render_json(
          {
            :nanopub_validation => {
              :bel_statement_validation      => stmt_validation,
              :experiment_context_validation => expctx_validation
            }
          }
        )
      )
    end
  end
end
