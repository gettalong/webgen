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

module PictureGalleryLayouter

  class DefaultGalleryLayouter < Webgen::Plugin

    summary "Base class for all Picture Gallery Layouters and, at the same time, default layouter"

    # Associates a specific layout name with a layouter.
    def self.layout_name( name )
      (Webgen::Plugin.config[DefaultGalleryLayouter.name].layouter ||= {})[name] = self.name
      Webgen::Plugin.config[self.name].layout = name
    end

    layout_name 'default'

    # Returns the layouter called +name+.
    def layouter( name )
      if Webgen::Plugin.config[DefaultGalleryLayouter.name].layouter.has_key?( name )
        Webgen::Plugin.config[Webgen::Plugin.config[DefaultGalleryLayouter.name].layouter[name]].obj
      else
        self.logger.error { "Invalid gallery layouter specified: #{name}! Using DefaultGalleryLayouter" }
        Webgen::Plugin['DefaultGalleryLayouter']
      end
    end

    # Returns the thumbnail img tag for the given +image+.
    def thumbnail_tag_for_image( image )
      if image['thumbnail'] != image['imageFilename']
        "<img src='#{image['thumbnail']}' alt='#{image['title']}' />"
      else
        "<img src='#{image['imageFilename']}' width='100' height='100' alt='#{image['title']}'/>"
      end
    end

    # Returns the gallery index of the previous gallery, if it exists, or +nil+ otherwise.
    def prev_gallery( data, gIndex )
      gIndex != 0 ? gIndex - 1 : nil
    end

    # Returns the gallery index of the next gallery, if it exists, or +nil+ otherwise.
    def next_gallery( data, gIndex )
      gIndex != data['galleries'].length - 1 ? gIndex + 1 : nil
    end

    # Returns the gallery and image indices of the previous picture, if it exists, or +nil+ otherwise.
    def prev_picture( data, gIndex, iIndex )
      result = nil
      if gIndex != 0 || iIndex != 0
        if iIndex == 0
          gIndex -= 1
          iIndex = data['galleries'][gIndex]['imageList'].length - 1
        else
          iIndex -= 1
        end
        result = [gIndex, iIndex]
      end
      return result
    end

    # Returns the gallery and image indices of the next picture, if it exists, or +nil+ otherwise.
    def next_picture( data, gIndex, iIndex )
      result = nil
      if gIndex != data['galleries'].length - 1 || iIndex != data['galleries'][gIndex]['imageList'].length - 1
        if iIndex == data['galleries'][gIndex]['imageList'].length - 1
          gIndex += 1
          iIndex = 0
        else
          iIndex += 1
        end
        result = [gIndex, iIndex]
      end
      return result
    end

    # Should be overwritten by subclasses! +data+ is the data structure which holds all information
    # about the gallery.
    def main( data )
      s = "
<h2>#{data['title']}</h2>
<div class=\"webgen-gallery\">
<table>
"
      0.step( data['galleries'].length - 1, 5 ) do |i|
        s += "<tr>"
        s += data['galleries'][i...i+5].collect {|g| "<td><a href=\"#{g['srcName']}\">#{thumbnail_tag_for_image( g['imageList'][0] )}<br />#{g['title']}</a></td>"}.join( "\n" )
        s += "</tr>"
      end
      s += "</table></div>"
    end

    # Should be overwritten by subclasses! +data+ is the data structure which holds all information
    # about the gallery. +gIndex+ is the index of the current gallery.
    def gallery( data, gIndex )

      s = "
<h2>#{data['galleries'][gIndex]['title']}</h2>
<div class=\"webgen-gallery\">
"

      s += "<a href=\"#{data['srcName']}\">^&nbsp;#{data['title']}&nbsp;^</a><br />" unless data['pageNotUsed']
      prevIndex = prev_gallery( data, gIndex )
      nextIndex = next_gallery( data, gIndex )
      s += "<a href=\"#{data['galleries'][prevIndex]['srcName']}\">&lt;&nbsp;#{data['galleries'][prevIndex]['title']}</a>" unless prevIndex.nil?
      s += "&nbsp;&mdash;&nbsp;" unless prevIndex.nil? || nextIndex.nil?
      s += "<a href=\"#{data['galleries'][nextIndex]['srcName']}\">#{data['galleries'][nextIndex]['title']}&nbsp;&gt;</a>" unless nextIndex.nil?

      s += "<table>"
      0.step( data['galleries'][gIndex]['imageList'].length - 1, 5 ) do |i|
        s += "<tr>"
        s += data['galleries'][gIndex]['imageList'][i...i+5].collect {|i| "<td><a href=\"#{i['srcName']}\">#{thumbnail_tag_for_image( i )}<br />#{i['title']}</a></td>"}.join( "\n" )
        s += "</tr>"
      end
      s += "</table></div>"
    end

    # Should be overwritten by subclasses! +data+ is the data structure which holds all information
    # about the gallery. +gIndex+ is the index of the current gallery. +iIndex+ is the index of the
    # current image.
    def picture( data, gIndex, iIndex )
      s = "
<h2>#{data['galleries'][gIndex]['imageList'][iIndex]['title']}</h2>
<div class=\"webgen-picture\">
"
      s += "<a href=\"#{data['galleries'][gIndex]['srcName']}\">^&nbsp;#{data['galleries'][gIndex]['title']}&nbsp;^</a><br />"
      prevGIndex, prevIIndex = prev_picture( data, gIndex, iIndex )
      nextGIndex, nextIIndex = next_picture( data, gIndex, iIndex )
      s += "<a href=\"#{data['galleries'][prevGIndex]['imageList'][prevIIndex]['srcName']}\">" \
      "&lt;&nbsp;#{data['galleries'][prevGIndex]['imageList'][prevIIndex]['title']}</a>" unless prevGIndex.nil?
      s += "&nbsp;&mdash;&nbsp;" unless prevGIndex.nil? || nextGIndex.nil?
      s += "<a href=\"#{data['galleries'][nextGIndex]['imageList'][nextIIndex]['srcName']}\">" \
      "#{data['galleries'][nextGIndex]['imageList'][nextIIndex]['title']}&nbsp;&gt;</a>" unless nextGIndex.nil?

      s += "
<img src='#{data['galleries'][gIndex]['imageList'][iIndex]['imageFilename']}' alt='#{data['galleries'][gIndex]['imageList'][iIndex]['title']}' />

<p>{description: }</p>
</div>
"
    end

  end

end
