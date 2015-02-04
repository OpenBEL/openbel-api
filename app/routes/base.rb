require 'json_schema'
require 'multi_json'
require 'namespace/model'
require 'app/resources/completion'
require 'app/resources/evidence'
require 'app/resources/function'
require 'app/resources/namespace'
require 'app/schemas'

module OpenBEL
  module Routes

    class Base < Sinatra::Application
      include OpenBEL::Resource::Evidence
      include OpenBEL::Resource::Expressions
      include OpenBEL::Resource::Functions
      include OpenBEL::Resource::Namespaces
      include OpenBEL::Schemas

      DEFAULT_CONTENT_TYPE   = 'application/json'
      SPOKEN_CONTENT_TYPES   = %w[application/json application/hal+json text/html text/xml]
      SCHEMA_BASE_URL        = 'http://next.belframework.org/schema/'
      RESOURCE_SERIALIZERS   = {
        :completion                 => CompletionResourceSerializer,
        :completion_collection      => CompletionCollectionSerializer,
        :function                   => FunctionResourceSerializer,
        :function_collection        => FunctionCollectionSerializer,
        :namespace                  => NamespaceResourceSerializer,
        :namespace_collection       => NamespaceCollectionSerializer,
        :namespace_value            => NamespaceValueResourceSerializer,
        :namespace_value_collection => NamespaceValueCollectionSerializer,
        :evidence                   => EvidenceResourceSerializer,
        :evidence_collection        => EvidenceCollectionSerializer
      }

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

        def schema_url(name)
          SCHEMA_BASE_URL + "#{name}.schema.json"
        end

        def validate_media_type!(content_type, options = {})
          ctype = request.content_type
          valid = ctype.start_with? content_type
          if options[:profile]
            valid &= (%r{profile=#{options[:profile]}} =~ ctype)
          end

          halt 415 unless valid
        end

        def resolve_supported_content_type(request)
          preferred = (request.preferred_type || '*/*').to_str
          if preferred == '*/*'
            DEFAULT_CONTENT_TYPE
          else
            preferred
          end
        end

        def read_json
          request.body.rewind
          MultiJson.load request.body.read
        end

        def render_json(obj, media_type = 'application/json', profile = nil)
          ctype =
            if profile
              "#{media_type}; profile=#{profile}"
            else
              media_type
            end
          response.headers['Content-Type'] = ctype
          MultiJson.dump obj
        end

        def validate_schema(data, type)
          self.validate(data, type)
        end

        def render(obj, type, options = {})
          media_type = resolve_supported_content_type(request)
          resource_context = {
            :base_url => base_url,
            :url      => url
          }.merge(options)

          serializer_class = RESOURCE_SERIALIZERS[type]
          if not serializer_class
            raise NotImplementedError.new("Cannot serialize the #{type} resource.")
          end

          adapter =
            case media_type
            when 'application/hal+json'
              Oat::Adapters::HAL
            else
              media_type = 'application/json'
              Oat::Adapters::BasicJson
            end

          render_json(
            serializer_class.new(obj, resource_context, adapter).to_hash,
            media_type
          )
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
