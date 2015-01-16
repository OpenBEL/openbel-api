require 'oat'
require 'oat/adapters/hal'
require 'app/resources/completion'

module OpenBEL
  module Routes

    class Base < Sinatra::Application

      DEFAULT_CONTENT_TYPE = 'application/json'
      SPOKEN_CONTENT_TYPES = %w[application/json application/hal+json text/html text/xml]
      disable :protection

      before do
        unless request.preferred_type(SPOKEN_CONTENT_TYPES)
          halt 406
        end
      end

      helpers do
        def request_headers
          env.inject({}) { |hdrs, (k,v)|
            hdrs[$1.downcase] = v if k =~ /^http_(.*)/i
            hdrs
          }
        end

        def base_url
          env['HTTP_X_REAL_BASE_URL'] ||
            "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}"
        end

        def url
          env['HTTP_X_REAL_URL'] ||
            "#{env['rack.url_scheme']}://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}/#{env['PATH_INFO']}"
        end

        def resolve_supported_content_type(request)
          preferred = request.preferred_type.to_str
          if preferred == '*/*'
            DEFAULT_CONTENT_TYPE
          else
            preferred
          end
        end

        def render(obj, type)
          media_type = resolve_supported_content_type(request)
          resource_context = {
            :base_url => base_url
          }

          if obj.respond_to? :each
            # multiple
            case type
            when :completion
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                collection = obj.map { |resource|
                  {
                    :completion => CompletionJsonSerializer.new(resource, resource_context).to_hash
                  }
                }
                MultiJson.dump(collection)
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                collection = obj.map { |resource|
                  {
                    :completion => CompletionHALSerializer.new(resource, resource_context).to_hash
                  }
                }
                MultiJson.dump(collection)
              else
                response.headers['Content-Type'] = 'application/json'
                collection = obj.map { |resource|
                  {
                    :completion => CompletionJsonSerializer.new(resource, resource_context).to_hash
                  }
                }
                MultiJson.dump(collection)
              end
            else
              raise NotImplementedError.new("Cannot render type, #{type}")
            end
          else
            # single
            if media_type == 'application/json'
              response.headers['Content-Type'] = 'application/json'
              MultiJson.dump(
                CompletionSerializer.new(resource, resource_context).to_hash
              )
            elsif media_type == 'application/hal+json'
              response.headers['Content-Type'] = 'application/hal+json'
              MultiJson.dump(
                CompletionSerializer.new(resource, resource_context, Oat::Adapters::HAL).to_hash
              )
            else
              response.headers['Content-Type'] = 'application/json'
              MultiJson.dump(
                CompletionSerializer.new(resource, resource_context).to_hash
              )
            end
          end
        end

        def render_single(request, obj, title)
          content_type = resolve_supported_content_type(request)
          resource = OpenBEL::Namespace.resource_for(obj, content_type)
          case content_type
          when 'application/json'
            response.headers['Content-Type'] = 'application/json'
            resource.to_json(base_url: request.base_url, url: request.url)
          when 'application/hal+json'
            response.headers['Content-Type'] = 'application/hal+json'
            resource.to_json(base_url: request.base_url, url: request.url)
          when 'text/html'
            response.headers['Content-Type'] = 'text/html'
            template = OpenBEL::Util::path(APP_ROOT, 'views', 'obj.html')
            obj_doc = Nokogiri::HTML.parse(File.open(template))
            resource.to_html(obj_doc, title,
              base_url: request.base_url,
              url: request.url)
          when 'text/xml'
            response.headers['Content-Type'] = 'text/xml'
            resource.to_xml(base_url: request.base_url, url: request.url)
          else
            response.headers['Content-Type'] = 'application/json'
            resource.to_json(base_url: request.base_url, url: request.url)
          end
        end

        def render_multiple(request, obj, title)
          content_type = resolve_supported_content_type(request)
          resource = OpenBEL::Namespace.resource_for(obj, content_type)
          case content_type
          when 'application/json'
            response.headers['Content-Type'] = 'application/json'
            resource.to_json(base_url: request.base_url, url: request.url)
          when 'application/hal+json'
            response.headers['Content-Type'] = 'application/hal+json'
            resource.to_json(base_url: request.base_url, url: request.url)
          when 'text/html'
            response.headers['Content-Type'] = 'text/html'
            template = OpenBEL::Util::path(APP_ROOT, 'views', 'obj.html')
            obj_doc = Nokogiri::HTML.parse(File.open(template))
            resource.to_html(obj_doc, title,
              base_url: request.base_url,
              url: request.url)
          when 'text/xml'
            response.headers['Content-Type'] = 'text/xml'
            resource.to_xml(base_url: request.base_url, url: request.url)
          else
            response.headers['Content-Type'] = 'application/json'
            resource.to_json(base_url: request.base_url, url: request.url)
          end
        end

        def path(*args)
          return nil if args.empty?
          tokens = args.flatten
          tokens.reduce(Pathname(tokens.shift)) { |path, t| path += t }
        end
      end
    end
  end
end
