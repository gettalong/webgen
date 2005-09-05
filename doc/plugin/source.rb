module WebgenDocuPlugins

  class ShowSourceTag < Tags::DefaultTag

    summary "Copy the page source and link to it"

    tag 'source'

    def process_tag( tag, node, refNode )
      outpath = node.recursive_value( 'src' ).sub( /^#{Webgen::Plugin['Configuration']['srcDirectory']}/, Webgen::Plugin['Configuration']['outDirectory'] )
      puts "Copying #{node['src']}"
      if File.exists?( node.recursive_value('src') )
        FileUtils.cp( node.recursive_value( 'src' ), outpath )
        "Source: <a href=\"#{node['src']}\">page source</a>"
      else
        ""
      end
    end

  end

end
