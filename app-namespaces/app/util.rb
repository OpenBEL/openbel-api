require 'pathname'

module OpenBEL
  module Util
    def self.path(*args)
      return nil if args.empty?
      tokens = args.flatten
      tokens.reduce(Pathname(tokens.shift)) { |path, t| path += t }
    end
  end
end
