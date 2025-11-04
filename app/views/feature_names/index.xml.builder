xml.instruct!
xml.features(type: 'array') do
  @features.each do |feature|
    xml.feature do
      xml.fid(feature.fid, type: 'integer')
      xml << render(partial: 'index', formats: [:xml], locals: { names: feature.names })
    end
  end
end