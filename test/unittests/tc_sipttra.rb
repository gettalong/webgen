require 'webgen/test'
require 'webgen/sipttra'


class TrackerTest < Webgen::TestCase

  def test_category_regexp
    assert_match_special( Sipttra::Tracker::CATEGORY_REGEXP, '#   Name   #', ['#', 'Name',nil] )
    assert_match_special( Sipttra::Tracker::CATEGORY_REGEXP, '### Name ###', ['###', 'Name',nil] )
    assert_match_special( Sipttra::Tracker::CATEGORY_REGEXP, '### Name (open) ###', ['###', 'Name','open'] )
    assert_match_special( Sipttra::Tracker::CATEGORY_REGEXP, '# Name(done) #', ['#', 'Name','done'] )

    assert_no_match( Sipttra::Tracker::CATEGORY_REGEXP, '# Name' )
    assert_no_match( Sipttra::Tracker::CATEGORY_REGEXP, '# Name () #' )
    assert_no_match( Sipttra::Tracker::CATEGORY_REGEXP, '# Name (done)#' )
  end

  def test_ticket_regexp
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* text', [nil, nil, nil, 'text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* text and more', [nil, nil, nil, 'text and more'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* title text', [nil, nil, nil, 'title text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* title:', ['title', nil, nil, nil] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* title: text', ['title', nil, nil, 'text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* [belongs] text', [nil, nil, 'belongs', 'text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* (2007-02-03) text', [nil, '2007-02-03', nil, 'text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* title [belongs] text', ['title', nil, 'belongs', 'text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* title (2007-02-03) text', ['title', '2007-02-03', nil, 'text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* title (2007-02-03) [belongs] text', ['title', '2007-02-03', 'belongs', 'text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* 0.5.0 (2007-09-21) test', ['0.5.0', '2007-09-21', nil, 'test'] )

    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* t:', ['t', nil, nil, nil] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* [t]', [nil, nil, 't', nil] )

    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* [belongs]text', [nil, nil, nil, '[belongs]text'] )
    assert_match_special( Sipttra::Tracker::TICKET_REGEXP, '* (2007-02-03)text', [nil, nil, nil, '(2007-02-03)text'] )
    assert_no_match( Sipttra::Tracker::TICKET_REGEXP, '*text' )
  end

  def assert_match_special( regexp, string, args )
    assert_match( regexp, string )
    match = regexp.match( string )
    assert_equal( args, match[1..-1] )
  end

  def test_methods
    data = File.read( fixture_path( 'test.sipttra' ) )
    tracker = Sipttra::Tracker.new( data )
    assert_equal( tracker.info['categories'], tracker.categories.length )
    assert_equal( tracker.info['milestones'], tracker.milestones.length )
    assert_equal( tracker.info['tickets'], tracker.tickets.length )
    assert_equal( tracker.info['tickets_todo_open'], tracker.category( 'TODO', 'open' ).tickets.length )
    assert_equal( tracker.info['tickets_todo_closed'], tracker.category( 'TODO', 'closed' ).tickets.length )
    assert_equal( tracker.info['tickets_todo_open_names'], tracker.category( 'TODO', 'open' ).tickets.collect {|t| t.name} )
    assert_equal( tracker.info['baap_belongs_to'], tracker.ticket( 'baap' ).belongs_to )
    assert_equal( tracker.info['M1_all_tickets'], tracker.milestone( 'M1' ).all_assigned_tickets.length )
    #TODO: assert_equal( tracker, Sipttra::Tracker.new( tracker.to_s ) )
  end

end
