require 'rspec'
require 'hyperclient'
require 'json'

# silence rantly output
ENV['RANTLY_VERBOSE'] = '0'

HAL                   = 'application/hal+json'
HAL_REGEX             = Regexp.escape(HAL)
HTTP_OK               = 200

def api_root
  ENV['API_ROOT_URL'] || (raise RuntimeError.new('API_ROOT_URL is not set'))
end

def root_resource(resource_name)
  api_client                         = Hyperclient.new(api_root) do |c|
    c.connection do |conn|
      conn.adapter  Faraday.default_adapter
      #conn.response :logger
      conn.response :json, :content_type => 'application/hal+json'
    end
  end
  api_client.headers['Content-Type'] = 'application/json'
  resource = api_client._links.item.find { |item|
    item._url =~ %r{/#{resource_name}$}
  }

  unless resource
    msg = "#{resource_name.to_s.capitalize} API _link cannot be found."
    raise RuntimeError.new(msg)
  end

  resource
end

def api_conn
  Faraday.new(:url => api_root) do |builder|
    builder.adapter  Faraday.default_adapter
    #builder.response :logger
    builder.response :json, :content_type => 'application/hal+json'
  end
end

def test_file(name)
  File.open(
    File.join(
      File.dirname(File.expand_path(__FILE__)),
      'test_data',
      name
    ),
    :ext_enc => Encoding::UTF_8
  )
end

def post_and_get(content, url)
  data =
    case
    when content.respond_to?(:read)
      content.read
    when content.respond_to?(:each_pair)
      JSON.dump(content)
    else
      content.to_s
    end

  response = api_conn.post(url) { |req|
    req.headers['Content-Type'] = 'application/json; charset=utf-8'
    req.body                    = data
  }

  location = response['Location']
  response = api_conn.get location

  if block_given?
    begin
      yield response
    ensure
      api_conn.delete location
    end
  else
    response
  end
end
