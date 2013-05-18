# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/page'

class TestPage < MiniTest::Unit::TestCase

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
      content: "  block2  "
    - name: block3
      content: ''
    - name: block4
      content: "yes\\n"

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

# with only meta information, no blocks
- in: |
    ---
    key: value

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
      content: "before\\n--- in\\nafter\\n"

# no meta info, starting with block with name
- in: |
    --- name:block1
  meta_info: {}
  blocks:
    - name: block1
      content: ''

# named blocks using simple scheme
- in: |
    --- block1
    content1
    --- block2
    content2
    --- block3
    content3
    --- block4  -
    content4
    ---   block5 -----------------------------------  
    content5
  meta_info: {}
  blocks:
    - name: block1
      content: content1
    - name: block2
      content: content2
    - name: block3
      content: content3
    - name: block4
      content: content4
    - name: block5
      content: "content5\\n"

# named block and block with other options
- in: |
    --- name:block  -------------------------------
    content doing -
    with?: with some things

    ---   other:options test1:true test2:false 	test3:542 pipeline: ----------------  
  meta_info:
    blocks: {block2: {other: options, test1: true, test2: false, test3: 542, pipeline: ~}}
  blocks:
    - name: block
      content: "content doing -\\nwith?: with some things\\n"
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
      content: "content\\n----------- some block start???\\nthings\\n"

# last block ending with no whitespace at tend
- in: "--- name:block\\nblock\\n\\n--- name:block1\\ncontent"
  meta_info: {}
  blocks:
    - name: block
      content: "block\\n"
    - name: block1
      content: "content"

# last block ending with empty line
- in: "content\\n\\n"
  meta_info: {}
  blocks:
    - name: content
      content: "content\\n\\n"

EOF

  INVALID_MI=<<EOF
# invalid meta info: none specified
- "---\\n---"

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
EOF

  INVALID_BLOCKS=<<EOF
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

# invalid ending of block options
- |
  asdfasd
  dfdf
  --- name:block -- ---
  lsldf
EOF

  def test_invalid_pagefiles
    testdata = YAML::load(INVALID_MI)
    testdata.each_with_index do |data, index|
      assert_raises(Webgen::Page::FormatError, "test mi item #{index}") { Webgen::Page.from_data(data) }
    end
    testdata = YAML::load(INVALID_BLOCKS)
    testdata.each_with_index do |data, index|
      assert_raises(Webgen::Page::FormatError, "test blocks item #{index}") { Webgen::Page.from_data(data) }
    end
  end

  def test_valid_pagefiles
    YAML::load(VALID).each_with_index do |data, oindex|
      d = Webgen::Page.from_data(data['in'])
      assert_equal(data['meta_info'], d.meta_info, "test item #{oindex} - meta info all")
      assert_equal(data['blocks'].length, d.blocks.length)
      data['blocks'].each_with_index do |b, index|
        index += 1
        assert_equal(b['content'], d.blocks[b['name']], "test item #{oindex} - content")
      end
    end
  end

  def test_eol_encodings
    d = Webgen::Page.from_data("---\ntitle: test\r\n---\r\ncontent")
    assert_equal({'title' => 'test'}, d.meta_info)
    assert_equal('content', d.blocks['content'])
  end

  def test_to_s
    data = "---\ntitle: test\n---\ncontent\n\\--- name\nother content\n--- block2\ncontent block2"
    result = "---\ntitle: test\n--- content\ncontent\n\\--- name\nother content\n--- block2\ncontent block2\n"
    page = Webgen::Page.from_data(data)
    assert_equal(result, page.to_s)
    assert_equal(result, Webgen::Page.from_data(page.to_s).to_s)
  end

end
