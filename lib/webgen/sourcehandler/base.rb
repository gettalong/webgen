require 'webgen/websiteaccess'

module Webgen::SourceHandler

  module Base

    # Constructs the output name for the given +path+. Then it is checked using the parameter
    # +parent+ if a node with such an output name already exists. If it exists, the language part is
    # forced to be in the output name and the resulting output name is returned.
    #
    # The parameter +style+ (which uses either the meta information +output_path_style+ from the
    # path's meta information hash or, if the former is not defined, the configuration value
    # +webgen.sourcehandler.output_path_style+) defines how the output name should be built (more
    # information about this in the user documentation).
    def output_path(parent, path, style = path.meta_info['output_path_style'])
      name = construct_output_path(parent, path, style)
      name += '/'  if path.path =~ /\/$/ && name !~ /\/$/
      if node_exists?(parent, path, name)
        name = construct_output_path(parent, path, style, true)
        name += '/'  if path.path =~ /\/$/ && name !~ /\/$/
      end
      name
    end

    # Utility method for constructing the output name.
    def construct_output_path(parent, path, style, use_lang_part = nil)
      use_lang_part = if path.meta_info['lang'].nil? # unlocalized files never get a lang in the filename!
                        false
                      elsif use_lang_part.nil?
                        Webgen::WebsiteAccess.website.config['sourcehandler.default_lang_in_output_path'] ||
                          Webgen::WebsiteAccess.website.config['website.lang'] != path.meta_info['lang']
                      else
                        use_lang_part
                      end
      result = style.collect do |part|
        case part
        when String  then part
        when :lang   then use_lang_part ? path.meta_info['lang'] : ''
        when :ext    then path.ext.empty? ? '' : '.' + path.ext
        when :parent then temp = parent; temp = temp.parent while temp.is_fragment?; temp.path
        when Symbol  then path.send(part)
        when Array   then part.include?(:lang) && !use_lang_part ? '' : construct_output_path(parent, path, part, use_lang_part)
        else ''
        end
      end
      result.join('')
    end
    private :construct_output_path

    # Checks if the node alcn and output path which would be created by <tt>create_node(parent,
    # path)</tt> exists. The +output_path+ to check for can individually be set.
    def node_exists?(parent, path, output_path = self.output_path(parent, path))
      parent.tree[Webgen::Node.absolute_name(parent, path.lcn, :alcn)] || parent.tree[output_path, :path]
    end

    # Creates and returns a node under +parent+ from +path+ if it does not already exists. The
    # created node is yielded if a block is given.
    def create_node(parent, path)
      opath = output_path(parent, path)
      if !node_exists?(parent, path, opath)
        node = Webgen::Node.new(parent, opath, path.cn, path.meta_info)
        node.node_info[:processor] = self.class.name
        yield(node) if block_given?
        node
      end
    end

    # The default +content+ method which just returns +nil+.
    def content(node)
      nil
    end

    # Utility method for creating a +Webgen::Page+ object from the +path+. Also updates
    # <tt>path.meta_info</tt> with the meta info from the page.
    def page_from_path(path)
      begin
        page = Webgen::Page.from_data(path.io.data, path.meta_info)
      rescue Webgen::WebgenPageFormatError => e
        raise "Error reading source path <#{path}>: #{e.message}"
      end
      path.meta_info = page.meta_info
      page
    end

  end

end
