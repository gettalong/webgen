require 'webgen/website'

class MainController < Ramaze::Controller

  layout '/page'

  def site_ops
    if request['set_site']
      session['website_dir'] = request['site_dir']
    elsif request['render_site'] && session['website_dir']
      Webgen::Website.new(session['website_dir']).render
    elsif request['auto_render_site'] && session['website_dir']
      #TODO
    end
    redirect R('/')
  end

  def website(*args)
    ws = Webgen::Website.new(session['website_dir'])
    ws.init
    ws.execute_in_env do
      oi = ws.blackboard.invoke(:output_instance)
      path = File.join(*args)
      response.header["Content-Type"] =  Ramaze::Tool::MIME.trait[:types][File.extname(path)].to_s
      response.body = oi.read(path)
      throw(:respond)
    end
  end

end
