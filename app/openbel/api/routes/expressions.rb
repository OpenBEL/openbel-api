require 'cgi'
require 'bel'
require 'uri'
require 'bel_parser/expression/parser'
require 'bel_parser/expression/model'
require 'bel_parser/resource/jena_tdb_reader'

module OpenBEL
  module Routes

    class Expressions < Base

      def initialize(app)
        super

        # Obtain configured BEL version.
        bel_version   = OpenBEL::Settings[:bel][:version]
        @spec         = BELParser::Language.specification(bel_version)
        tdb_directory = OpenBEL::Settings[:resource_rdf][:jena][:tdb_directory]

        # RdfRepository using Jena.
        @rr = BEL::RdfRepository.plugins[:jena].create_repository(
          :tdb_directory => tdb_directory
        )

        # Annotations using RdfRepository
        @annotations = BEL::Resource::Annotations.new(@rr)
        # Namespaces using RdfRepository
        @namespaces = BEL::Resource::Namespaces.new(@rr)

        # Resource Search using SQLite.
        @search = BEL::Resource::Search.plugins[:sqlite].create_search(
          :database_file => OpenBEL::Settings[:resource_search][:sqlite][:database_file]
        )

        @reader = BELParser::Resource::JenaTDBReader.new(tdb_directory)
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
            obj.merge!({
              :subject      => bel_statement.subject ? bel_statement.subject.to_s : nil,
              :relationship => bel_statement.relationship && bel_statement.relationship.long,
              :object       => bel_statement.object ? bel_statement.object.to_s : nil
            })
          else
            obj.merge!({
              :subject      => term_components(bel_statement.subject),
              :relationship => bel_statement.relationship && bel_statement.relationship.to_h,
              :object       => term_components(bel_statement.object)
            })
          end

          obj
        end

        def arg_components(bel_argument)
          case bel_argument
          when BELParser::Expression::Model::Parameter
            parameter_components(bel_argument)
          when BELParser::Expression::Model::Term
            term_components(bel_argument)
          else
            nil
          end
        end

        def term_components(bel_term)
          return nil unless bel_term

          {
            :term => {
              :function  => bel_term.function.to_h,
              :arguments => bel_term.arguments.map { |a| arg_components(a) }
            }
          }
        end

        def parameter_components(bel_parameter)
          return nil unless bel_parameter
          namespace = bel_parameter.namespace && bel_parameter.namespace.to_s

          {
            :parameter => {
              :namespace => namespace,
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
          completions = BEL::Completion.complete(bel, @spec, @search, @namespaces, caret_position)
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

        statement =
          BELParser::Expression.parse_statements(
            bel,
            @spec)
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

        terms =
          BELParser::Expression.parse_terms(
            bel,
            @spec)
        halt 404 if terms.empty?

        if !functions.empty?
          functions = functions.map(&:to_sym)
          terms =
            terms.select do |term|
              functions.any? { |match| term.function === match }
            end
        end

        if inner_terms
          terms =
            terms.flat_map do |term|
              term.arguments.select do |arg|
                arg.is_a?(BELParser::Expression::Model::Term)
              end
            end
        end

        terms = terms.to_a
        halt 404 if terms.empty?

        response.headers['Content-Type'] = 'application/json'
        if flatten
          MultiJson.dump({
            :terms => terms.map { |term| term.to_s }
          })
        else
          MultiJson.dump({
            :terms => terms.map { |term| term_components(term) }
          })
        end
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
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
