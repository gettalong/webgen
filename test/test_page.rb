require 'test/unit'
require 'webgen/page'

class TestPage < Test::Unit::TestCase

  VALID = <<EOF
# with more blocks
- in: |
    ---
    key: value
    ---
    block1
    --- 
      block2  
    ---  name:block3
    ---  name:block4
    yes
  meta_info: {key: value}
  blocks:
    - name: content
      content: "block1"
    - name: block2
      content: "block2"
    - name: block3
      content: ''
    - name: block4
      content: 'yes'

# empty file
- in: ""
  meta_info: {}
  blocks:
    - name: content
      content: ''

# without meta info
- in: "hallo"
  meta_info: {}
  blocks:
    - name: content
      content: "hallo"

# with empty block
- in: |
    --- 
    key: value

    ---

  meta_info: {key: value}
  blocks:
    - name: content
      content: ''

# block with escaped ---
- in: |
    before
    \\--- in
    after
  meta_info: {}
  blocks:
    - name: content
      content: "before\\n--- in\\nafter"

# no meta info, starting with block with name
- in: |
    --- name:block1
  meta_info: {}
  blocks:
    - name: block1
      content: ''

# named block and block with other options
- in: |
    --- name:block
    content doing -
    with?: with some things
    --- other:optins
  meta_info: {}
  blocks:
    - name: block
      content: "content doing -\\nwith?: with some things"
    - name: block2
      content: ''

# block with seemingly block start line it
- in: |
    --- name:block
    content
    ----------- some block start???
    things
  meta_info: {}
  blocks:
    - name: block
      content: "content\\n----------- some block start???\\nthings"
EOF

  INVALID=<<EOF
# invalid meta info: no hash
- |
  ---
  doit
  ---
  asdf kadsfakl

# invalid meta info: not in yaml format
- |
  ---
  - doit
  : * [ }
  ---
  asdf kadsfakl

# no block specified
- |
  ---
  doit: now

# two blocks with same name
- |
  aasdf
  asdfdf
  --- name:name
  asdkf dsaf
  --- name:name
  asdf adsf

# invalid format
- |
  asdfasd
  dfdf
  --- name, incorrect_format
  lsldf
EOF

  def test_invalid_pagefiles
    testdata = YAML::load(INVALID)
    testdata.each_with_index do |data, index|
      assert_raise(Webgen::WebgenPageFormatError, "test item #{index}") { Webgen::Page.from_data(data) }
    end
  end

  def test_valid_pagefiles
    YAML::load(VALID).each_with_index do |data, oindex|
      d = Webgen::Page.from_data(data['in'])
      assert_equal(data['meta_info'], d.meta_info, "test item #{oindex} - meta info")
      data['blocks'].each_with_index do |b, index|
        index += 1
        assert_equal(b['name'], d.blocks[index].name, "test item #{oindex} - name")
        assert_equal(b['content'], d.blocks[index].content, "test item #{oindex} - content")
        assert_same(d.blocks[index], d.blocks[b['name']])
      end
    end
  end

  def test_default_values
    valid = YAML::load(VALID)
    d = Webgen::Page.from_data(valid[0]['in'], 'blocks' => {'1' => { 'name' => 'other1'}, '2' => { 'name' => 'block7'}})
    assert_equal({'key' => 'value'}, d.meta_info)
    assert_equal('other1', d.blocks[1].name)
    assert_equal('block7', d.blocks[2].name)
  end

  def test_eol_encodings
    d = Webgen::Page.from_data("---\ntitle: test\r---\r\ncontent")
    assert_equal({'title' => 'test'}, d.meta_info)
    assert_equal('content', d.blocks['content'].content)
  end

  def test_meta_info_dupped
    mi = {'key' => 'value'}
    d = Webgen::Page.from_data("---\ntitle: test\n---\ncontent", mi)
    assert_equal({'title' => 'test', 'key' => 'value'}, d.meta_info)
    assert_not_same(mi, d.meta_info)
    d = Webgen::Page.from_data("content", mi)
    assert_equal({'key' => 'value'}, d.meta_info)
    assert_not_same(mi, d.meta_info)
  end

end
