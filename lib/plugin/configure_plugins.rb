require_relative '../helpers/dependency_graph'

module OpenBEL
  module ConfigurePlugins

    def check_configuration(plugins, config)
      sorted_plugin_config_ids = build_dependency_graph(config)

      all_errors = []
      valid_plugins = {}
      sorted_plugin_config_ids.each do |plugin_config_id|
        # validate plugin configuration...
        plugin_config = config[plugin_config_id.to_s]

        # ...check plugin defines required properties
        ['type', 'plugin'].each do |p|
          errors << %Q{The "#{p}" property (defined in "#{plugin_config_id}") does not define a type.} unless plugin_config.has_key?(p)
          next
        end
        type = plugin_config['type']
        plugin_id = plugin_config['plugin']

        # ...check if any plugin(s) are loaded for specified type
        if plugins.none? { |p| p.type.to_s.to_sym == type.to_s.to_sym }
          errors << %Q{The "#{type}" type (defined in "#{plugin_config_id}") does not have any registered plugins.}
        end

        # ...check if plugin exists
        plugin = plugins.find { |p| p.id == plugin_id }
        unless plugin
          errors << %Q{The "#{plugin_id}" plugin (defined in "#{plugin_config_id}") does not have any registered plugins.}
        end

        # ...check plugin extensions
        extensions = plugin_config['extensions'] || {}
        extensions.values.find_all { |ext|
          not valid_plugins.has_key? ext.to_s
        }.each do |ext|
          all_errors << %Q{The "#{ext}" extension (defined in "#{plugin_config_id}") is not valid.}
        end

        # ...prepare extensions/options for plugin validation
        extensions = Hash[extensions.map { |ext_type, ext_id|
          [ext_type.to_s.to_sym, valid_plugins[ext_id.to_s]]
        }]
        options = Hash[(plugin_config['options'] || {}).map { |k, v|
          [k.to_s.to_sym, v]
        }]

        # ...call plugin-specific validation
        plugin_errors = [plugin.validate(extensions.dup, options.dup)].flatten.map(&:to_s)
        if plugin_errors.empty?
          valid_plugins[plugin_config_id.to_s] = plugin
        else
          all_errors.concat(plugin_errors)
        end
        # TODO Log successful plugin check if verbose.
      end
      all_errors
    end

    def configure_plugins(plugins, config)
      sorted_plugin_config_ids = build_dependency_graph(config)
      sorted_plugin_config_ids.inject({}) { |plugins_by_id, plugin_config_id|
        plugin_config = config[plugin_config_id.to_s]

        plugin_id = plugin_config['plugin']

        plugin = plugins.find { |p| p.id == plugin_id }
        extensions = Hash[(plugin_config['extensions'] || {}).map { |type, id|
          [type.to_s.to_sym, plugins_by_id[id.to_s]]
        }]
        options = Hash[(plugin_config['options'] || {}).map { |k, v|
          [k.to_s.to_sym, v]
        }]

        plugin.configure(extensions.dup, options.dup)
        plugin.on_load

        plugins_by_id[plugin_config_id.to_s] = plugin
        plugins_by_id
      }
    end

    private

    def build_dependency_graph(config)
      dependency_graph = Helpers::DependencyGraph.new
      config.keys.each do |plugin_key|
        block = config[plugin_key]
        dependencies = (block['extensions'] || {}).each_value.to_a.map { |v| v.to_s.to_sym }
        dependency_graph.add_dependency(plugin_key.to_s, *dependencies)
      end
      dependency_graph.tsort
    end
  end
end
