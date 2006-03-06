require 'yaml'
require 'webgen/test'
require 'webgen/webpage'

class WebPageDataTest < Webgen::TestCase

  def setup
    @valid_files = YAML::load( File.read( fixture_path( 'correct.yaml' ) ) )
  end

  def test_invalid_pagefiles
    testdata = YAML::load( File.read( fixture_path( 'incorrect.yaml' ) ) )
    testdata.each_with_index {|data, index| assert_raise( WebPageDataInvalid, "test item #{index}" ) { WebPageData.new( data ) } }
  end

  def test_valid_pagefiles
    @valid_files.each_with_index do |data, oindex|
      assert_nothing_raised do
        d = WebPageData.new( data['in'] )
        assert_equal( data['meta_info'], d.meta_info, "test item #{oindex} - meta info" )
        data['blocks'].each_with_index do |b, index|
          assert_equal( b['name'], d.blocks[index].name, "test item #{oindex} - name" )
          assert_equal( b['format'], d.blocks[index].format, "test item #{oindex} - format" )
          assert_equal( b['content'], d.blocks[index].content, "test item #{oindex} - content" )
        end
      end
    end
  end

  def test_accessors
    d = WebPageData.parse( @valid_files[2]['in'] )
    assert_equal( d.blocks[0], d.blocks['content'] )
    assert_equal( d.blocks[1], d.blocks['block2'] )
  end

end
