require_relative '../cache_api.rb'
require 'gdbm'
require 'benchmark'

module OpenBEL
  module Namespace

    class Cache
      include CacheAPI

      def initialize(options = {})
        value_file = options['value_file']
        equivalence_file = options['equivalence_file']
        orthology_file = options['orthology_file']

        [value_file, equivalence_file, orthology_file].each do |f|
          unless f or File.exist?(f)
            fail "Database file not found - #{f}"
          end
        end

        @v = GDBM.new(value_file, 0666, GDBM::READER)
        @e = GDBM.new(equivalence_file, 0666, GDBM::READER)
        @o = GDBM.new(orthology_file, 0666, GDBM::READER)
      end

      def fetch_all_values(namespace)
      end

      def fetch_values(namespace, values)
      end

      def fetch_equivalences(namespace, values)
      end

      def fetch_equivalences(namespace, values, target_namespace)
        vals = nil
        puts Benchmark.measure {
          vals = values.map { |v|
            val = @e["#{namespace}:#{v}:#{target_namespace}"]
            if not val
              [v, nil]
            else
              #prefLabel
              [v, val.unpack('m*')[0].split('\0')[1]]
            end
          }
        }
        vals
      end

      def fetch_orthologs(namespace, values)
      end

      def fetch_orthologs(namespace, values, target_namespace)
      end
    end
  end
end
