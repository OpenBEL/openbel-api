require 'oat'
require 'oat/adapters/hal'
require_relative 'adapters/basic_json'

class BaseSerializer < Oat::Serializer

  protected

  def url
    context[:url]
  end

  def base_url
    context[:base_url]
  end
end
