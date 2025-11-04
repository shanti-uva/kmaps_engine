xml.descriptions(type: 'array') do
  xml << render(partial: 'description', formats: [:xml], collection: @descriptions) if !@descriptions.empty?
end