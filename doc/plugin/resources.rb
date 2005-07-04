module WebgenDocuPlugins

  class PredefinedResourcesTag < Tags::DefaultTag

    summary "Creates a table of all predefined resources"

    tag 'predefinedResources'

    def initialize
      super
      @processOutput = false
    end

    def process_tag( tag, node, refNode )
      res = Webgen::Plugin.config[Webgen::ResourceManager].resources
      output = '<table style="width: 100%; border: 1px solid black" summary="List of predefined resources" rules="cols" frame="border">'
      output << '<thead><tr><th>Name</th><th>Type</th><th>Output path</th><th>Description</th></tr></thead>'
      output << '<tbody>'
      res.sort.each do |name, r|
        logger.info { "At resource #{r.name}..." }
        next unless r.predefined
        logger.info { "Describing resource #{r.name}..." }
        output << "<tr><td>#{r.name}</td><td>#{r.type.to_s}</td><td>#{r.output_path}</td><td>#{r.predefined}</td></tr>"
      end
      output << '</tbody></table>'
    end

  end

end
