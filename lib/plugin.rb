module OpenBEL::Plugin

  def name
    fail NotImplementedError.new("#{__method__} not implemented")
  end

  def description
    fail NotImplementedError.new("#{__method__} not implemented")
  end

  def on_load ; end

  def create_instance(options = {}) ; end

  def on_unload ; end

  class PluginConfigureError < StandardError

    def initialize(plugin)
      @plugin = plugin
    end

    def message
      msg = super
      "[Configuration Error] #{@plugin.name}: #{msg}"
    end
  end
end
