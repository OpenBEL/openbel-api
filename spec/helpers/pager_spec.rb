require_relative '../spec_helper'
require_relative '../../app/helpers/pager'
require          'rantly'
require          'rantly/rspec_extensions'

include OpenBEL::Helpers

describe Pager do

  context 'property tests' do

    context 'correctly computes total_pages' do

      it 'when not paging but starting in middle (i.e. page_size = 0, start > 0)' do
        property_of {
          Rantly.value(1000) {
            start     = range(1, 10000)
            page_size = 0
            total     = range(0, 10000)

            guard start <= total

            [start, page_size, total]
          }
        }.check(25000, 1000) { |start, page_size, total|
          pager = Pager.new(start, page_size, total)
          expect(pager.total_pages).to eql 2
        }
      end

      it 'when not paging and at beginning (i.e. page_size = 0, start = 0, total > 0)' do
        property_of {
          Rantly.value(1000) {
            start     = 0
            page_size = 0
            total     = range(1, 10000)

            guard start <= total

            [start, page_size, total]
          }
        }.check(25000, 1000) { |start, page_size, total|
          pager = Pager.new(start, page_size, total)
          expect(pager.total_pages).to eql 1
        }
      end

      it 'when using page_size (i.e. page_size >= 0)' do
        property_of {
          Rantly.value(1000) {
            start     = range(0, 10000)
            page_size = range(1, 10000)
            total     = range(1, 10000)

            guard start     <= total

            [start, page_size, total]
          }
        }.check(25000, 1000) { |start, page_size, total|
          pager = Pager.new(start, page_size, total)
          partition_ceiling = (total / page_size.to_f).ceil
          expect(pager.total_pages).to eql partition_ceiling
        }
      end
    end

    context 'correctly computes current_page' do

      it 'when not paging, empty collection' do
        start = 0; page_size = 0; total = 0
        pager = Pager.new(start, page_size, total)

        expect(pager.current_page).to eql 0
      end

      it 'when not paging, starting at beginning' do
        property_of {
          Rantly.value(1000) {
            start     = 0
            page_size = 0
            total     = range(1, 10000)
            [start, page_size, total]
          }
        }.check(25000, 1000) { |start, page_size, total|
          pager = Pager.new(start, page_size, total)
          expect(pager.current_page).to eql 1
        }
      end

      it 'when not paging but starting in first half of collection' do
        property_of {
          Rantly.value(1000) {
            start       = range(1, 10000)
            page_size   = 0
            total       = range(1, 10000)

            guard start < (total / 2)

            [start, page_size, total]
          }
        }.check(25000, 1000) { |start, page_size, total|
          pager = Pager.new(start, page_size, total)
          expect(pager.current_page).to eql 1
        }
      end

      it 'when not paging but starting in second half of collection' do
        property_of {
          Rantly.value(1000) {
            start       = range(1, 10000)
            page_size   = 0
            total       = range(1, 10000)

            guard start >= (total / 2)

            [start, page_size, total]
          }
        }.check(25000, 1000) { |start, page_size, total|
          pager = Pager.new(start, page_size, total)
          expect(pager.current_page).to eql 2
        }
      end
    end
  end
end
