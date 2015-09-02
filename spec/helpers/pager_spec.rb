require_relative '../spec_helper'
require_relative '../../app/helpers/pager'
require          'rantly'
require          'rantly/rspec_extensions'

include OpenBEL::Helpers

describe Pager do

  context 'property tests' do

    it 'correctly computes total_pages when page_size == 0' do
      property_of {
        Rantly.value(1000) {
          start     = range(0, 10000)
          page_size = 0
          total     = range(0, 10000)

          guard start <= total
          
          [start, page_size, total]
        }
      }.check(1000, 1000) { |start, page_size, total|
        pager = Pager.new(start, page_size, total)
        expect(pager.total_pages).to eql 1
      }
    end

    it 'correctly computes total_pages when page_size >= 0' do
      property_of {
        Rantly.value(1000) {
          start     = range(0, 10000)
          page_size = range(0, 10000)
          total     = range(0, 10000)

          guard start     <= total
          guard page_size >  0
          
          [start, page_size, total]
        }
      }.check(1000, 1000) { |start, page_size, total|
        pager = Pager.new(start, page_size, total)
        partition_ceiling = (total / page_size.to_f).ceil
        expect(pager.total_pages).to eql partition_ceiling
      }
    end
  end
end
