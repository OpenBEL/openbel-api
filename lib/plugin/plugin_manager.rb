require_relative 'configure_plugins'
require_relative 'plugin_repository'

module OpenBEL

  class PluginManager
    include ConfigurePlugins
    include PluginRepository

    def report_plugins_available
      map { |plugin|
        "id: #{plugin.id}
  name:        #{plugin.name}
  description: #{plugin.description}
  class:       #{plugin.class}
        "
      }
    end
  end
end
