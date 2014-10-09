module OpenBEL::Plugin::Storage
  include OpenBEL::Plugin

  NAME = 'Redland RDF Storage'
  DESC = 'Storage of RDF using the Redland libraries over FFI.'
  TYPE_OPTION_VALUES = [ :memory, :sqlite ]
  DEFAULT_OPTIONS = {
    :type => :memory
  }

  def name
    NAME
  end

  def description
    DESC
  end

  def on_load
    require_relative '../lib/storage/redland'
  end

  def create_instance(options = {})
    options = DEFAULT_OPTIONS.merge(options)

    type = options.delete(:type)
    if not type
      fail PluginConfigureError.new(self), "The 'type' option is required. Options are one of [#{TYPE_OPTION_VALUES.join(', ')}]."
    end
    type = type.to_sym
    if not TYPE_OPTION_VALUES.include?(type)
      fail PluginConfigureError.new(self), "The 'type' option is not supported. Options are one of [#{TYPE_OPTION_VALUES.join(', ')}]."
    end

    Redlander::Model.new :storage => type
  end
end
