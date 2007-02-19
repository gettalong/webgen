load_plugin "webgen/plugins/coreplugins/configuration"

module Testing

  class BasicPlugin < Webgen::Plugin
  end


  INFOS_HASH = {
    :summary => 'Summary',
    :description => 'Description',
    :instantiate => false,
    :name => 'Testing/PluginWithData'
  }
  PARAM_ARRAY = ['test', [5,6], 'Test description']
  DEPS_ARRAY = ['Testing/BasicPlugin', 'Testing/DerivedPlugin']

  class PluginWithData < Webgen::Plugin

    infos INFOS_HASH

    param( *PARAM_ARRAY )
    param 'otherparam', 'otherparam', 'tst'

    depends_on( *DEPS_ARRAY )

  end

  load_optional_part( 'test',
                      :needed_gems => ['unknown'],
                      :error_msg => 'error_msg' ) do
    require 'unknown_library'
  end

end
