require_relative '../../api.rb'

module Kernel
  def include_redland_extension
    # by configuration
    if ENV[OpenBEL::REDLAND_IMPLEMENTATION]
      value = ENV[OpenBEL::REDLAND_IMPLEMENTATION]
      if value == 'librdf'
        puts "loading librdf by configuration"
        fail(RuntimeError, "The librdf implementation could not be loaded!") unless librdf?
        include OpenBEL::LibRdfStorage
      elsif value == 'redlander'
        puts "loading redlander by configuration"
        fail(RuntimeError, "The redlander implementation could not be loaded!") unless redlander?
        include OpenBEL::RedlanderStorage
      else
        fail RuntimeError, "The #{value} implementation is incorrect"
      end
      return
    end

    # by preference
    if redlander?
      puts "loading redlander by preference"
      include OpenBEL::RedlanderStorage
    elsif librdf?
      puts "loading librdf by preference"
      include OpenBEL::LibRdfStorage
    else
      fail RuntimeError, "Redland implementation not found (e.g. librdf or redlander)."
    end
  end

  def redlander?
    begin
      require 'redlander'
      require_relative 'redlander/storage'
      return true
    rescue
      return false
    end
  end

  def librdf?
    begin
      require 'rdf/redland'
      require_relative 'librdf/storage'
      return true
    rescue LoadError
      return false
    end
  end
end

module OpenBEL

  REDLAND_IMPLEMENTATION = 'OPENBEL_REDLAND_IMPLEMENTATION'

  class Storage
    include OpenBEL::StorageAPI
    include_redland_extension

    DEFAULTS = {
      storage: 'sqlite',
      name: 'rdf.db',
      synchronous: 'off'
    }

    def initialize(options = {})
      options = Hash[options.map {|k,v| [k.to_sym, v]}]
      options = DEFAULTS.merge(options)
      model(options)
    end

    def triples(subject, predicate, object, options={})
      # option "only": subsets each triple as desired
      map_method = options[:only]
      if map_method && self.respond_to?(map_method)
        map_method = self.method(map_method)
      end
      map_method ||= self.method(:all)

      enum = statement_enumerator(subject, predicate, object, options).each
      if block_given?
        enum.each { |triple| yield map_method.call(triple) }
      else
        enum = enum.respond_to?(:lazy) ? enum.lazy : enum
        enum.map(&map_method)
      end
    end
  end
end
# vim: ts=2 sts=2 sw=2 expandtab
# encoding: utf-8
