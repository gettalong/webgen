module WebgenDocuPlugins

  class ShowEmoticonsTag < Tags::DefaultTag

    summary "Creates a table of the existing emoticon packs"

    tag 'showEmoticonPacks'

    def process_tag( tag, node, refNode )
      res = Webgen::Plugin.config[Webgen::ResourceManager].resources
      packs = Dir[File.join( CorePlugins::Configuration.data_dir, 'resources', 'emoticons', '*/')].collect {|p| File.basename( p )}.sort

      map = MiscPlugins::SmileyReplacer::SMILEY_MAP
      output = '<table style="width: 100%; border: 1px solid black" summary="List of emoticon packs" rules="groups" frame="border">'
      header = map.sort {|a,b| a[1] <=> b[1]}.collect {|s, name| "<th><code>#{s}</code><br />(#{name})</th>" }.join('')
      output << "<thead><tr><th>Smiley/Pack</th>#{header}</tr></thead><tbody>"
      packs.each do |pack|
        output << "<tr><th>#{pack}</th>"
        output << map.values.sort.collect do |v|
          "<td align=\"center\"><img src=\"{resource: webgen-emoticons-#{pack}-#{v}}\" alt=\"smiley\"/></td>"
        end.join('')
        output << "</tr>"
      end
      output << "</tbody></table>"
    end

  end

end
