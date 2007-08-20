require 'uri'
require 'pathname'
require 'webgen/composite'

# The Node class is used for building the internal data structure which represents the output tree.
#
# This class caches information to provide fast access to some often used, computed values. These
# values are: full_path, absolute_path, absolute_lcn and to_url. It is essential that the provided
# accessors are always used because otherwise the cached information might be invalid. For instance,
# the following should not be done:
#    node.meta_info.update({:key => :value, 5 => 6})
# Instead, the accessor should be used:
#    node.meta_info = node.meta_info.merge({:key => :value, 5 => 6})
class Node

  include Composite

  # The parent node.
  attr_reader :parent

  # The path of this node.
  attr_reader :path

  # The canonical name of this node.
  attr_reader :cn

  # Information used for processing the node.
  attr_accessor :node_info

  # Meta information associated with the node.
  attr_reader :meta_info

  # Initializes a new Node instance.
  #
  # +parent+::
  #    If this parameter is +nil+, then the new node acts as root. Otherwise, +parent+ has to
  #    be a valid node instance.
  # +path+::
  #    The path for this node. If this node is a directory, the path must have a trailing
  #    slash ('dir/'). If it is a fragment, the hash sign must be the first character of the
  #    path ('#fragment'). A compound path like 'dir/file#fragment' is also allowed as are
  #    absolute paths like 'http://myhost.com/'.
  # +canonical_name+::
  #    The canonical name used for resolving this node. Needs to be of the form 'basename.ext'
  #    or 'basename' where +basename+ does not contain any dots. Also, the 'basename' must not
  #    include a language part! If not set, the +path+ is used as canonical name.
  #
  #    Note: a compound path like 'dir/file' is invalid if the parent node already has a child
  #    with path 'dir/'!!! (solution: just create a node with path 'file' and node 'dir/' as parent!)
  # +meta_info+::
  #    A hash with meta information for the new node.
  def initialize( parent, path, canonical_name = path, meta_info = {} )
    @parent = nil
    @path = path
    @cn = canonical_name.chomp('/')
    @node_info = Hash.new
    @meta_info = meta_info
    self.parent = parent
  end

  # Returns the root node for +node+.
  def self.root( node )
    node = node.parent until node.parent.nil?
    node
  end

  # Returns the localized canoncial name for the given canonical name and language.
  def self.lcn( cn, lang )
    if lang.nil?
      cn
    else
      cn.split( '.' ).insert( 1, lang.to_s ).join( '.' )
    end
  end

  # Returns the localized canoncial name for this node.
  def lcn
    return @precalc[:lcn] if @precalc
    self.class.lcn( @cn, @meta_info['lang'] )
  end

  # Sets a new parent for the node.
  def parent=( var )
    @parent.del_child( self ) unless @parent.nil?
    @parent = var
    @parent.add_child( self ) unless @parent.nil?
    precalc_with_children!
  end

  # Sets the path for the node.
  def path=( path )
    @path = path
    precalc_with_children!
  end

  # Sets the meta information hash for the node.
  def meta_info=( meta_info )
    @meta_info = meta_info
    precalc_with_children!
  end

  # Gets object +name+ from +meta_info+.
  def []( name )
    @meta_info[name]
  end

  # Assigns +value+ to +meta_info+ called +name.
  def []=( name, value )
    @meta_info[name] = value
    precalc_with_children! if name == 'lang'
  end

  # Regexp for matching absolute URLs, ie. URLs with a scheme part (also see RFC1738)
  ABSOLUTE_URL = /^\w[a-zA-Z0-9+.-]*:/

  # Returns the full path for this node. See also Node#absolute_path !
  def full_path
    return @precalc[:full_path] if @precalc

    if @path =~ ABSOLUTE_URL
      @path
    else
      (@parent.nil? ? @path : @parent.full_path + @path)
    end
  end

  # Returns the absolute path, ie. starting with a slash for the root directory, for this node.
  #
  # Here is an example that shows the difference between +full_path+ and +absolute_path+:
  #
  #   root = Node.new( nil, '../output/' )
  #   dir = Node.new( root, 'testdir/' )
  #   node = Node.new( dir, 'testfile' )
  #   node.full_path # => '../output/testdir/testfile'
  #   node.absolute_path # => '/testdir/testfile'
  def absolute_path
    return @precalc[:absolute_path] if @precalc

    if @parent.nil?
      '/'
    elsif @path =~ ABSOLUTE_URL
      @path
    else
      full_path.sub( /^#{Node.root( self ).path}/, '/' )
    end
  end

  # Returns the absolute localized canonical name for the node. This is similar to the
  # #absolute_path method, but it does not use the +path+ but the +lcn+ field.
  def absolute_lcn
    return @precalc[:absolute_lcn] if @precalc

    (@parent.nil? ? '/' : @parent.absolute_lcn + self.lcn + (is_directory? ? '/' : '') )
  end

  # Returns the level of the node. The level specifies how deep the node is in the hierarchy.
  def level
    (@parent.nil? ? 0 : @parent.level + 1)
  end

  # Checks if the node is a directory.
  def is_directory?
    @path[-1] == ?/
  end

  # Checks if the node is a file.
  def is_file?
    !is_directory? && !is_fragment?
  end

  # Checks if the node is a fragment.
  def is_fragment?
    @path[0] == ?#
  end

  # Matches the (localized) canonical name of the node against the given path at the beginning.
  # Returns the matched portion or +nil+. Used by #resolve_node.
  def =~( path )
    md = (@match_pattern =~ path)
    if md then $& end
  end

  # Returns the value of the meta info +orderInfo+ or +0+ if it is not set.
  def order_info
    self['orderInfo'].to_s.to_i         # nil.to_s.to_i => 0
  end

  # Sorts nodes by using the meta info +orderInfo+ of both involved nodes or, if these values are
  # equal, by the meta info +title+.
  def <=>( other )
    self_oi = self.order_info
    other_oi = other.order_info
    (self_oi == other_oi ? (self['title'] || '') <=> (other['title'] || '') : self_oi <=> other_oi)
  end

  # Returns the route to the given path. The parameter +path+ can be a String or an object that
  # responds to <tt>to_url</tt>.
  def route_to( other )
    my_url = self.to_url
    other_url = if other.respond_to?(:to_url)
                  other.to_url
                elsif other.kind_of?(String)
                  my_url + other.to_s
                else
                  raise ArgumentError, "argument has improper class"
                end

    # resolve any '.' and '..' paths in the target url
    if other_url.path =~ /\/\.\.?\// && other_url.scheme == 'webgen'
      other_url.path = Pathname.new( other_url.path ).cleanpath.to_s
    end
    route = my_url.route_to( other_url ).to_s
    (route == '' ? ( self.is_fragment? ? self.parent.path : self.path ) : route )
  end

  # Checks if the current node is in the subtree which is spanned by the supplied node. The check is
  # performed using only the +parent+ information of the involved nodes, NOT the actual path values!
  def in_subtree_of?( node )
    temp = self
    temp = temp.parent while !temp.nil? && temp != node
    !temp.nil?
  end

  # Returns the node representing the given +path+. The path can be absolute (i.e. starting with a
  # slash) or relative to the current node. If no node exists for the given path or it would lie
  # outside the node tree, +nil+ is returned.
  #
  # The method always tries to return the most general node for the given +path+. If the parameter
  # +lang+ is not specified, an unlocalized version for the +path+ is returned, if it exists, or
  # else simply the found node. If +lang+ is specified, then the localized version of the node for
  # +path+ is returned or +nil+ if such a node does not exist.
  def resolve_node( path, lang = nil )
    url = self.to_url + path

    path = url.path[1..-1].to_s + (url.fragment.nil? ? '' : '#' + url.fragment)
    return nil if path =~ /^\.\./ || url.scheme != 'webgen' # path outside dest dir or not an internal URL (webgen://...)

    node = Node.root( self )

    match = ''
    while !node.nil? && !path.empty?
      node = node.find {|c| match = (c =~ path) }
      path.sub!( match, '' ) unless node.nil?
      break if path.empty?
    end

    uln = node.node_for_lang( nil ) if node && !node.parent.nil? && match != node.lcn
    node = uln if uln

    if !lang.nil? && !match.nil? && !node.parent.nil? && (node['lang'].nil? || match != node.lcn)
      node = node.node_for_lang( lang )
    end

    node
  end

  # Returns the full URL (including dummy scheme and host) for use with URI classes. The returned
  # URL does not include the real path of the root node but a slash instead. So if the full path of
  # the node is 'a/b/c/d/file1' and the root node path is 'a/b/c', the URL path would be '/d/file1'.
  def to_url
    return @precalc[:to_url] if @precalc

    url = URI::parse( absolute_path )
    url = URI::parse( 'webgen://webgen.localhost/' ) + url unless url.absolute?
    url
  end

  # Returns an informative representation of the node.
  def inspect
    "<##{self.class.name}: path=#{full_path}>"
  end

  alias_method :to_s, :full_path

  #######
  private
  #######

  def precalc!
    @precalc = nil
    @precalc = {
      :full_path => full_path,
      :absolute_path => absolute_path,
      :absolute_lcn => absolute_lcn,
      :lcn => lcn,
      :to_url => to_url
    }
    @match_pattern = if is_directory?
                       /^#{@cn}(\/|$)/
                     elsif is_fragment?
                       /^#{@cn}$/
                     else
                       /^(#{@cn}|#{lcn})(?=#|$)/
                     end
  end

  def precalc_with_children!
    precalc!
    each {|child| child.precalc_with_children!}
  end
  protected :precalc_with_children!

  # Delegates missing methods to a processor. The current node is placed into the argument array as
  # the first argument before the method +name+ is invoked on the processor.
  def method_missing( name, *args, &block )
    if @node_info[:processor]
      @node_info[:processor].send( name, *([self] + args), &block )
    else
      super
    end
  end

=begin
TODO:
- stable sort which does not switch items that have the same order_info
=end

end
