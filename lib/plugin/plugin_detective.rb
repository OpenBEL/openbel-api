require_relative 'plugin_descriptor'

module OpenBEL
  module PluginDetective

    class << self

      def require_plugin_descriptor_paths(paths)
        [paths].flatten.compact.each do |p|
          p << File::SEPARATOR if not p.end_with? File::SEPARATOR
          Dir["#{p}*.rb"].each do |source|
            require source
          end
        end
      end

      def find_plugin_descriptors
        # guard if there are no plugin classes defined
        return [] unless OpenBEL::const_defined? :Plugin

        plugin_descriptor_hash = Hash.new {|hash, key| hash[key] = Hash.new(&hash.default_proc)}
        OpenBEL::Plugin.constants.inject(plugin_descriptor_hash) { |hash, const|
          const = OpenBEL::Plugin::const_get(const)
          level = const.to_s.split('::').last.to_sym
          const.constants.each do |plugin_const|
            plugin_klass = const.const_get(plugin_const)
            if plugin_klass.respond_to?(:ancestors) and plugin_klass.ancestors.include?(OpenBEL::PluginDescriptor)
              hash[level][plugin_klass.name.split('::').last] = plugin_klass
            end
          end

          hash
        }
        plugin_descriptor_hash
      end
    end
  end
end
