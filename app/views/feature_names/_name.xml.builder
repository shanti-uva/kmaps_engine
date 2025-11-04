xml.name do
  xml.id(name.id, type: 'integer')
  xml.etymology(name.etymology)
  xml.language(name: name.language.name, code: name.language.code)
  xml.name(name.name)
  w = name.writing_system
  if w.nil?
    xml.writing_system(nil)
  else
    xml.writing_system(name: w.name, code: w.code)
  end
  xml << render(partial: 'time_units/index', formats: [:xml], locals: {time_units: name.time_units})
  xml << render(partial: 'citations/index', formats: [:xml], locals: {citations: name.citations})
  xml << render(partial: 'notes/index', formats: [:xml], locals: {notes: name.notes})
  parent_relation = name.parent_relations.first
  if parent_relation.nil?
    xml.relationship(name: 'Original', code: nil, type: nil)
  else
    xml.relationship do
      relationship = parent_relation.phonetic_system
      relationship = parent_relation.orthographic_system if relationship.nil?
      relationship = parent_relation.alt_spelling_system if relationship.nil?
      if relationship.nil?
        xml.name(parent_relation.is_translation ? 'Translation' : 'Unknown Relation')
        xml.code(nil)
        xml.type(nil)
      else
        xml.name(relationship.name)
        xml.code(relationship.code)
        xml.type(relationship.type)
      end
      xml << render(partial: 'citations/index', formats: [:xml], locals: {citations: parent_relation.citations})
      xml << render(partial: 'notes/index', formats: [:xml], locals: {notes: parent_relation.notes})
    end
    # have to add time units and citations to name relations.
  end
  if !@feature.nil?
    xml.names(type: 'array') do
      names = name.children.order('position')
      xml << render(partial: 'name', formats: [:xml], collection: names) if !names.empty?
    end
  end
end