module ContentProcessor

  class Fragments

    SECTION_REGEXP = /<h([123456])(?:>|\s([^>]*)>)(.*?)<\/h\1\s*>/i
    ATTR_REGEXP = /\s*(\w+)\s*=\s*('|")([^\2]+)\2\s*/

    def process( context )
      sections = []
      stack = []
      context.content.scan( SECTION_REGEXP ).each do |level,attrs,title|
        next if attrs.nil?
        id_attr = attrs.scan( ATTR_REGEXP ).find {|name,sep,value| name == 'id'}
        next if id_attr.nil?
        id = id_attr[2]

        section = [level.to_i, id, title, []]
        success = false
        while !success
          if stack.empty?
            sections << section
            stack << section
            success = true
          elsif stack.last.first < section.first
            stack.last.last << section
            stack << section
            success = true
          else
            stack.pop
          end
        end
      end
      @plugin_manager['Core/CacheManager'].set( [:nodes, context.ref_node.absolute_lcn, :fragments, context.block.name],
                                                sections )
      context
    end

  end

end
