require_relative '../cache_api.rb'
require 'gdbm'
require 'benchmark'
require 'uri'

module OpenBEL
  module Namespace

    class Cache
      include CacheAPI

      def initialize(options = {})
        n_file = options[:namespace_file] || (fail ArgumentError, 'namespace_file required in options')
        v_file = options[:value_file] || (fail ArgumentError, 'value_file required in options')
        e_file = options[:equivalence_file] || (fail ArgumentError, 'equivalence_file required in options')
        o_file = options[:orthology_file] || (fail ArgumentError, 'orthology_file required in options')

        [n_file, v_file, e_file, o_file].each do |f|
          unless f and File.exist?(f)
            fail "Database file not found - #{f}"
          end
        end

        @n = GDBM.new(n_file, 0666, GDBM::READER)
        @v = GDBM.new(v_file, 0666, GDBM::READER)
        @e = GDBM.new(e_file, 0666, GDBM::READER)
        @o = GDBM.new(o_file, 0666, GDBM::READER)
      end

      def fetch_namespaces
        keys = @n.keys
        if block_given?
          keys.each do |k|
            yield unpack(@n[k]).insert(0,k)
          end
        else
          @n.keys.map {|k| unpack(@n[k]).insert(0,k)}
        end
      end

      def fetch_namespace(namespace)
        case namespace
        when URI
          ns_str = namespace.to_s
          value = @n[ns_str]
          if value
            unpack(value).insert(0, ns_str)
          end
        else
          ns_str = namespace.to_s
          fetch_namespaces.find { |ns|
            ns[0].end_with? ns_str or ns[2] == ns_str or ns[3] == ns_str
          }
        end
      end

      def fetch_all_values(namespace)
        ns = fetch_namespace(namespace)
        return nil unless ns

        uri = ns[0]
        if block_given?
          @v.keys.each do |k|
            if k.start_with? uri
              yield unpack(@v[k])
            end
          end
        else
          @v.keys.lazy.find_all { |k|
            k.start_with? uri
          }.map { |k|
            unpack(@v[k])
          }
        end
      end

      def fetch_values(namespace, values, return_value: :all, &block)
        ns = fetch_namespace(namespace)
        return nil unless ns

        (uri, prefix) = ns
        unpack_fx = unpack_func_for(return_value)
        key_fx = lambda { |v|
          "#{uri}:#{v}"
        }
        fetch(values, @v, key_fx: key_fx, unpack_fx: unpack_fx, &block)
      end

      def fetch_equivalences(namespace, values, &block)
        ns = fetch_namespace(namespace)
        return nil unless ns

        (uri, prefix) = ns
        eq_hash = Hash.new { |hash, key| hash[key] = [] }
        values.each { |v|
          data = @e["#{uri}:#{v}"]
          next eq_hash[v] = nil unless data

          unpack(data).each_slice(5).each do |eq|
            eq_hash[v] << eq
          end
        }
        eq_hash
      end

      def fetch_target_equivalences(namespace, values, target_namespace, &block)
        ns = fetch_namespace(namespace)
        return nil unless ns
        target = fetch_namespace(target_namespace)
        return nil unless target

        uri = ns[0]
        target_uri = target[0]
        eq_hash = Hash.new { |hash, key| hash[key] = [] }
        values.each { |v|
          data = @e["#{uri}:#{v}:#{target_uri}"]
          next eq_hash[v] = nil unless data

          unpack(data).each_slice(4).each do |eq|
            eq_hash[v] << eq.insert(0, target_uri)
          end
        }
        eq_hash
      end

      def fetch_orthologs(namespace, values, &block)
        ns = fetch_namespace(namespace)
        return nil unless ns

        (uri, prefix) = ns
        eq_hash = Hash.new { |hash, key| hash[key] = [] }
        values.each { |v|
          data = @o["#{uri}:#{v}"]
          next eq_hash[v] = nil unless data

          unpack(data).each_slice(5).each do |eq|
            eq_hash[v] << eq
          end
        }
        eq_hash
      end

      def fetch_target_orthologs(namespace, values, target_namespace, &block)
        ns = fetch_namespace(namespace)
        return nil unless ns
        target = fetch_namespace(target_namespace)
        return nil unless target

        uri = ns[0]
        target_uri = target[0]
        eq_hash = Hash.new { |hash, key| hash[key] = [] }
        values.each { |v|
          data = @o["#{uri}:#{v}:#{target_uri}"]
          next eq_hash[v] = nil unless data

          unpack(data).each_slice(4).each do |eq|
            eq_hash[v] << eq.insert(0, target_uri)
          end
        }
        eq_hash
      end

      private

      def unpack(value)
        return nil unless value
        value.unpack('m*')[0].split('\0')
      end

      def unpack_func_for(value_type)
        case value_type
          when :identifier
            lambda { |value| unpack(value)[1] }
          when :prefLabel
            lambda { |value| unpack(value)[2] }
          when :title
            lambda { |value| unpack(value)[3] }
          else
            lambda { |value| unpack(value) }
        end
      end

      def fetch(value_or_enum, db,
                key_fx: raise(ArgumentError),
                map_fx: lambda { |v| v },
                unpack_fx: unpack_func_for(:all),
                &block)
        if value_or_enum.respond_to? :each
          if block
            value_or_enum.each do |v|
              key = key_fx.call(v.to_s)
              data = db[key]
              if data
                block.call map_fx.call(unpack_fx.call(data))
              else
                block.call nil
              end
            end
          else
            value_or_enum.map { |v|
              key = key_fx.call(v.to_s)
              data = db[key]
              data ? map_fx.call(unpack_fx.call(data)) : nil
            }
          end
        else
          key = key_fx.call(value_or_enum.to_s)
          data = db[key]
          val = data ? map_fx.call(unpack_fx.call(data)) : nil
          if block
            block.call val
          else
            val
          end
        end
      end
    end
  end
end
