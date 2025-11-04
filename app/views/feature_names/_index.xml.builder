xml.names(type: 'array') do
  xml << render(partial: 'name', formats: [:xml], collection: names) if !names.empty?
end