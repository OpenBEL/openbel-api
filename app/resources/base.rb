require 'oat'

class BaseSerializer < Oat::Serializer

  protected

  def base_url
    context[:base_url]
  end
end
