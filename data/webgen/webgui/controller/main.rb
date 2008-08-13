require 'stringio'
require 'webgen/website'
require 'webgen/websitemanager'

class MemoryOutput

  include Webgen::WebsiteAccess

  attr_reader :data

  def initialize
    @data = {}
  end

  def exists?(path)
    @data.has_key?(path)
  end

  def delete(path)
    @data.delete(path)
  end

  def write(path, io, type = :file)
    @data[path] = [(io.kind_of?(String) ? io : io.data), type]
  end

  def read(path)
    path = File.join('/', path)
    raise "No such file #{path}" unless @data[path] && @data[path].last == :file
    @data[path].first
  end

end

class MainController < Ramaze::Controller

  layout '/page'

  def site_ops
    session['website_dir'] = request['website_dir'].to_s

    if File.directory?(session['website_dir'])
      redirect R(:manage_website)
    elsif session['website_dir']
      redirect R(:create_website)
    else
      redirect R('/')
    end
  end

  def path_autocomplete
    if request['q']
      Dir[File.expand_path(request['q'].to_s + '*')].select {|f| File.directory?(f)}.join("\n")
    else
      ''
    end
  end
  deny_layout :path_autocomplete

  def manage_website
    if request['render_site'] && session['website_dir']
      @verbosity = request['verbosity']

      sio = StringIO.new
      ws = Webgen::Website.new(session['website_dir'], Webgen::Logger.new(sio, false))
      ws.logger.verbosity = @verbosity.to_sym if @verbosity
      ws.render
      @log = sio.string
    elsif request['auto_render_site'] && session['website_dir']
      #TODO
    end
  end

  def preview_website(*args)
    ws = Webgen::Website.new(session['website_dir'])
    ws.init
    ws.execute_in_env do
      oi = ws.blackboard.invoke(:output_instance)
      path = File.join(*args)
      response.header["Content-Type"] =  Ramaze::Tool::MIME.trait[:types][File.extname(path)].to_s
      response.header['Cache-Control'] = 'no-store'
      response.header['Pragma'] = 'no-cache'
      response.body = (oi.read(path) rescue '')
      throw(:respond)
    end
  end

  def create_website
    @cur_style = request['website_style'] || @cur_style || '1024px'
    @cur_template = request['website_template'] || @cur_template || 'default'

    if request['create_site']
      wm = Webgen::WebsiteManager.new(session['website_dir'])
      wm.create_website
      wm.apply_template(@cur_template)
      wm.apply_style(@cur_style)

      redirect R(:manage_website)
    else
      wm = Webgen::WebsiteManager.new(session['website_dir'])
      @templates = wm.templates.keys.sort
      @styles = wm.styles.keys.select {|k| k =~ /^website-|[^-]+/ }.sort

      if !@cur_style.nil? && !@cur_template.nil?
        ws = Webgen::Website.new('unknown') do |config|
          config['sources'] = [
                               ['/', 'Webgen::Source::Resource', 'webgen-website-template-' + @cur_template, '/src/**', '/src'],
                               ['/', 'Webgen::Source::Resource', 'webgen-website-style-' + @cur_style, '/src/**', '/src']
                              ]
          config['output'] = ['MemoryOutput']
          config['website.cache'] = [:memory, '']
        end
        ws.render
        ws.execute_in_env { session['create_website_preview'] = ws.blackboard.invoke(:output_instance) }
      end
    end
  end

  def preview_style_and_template(*args)
    throw(:respond) unless session['create_website_preview']
    path = File.join(*args)
    response.header["Content-Type"] = Ramaze::Tool::MIME.trait[:types][File.extname(path)].to_s
    response.header['Cache-Control'] = 'no-store'
    response.header['Pragma'] = 'no-cache'
    response.body = session['create_website_preview'].read(path)
    throw(:respond)
  end

end
