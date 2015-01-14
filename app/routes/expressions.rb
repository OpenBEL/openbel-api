require 'bel'

module OpenBEL
  module Routes

    class Expressions < Base

      get '/api/expressions/:bel/completions/?' do
        bel = params[:bel]
        cursor_position = params[:cursor_position].to_i
        halt 400 unless bel and cursor_position

        completions = BEL::Completion.complete(bel, cursor_position)
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump completions
      end

      # BEL Syntax Validation
      # TODO Move out to a separate route.
      get '/api/expressions/:bel/syntax-validations/?' do
        bel = params[:bel]
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
      get '/api/expressions/:bel/semantic-validations/?' do
        bel = params[:bel]
        halt 400 unless bel

        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump [ valid: "i'll allow it, but don't get punchy!" ]
      end

    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
