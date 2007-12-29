module Tag

  # Generates a list with all the languages for a page.
  class Langbar < DefaultTag

    def process_tag( tag, body, context )
      lang_nodes = context.node.parent.find_all {|o| o.cn == context.node.cn }
      nr_langs = lang_nodes.length
      result = lang_nodes.
        delete_if {|n| (context.node['lang'] == n['lang'] && !param( 'showOwnLang' )) }.
        sort {|a, b| a['lang'] <=> b['lang']}.
        collect {|n| n.link_from( context.dest_node, :link_text => n['lang'], :context => { :caller => self.plugin_name } )}.
        join( param( 'separator' ) )
      ( param( 'showSingleLang' ) || nr_langs > 1 ? result : "" )
    end

  end

end
