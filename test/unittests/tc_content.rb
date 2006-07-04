require 'yaml'
require 'webgen/test'
require 'webgen/content'


class HtmlBlockTest < Webgen::TestCase

  def setup
    @valid = []
    YAML::load_documents( File.read( fixture_path( 'blocks.yaml' ) ) ) {|doc| @valid << doc }
  end

  def test_accessors
    block = HtmlBlock.new( 'test', @valid[0]['testdata'] )
    assert_equal( 'test', block.name )
    assert_equal( @valid[0]['testdata'], block.content )
    assert_not_nil( block.sections )
  end

  def test_sections
    @valid.each_with_index do |data,index|
      assert_nothing_raised( "test item #{index}" ) do
        block = HtmlBlock.new( 'test', data['testdata'] )
        data['result'].each_with_index do |d, i|
          compare_sections( block.sections[i], d, index )
        end
      end
    end
  end

  def test_render_with_erb
    block = HtmlBlock.new( 'test', "5 * 3 = <%= 5*3 + @fuzzy %>" )
    @fuzzy = 5
    assert_equal( '5 * 3 = 20', block.render_with_erb( binding ) )
  end

  def compare_sections( section, data, tindex )
    assert_equal( data[0], section.level, "test item #{tindex}" )
    assert_equal( data[1], section.id, "test item #{tindex}" )
    assert_equal( data[2], section.title, "test item #{tindex}" )
    data[3].each_with_index {|d,i| compare_sections( section.subsections[i], d, tindex )} if data[3]
  end

end

class WebPageDataTest < Webgen::TestCase

  def setup
    @valid_files = YAML::load( File.read( fixture_path( 'correct.yaml' ) ) )
    @formatters = {'default' => proc {|c| c}, 'textile' => proc {|c| c}}
  end

  def test_initalize
    assert_nothing_raised { WebPageData.new( '' ) }
  end

  def test_invalid_pagefiles
    testdata = YAML::load( File.read( fixture_path( 'incorrect.yaml' ) ) )
    testdata.each_with_index do |data, index|
      assert_raise( WebPageDataInvalid, "test item #{index}" ) { WebPageData.new( data, @formatters ) }
    end
  end

  def test_valid_pagefiles
    @valid_files.each_with_index do |data, oindex|
      assert_nothing_raised do
        d = WebPageData.new( data['in'], @formatters )
        assert_equal( data['meta_info'], d.meta_info, "test item #{oindex} - meta info" )
        data['blocks'].each_with_index do |b, index|
          assert_equal( b['name'], d.blocks[index].name, "test item #{oindex} - name" )
          assert_equal( b['content'], d.blocks[index].content, "test item #{oindex} - content" )
          assert_same( d.blocks[index], d.blocks[b['name']] )
        end
      end
    end
  end

  def test_default_values
    d = WebPageData.new( @valid_files[0]['in'], @formatters, 'blocks' => [{'name'=>'other1'},{'name'=>'other2'}] )
    assert_equal( 'other1', d.blocks[0].name )
    assert_equal( 'other2', d.blocks[1].name )

    assert_raise( WebPageDataInvalid ) do
      d = WebPageData.new( @valid_files[0]['in'], @formatters, 'blocks' => [nil,nil,{'format'=>'other'}] )
    end
  end

end
