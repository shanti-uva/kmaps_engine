# The following is performed because the name expression returns nil for Feature.find(15512)
name = feature.prioritized_name(@view)
header = name.nil? ? feature.pid : name.name
object_types = feature.object_types
options = { :id => feature.id, :fid => feature.fid, :header => header }
if object_types.empty?
  xml.feature(options)
else
  xml.feature(options) do # , :pid => feature.pid
    object_types.each { |type| xml.feature_type(:title => type.title) } #, :id => type.id
  end
end
