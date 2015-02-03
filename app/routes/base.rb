require 'json_schema'
require 'multi_json'
require 'oat'
require 'oat/adapters/hal'
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

        def validate_schema(data, type)
          self.validate(data, type)
        end

        def render(obj, type, options = {})
          media_type = resolve_supported_content_type(request)
          resource_context = {
            :base_url => base_url,
            :url      => url
          }.merge(options)

          if obj.kind_of?(Array)
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
            when :function
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  FunctionCollectionJsonSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  FunctionCollectionHALSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  FunctionCollectionJsonSerializer.new(obj, resource_context).to_hash
                )
              end
            when :namespace
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  NamespaceCollectionJsonSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  NamespaceCollectionHALSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  NamespaceCollectionJsonSerializer.new(obj, resource_context).to_hash
                )
              end
            when :"namespace-value"
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  NamespaceValueCollectionJsonSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  NamespaceValueCollectionHALSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  NamespaceValueCollectionJsonSerializer.new(obj, resource_context).to_hash
                )
              end
            when :evidence
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  EvidenceCollectionJsonSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  EvidenceCollectionHALSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  EvidenceCollectionJsonSerializer.new(obj, resource_context).to_hash
                )
              end
            else
              raise NotImplementedError.new("Cannot render type, #{type}")
            end
          else
            # single
            case type
            when :completion
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  CompletionSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  CompletionSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  CompletionSerializer.new(obj, resource_context).to_hash
                )
              end
            when :function
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  FunctionJsonSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  FunctionHALSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  FunctionJsonSerializer.new(obj, resource_context).to_hash
                )
              end
            when :namespace
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  NamespaceJsonSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  NamespaceHALSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  NamespaceJsonSerializer.new(obj, resource_context).to_hash
                )
              end
            when :"namespace-value"
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  NamespaceValueJsonSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  NamespaceValueHALSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  NamespaceValueJsonSerializer.new(obj, resource_context).to_hash
                )
              end
            when :evidence
              if media_type == 'application/json'
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  EvidenceJsonSerializer.new(obj, resource_context).to_hash
                )
              elsif media_type == 'application/hal+json'
                response.headers['Content-Type'] = 'application/hal+json'
                MultiJson.dump(
                  EvidenceHALSerializer.new(obj, resource_context).to_hash
                )
              else
                response.headers['Content-Type'] = 'application/json'
                MultiJson.dump(
                  EvidenceJsonSerializer.new(obj, resource_context).to_hash
                )
              end
            else
              raise NotImplementedError.new("Cannot render type, #{type}")
            end
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
