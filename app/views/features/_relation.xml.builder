xml.relation(id: relation.id) do
  xml.perspective(id: relation.perspective.id, code: relation.perspective.code)
  xml.feature_relation_type(id: relation.feature_relation_type.id, code: relation.feature_relation_type.code, asymmetric_code: relation.feature_relation_type.asymmetric_code)
  xml << render(partial: 'time_units/index', formats: [:xml], locals: {time_units: relation.time_units})
  xml << render(partial: 'citations/index', formats: [:xml], locals: {citations: relation.citations})
  xml << render(partial: 'notes/index', formats: [:xml], locals: {notes: relation.notes})
end