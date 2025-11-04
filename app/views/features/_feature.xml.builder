# The following is performed because the name expression returns nil for Feature.find(15512)
@view = View.get_by_code(default_view_code)
name = feature.prioritized_name(@view)
header = name.nil? ? feature.pid : name.name
xml.feature(:id => feature.fid, :db_id => feature.id, :header => header) do
  xml.names(:type => 'array') do
    View.all.each do |v|
      name = feature.prioritized_name(v)
      next if name.nil?
      tags = {:id => name.id, :language => name.language.code, :view => v.code, :name => name.name}
      tags[:writing_system] = name.writing_system.code if !name.writing_system.nil?
      tags[:language] = name.language.code if !name.language.nil?
      relation = name.parent_relations.first
      if !relation.nil?
        tags[:alt_spelling_system] = relation.alt_spelling_system.code if !relation.alt_spelling_system.nil?
        tags[:orthographic_system] = relation.orthographic_system.code if !relation.orthographic_system.nil?
        tags[:phonetic_system] = relation.phonetic_system.code if !relation.phonetic_system.nil?
      end
      xml.name(tags)
    end
  end
  parents = feature.all_parent_relations
  xml.parents(type: 'array') { xml << render(:partial => 'stripped_parent_relation', formats: [:xml], collection: parents, as: :parent_relation) if !parents.empty? }
  children = feature.all_child_relations
  xml.children(type: 'array') { xml << render(:partial => 'stripped_child_relation', formats: [:xml], collection: children, as: :child_relation) if !children.empty? }
  per = Perspective.get_by_code(default_perspective_code)
  hierarchy = feature.closest_ancestors_by_perspective(per)
  xml.ancestors(type: 'array') { xml << render(:partial => 'stripped_feature', formats: [:xml], collection: hierarchy, as: :feature) if !hierarchy.empty? }
  xml.codes(type: 'array') { xml << render(partial: 'codes/stripped_geo_code', formats: [:xml], collection: feature.geo_codes, as: :geo_code) } if !feature.geo_codes.empty?
  per = Perspective.get_by_code('cult.reg')
  if !per.nil?
    hierarchy = feature.closest_ancestors_by_perspective(per)
    xml.ancestors(type: 'array') { xml << render(partial: 'stripped_feature', formats: [:xml], collection: hierarchy, as: :feature) if !hierarchy.empty? }
  end
  captions = feature.captions
  xml.nested_captions(type: 'array') do
    captions.each do |c|
      options = {id: c.id, language: c.language.code, content: c.content }
      xml.nested_caption(options)
    end
  end
  summaries = feature.summaries
  xml.summaries(type: 'array') do
    summaries.each do |s|
      xml.summary do
        xml.id(s.id, type: 'integer')
        xml.language(s.language.code)
        xml.content(s.content)
        xml << render(partial: 'citations/index', formats: [:xml], locals: {citations: s.citations})
      end
    end
  end
  descriptions = feature.descriptions
  xml.nested_descriptions(type: 'array') do
    descriptions.each do |d|
      options = {id: d.id, is_primary: d.is_primary}
      options[:source_url] = d.source_url if !d.source_url.blank?
      options[:title] = d.title if !d.title.blank?
      xml.nested_description(options)
    end
  end
  xml.illustrations(type: 'array') do
    feature.illustrations.each do |illustration|
      options = { id: illustration.picture_id, type: illustration.picture_type, url: illustration.picture_url }
      if illustration.picture_type=='ExternalPicture'
        picture = illustration.picture
        options[:width] = picture.width
        options[:height] = picture.height
      end
      xml.picture(options)
    end
  end
  xml.associated_resources do
    xml.etymology_count(feature.names.where(['etymology <> ?', '']).count.to_s, type: 'integer')
    xml.related_feature_count(feature.all_relations.size.to_s, type: 'integer')
    xml.description_count(feature.descriptions.size.to_s, type: 'integer')
    xml.place_count(feature.feature_count.to_s, type: 'integer')
    xml.picture_count(feature.media_count(type: 'Picture').to_s, type: 'integer')
    xml.video_count(feature.media_count(type: 'Video').to_s, type: 'integer')
    xml.document_count(feature.media_count(type: 'Document').to_s, type: 'integer')
  end
  xml << render(partial: 'time_units/index', formats: [:xml], locals: {time_units: feature.time_units})
  xml << render(partial: 'citations/index', formats: [:xml], locals: {citations: feature.citations})
  xml.created_at(feature.created_at, type: 'datetime')
  xml.updated_at(feature.updated_at, type: 'datetime')
end