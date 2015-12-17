require 'pathname'
require 'multi_json'
require 'json_schema'

module OpenBEL
  module Schemas

    COMPILED_SCHEMAS = {}
    SCHEMA_DIR = File.join(File.expand_path(File.dirname(__FILE__)), 'schemas')
    SUFFIX     = ".schema.json"

    def validate(data, type)
      _get_schema(type).validate(data)
    end

    private

    def _get_schema(type)
      schemas = @@compiled ||= {}
      schemas[type] ||= _compile_schema(type)
    end

    def _compile_schema(type)
      path = (Pathname(SCHEMA_DIR) + "#{type}#{SUFFIX}").to_s
      if File.exists? path
        schema_data = MultiJson.load File.read(path)
        JsonSchema.parse!(schema_data)
      else
        fail IOError.new "No schema file for type: #{type} at path: #{path}"
      end
    end
  end
end

