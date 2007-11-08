require 'yaml'
require 'cgi'


module Sipttra

  # A simple node belonging to a Tracker. One node represents exactly one line of a sipttra file.
  class Node

    attr_accessor :tracker

    # Returns the line representation of this node.
    def to_line
      ''
    end

    def inspect
      "#<#{self.class.name}: #{to_line}>"
    end

  end


  # Base class for all nodes which deal with simple text lines.
  class TextNode < Node

    # The text of the node/line.
    attr_accessor :text

    def initialize( text )
      @text = text
    end

    def to_line
      @text
    end

    def to_s
      @text
    end

  end


  # A comment is just a special text node.
  class Comment < TextNode; end


  # Represents a category line.
  class Category < Node

    # The name of the category.
    attr_accessor :name

    # The type of the category.
    attr_accessor :type

    def initialize( name, type = nil )
      @name = name
      @type = type
      raise "Category must have a name" if name.nil?
    end

    # Returns all tickets belonging to this category.
    def tickets
      tickets = []
      i = @tracker.nodes.index( self ) + 1
      while i < @tracker.nodes.length
        line = @tracker.nodes[i]
        break if line.kind_of?( Category )
        tickets << line if line.kind_of?( Ticket )
        i += 1
      end
      tickets
    end

    def to_line
      '### ' + to_s + ' ###'
    end

    def to_s
      name + (type.nil? ? '' : ' (' + type + ')')
    end

  end


  # Represents a ticket line.
  class Ticket < Node

    attr_accessor :name, :due_date, :belongs_to, :summary

    def initialize( name, due_date, belongs_to, text = '' )
      @name =  name
      @due_date = due_date
      @belongs_to = belongs_to
      @summary = text.strip
    end

    # Returns the category to which this ticket belongs.
    def category
      i = @tracker.nodes.index( self ) - 1
      i -= 1 while i >= 0 && !@tracker.nodes[i].kind_of?( Category )
      (i < 0 ? nil : @tracker.nodes[i])
    end

    # Returns +true+ if this ticket is closed, ie. if it belongs to a category with type closed.
    def closed?
      category.type == 'closed'
    end

    # Returns the tickets assigned to this ticket, ie. all sub-tickets. The +type+ parameter can be
    # one of:
    # :open   :: all tickets with a type different from +closed+
    # :closed :: all tickets with type +closed+
    # :all    :: all tickets independent from type
    def assigned_tickets( type = :all )
      if @name.nil?
        []
      else
        @tracker.tickets.select do |t|
          t.belongs_to == @name &&
            (type == :all || (type == :closed ? t.category.type == 'closed' : t.category.type != 'closed' ))
        end
      end
    end

    # Returns the detailed description for this ticket.
    def description
      text = []
      line = nil
      i = @tracker.nodes.index( self ) + 1
      while i < @tracker.nodes.length && (line = @tracker.nodes[i]).kind_of?( AdditionalText )
        text << line
        i += 1
      end
      text.join( "\n" ).strip
    end

    # Returns the whole text for the ticket, ie. the summary and ticket joined by a line separator.
    def all_text
      [@summary, description].join( "\n" )
    end
    alias_method :to_s, :all_text

    def to_line
      s = '*'
      s << ' ' + name unless name.nil?
      s << ' (' + due_date + ')' unless due_date.nil?
      s << ' [' + belongs_to + ']' unless belongs_to.nil?
      s << (!name.nil? && due_date.nil? && belongs_to.nil? ? ':' : '' ) + (summary.empty? ? '' : ' ' + summary.to_s)
      s
    end

  end


  # Represents a milestone which is a special ticket.
  class Milestone < Ticket

    def initialize( *args )
      super( *args )
      raise "Milestone must have a name" if @name.nil?
    end

    # Like assigned_tickets but includes tickets in sub milestones.
    def all_assigned_tickets( type = :all )
      (assigned_tickets( type ) + sub_milestones.collect {|sm| sm.all_assigned_tickets( type )}).flatten
    end

    # A milestone is closed if all assigned tickets are closed, including the ones from the sub
    # milestones.
    def closed?
      assigned_tickets( :open ).empty? && sub_milestones.all? {|sm| sm.closed?}
    end

    # Returns all direct sub milestones.
    def sub_milestones
      (@name.nil? ? [] : @tracker.milestones.select {|m| m.belongs_to == @name})
    end

  end


  # Represents additional text lines for tickets. All additional text lines for one ticket are the
  # ticket's description.
  class AdditionalText < TextNode

    def initialize( text )
      super( text.sub( /^  /, '' ) )
    end

    def to_line
      (@text.strip.empty? ? '' : '  ' + @text)
    end

  end


  # The tracker is used to parse sipttra files and to change the sipttra data in memory.
  class Tracker

    IDENT_REGEXP=/\w[-.\w]*/

    DATE_REGEXP=/\((\d\d\d\d-\d\d-\d\d)\)/
    BELONGS_REGEXP=/\[(#{IDENT_REGEXP})\]/

    TICKET_REGEXP=/^\*(?:\s(#{IDENT_REGEXP})(?=:|\s\[|\s\():?)?(?:\s#{DATE_REGEXP})?(?:\s#{BELONGS_REGEXP})?(?:$|\s(.*)$)/
    CONTENT_REGEXP=/^\s\s(.*)$/
    CATEGORY_REGEXP=/^(#+)\s{1,}([^(]*?)(?:\s*\((\w+)\))?\s{1,}\1$/

    attr_reader :nodes, :info

    def initialize( data = nil )
      @nodes = []
      @info = {}
      parse( data ) if data
    end

    # Parses the given +data+ and fills the tracker with information.
    def parse( data )
      @nodes = []
      @info = {}
      level = 0

      if data =~ /\A---\n/m
        begin
          index = data.index( "---\n", 4 ) || 0
          @info = YAML.load( data[0...index] )
          data = data[index..-1]
        rescue
        ensure
          @info = {} unless @info.kind_of?( Hash )
        end
      end

      data.split(/\n/).each do |line|
        case
        when (m = CATEGORY_REGEXP.match( line )) && category( m[2], m[3] ).nil?
          @nodes << Category.new( m[2], m[3] )
          level = 1

        when level == 0
          @nodes  << Comment.new( line )

        when (m = TICKET_REGEXP.match( line )) && (milestone( m[1] ).nil? && ticket( m[1] ).nil?)
          if @nodes.find_all {|child| child.kind_of?( Category )}.last.type.nil?
            @nodes << Milestone.new( m[1], m[2], m[3], m[4] || '' )
          else
            @nodes << Ticket.new( m[1], m[2], m[3], m[4] || '' )
          end

        when (@nodes.last.kind_of?( Ticket ) || @nodes.last.kind_of?( AdditionalText )) &&
            (line.empty? || (m = CONTENT_REGEXP.match( line )))
          @nodes << AdditionalText.new( line )

        else
          @nodes << Comment.new( line )
        end
        @nodes.last.tracker = self
      end

    end

    def check_consistency
      # TODO what to check?
    end

    # If Bluecloth is available +text+ is considered to be in Markdown format and converted
    # to HTML. Otherwise the unchanged text is returned.
    def htmlize( text )
      require 'bluecloth'
      BlueCloth.new( text ).to_html
    rescue
      text
    end

    # Returns all categories.
    def categories
      @nodes.find_all {|child| child.kind_of?( Category ) && !child.type.nil? }
    end

    # Returns the category with the given +name+ and +type+.
    def category( name, type )
      categories.find {|cat| cat.name == name && cat.type == type}
    end

    # Returns all category names.
    def category_names
      categories.collect {|cat| cat.name}.uniq
    end

    # Returns all milestones.
    def milestones
      @nodes.find_all {|child| child.instance_of?( Milestone ) }
    end

    # Returns the milestone with the given +name+.
    def milestone( name )
      (name.nil? ? nil : milestones.find {|ms| ms.name == name})
    end

    # Returns all tickets independent from their categories.
    def tickets
      @nodes.find_all {|child| child.instance_of?( Ticket ) }
    end

    # Returns the ticket with the given +name+.
    def ticket( name )
      (name.nil? ? nil : tickets.find {|ticket| ticket.name == name})
    end

    # Returns all tickets for the category +name+ independent from the category type.
    def tickets_for_category( name )
      tickets.select {|t| t.category.name == name}
    end

    # Returns a string representation of the tracker which can later be used by #parse .
    def to_s
      @info.to_yaml.sub( /^---\s*\n/m, '' ) + "\n\n" + @nodes.collect {|line| line.to_line}.join( "\n" )
    end

  end

end
