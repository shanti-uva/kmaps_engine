xml.instruct!
xml.features(type: 'array') do
  xml << render(partial: 'recursive_nested_feature', formats: [:xml], collection: @features, as: :feature) if !@features.empty?
end