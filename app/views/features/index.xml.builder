p = Perspective.get_by_code(default_perspective_code)
v = View.get_by_code(default_view_code)
@features = Feature.current_roots(p, v).sort_by{ |f| [f.position, f.prioritized_name(v).name] } if @features.nil?
xml.instruct!
xml.features(type: 'array') do
  xml << render(partial: 'features/feature', formats: [:xml], collection: @features) if !@features.empty?
end