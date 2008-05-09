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
    def output_path(parent, path, style = path.meta_info['output_path_style'] || Webgen::WebsiteAccess.website.config['sourcehandler.output_path_style'])
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
      style.collect do |part|
        case part
        when String  then part
        when :lang   then use_lang_part ? path.meta_info['lang'] : ''
        when :ext    then path.ext.empty? ? '' : '.' + path.ext
        when :parent then parent.path
        when Symbol  then path.send(part)
        when Array   then part.include?(:lang) && !use_lang_part ? '' : construct_output_path(parent, path, part, use_lang_part)
        else ''
        end
      end.join('')
    end
    private :construct_output_path

    def node_exists?(parent, path, output_path = self.output_path(parent, path))
      parent.tree[Webgen::Node.absolute_name(parent, path.lcn, :alcn)] || parent.tree[output_path, :path]
    end

    def create_node(parent, path)
      opath = output_path(parent, path)
      if !node_exists?(parent, path, opath)
        node = Webgen::Node.new(parent, opath, path.cn, path.meta_info)
        node.node_info[:processor] = self.class.name
        yield(node) if block_given?
        node
      end
    end

    def content(node)
      nil
    end

  end

end
