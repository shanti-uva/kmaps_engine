# The following is performed because the name expression returns nil for Feature.find(15512)
name = feature.prioritized_name(@view)
header = name.nil? ? feature.pid : name.name
view = current_view
children = feature.children.where(:is_public => 1).sort_by do |f|
  n = f.prioritized_name(view)
  [f.position, n.nil? ? f.pid : n.name]
end
options = { id: feature.fid, db_id: feature.id, header: header }
if children.empty?
  xml.feature(options)
else
  xml.feature(options) do # , :pid => feature.pid
    xml.features(type: 'array') do
      xml << render(partial: 'recursive_stripped_feature', formats: [:xml], collection: children, as: :feature) if !children.empty?
    end
  end
end