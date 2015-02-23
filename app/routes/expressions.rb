require 'bel'

module OpenBEL
  module Routes

    class Expressions < Base

      def initialize(app)
        super
        @search = BEL::Search.use(:sqlite3, :db_file => 'rdf.db')
      end

      options '/api/expressions/*/completions' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/expressions/*/completions/?' do
        bel = params[:splat].first
        caret_position = (params[:caret_position] || bel.length).to_i
        halt 400 unless bel and caret_position

        begin
          completions = BEL::Completion.complete(bel, @search, caret_position)
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
