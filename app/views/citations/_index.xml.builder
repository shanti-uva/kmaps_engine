xml.citations(type: 'array') do
  xml << render(partial: 'citations/citation', formats: [:xml], collection: citations) if !citations.empty?
end