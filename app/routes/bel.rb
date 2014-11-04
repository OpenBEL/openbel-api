require 'bel'

module OpenBEL
  module Routes

    # App
    class BELApp < Base

      get '/bel/completer/?' do
        input = params[:input]
        result = BEL::Completion.complete(input).map { |r|
          hash = r.to_h
          hash[:type] = r.class.name.split('::')[-1].downcase
          hash
        }
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump result
      end

    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
