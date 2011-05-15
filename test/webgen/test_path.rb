# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'webgen/path'
require 'stringio'
require 'tmpdir'

class TestPath < MiniTest::Unit::TestCase

  def test_class_url
    assert_equal("webgen://webgen.localhost/hallo", Webgen::Path.url("hallo").to_s)
    assert_equal("webgen://webgen.localhost/hallo%20du", Webgen::Path.url("hallo du").to_s)
    assert_equal("webgen://webgen.localhost/hall%C3%B6chen", Webgen::Path.url("hallöchen").to_s)
    assert_equal("webgen://webgen.localhost/hallo#du", Webgen::Path.url("hallo#du").to_s)

    assert_equal("webgen://webgen.localhost/test", Webgen::Path.url("/test").to_s)
    assert_equal("http://example.com/test", Webgen::Path.url("http://example.com/test").to_s)

    assert_equal("test", Webgen::Path.url("test", false).to_s)
    assert_equal("http://example.com/test", Webgen::Path.url("http://example.com/test", false).to_s)
  end

  def test_class_append
    assert_raises(ArgumentError) { Webgen::Path.append('test', 'test') }
    assert_raises(ArgumentError) { Webgen::Path.append('test/', 'test') }
    assert_equal('/', Webgen::Path.append('/', '/'))
    assert_equal('/dir', Webgen::Path.append('/other', '/dir'))
    assert_equal('/dir/', Webgen::Path.append('/other', '/dir/'))
    assert_equal('/other/dir', Webgen::Path.append('/other/', 'dir'))
    assert_equal('/test/dir', Webgen::Path.append('/other', '../test/dir'))
    assert_equal('/test', Webgen::Path.append('/', '/../test'))
    assert_equal('/dir/', Webgen::Path.append('/', '/../dir/.'))
  end

  def test_class_matches_pattern
    path = '/dir/to/file.de.page'
    assert(Webgen::Path.matches_pattern?(path, '**/*'))
    assert(Webgen::Path.matches_pattern?(path, '**/file.de.PAGE'))
    assert(Webgen::Path.matches_pattern?(path, '/dir/*/file.*.page'))
    assert(!Webgen::Path.matches_pattern?(path, '**/*.test'))

    path = '/dir/'
    assert(Webgen::Path.matches_pattern?(path, '/dir/'))
    assert(Webgen::Path.matches_pattern?(path, '/dir'))
    assert(Webgen::Path.matches_pattern?(path, '/*/'))
    assert(Webgen::Path.matches_pattern?(path, '/*'))

    path = '/file'
    assert(!Webgen::Path.matches_pattern?(path, '/file/'))
    assert(Webgen::Path.matches_pattern?(path, '/file'))
    assert(!Webgen::Path.matches_pattern?(path, '/*/'))
    assert(Webgen::Path.matches_pattern?(path, '/*'))

    path = '/'
    assert(Webgen::Path.matches_pattern?(path, '/'))
    assert(!Webgen::Path.matches_pattern?(path, ''))

    path = ''
    assert(!Webgen::Path.matches_pattern?(path, '/'))
  end

  def test_initialize_and_accessors
    check_proc = proc do |o, ppath, bn, lang, ext, cn, lcn, acn, alcn, oi, title|
      assert_kind_of(String, o.path)
      assert_equal(o.path, o.source_path)
      assert_equal(ppath, o.parent_path)
      assert_equal(bn, o.basename)
      assert_equal(lang, o.meta_info['lang'])
      assert_equal(ext, o.ext)
      assert_equal(cn, o.cn)
      assert_equal(lcn, o.lcn)
      assert_equal(acn, o.acn)
      assert_equal(alcn, o.alcn)
      assert_equal(oi, o.meta_info['sort_info'])
      assert_equal(title, o.meta_info['title'])
    end

    # Check directory paths
    check_proc.call(Webgen::Path.new('/'),
                    '', '/', nil, '', '/', '/', '/', '/', nil, '/')
    check_proc.call(Webgen::Path.new('/directory/'),
                    '/', 'directory', nil, '', 'directory/', 'directory/', '/directory/', '/directory/', nil, 'Directory')
    check_proc.call(Webgen::Path.new('/dir1/dir2.ext/'),
                    '/dir1/', 'dir2.ext', nil, '', 'dir2.ext/', 'dir2.ext/', '/dir1/dir2.ext/', '/dir1/dir2.ext/', nil, 'Dir2.ext')

    # Check file paths
    check_proc.call(Webgen::Path.new('/5.b_n-one.de.page'),
                    '/', 'b_n-one', 'de', 'page', 'b_n-one.page', 'b_n-one.de.page',  '/b_n-one.page', '/b_n-one.de.page', 5, 'B n one')
    check_proc.call(Webgen::Path.new('/dir/default.png'),
                    '/dir/',  'default', nil, 'png', 'default.png', 'default.png', '/dir/default.png', '/dir/default.png', nil, 'Default')
    check_proc.call(Webgen::Path.new('/default.deu.png'),
                    '/', 'default', 'de', 'png', 'default.png', 'default.de.png', '/default.png', '/default.de.png', nil, 'Default')
    check_proc.call(Webgen::Path.new('/default.tar.bz2'),
                    '/', 'default', nil, 'tar.bz2', 'default.tar.bz2', 'default.tar.bz2', '/default.tar.bz2', '/default.tar.bz2', nil, 'Default')
    check_proc.call(Webgen::Path.new('/default.en.tar.bz2'),
                    '/', 'default', 'en', 'tar.bz2', 'default.tar.bz2', 'default.en.tar.bz2', '/default.tar.bz2', '/default.en.tar.bz2', nil, 'Default')
    check_proc.call(Webgen::Path.new('/default.deu.'),
                    '/',  'default', 'de', '', 'default', 'default.de', '/default', '/default.de', nil, 'Default')
    check_proc.call(Webgen::Path.new('/default'),
                    '/', 'default', nil, '', 'default', 'default', '/default', '/default', nil, 'Default')
    check_proc.call(Webgen::Path.new('/.htaccess'),
                    '/', '.htaccess', nil, '', '.htaccess', '.htaccess', '/.htaccess', '/.htaccess', nil, '.htaccess')
    check_proc.call(Webgen::Path.new('/.htaccess.page'),
                    '/', '.htaccess', nil, 'page', '.htaccess.page', '.htaccess.page', '/.htaccess.page', '/.htaccess.page', nil, '.htaccess')
    check_proc.call(Webgen::Path.new('/.htaccess.en.'),
                    '/', '.htaccess', 'en', '', '.htaccess', '.htaccess.en', '/.htaccess', '/.htaccess.en', nil, '.htaccess')
    check_proc.call(Webgen::Path.new('/.htaccess.en.page'),
                    '/', '.htaccess', 'en', 'page', '.htaccess.page', '.htaccess.en.page', '/.htaccess.page', '/.htaccess.en.page', nil, '.htaccess')
    check_proc.call(Webgen::Path.new('/5.png'),
                    '/', '5', nil, 'png', '5.png', '5.png', '/5.png', '/5.png', nil, '5')
    check_proc.call(Webgen::Path.new('/5.de.png'),
                    '/', 'de', nil, 'png', 'de.png', 'de.png', '/de.png', '/de.png', 5, 'De')
    check_proc.call(Webgen::Path.new('/5.66.png'),
                    '/', '66', nil, 'png', '66.png', '66.png', '/66.png', '/66.png', 5, '66')


    # Check fragment paths
    assert_raises(RuntimeError) { Webgen::Path.new("/#hallo").basename }
    assert_raises(RuntimeError) { Webgen::Path.new("/#hallo#done").basename }
    check_proc.call(Webgen::Path.new('/file#hallo'),
                    '/file', '#hallo', nil, '', '#hallo', '#hallo', '/file#hallo', '/file#hallo', nil, '#hallo')
    check_proc.call(Webgen::Path.new('/file.en.page#hallo'),
                    '/file.en.page', '#hallo', nil, '', '#hallo', '#hallo', '/file.page#hallo', '/file.en.page#hallo', nil, '#hallo')

    # Check general exceptions
    assert_raises(RuntimeError) { Webgen::Path.new('/no_basename#').basename }
    assert_raises(RuntimeError) { Webgen::Path.new('relative.page').basename }

    # Check path with set meta infos
    path = Webgen::Path.new('/test/', :src => '/other.path', 'title' => 'Hello')
    assert_equal('/other.path', path.source_path)
    assert_equal('/test/', path.path)
    assert_equal('Hello', path.meta_info['title'])
    refute(path.meta_info[:no_output])

    # Check other accessors
    path = Webgen::Path.new('/test/')
    path['key'] = 'val'
    assert_equal('val', path.meta_info['key'])
  end

  def test_mount_at
    path = Webgen::Path.new('/test.de.page')
    assert_raises(ArgumentError) { path.mount_at('no_start_slash/') }
    assert_raises(ArgumentError) { path.mount_at('/no_end_slash') }
    assert_raises(ArgumentError) { path.mount_at('/no_with_hash#_char/') }
    assert_raises(ArgumentError) { path.mount_at('/', 'no_start_slash/') }
    assert_raises(ArgumentError) { path.mount_at('/', '/no_end_slash') }
    assert_raises(ArgumentError) { path.mount_at('/', '/no_with_hash#_char/') }
    assert_raises(ArgumentError) { path.basename; path.mount_at('/') }

    path = Webgen::Path.new('/test.de.page').mount_at('/somedir/')
    assert_equal('/somedir/test.de.page', path.path)
    assert_equal('/somedir/test.de.page', path.source_path)
    assert_equal('/somedir/', path.parent_path)

    path = Webgen::Path.new('/').mount_at('/somedir/')
    assert_equal('/somedir/', path.path)
    assert_equal('/somedir/', path.source_path)
    assert_equal('/', path.parent_path)
    assert_equal('somedir/', path.cn)
    assert_equal('Somedir', path.meta_info['title'])

    path = Webgen::Path.new('/source/test.rb').mount_at('/', '/source/')
    assert_equal('/test.rb', path.path)
    assert_equal('/test.rb', path.source_path)
    assert_equal('/', path.parent_path)
    assert_equal('test.rb', path.cn)
    assert_equal('Test', path.meta_info['title'])

    path = Webgen::Path.new('/source/').mount_at('/', '/source/')
    assert_equal('/', path.path)
    assert_equal('/', path.source_path)
    assert_equal('', path.parent_path)
    assert_equal('/', path.cn)
    assert_equal('/', path.meta_info['title'])

    path = Webgen::Path.new('/test.rb', :src => '/other.rb').mount_at('/source/')
    assert_equal('/source/test.rb', path.path)
    assert_equal('/other.rb', path.source_path)
    assert_equal('/source/', path.parent_path)
    assert_equal('test.rb', path.cn)
    assert_equal('Test', path.meta_info['title'])
  end

  def test_dup
    p = Webgen::Path.new('/test.de.page')
    dupped = p.dup
    dupped.meta_info['title'] = 'changed'
    assert_equal('Test', p.meta_info['title'])
  end

  def test_io
    p = Webgen::Path.new('/test.de.page')
    assert_raises(RuntimeError) { p.io }
    p = Webgen::Path.new('/test.de.page') { StringIO.new('hallo') }
    assert_equal('hallo', p.data)
    assert_equal('hallo', p.io {|f| f.read })

    if RUBY_VERSION >= '1.9'
      begin
        dir = File.join(Dir.tmpdir, 'webgen-' + Process.pid.to_s)
        FileUtils.mkdir_p(dir)
        File.open(File.join(dir, 'src'), 'wb+') {|f| f.write("\303\274")}
        path = Webgen::Path.new('/test') {|mode| File.open(File.join(dir, 'src'), mode) }
        assert_equal(1, path.data('r:UTF-8').length)
        assert_equal(2, path.data('rb').length)
      ensure
        FileUtils.rm_rf(dir) if dir
      end
    end
  end

  def test_equality
    p = Webgen::Path.new('/test.de.page')
    assert_equal('/test.de.page', p)
    assert_equal(Webgen::Path.new('/test.de.page'), p)
    refute_equal(5, p)
  end

  def test_comparison
    p1 = Webgen::Path.new('/test.de.page')
    p2 = Webgen::Path.new('/test.en.page')
    assert_equal(0, p1 <=> p1)
    assert_equal(-1, p1 <=> p2)
    assert_equal(1, p2 <=> p1)
  end

  def test_hashing
    path = Webgen::Path.new('test.de.page')
    h = { 'test.de.page' => :value }
    assert_equal(:value, h['test.de.page'])
    assert_equal(:value, h[path])
    assert(path <=> 'test.de.page')
    h = { p => :newvalue}
    assert_nil(h['test.de.page'])
  end

  def test_introspection
    p = Webgen::Path.new('/test.de.page')
    assert_equal('/test.de.page', p.to_s)
    assert(p.inspect.include?('/test.de.page'))
  end

end