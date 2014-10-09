module OpenBEL::Plugin::Cache
  include OpenBEL::Plugin

  ABBR = 'kc'
  NAME = 'KyotoCabinet Cache'
  DESC = 'Cache implementation using KyotoCabinet over FFI.'
  MEMR_TYPES = [ :"memory-hash" ]
  FILE_TYPES = [ :"file-hash" ]
  TYPE_OPTION_VALUES = [ MEMR_TYPES, FILE_TYPES ].flatten
  MODE_OPTION_VALUES = [ :reader, :writer, :create ]
  DEFAULT_OPTIONS = {
    :type => :protohash,
    :mode => [:writer, :create]
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
    require_relative '../lib/cache/kyotocabinet'
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

    mode = options.delete(:mode)
    if not mode
      fail PluginConfigureError.new(self), "The 'mode' option is required. Options are one of [#{MODE_OPTION_VALUES.join(', ')}]."
    end

    file = options.delete(:file)
    if not file and FILE_TYPES.include?(type)
      fail PluginConfigureError.new(self), "The 'file' option is required for file database types."
    end

    case type
    when :"memory-hash"
      KyotoCabinet::Db::MemoryHash.new mode
    when :"file-hash"
      KyotoCabinet::Db::FileHash.new file, mode
    end
  end
end
