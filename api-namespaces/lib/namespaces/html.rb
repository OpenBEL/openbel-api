require 'representable/hash'
require 'nokogiri'

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
    def to_html(layout_doc, *args)
      obj_hash = to_hash(*args)
      obj_doc = layout_doc.clone
      span = Nokogiri::XML::Node.new('span', obj_doc)
      span.set_attribute('class', 'titled')
      span.add_child(Nokogiri::XML::Text.new('Namespace', obj_doc))
      h3 = Nokogiri::XML::Node.new('h3', obj_doc)
      h3.add_child(span)
      obj_doc.at('//div[@class="object"]').add_child(h3)
      obj_doc.to_html
    end
  end
end
# vim: ts=2 sw=2
