require 'test/unit'
require 'webgen/path'
require 'stringio'

class TestPath < Test::Unit::TestCase

  def test_initialize
    check_proc = proc do |o, path, dir, bn, lang, ext, cn, oi, title|
      assert_equal(path, o.path)
      assert_equal(path, o.source_path)
      assert_equal(dir, o.directory)
      assert_equal(bn, o.cnbase)
      assert_equal(lang, o.meta_info['lang'])
      assert_equal(ext, o.ext)
      assert_equal(cn, o.cn)
      assert_equal(oi, o.meta_info['sort_info'])
      assert_equal(title, o.meta_info['title'])
    end
    check_proc.call(Webgen::Path.new('5.base_name-one.de.page'),
                    '5.base_name-one.de.page', './', 'base_name-one', 'de', 'page', 'base_name-one.page', 5, 'Base name one')
    check_proc.call(Webgen::Path.new('dir/default.png'),
                    'dir/default.png', 'dir/', 'default', nil, 'png', 'default.png', nil, 'Default')
    check_proc.call(Webgen::Path.new('default.en.png'),
                    'default.en.png', './', 'default', 'en', 'png', 'default.png', nil, 'Default')
    check_proc.call(Webgen::Path.new('default.deu.png'),
                    'default.deu.png', './', 'default', 'de', 'png', 'default.png', nil, 'Default')
    check_proc.call(Webgen::Path.new('default.template'),
                    'default.template', './', 'default', nil, 'template', 'default.template', nil, 'Default')
    check_proc.call(Webgen::Path.new('default.en.tar.bz2'),
                    'default.en.tar.bz2', './', 'default', 'en', 'tar.bz2', 'default.tar.bz2', nil, 'Default')
    check_proc.call(Webgen::Path.new('default.tar.bz2'),
                    'default.tar.bz2', './', 'default', nil, 'tar.bz2', 'default.tar.bz2', nil, 'Default')
    check_proc.call(Webgen::Path.new('default'),
                    'default', './', 'default', nil, '', 'default', nil, 'Default')
    check_proc.call(Webgen::Path.new('.htaccess'),
                    '.htaccess', './', '', nil, 'htaccess', '.htaccess', nil, '')

    check_proc.call(Webgen::Path.new('/'),
                    '/', '/', '/', nil, '', '/', nil, '/')
    check_proc.call(Webgen::Path.new('/dir/'),
                    '/dir/', '/', 'dir', nil, '', 'dir', nil, 'Dir')

    path = Webgen::Path.new('/test/', '/other.path')
    assert_equal('/other.path', path.source_path)
    assert_equal('/test/', path.path)
  end

  def test_mount_at
    p = Webgen::Path.new('test.de.page')
    p = p.mount_at('/somedir')
    assert_equal('/somedir/test.de.page', p.path)
    assert_equal('/somedir/', p.directory)

    p = Webgen::Path.new('/')
    p = p.mount_at('/somedir')
    assert_equal('/somedir/', p.path)
    assert_equal('/', p.directory)
    assert_equal('somedir', p.cn)
    assert_equal('Somedir', p.meta_info['title'])

    p = Webgen::Path.new('/source/test.rb')
    p = p.mount_at('/', '/source/')
    assert_equal('/test.rb', p.path)
    assert_equal('/', p.directory)
    assert_equal('test.rb', p.cn)
    assert_equal('Test', p.meta_info['title'])

    p = Webgen::Path.new('/source/')
    p = p.mount_at('/', '/source')
    assert_equal('/', p.path)
    assert_equal('/', p.directory)
    assert_equal('/', p.cn)
    assert_equal('/', p.meta_info['title'])
  end

  def test_dup
    p = Webgen::Path.new('test.de.page')
    dupped = p.dup
    dupped.meta_info['title'] = 'changed'
    assert_equal('Test', p.meta_info['title'])
  end

  def test_io
    p = Webgen::Path.new('test.de.page')
    assert_raise(RuntimeError) { p.io }
    p = Webgen::Path.new('test.de.page') { StringIO.new('hallo') }
    assert_equal('hallo', p.io.data)
    assert_equal('hallo', p.io.stream {|f| f.read })
  end

  def test_lcn
    p = Webgen::Path.new('test.de.page')
    assert_equal('test.page', p.cn)
    assert_equal('test.de.page', p.lcn)
    p = Webgen::Path.new('test.page')
    assert_equal('test.page', p.cn)
    assert_equal('test.page', p.lcn)
  end

  def test_equality
    p = Webgen::Path.new('test.de.page')
    assert_equal('test.de.page', p)
    assert_equal(Webgen::Path.new('test.de.page'), p)
    assert_not_equal(5, p)
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

  def test_matching
    path = '/dir/to/file.de.page'
    assert(Webgen::Path.match(path, '**/*'))
    assert(Webgen::Path.match(path, '**/file.de.PAGE'))
    assert(Webgen::Path.match(path, '/dir/*/file.*.page'))
    assert(!Webgen::Path.match(path, '**/*.test'))

    path = '/dir/'
    assert(Webgen::Path.match(path, '/dir/'))
    assert(Webgen::Path.match(path, '/dir'))

    path = '/dir'
    assert(Webgen::Path.match(path, '/dir/'))
    assert(Webgen::Path.match(path, '/dir'))

    path = '/'
    assert(Webgen::Path.match(path, '/'))
    assert(!Webgen::Path.match(path, ''))

    path = ''
    assert(!Webgen::Path.match(path, '/'))
  end

  def test_introspection
    p = Webgen::Path.new('test.de.page')
    assert_equal('test.de.page', p.to_s)
    assert(p.inspect.include?('test.de.page'))
  end

  def test_changed?
    p = Webgen::Path.new('test.de.page')
    assert(p.changed?)
  end

end
