module Testing

  class BasicPlugin < Webgen::Plugin
  end


  INFOS_HASH = {
    :summary => 'Summary',
    :description => 'Description',
    :no_instantiation => true
  }
  PARAM_ARRAY = ['test', [5,6], 'Test description']
  DEPS_ARRAY = [BasicPlugin, 'Testing::DerivedPlugin']
  DEPS_ARRAY_CHECK = ['Testing::BasicPlugin', 'Testing::DerivedPlugin']

  class PluginWithData < Webgen::Plugin

    infos INFOS_HASH

    param( *PARAM_ARRAY )

    depends_on( *DEPS_ARRAY )

  end

end
