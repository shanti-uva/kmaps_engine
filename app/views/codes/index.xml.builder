xml.instruct!
xml.feature do
  xml.old_pid(@feature.old_pid)
  xml.fid(@feature.fid, type: 'integer')
  xml.geo_codes(type: 'array') do
    xml << render(partial: 'geo_code', formats: [:xml], collection: @geo_codes) if !@geo_codes.empty?
  end
end