require 'dot_hash'
require 'bel_parser'

module OpenBEL
  module Config
    include DotHash

    CFG_VAR = 'OPENBEL_API_CONFIG_FILE'

    def self.load!
      config_file = ENV[CFG_VAR] || raise('No OpenBEL API configuration found. Set the OPENBEL_API_CONFIG_FILE environment variable.')
      config = {}
      File.open(config_file, 'r:UTF-8') do |cf|
        config = YAML::load(cf)
        if not config
          config = {}
        end
      end
      cfg = Settings.new config, SilentProperties

      failure = validate cfg
      if failure
        if block_given?
          yield failure[1]
        else
          fail(<<-ERR.gsub(/^\s+/, ''))
            Configuration error within #{File.expand_path(config_file)}:
            #{failure[1]}
          ERR
        end
      end

      cfg
    end

    private

    def self.validate(cfg)
      # validate BEL version
      bel = cfg[:bel]
      unless bel
        return [
          true, <<-ERR.gsub(/ {12}/, '')
            The "bel" section has not been configured.
            You will need to supply a "bel.version" configuration block.
            #{boilerplate_help}
          ERR
        ]
      end
      bel_failure = self.validate_bel(bel)
      return bel_failure if bel_failure
      
      # validate evidence_store block
      evidence_store = cfg[:evidence_store]
      unless evidence_store
        return [
          true, <<-ERR
            An "evidence_store" is not configured.
            #{boilerplate_help}
          ERR
        ]
      end
      evidence_failure = self.validate_evidence_store(cfg[:evidence_store])
      return evidence_failure if evidence_failure

      nil
    end

    def self.validate_bel(bel)
      unless bel[:version]
        return [
          true, <<-ERR
            The "bel.version" setting is not configured. This is required to
            indicate which BEL version is supported by this OpenBEL API
            instance.
            #{boilerplate_help}
          ERR
        ]
      end

      version = bel[:version]
      unless BELParser::Language.defines_version?(version)
        defined_versions = BELParser::Language.versions
        return [
          true, <<-ERR
            The "bel.version" setting of "#{version}" is not a defined BEL version. Allowed values: #{defined_versions}
            #{boilerplate_help}
          ERR
        ]
        
      end

      nil
    end

    def self.validate_evidence_store(evidence_store)
      mongo = evidence_store[:mongo]
      unless mongo
        return [
          true, <<-ERR
            The "evidence_store.mongo" configuration block is not configured.
            #{boilerplate_help}
          ERR
        ]
      end

      required = [:host, :port, :database]

      required.each do |setting|
        unless mongo[setting]
          return [
            true, <<-ERR
              The "evidence_store.mongo.#{setting}" setting is not configured.
              #{boilerplate_help}
            ERR
          ]
        end
      end

      # Test connection to the MongoDB instance.
      require 'mongo'
      begin
        mongo_client = Mongo::MongoClient.new(mongo[:host], mongo[:port])
        mongo_client.connect
      rescue Mongo::ConnectionFailure => e
        return [
          true, <<-ERR
            Unable to connect to MongoDB at host "#{mongo[:host]}" and port "#{mongo[:port]}".
            #{boilerplate_help}

            MongoDB error:
            #{e}
          ERR
        ]
      end

      # Check Mongo server version >= 3.2.
      # The aggregation framework's $slice operator is used which requires 3.2.
      if mongo_client.server_version.to_s !~ /^3.2/
        return [
          true, <<-ERR
            MongoDB version 3.2 or greater is required.

            MongoDB version: #{mongo_client.server_version}
          ERR
        ]
      end

      # Attempt access of database.
      db = mongo_client.db(mongo[:database])

      # Authenticate user if provided.
      if mongo[:username] && mongo[:password]
        auth_db = mongo[:authentication_database] || mongo[:database]
        begin
          db.authenticate(mongo[:username], mongo[:password], nil, auth_db)
        rescue Mongo::AuthenticationError => e
          return [
            true, <<-ERR
              Unable to authenticate "#{mongo[:username]}" against the "#{auth_db}" authentication database.
              #{boilerplate_help}

              MongoDB error:
              #{e}
            ERR
          ]
        end
      end

      nil
    end

    def self.boilerplate_help
      <<-ERR.gsub(/^\s+/, '')
        Run the "openbel-config" command to see an example configuration.
        See https://github.com/OpenBEL/openbel-api/wiki/Configuring-the-Evidence-Store for details on how to configure an Evidence Store.
      ERR
    end

    class SilentProperties < Properties
      def method_missing(key, *args, &block)
        return nil unless has_key?(key)
        execute(key, *args, &block)
      end
    end
  end
end
