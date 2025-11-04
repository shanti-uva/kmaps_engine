xml.instruct!
xml.features(type: 'array') do
  xml << render(partial: 'stripped_feature', formats: [:xml], collection: @features, as: :feature) if !@features.empty?
end