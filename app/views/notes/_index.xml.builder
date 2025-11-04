xml.notes(type: 'array') do
  xml << render(partial: 'notes/note', formats: [:xml], collection: notes) if !notes.empty?
end