require 'yaml'
require 'webgen/sourcehandler/base'
require 'webgen/websiteaccess'

module Webgen::SourceHandler

  class Virtual

    include Base
    include Webgen::WebsiteAccess

    def create_node(parent, path)
      page = page_from_path(path)
      nodes = []
      YAML::load(page.blocks['content'].content).each do |key, value|
        key = (key =~ /^\// ? key : File.join(parent.absolute_lcn, key))
        temp_parent = create_directories(parent.tree.root, File.dirname(key), path)

        temp_path = Webgen::Path.new(key)
        temp_path.meta_info.update(value || {})
        temp_path.meta_info['no_output'] = true
        output_path = temp_path.meta_info.delete('url') || key
        output_path = (output_path =~ /^\// ? output_path : File.join(temp_parent.absolute_lcn, output_path))

        if key =~ /\/$/
          nodes << create_directory(temp_parent, key, path, temp_path.meta_info)
        else
          nodes << super(temp_parent, temp_path, output_path) {|n| n.node_info[:src] = path.path}
        end
      end if page.blocks.has_key?('content')
      nodes.compact
    end

    #######
    private
    #######

    def create_directories(parent, dirname, path)
      dirname.sub(/^\//, '').split('/').each do |dir|
        parent = create_directory(parent, File.join(parent.absolute_lcn, dir), path)
      end
      parent
    end

    def create_directory(parent, dir, path, meta_info = nil)
      dir_handler = website.cache.instance('Webgen::SourceHandler::Directory')
      website.blackboard.invoke(:create_nodes, parent.tree, parent.absolute_lcn,
                                Webgen::Path.new(File.join(dir, '/')),
                                dir_handler) do |par, temp_path|
        if (node = dir_handler.node_exists?(par, temp_path)) && (!meta_info || node.node_info[:src] != path.path)
          parent = node
        else
          temp_path.meta_info.update(meta_info) if meta_info
          parent = dir_handler.create_node(par, temp_path)
          parent.node_info[:src] = path.path
        end
      end
      parent
    end

  end

end
