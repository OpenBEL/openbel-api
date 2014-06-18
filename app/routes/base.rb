module OpenBEL
  module Routes

    class Base < Sinatra::Application

      register Sinatra::ConfigFile
      config_file "config.yml"

      SPOKEN_CONTENT_TYPES = %w[application/json text/html text/xml]

      before do
        unless request.preferred_type(SPOKEN_CONTENT_TYPES)
          halt 406
        end
      end

      helpers do

        def resolve_supported_content_type(request)
          preferred = request.preferred_type.to_str
          if preferred == '*/*'
            'application/json'
          else
            preferred
          end
        end

        def render_single(request, obj, title)
          content_type = resolve_supported_content_type(request)
          resource = OpenBEL::Namespace.resource_for(obj, content_type)
          case content_type
          when 'application/json'
            response.headers['Content-Type'] = 'application/json'
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
          end
        end

        def render_multiple(request, obj, title)
          content_type = resolve_supported_content_type(request)
          resource = OpenBEL::Namespace.resource_for(obj, content_type)
          case content_type
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
