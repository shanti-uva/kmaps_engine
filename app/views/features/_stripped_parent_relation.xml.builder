xml << render(:partial => 'stripped_feature.xml.builder', locals: {feature: parent_relation.parent_node, relation: parent_relation})