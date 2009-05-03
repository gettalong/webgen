# -*- encoding: utf-8 -*-

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

  layout(:default) {|name, wish| !["path_autocomplete", "preview_website", "preview_website_bundles"].include?(name)}
  helper :xhtml
  engine :Etanni

  def initialize
    @title = 'webgen webgui'
  end

  def site_ops
    session['website_dir'] = request['website_dir'].to_s

    if File.directory?(session['website_dir'])
      redirect r(:manage_website)
    elsif session['website_dir']
      redirect r(:create_website)
    else
      redirect r('/')
    end
  end

  def path_autocomplete
    if request['q']
      Dir[File.expand_path(request['q'].to_s + '*')].select {|f| File.directory?(f)}.join("\n")
    else
      ''
    end
  end

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
      send_preview_file(args, ws.blackboard.invoke(:output_instance))
    end
  end

  def create_website
    @cur_bundle = request['website_bundle'] || @cur_bundle || 'style-andreas07'

    if request['create_site']
      wm = Webgen::WebsiteManager.new(session['website_dir'])
      wm.create_website
      wm.apply_bundle('default')
      wm.apply_bundle(@cur_bundle)

      redirect r(:manage_website)
    else
      wm = Webgen::WebsiteManager.new(session['website_dir'])
      @bundles = wm.bundles.keys.sort

      if !@cur_bundle.nil?
        ws = Webgen::Website.new('unknown', nil) do |config|
          config['sources'] = [
                               ['/', 'Webgen::Source::Resource', 'webgen-website-bundle-default', '/src/**', '/src'],
                               ['/', 'Webgen::Source::Resource', 'webgen-website-bundle-' + @cur_bundle, '/src/**', '/src']
                              ]
          config['output'] = ['MemoryOutput']
          config['website.cache'] = [:memory, '']
        end
        ws.render
        ws.execute_in_env { session['create_website_preview'] = ws.blackboard.invoke(:output_instance) }
      end
    end
  end

  def preview_website_bundles(*args)
    throw(:respond) unless session['create_website_preview']
    send_preview_file(args, session['create_website_preview'])
  end

  def send_preview_file(args, oi)
    path = File.join(*args)
    path += ".html" if path !~ /\.\w+$/
    response.header["Content-Type"] = Rack::Mime.mime_type(File.extname(path)).to_s
    response.header['Cache-Control'] = 'no-store'
    response.header['Pragma'] = 'no-cache'
    response.body = [(oi.read(path) rescue '')]
    throw(:respond, response)
  end
  private :send_preview_file

end
