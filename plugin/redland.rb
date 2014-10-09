module OpenBEL::Plugin::Storage
  include OpenBEL::Plugin

  ABBR = 'redland'
  NAME = 'Redland RDF Storage'
  DESC = 'Storage of RDF using the Redland libraries over FFI.'
  STORAGE_OPTION_VALUES = [ :memory, :sqlite ]
  DEFAULT_OPTIONS = {
    :storage => :memory
  }

  def abbreviation
    ABBR
  end

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

    storage = options.delete(:storage)
    if not storage
      fail PluginConfigureError.new(self), "The 'storage' option is required. Options are one of [#{STORAGE_OPTION_VALUES.join(', ')}]."
    end
    storage = storage.to_sym
    if not STORAGE_OPTION_VALUES.include?(storage)
      fail PluginConfigureError.new(self), "The 'storage' option is not supported. Options are one of [#{STORAGE_OPTION_VALUES.join(', ')}]."
    end

    OpenBEL::Storage::Redlander.new(options)
  end
end
