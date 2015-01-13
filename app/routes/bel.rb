require 'bel'

module OpenBEL
  module Routes

    # App
    class BELApp < Base

      # BEL Completion
      get '/bel/expressions/:bel/completions/?' do
        bel = params[:bel]
        cursor_position = params[:cursor_position].to_i
        halt 400 unless bel and cursor_position

        completions = BEL::Completion.complete(bel, cursor_position)
        puts completions
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump completions
      end
      get '/bel/expressions/completions/?' do
        part_params = [:subject, :relationship, :object]
        halt 400 unless part_params.any? { |part| params[part] }
        bel = part_params.reduce('') { |bel, part|
            bel + ' ' + (params[part] || '')
        }.strip

        result = BEL::Completion.complete(bel).map { |r|
          hash = r.to_h
          hash[:type] = r.class.name.split('::')[-1].downcase
          hash
        }
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump result
      end

      # BEL Syntax Validation
      get '/bel/expressions/:bel/syntax-validations/?' do
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
      get '/bel/expressions/syntax-validations/?' do
        part_params = [:subject, :relationship, :object]
        halt 400 unless part_params.any? { |part| params[part] }
        bel = part_params.reduce('') { |bel, part|
            bel + ' ' + (params[part] || '')
        }.strip

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
      get '/bel/expressions/:bel/semantic-validations/?' do
        bel = params[:bel]
        halt 400 unless bel

        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump [ valid: "i'll allow it, but don't get punchy!" ]
      end
      get '/bel/expressions/semantic-validations/?' do
        part_params = [:subject, :relationship, :object]
        halt 400 unless part_params.any? { |part| params[part] }
        bel = part_params.reduce('') { |bel, part|
            bel + ' ' + (params[part] || '')
        }.strip

        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump [ valid: "i'll allow it, but don't get punchy!" ]
      end

    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
