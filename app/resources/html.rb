require 'representable/hash'
require 'nokogiri'
require 'uri'

module OpenBEL
  module HTML
    extend Representable::Hash::ClassMethods
    include Representable::Hash

    def self.included(base)
      base.class_eval do
        include Representable # either in Hero or HeroRepresentation.
        extend ClassMethods # DISCUSS: do that only for classes?
        extend Representable::Hash::ClassMethods  # DISCUSS: this is only for .from_hash, remove in 2.3?
      end
    end

    module ClassMethods
      # Creates a new object from the passed JSON document.
      def from_html(*args, &block)
        create_represented(*args, &block).from_html(*args)
      end

      private

      def representer_engine
        Representable::HTML
      end
    end

    # Parses the body as JSON and delegates to #from_hash.
    def from_html(data, *args)
      fail NotImplementedError
    end

    # Returns a JSON string representing this object.
    def to_html(layout_doc, title, *args)
      obj_hash = to_hash(*args)
      obj_doc = layout_doc.clone
      body = obj_doc.at('/html/body/div')
      object_div = make_object(obj_doc, obj_hash, title)
      body.add_child(object_div)
      obj_doc.to_html
    end

    def make_object(doc, obj, name)
      div = Nokogiri::XML::Node.new('div', doc)

      span = Nokogiri::XML::Node.new('span', doc)
      span.add_child(Nokogiri::XML::Text.new(name, doc))
      h3 = Nokogiri::XML::Node.new('h3', doc)
      h3.add_child(span)

      table = Nokogiri::XML::Node.new('table', doc)
      tbody = Nokogiri::XML::Node.new('tbody', doc)
      tr = Nokogiri::XML::Node.new('tr', doc)
      th = Nokogiri::XML::Node.new('th', doc)
      th.add_child(Nokogiri::XML::Text.new('Name', doc))
      tr.add_child(th)
      th = Nokogiri::XML::Node.new('th', doc)
      th.add_child(Nokogiri::XML::Text.new('Value', doc))
      tr.add_child(th)
      tbody.add_child(tr)

      if obj.is_a? Array
        obj.each_with_index do |item, index|
          tr = Nokogiri::XML::Node.new('tr', doc)
          th = Nokogiri::XML::Node.new('th', doc)
          th.add_child(Nokogiri::XML::Text.new(index.to_s, doc))
          tr.add_child(th)

          th = Nokogiri::XML::Node.new('th', doc)
          th.add_child(make_object(doc, item, ''))
          tr.add_child(th)
          tbody.add_child(tr)
        end
      else
        obj.each do |k, v|
          tr = Nokogiri::XML::Node.new('tr', doc)
          th = Nokogiri::XML::Node.new('th', doc)
          th.add_child(Nokogiri::XML::Text.new(k.to_s, doc))
          tr.add_child(th)
          th = Nokogiri::XML::Node.new('th', doc)
          uri_value = nil
          begin
            uri_value = v if URI.parse(v).scheme
          rescue URI::InvalidURIError
            uri_value = nil
          end

          if uri_value
            anchor = Nokogiri::XML::Node.new('a', doc)
            anchor.set_attribute('href', v)
            anchor.add_child(Nokogiri::XML::Text.new(uri_value, doc))
            th.add_child(anchor)
          elsif v.is_a? Hash
            th.add_child(make_object(doc, v, ''))
          elsif v.is_a? Array
            v.each { |x| th.add_child(make_object(doc, x, '')) }
          else
            th.add_child(Nokogiri::XML::Text.new(v.to_s, doc))
          end
          tr.add_child(th)
          tbody.add_child(tr)
        end
      end

      table.add_child(tbody)
      div.add_child(h3)
      div.add_child(table)
      div
    end
  end
end
# vim: ts=2 sw=2
