#
#--
#
# $Id: executecommand.rb 484 2006-09-02 07:55:59Z thomas $
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

load_optional_part( 'syntax-highlighting',
                    :needed_gems => ['coderay'],
                    :error_msg => "Coderay not available, therefore syntax highlighting is not available",
                    :info => "Syntax highlighting of source code will be available (e.g. for the includeFile tag)" ) do

  require 'coderay'

end


module MiscPlugins

  class SyntaxHighlighter < Webgen::Plugin

    infos( :name => 'Misc/SyntaxHighlighter',
           :summary => "Utility plugin for syntax highlighting"
           )

    depends_on 'Core/ResourceManager'

=begin
TODO: move to doc
- coderay (gem install coderay) needed for syntax highlighting
- available syntax highlighting languages depend on version of Coderay
=end

    def initialize( plugin_manager )
      super
      @sl_available = plugin_manager.optional_part( 'syntax-highlighting' )[:loaded]
      if @sl_available
        @plugin_manager['Core/ResourceManager'].append_data( 'webgen-css', CodeRay::Encoders[:html]::CSS.new.stylesheet )
      end
    end

    # Highlights the given +content+ in language +lang+.
    def highlight( content, lang )
      if @sl_available
        CodeRay.scan( content, (lang.kind_of?( String ) ? lang.to_sym : lang ) ).html( :wrap => :div, :line_numbers => :inline )
      else
        content
      end
    end

    # Returns all available syntax highlighting languages.
    def self.available_languages
      if Object.const_defined?( :CodeRay )
        CodeRay::Scanners.all_plugin_names
      else
        []
      end
    end

  end

end
