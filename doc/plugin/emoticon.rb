class ShowEmoticonsTag < Tags::DefaultTag

  infos( :name => 'WebgenDocu/EmoticonTag',
         :summary => "Creates a table of the existing emoticon packs"
         )

  register_tag 'showEmoticonPacks'

  def process_tag( tag, chain )
    res = @plugin_manager['Core/ResourceManager'].resources
    packs = Dir[File.join( Webgen.data_dir, 'resources', 'emoticons', '*/')].collect {|p| File.basename( p )}.sort

    map = @plugin_manager['Misc/SmileyReplacer'].class::SMILEY_MAP
    output = '<table class="examples" summary="List of emoticon packs">'
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
