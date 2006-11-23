class PredefinedResourcesTag < Tags::DefaultTag

  infos( :name => 'WebgenDocu/ResourcesTag',
         :summary => "Creates a table of all predefined resources"
         )

  register_tag 'predefinedResources'

  def initialize( pm )
    super
    @process_output = false
  end

  def process_tag( tag, chain )
    res = @plugin_manager['Core/ResourceManager'].resources
    output = '<table class="resources" summary="List of predefined resources">'
    output << '<thead><tr><th>Name</th><th>Type</th><th>Output path</th><th>Description</th></tr></thead>'
    output << '<tbody>'
    res.sort.each do |name, r|
      log(:debug) { "At resource #{r.name}..." }
      next unless r.predefined
      log(:debug) { "Describing resource #{r.name}..." }
      output << "<tr><td>#{r.name}</td><td>#{r.type.to_s}</td><td>#{r.output_path}</td><td>#{r.predefined}</td></tr>"
    end
    output << '</tbody></table>'
  end

end
