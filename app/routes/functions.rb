require 'bel'

module OpenBEL
  module Routes

    class Functions < Base
      include BEL::Language

      SORTED_FUNCTIONS = FUNCTIONS.values.uniq.sort_by { |fx|
        fx[:short_form]
      }

      get '/api/functions' do
        render(SORTED_FUNCTIONS, :function)
      end

      # BEL Completion
      get '/api/functions/:fx' do
        fx_match = FUNCTIONS[params[:fx].to_sym]
        halt 404 unless fx_match

        render(fx_match, :function)
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
