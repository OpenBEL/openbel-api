module OpenBEL
  module Helpers

    class Pager

      NEGATIVE_FUNCTION      = lambda { |v| v < 0 ? 0 : v }
      FLOAT_FUNCTION         = lambda { |v| Float(v)      }
      PREVIOUS_COND_FUNCTION = lambda { |pager, neg_proc, pos_proc|
        [
          pager.start_offset,
          pager.page_size,
        ].any?(&(lambda { |v| v <= 0 })) ?
          neg_proc.call(pager) :
          pos_proc.call(pager)
      }
      NEXT_COND_FUNCTION = lambda { |pager, false_proc, true_proc|
        test  = pager.page_size > 0
        test &= (pager.start_offset + pager.page_size) <= pager.total_size

        test ?
          true_proc.call(pager) :
          false_proc.call(pager)
      }

      private_constant :NEGATIVE_FUNCTION
      private_constant :FLOAT_FUNCTION
      private_constant :PREVIOUS_COND_FUNCTION
      private_constant :NEXT_COND_FUNCTION

      def initialize(start_offset, page_size, total_size)
        raise ArgumentError.new("start_offset must be >= 0") if start_offset < 0
        raise ArgumentError.new("page_size must be >= 0") if page_size < 0
        raise ArgumentError.new("total_size must be >= 0") if total_size < 0

        @start_offset = NEGATIVE_FUNCTION.call(start_offset)
        @page_size    = FLOAT_FUNCTION.call(page_size)
        @total_size   = total_size
      end

      def start_offset
        @start_offset
      end

      def current_page
        return 0 if @total_size == 0

        if @page_size > 0
          ((@start_offset + @page_size) / @page_size).ceil
        else
          total_pages = total_pages()

          case total_pages
          when 1
            1
          when 2
            midpoint = @total_size / total_pages
            @start_offset < midpoint ? 1 : 2
          end
        end
      end

      def page_size
        @page_size.to_i
      end

      def total_pages
        return 0 if @total_size == 0

        if @page_size > 0
          (@total_size / @page_size).ceil
        else
          @start_offset == 0 ? 1 : 2
        end
      end

      def total_size
        @total_size
      end

      def previous_page
        PREVIOUS_COND_FUNCTION.call(
          self,
          lambda { |_| nil },
          lambda { |pager| 
            Pager.new(
              NEGATIVE_FUNCTION.call(start_offset - page_size),
              page_size,
              total_size
            )
          }
        )
      end

      def next_page
        NEXT_COND_FUNCTION.call(
          self,
          lambda { |_| nil },
          lambda { |pager| 
            Pager.new(
              NEGATIVE_FUNCTION.call(start_offset + page_size),
              page_size,
              total_size
            )
          }
        )
      end
    end
  end
end
