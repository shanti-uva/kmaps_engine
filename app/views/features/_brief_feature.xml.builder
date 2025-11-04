# The following is performed because the name expression returns nil for Feature.find(15512)
name = feature.prioritized_name(@view)
header = name.nil? ? feature.pid : name.name
per = Perspective.get_by_code(default_perspective_code)
hierarchy = feature.closest_ancestors_by_perspective(per)
xml.feature do 
  xml.id(feature.fid, type: 'integer')
  xml.db_id(feature.id, type: 'integer')
  xml.header(header)
  caption = feature.caption
  xml.caption(caption&.content)
  xml.ancestors(type: 'array') { xml << render(partial: 'stripped_feature', formats: [:xml], collection: hierarchy, as: :feature) if !hierarchy.empty? }
end