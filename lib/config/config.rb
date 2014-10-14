require 'yaml'
require 'pp'
require_relative '../plugin/plugin_detective'
require_relative '../helpers/dependency_graph'

module OpenBEL
  module Config

    CFG_VAR = 'OPENBEL_SERVER_CONFIG'
    RESERVED_PROPS = ['plugin_descriptor_paths']

    def self.load(config_file=nil)
      # determine config file
      config_file = ENV[CFG_VAR] || config_file
      fail %Q{The configuration file is empty.} unless config_file

      # read config file
      config = {}
      File.open(config_file, 'r:UTF-8') do |cf|
        config = YAML::load(cf)
        if not config
          config = {}
        end
      end

      # load plugin descriptor paths
      plugin_desc_paths = config['plugin_descriptor_paths']
      if plugin_desc_paths
        fail %Q{The "plugin_descriptor_paths" property must be a list.} unless plugin_desc_paths.kind_of? Array
        PluginDetective::require_plugin_descriptor_paths(plugin_desc_paths)
      end

      # load plugin descriptors
      plugin_descriptor_hash = PluginDetective::find_plugin_descriptors

      # build topologically sorted dependency graph
      dependency_graph = Helpers::DependencyGraph.new
      (config.keys - RESERVED_PROPS).each do |plugin_key|
        block = config[plugin_key]
        dependencies = (block['extensions'] || {}).each_value.to_a.map { |v| v.to_s.to_sym }
        dependency_graph.add_dependencies(plugin_key.to_s.to_sym, dependencies)
      end
      topologically_sorted_plugins = dependency_graph.tsort

      # configure plugins
      loaded = {}
      topologically_sorted_plugins.each do |plugin_key|
        cfg = config[plugin_key.to_s]
        ['type', 'plugin'].each do |p|
          fail %Q{The "#{p}" property ("#{plugin_key}") does not define a type.} unless cfg.has_key?(p)
        end
        type = cfg['type']
        plugin = cfg['plugin']
        descriptors_for_type = plugin_descriptor_hash[type.to_s.to_sym]
        if not descriptors_for_type or descriptors_for_type.empty?
          fail %Q{The "#{type}" type ("#{plugin_key}" plugin) does not have any registered plugins.}
        end
        desc = descriptors_for_type.find { |desc|
          [desc.abbreviation, desc.name].any? { |value| value == plugin }
        }
        extensions = Hash[(cfg['extensions'] || {}).map { |type, id|
          [type.to_s.to_sym, loaded[id.to_s.to_sym]]
        }]
        options = Hash[(cfg['options'] || {}).map { |k, v|
          [k.to_s.to_sym, v]
        }]

        errors = [desc.validate(extensions.dup, options.dup)].flatten
        fail errors.join("\n") if not errors.empty?
        desc.configure(extensions.dup, options.dup)

        desc.on_load

        loaded[plugin_key] = desc
      end

      loaded
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
