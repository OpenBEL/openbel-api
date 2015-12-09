require 'pathname'

module OpenBEL
  module PluginRepository
    include Enumerable

    WRITE_MUTEX = Mutex.new

    def with_plugins_from(*paths)
      WRITE_MUTEX.lock
      begin
        (@paths ||= []).concat paths.flatten.compact.uniq
      ensure
        WRITE_MUTEX.unlock
      end
      self
    end

    def find_plugins(id, type = nil)
      find_all { |p|
        ([p.id, p.name].include? id) and (!type or p.type == type.to_s.to_sym)
      }
    end

    def each
      WRITE_MUTEX.lock
      begin
        @paths ||= []
        if block_given?
          require_plugins(@paths)
          plugins.each { |p| yield p.new }
        else
          enum_for(:each)
        end
      ensure
        WRITE_MUTEX.unlock
      end
    end
    alias_method :each_plugin, :each

    private

    def plugins
      OpenBEL::PluginClasses.uniq
    end

    def require_plugins(paths)
      [paths].flatten.compact.uniq.each do |p|
        p << File::SEPARATOR if not p.end_with? File::SEPARATOR
        Dir["#{p}*.rb"].each do |source|
          if Pathname.new(source).absolute?
            require source
          else
            require ".#{File::SEPARATOR}#{source}"
          end
        end
      end
    end
  end
end
