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
        return {} unless OpenBEL::const_defined? :Plugin

        plugin_descriptor_hash = Hash.new {|hash, key| hash[key] = []}
        OpenBEL::Plugin.constants.inject(plugin_descriptor_hash) { |hash, const|
          const = OpenBEL::Plugin::const_get(const)
          level = const.to_s.split('::').last.downcase.to_sym
          const.constants.each do |plugin_const|
            plugin_klass = const.const_get(plugin_const)
            if plugin_klass.respond_to?(:ancestors) and plugin_klass.ancestors.include?(OpenBEL::PluginDescriptor)
              hash[level] << plugin_klass.new
            end
          end

          hash
        }
        plugin_descriptor_hash
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
