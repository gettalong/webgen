#
#--
#
# $Id: textile.rb 501 2006-09-09 17:25:43Z thomas $
#
# webgen: template based static website generator
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#


load_optional_part( 'content-converter-xmlbuilder',
                    :needed_gems => ['builder'],
                    :error_msg => "XML Builder not available as content format as it could not be loaded",
                    :info => "The builder library can be used to create XHTML/XML content" ) do

  require 'builder'
  load_plugin 'webgen/plugins/contentconverters/default'

  module ContentConverters

    # Handles content in Textile format using RedCloth.
    class XmlBuilderConverter < DefaultContentConverter

      infos( :name => 'ContentConverter/XmlBuilder',
             :author => Webgen::AUTHOR,
             :summary => "Handles content structured using the XML Builder library"
             )

      register_handler 'xmlbuilder'

=begin
TODO: move to doc
- the xml builder object is provided through the xml object in an XML builder block
=end

      def call( content )
        xml = Builder::XmlMarkup.new( :indent => 2 )
        eval( content )
        xml.target!
      rescue Exception => e
        log(:error) { "Error using XML Builder to generate HTML: #{e.message}" }
        content
      end

    end

  end

end
