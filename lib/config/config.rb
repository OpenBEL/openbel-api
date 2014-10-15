require 'yaml'
require_relative '../plugin/plugin_manager'

module OpenBEL
  module Config

    CFG_VAR = 'OPENBEL_SERVER_CONFIG'
    PLUGIN_PATHS = 'plugin_paths'

    def self.load(config_file=nil)
      config_file = ENV[CFG_VAR] || config_file
      fail %Q{The configuration file is empty.} unless config_file

      config = File.open(config_file, 'r:UTF-8') do |cf|
        {}.merge(YAML::load(cf))
      end

      plugin_manager = PluginManager.new
      plugin_manager.with_plugins_from([config.delete(PLUGIN_PATHS)].flatten.compact.map(&:to_s))
      plugins = plugin_manager.to_a

      errors = plugin_manager.check_configuration(plugins, config)

      fail errors.join("\n") if not errors.empty?

      plugin_manager.configure_plugins(plugins.dup, config.dup)
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
