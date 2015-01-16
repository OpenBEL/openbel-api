require 'bel'

module OpenBEL
  module Routes

    class Expressions < Base

      get '/api/expressions/*/completions/?' do
        bel = params[:splat].first
        caret_position = (params[:caret_position] || bel.length).to_i
        halt 400 unless bel and caret_position

        completions = BEL::Completion.complete(bel, caret_position)
        halt 404 if completions.empty?
        render(completions, :completion)
      end

      # BEL Syntax Validation
      # TODO Move out to a separate route.
      get '/api/expressions/*/syntax-validations/?' do
        bel = params[:splat].first
        halt 400 unless bel

        response.headers['Content-Type'] = 'application/json'

        completions = BEL::Completion.complete(bel)
        if completions.length == 1
          is_terminal = completions.first.class == BEL::Completion::Terminal
          MultiJson.dump [ valid: is_terminal ]
        else
          MultiJson.dump [ value: false ]
        end
      end

      # BEL Semantic Validations
      # TODO Move out to a separate route.
      get '/api/expressions/*/semantic-validations/?' do
        bel = params[:splat].first
        halt 400 unless bel

        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump [ valid: "i'll allow it, but don't get punchy!" ]
      end

    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
