# -*- encoding: utf-8 -*-

require 'test/unit'
require 'webgen/path'
require 'stringio'
require 'tmpdir'

class TestPath < Test::Unit::TestCase

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

    # Check fragment paths
    assert_raises(RuntimeError) { Webgen::Path.new("/#hallo")}
    assert_raises(RuntimeError) { Webgen::Path.new("/#hallo#done")}
    check_proc.call(Webgen::Path.new('/file#hallo'),
                    '/file', '#hallo', nil, '', '#hallo', '#hallo', '/file#hallo', '/file#hallo', nil, '#hallo')
    check_proc.call(Webgen::Path.new('/file.en.page#hallo'),
                    '/file.en.page', '#hallo', nil, '', '#hallo', '#hallo', '/file.page#hallo', '/file.en.page#hallo', nil, '#hallo')

    # Check general exceptions
    assert_raise(RuntimeError) { Webgen::Path.new('/no_basename#') }
    assert_raise(RuntimeError) { Webgen::Path.new('relative.page') }

    path = Webgen::Path.new('/test/', '/other.path')
    assert_equal('/other.path', path.source_path)
    assert_equal('/test/', path.path)
    assert_equal(false, path.passive?)
  end

  def test_mount_at
    p = Webgen::Path.new('/test.de.page')
    assert_raise(ArgumentError) { p.mount_at('no_start_slash/') }
    assert_raise(ArgumentError) { p.mount_at('/no_end_slash') }
    assert_raise(ArgumentError) { p.mount_at('/no_with_hash#_char/') }
    assert_raise(ArgumentError) { p.mount_at('/', 'no_start_slash/') }
    assert_raise(ArgumentError) { p.mount_at('/', '/no_end_slash') }
    assert_raise(ArgumentError) { p.mount_at('/', '/no_with_hash#_char/') }

    p = p.mount_at('/somedir/')
    assert_equal('/somedir/test.de.page', p.path)
    assert_equal('/somedir/test.de.page', p.source_path)
    assert_equal('/somedir/', p.parent_path)

    p = Webgen::Path.new('/')
    p = p.mount_at('/somedir/')
    assert_equal('/somedir/', p.path)
    assert_equal('/somedir/', p.source_path)
    assert_equal('/', p.parent_path)
    assert_equal('somedir/', p.cn)
    assert_equal('Somedir', p.meta_info['title'])

    p = Webgen::Path.new('/source/test.rb')
    p = p.mount_at('/', '/source/')
    assert_equal('/test.rb', p.path)
    assert_equal('/test.rb', p.source_path)
    assert_equal('/', p.parent_path)
    assert_equal('test.rb', p.cn)
    assert_equal('Test', p.meta_info['title'])

    p = Webgen::Path.new('/source/')
    p = p.mount_at('/', '/source/')
    assert_equal('/', p.path)
    assert_equal('/', p.source_path)
    assert_equal('', p.parent_path)
    assert_equal('/', p.cn)
    assert_equal('/', p.meta_info['title'])

    p = Webgen::Path.new('/test.rb', '/other.rb')
    p = p.mount_at('/source/')
    assert_equal('/source/test.rb', p.path)
    assert_equal('/other.rb', p.source_path)
    assert_equal('/source/', p.parent_path)
    assert_equal('test.rb', p.cn)
    assert_equal('Test', p.meta_info['title'])
  end

  def test_dup
    p = Webgen::Path.new('/test.de.page')
    dupped = p.dup
    dupped.meta_info['title'] = 'changed'
    assert_equal('Test', p.meta_info['title'])
  end

  def test_io
    p = Webgen::Path.new('/test.de.page')
    assert_raise(RuntimeError) { p.io }
    p = Webgen::Path.new('/test.de.page') { StringIO.new('hallo') }
    assert_equal('hallo', p.io.data)
    assert_equal('hallo', p.io.stream {|f| f.read })

    if RUBY_VERSION >= '1.9'
      begin
        dir = File.join(Dir.tmpdir, 'webgen-' + Process.pid.to_s)
        FileUtils.mkdir_p(dir)
        File.open(File.join(dir, 'src'), 'wb+') {|f| f.write("\303\274")}
        sio = Webgen::Path::SourceIO.new {|mode| File.open(File.join(dir, 'src'), mode) }
        assert_equal(1, sio.data('r:UTF-8').length)
        assert_equal(2, sio.data('rb').length)
      ensure
        FileUtils.rm_rf(dir) if dir
      end
    end
  end

  def test_equality
    p = Webgen::Path.new('/test.de.page')
    assert_equal('/test.de.page', p)
    assert_equal(Webgen::Path.new('/test.de.page'), p)
    assert_not_equal(5, p)
  end

  def test_comparison
    p1 = Webgen::Path.new('/test.de.page')
    p2 = Webgen::Path.new('/test.en.page')
    assert_equal(0, p1 <=> p1)
    assert_equal(-1, p1 <=> p2)
    assert_equal(1, p2 <=> p1)
  end

  # Problem with hashing under 1.8.6 when changing from 'test.de.page' to '/test.de.page'...
  #   def test_hashing
  #     path = Webgen::Path.new('test.de.page')
  #     h = { 'test.de.page' => :value }
  #     assert_equal(:value, h['test.de.page'])
  #     assert_equal(:value, h[path])
  #     assert(path <=> 'test.de.page')
  #     h = { p => :newvalue}
  #     assert_nil(h['test.de.page'])
  #   end

  def test_match
    path = '/dir/to/file.de.page'
    assert(Webgen::Path.match(path, '**/*'))
    assert(Webgen::Path.match(path, '**/file.de.PAGE'))
    assert(Webgen::Path.match(path, '/dir/*/file.*.page'))
    assert(!Webgen::Path.match(path, '**/*.test'))

    path = '/dir/'
    assert(Webgen::Path.match(path, '/dir/'))
    assert(Webgen::Path.match(path, '/dir'))
    assert(Webgen::Path.match(path, '/*/'))

    path = '/dir'
    assert(Webgen::Path.match(path, '/dir/'))
    assert(Webgen::Path.match(path, '/dir'))

    path = '/'
    assert(Webgen::Path.match(path, '/'))
    assert(!Webgen::Path.match(path, ''))

    path = ''
    assert(!Webgen::Path.match(path, '/'))
  end

  def test_apath
    assert_raise(ArgumentError) { Webgen::Path.make_absolute('test', 'test') }
    assert_equal('/', Webgen::Path.make_absolute('/', '/'))
    assert_equal('/dir', Webgen::Path.make_absolute('/other', '/dir'))
    assert_equal('/other/dir', Webgen::Path.make_absolute('/other', 'dir'))
    assert_equal('/test/dir', Webgen::Path.make_absolute('/other', '../test/dir'))
    assert_equal('/', Webgen::Path.make_absolute('/', '/..'))
    assert_equal('/dir', Webgen::Path.make_absolute('/', '/../dir/.'))
  end


  def test_introspection
    p = Webgen::Path.new('/test.de.page')
    assert_equal('/test.de.page', p.to_s)
    assert(p.inspect.include?('/test.de.page'))
  end

  def test_changed?
    p = Webgen::Path.new('/test.de.page')
    assert(p.changed?)
  end

end
