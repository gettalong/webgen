#
#--
#
# $Id$
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

load_plugin 'webgen/plugins/tags/tag_processor'
require 'uri'

module Tags

  # Changes the path of file. This is very useful for templates. For example, you normally include a
  # stylesheet in a template. If you specify the filename of the stylesheet directly, the reference
  # to the stylesheet in the output file of a page file that is not in the same directory as the template
  # would be invalid.
  #
  # By using the +relocatable+ tag you ensure that the path stays valid.
  #
  # Tag parameter: the name of the file which should be relocated
  class RelocatableTag < DefaultTag

    infos :summary => 'Adds a relative path to the specified name if necessary'
    param 'path', nil, 'The path which should be relocatable'
    param 'resolveFragment', true, 'Specifies if the fragment part (#something) in the path should also be resolved'
    set_mandatory 'path', true

    register_tag 'relocatable'

=begin
TODO: move to doc
- resolves absolute and relative URLs
- basically, output names are searched for
- extension: standardized page names can also be used
  - without language part: searches for page in current language
  - with language part: uses exact language file
- extension: directory index files are resolved if only directory name specified
=end

    def process_tag( tag, chain )
      uri_string = param( 'path' )
      result = ''
      unless uri_string.nil?
        begin
          uri = URI.parse( uri_string )
          if uri.absolute?
            result = uri_string
          else
            result = resolve_path( uri, chain )
          end
          log(:error) { "Could not resolve path '#{uri_string}' in <#{chain.first.node_info[:src]}>" } if result.empty?
        rescue URI::InvalidURIError => e
          log(:error) { "Error while parsing path for tag relocatable in <#{chain.first.node_info[:src]}>: #{e.message}" }
        end
      end
      result
    end

    #######
    private
    #######

    def query_fragment( uri )
      (uri.query.nil? ? '' : '?'+ uri.query ) + (uri.fragment.nil? ? '' : '#' + uri.fragment)
    end

    def resolve_path( uri, chain )
      dest_node = chain.first.resolve_node( uri.path )
      if !dest_node.nil? && (File.basename( uri.path ) == dest_node.node_info[:pagename] || dest_node.is_directory?)
        dest_node = dest_node.node_for_lang( chain.last['lang'] )
      end
      if !dest_node.nil? && !uri.fragment.nil? && param( 'resolveFragment' )
        dest_node = dest_node.resolve_node( '#' + uri.fragment )
      end
      if dest_node.nil?
        ''
      else
        chain.last.route_to( dest_node.is_fragment? ? dest_node.parent : dest_node ) + query_fragment( uri )
      end
    end

  end

end
