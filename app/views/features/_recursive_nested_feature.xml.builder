name = feature.prioritized_name(@view)
# The following is performed because the name expression returns nil for Feature.find(15512)
header = name.nil? ? feature.pid : name.name
children = feature.current_children(@perspective, @view).sort_by{ |f| [f.position, f.prioritized_name(@view).name] }
caption = feature.caption
options = { :id => feature.fid, :childCount => children.size, :title => header }
options[:caption] = caption.content if !caption.nil?
xml.feature(options) do
  xml << render(:partial => 'recursive_nested_feature', formats: [:xml], collection: children, as: :feature) if !children.empty?
end
