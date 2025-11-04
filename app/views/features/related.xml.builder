@view = View.get_by_code(default_view_code)
parent_relation_counts = FeatureRelation.select('feature_relation_type_id, COUNT(DISTINCT id) as count').where(:child_node_id => @feature.id).group('feature_relation_type_id').order('feature_relation_type_id')
child_relation_counts = FeatureRelation.select('feature_relation_type_id, COUNT(DISTINCT id) as count').where(:parent_node_id => @feature.id).group('feature_relation_type_id').order('feature_relation_type_id')
xml.instruct!
xml.feature_relation_types(type: 'array') do
  parent_relation_counts.each do |rc|
    rt = rc.feature_relation_type
    xml.feature_relation_type do
      xml.id(rt.id, type: 'integer')
      xml.label(rt.asymmetric_label)
      xml.code(rt.code)
      features = FeatureRelation.where(feature_relation_type_id: rt.id, child_node_id: @feature.id, 'cached_feature_names.view_id' => @view.id).joins(parent_node: {cached_feature_names: :feature_name}).order('feature_names.name').collect(&:parent_node)
      xml.features(type: 'array') { xml << render(partial: 'brief_feature', formats: [:xml], collection: features, as: :feature) if !features.empty? }
    end
  end
  child_relation_counts.each do |rc|
    rt = rc.feature_relation_type
    xml.feature_relation_type do
      xml.id(rt.id, type: 'integer')
      xml.label(rt.label)
      xml.code(rt.asymmetric_code)
      features = FeatureRelation.where(feature_relation_type_id: rt.id, parent_node_id: @feature.id, 'cached_feature_names.view_id' => @view.id).joins(child_node: {cached_feature_names: :feature_name}).order('feature_names.name').collect(&:child_node)
      xml.features(type: 'array') { xml << render(partial: 'brief_feature', formats: [:xml], collection: features, as: :feature) if !features.empty? }
    end
  end
end