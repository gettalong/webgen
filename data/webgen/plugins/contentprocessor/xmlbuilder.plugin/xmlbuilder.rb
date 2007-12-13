require 'builder'

module ContentProcessor

  class XmlBuilder

    def process( context )
      xml = Builder::XmlMarkup.new( :indent => 2 )
      eval( context.content )
      context.content = xml.target!
      context
    rescue Exception => e
      log(:error) { "Error using XML Builder to generate XML: #{e.message}" }
    end

  end

end
