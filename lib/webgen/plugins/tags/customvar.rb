#
#--
#
# $Id: meta.rb 563 2006-12-29 08:59:41Z thomas $
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

module Tags

  class CustomVarTag < DefaultTag

    infos( :name => 'Tag/CustomVar',
           :author => Webgen::AUTHOR,
           :summary => "Used to output custom variables defined in Core/Configuration:customVars."
           )

    param 'var', nil, 'The variable of which the value should be retrieved.'
    set_mandatory 'var', true

    register_tag 'customVar'

    def process_tag( tag, chain )
      output = ''
      customVars = param( 'customVars', 'Core/Configuration' )
      var = param( 'var' )

      if customVars.kind_of?( Hash ) && customVars.has_key?( var )
        output = customVars[var]
      else
        log(:warn) { "No custom variable called '#{var}' found in Core/Configuration:customVars (file <#{chain.first.node_info[:src]}>)" }
      end
      output
    end

  end

end
