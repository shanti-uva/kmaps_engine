require 'kmaps_engine/import/importation'

module KmapsEngine
  class FeatureImportation < Importation
    attr_accessor :feature

    def self.say msg
      Rails.logger.info "IMPORTER COMMENT (#{Time.now.to_s}): #{msg}"
    end

    # Currently supported fields:
    # features.fid, features.old_pid, features.position, feature_names.delete, feature_names.is_primary.delete
    # i.feature_names.existing_name
    # i.feature_names.name, i.feature_names.position, i.feature_names.is_primary,
    # i.languages.code/name, i.writing_systems.code/name, i.alt_spelling_systems.code/name
    # i.phonetic_systems.code/name, i.orthographic_systems.code/name, BOTH DEPRECATED, INSTEAD USE: i.feature_name_relations.relationship.code
    # i.feature_name_relations.parent_node, i.feature_name_relations.is_translation, 
    # i.feature_name_relations.is_phonetic, i.feature_name_relations.is_orthographic, BOTH DEPRECATED AND USELESS
    # i.geo_code_types.code/name, i.feature_geo_codes.geo_code_value, i.feature_geo_codes.info_source.id/code,
    # feature_relations.delete, [i.]feature_relations.related_feature.fid, [i.]feature_relations.type.code,
    # [i.]perspectives.code/name, feature_relations.replace
    # descriptions.delete, [i.]descriptions.title, [i.]descriptions.content, [i.]descriptions.author.fullname, [i.]descriptions.language.code/name
    # [i.]captions:
    # content, author.fullname
    # [i.]summaries:
    # content, author.fullname


    # Fields that accept time_units:
    # features, i.feature_names[.j], i.feature_geo_codes[.j], [i.]feature_relations[.j]

    # time_units fields supported:
    # .time_units.[start.|end.]date, .time_units.[start.|end.]certainty_id, .time_units.season_id,
    # .time_units.calendar_id, .time_units.frequency_id

    # Fields that accept info_source:
    # [i.]feature_names[.j], i.feature_geo_codes[.j]
    # [i.]feature_relations[.j], [i.]summaries[.j]

    # info_source fields:
    # .info_source.id/code, info_source.note
    # When info source is a document: .info_source[.i].volume, info_source[.i].pages
    # When info source is an online resource: .info_source[.i].path, .info_source[.i].name
    # When info source is a oral source: .info_source.oral.fullname

    # Fields that accept note:
    # [i.]feature_names[.j], [i.]feature_relations[.j], i.feature_geo_codes[.j]

    # Note fields:
    # .note, .title

    def add_info_source(field_prefix, citable)
      info_source = nil
      begin
        info_source_id = self.fields.delete("#{field_prefix}.info_source.id")
        if info_source_id.blank?
          info_source_code = self.fields.delete("#{field_prefix}.info_source.code")
          if info_source_code.blank?
            source_name = self.fields.delete("#{field_prefix}.info_source.oral.fullname")
            if !source_name.blank?
              info_source = OralSource.find_by_name(source_name)
              info_source_type = 'OralSource'
              puts "Oral source with name #{source_name} was not found." if info_source.nil?
            end
          else
            info_source = MmsIntegration::Document.find_by_original_medium_id(info_source_code)
            info_source_type = 'MmsIntegration::Medium'
            puts "Info source with code #{info_source_code} was not found." if info_source.nil?
          end
        else
          info_source = MmsIntegration::Medium.find(info_source_id)
          info_source_type = 'MmsIntegration::Medium'
          puts "Info source with MMS ID #{info_source_id} was not found." if info_source.nil?
        end              
      rescue Exception => e
        puts e.to_s
      end
      if !info_source.nil?
        notes = self.fields.delete("#{field_prefix}.info_source.note")
        citations = citable.citations
        conditions = {info_source_id: info_source.id, info_source_type: info_source_type}
        citation = citations.find_by(conditions)
        if citation.nil?
          citation = citations.new(conditions.merge(notes: notes))
          citation.info_source_type = info_source_type
          citation.citable_type = citable.class.name
          citation.save
          self.spreadsheet.imports.create(:item => citation) if citation.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
        else
          if !notes.nil?
            citation.update_attribute(:notes, notes)
            self.spreadsheet.imports.create(:item => citation) if citation.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
          end
        end
        if citation.nil?
          puts "Info source #{info_source.id} could not be associated to #{citable.class_name.titleize}."  
        elsif info_source_type.start_with?('MmsIntegration')
          0.upto(2) do |j|
            prefix = j==0 ? "#{field_prefix}.info_source" : "#{field_prefix}.info_source.#{j}"
            case info_source.type
            when 'OnlineResource'
              pages = citation.web_pages
              path = self.fields.delete("#{prefix}.path")
              name = self.fields.delete("#{prefix}.name")
              if !(path.blank? || name.blank?)
                conditions = { :path => path, :title => name }
                page = pages.find_by(conditions)
                if page.nil?
                  page = pages.create(conditions)
                  self.spreadsheet.imports.create(:item => page) if page.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
                end
              end
            when 'Document'
              pages = citation.pages
              volume_str = self.fields.delete("#{prefix}.volume")
              pages_range = self.fields.delete("#{prefix}.pages")
              if !volume_str.blank? || !pages_range.blank?
                volume = nil
                start_page = nil
                end_page = nil
                if !pages_range.blank?
                  page_array = pages_range.split('-')
                  start_page_str = page_array.shift
                  end_page_str = page_array.shift
                  if !start_page_str.nil?
                    start_page_str.strip!
                    start_page = start_page_str.to_i if !start_page_str.blank?
                  end
                  if !end_page_str.nil?
                    end_page_str.strip!
                    end_page = end_page_str.to_i if !end_page_str.blank?
                  end
                end
                if !volume_str.blank?
                  volume_str.strip!
                  volume = volume_str.to_i if !volume_str.blank?
                end
                conditions = {:start_page => start_page, :end_page => end_page, :volume => volume}
                page = pages.find_by(conditions)
                if page.nil?
                  page = pages.create(conditions)
                  self.spreadsheet.imports.create(item: page) if page.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
                end
              end
            end
          end
        end
      end
    end

    # Valid columns: .note, .title
    def add_note(field_prefix, notable)
      prefix = "#{field_prefix}.note"
      author_name = self.fields.delete("#{prefix}.author.fullname")
      author = author_name.blank? ? nil : AuthenticatedSystem::Person.find_by(fullname: author_name)
      note_str = self.fields.delete("#{prefix}.content")
      if !note_str.blank?
        note_title = self.fields.delete("#{prefix}.title")
        notes = notable.notes
        if !note_title.blank?
          note = notes.find_by(custom_note_title: note_title)
          if note.nil?
            note = notes.find_by(content: note_str)
            note.update_attribute(:custom_note_title, note_title) if !note.nil?
          else
            note.update_attribute(:content, note_str)
          end
        else
          note = notes.find_by(content: note_str)
        end
        if note.nil?
          note = notes.create(content: note_str, custom_note_title: note_title)
          self.spreadsheet.imports.create(item: note) if note.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
        end
        note.authors << author if !note.nil? && !author.nil? && !note.author_ids.include?(author.id)
        puts "Note #{note_str} could not be added to #{notable.class_name.titleize} #{notable.id}." if note.nil?
      end
    end

    # The feature can either be specified with by its current fid ("features.fid")
    # or the pid used in THL's previous application ("features.old_pid"). One of the two is required.  
    # Valid columns: features.fid, features.old_pid
    
    def get_feature(current)
      fid = self.fields.delete('features.fid')
      if fid.blank?
        old_pid = self.fields.delete('features.old_pid')
        if old_pid.blank?
          puts "Either a \"features.fid\" or a \"features.old_pid\" must be present in line #{current}!"
          return false
        end

        feature = Feature.find_by(old_pid: old_pid)
        if feature.nil?
          puts "Feature with old pid #{old_pid} was not found."
          return false
        end
      else
        feature = Feature.get_by_fid(fid)
        if feature.nil?
          puts "Feature with THL ID #{fid} was not found."
          return false
        end
      end
      self.feature = Feature.find(feature.id)
      return true
    end
    
    # Valid columns: features.position
    def process_feature
      self.add_date('features', self.feature)
      position = self.fields.delete('features.position')
      self.feature.update_attribute(:position, position) if !position.blank?
    end

    # Name is optional. If there is a name, then the required column (for i varying from
    # 1 to 18) is "i.feature_names.name".
    # Optional columns are "i.languages.code"/"i.languages.name",
    # "i.writing_systems.code"/"i.writing_systems.name",
    # "i.feature_names.info_source.id"/"i.feature_names.info_source.code"
    # and "i.feature_names.is_primary"
    # If optional column "i.feature_names.time_units.date" is specified, a date will be
    # associated to the name.
    # Additionally, optional column "i.feature_name_relations.parent_node" can be
    # used to establish name i as child of name j by simply specifying the name number.
    # The parent name has to precede the child name. If a parent column is specified,
    # the two optional columns can be included: "i.feature_name_relations.is_translation"
    # and "i.feature_name_relations.relationship.code" containing the code for the
    # phonetic or orthographic system.That is the prefered method
    # Alternatively, the following can still be used:
    # "i.phonetic_systems.code"/"i.phonetic_systems.name", 
    # "i.orthographic_systems.code"/"i.orthographic_systems.name",
    # You can also explicitly specify "i.feature_name_relations.is_phonetic" and
    # "i.feature_name_relations.is_orthographic" but it will
    # inferred otherwise.
    def process_names(total)
      names = self.feature.names
      prioritized_names = self.feature.prioritized_names
      # If feature_names.delete is "yes", all names and relations will be deleted.
      delete_feature_names = self.fields.delete('feature_names.delete')
      association_notes = self.feature.association_notes
      if !delete_feature_names.blank? && delete_feature_names.downcase == 'yes'
        names.clear
        association_notes.delete(association_notes.where(:association_type => 'FeatureName'))
      end
      name_added = false
      name_positions_with_changed_relations = Array.new
      relations_pending_save = Array.new
      name_changed = false
      delete_is_primary = self.fields.delete('feature_names.is_primary.delete')
      if !delete_is_primary.blank? && delete_is_primary.downcase == 'yes'
        names.where(:is_primary_for_romanization => true).each do |name|
          name_changed = true if !name_changed
          name.update_attributes(:is_primary_for_romanization => false, :skip_update => true)
        end
      end    
      # feature_names.note can be used to add general notes to all names of a feature
      0.upto(3) do |i|
        feature_names_note = self.fields.delete(i==0 ? 'feature_names.note' : "feature_names.#{i}.note")
        if !feature_names_note.blank?
          note = association_notes.find_by(association_type: 'FeatureName', content: feature_names_note)
          if note.nil?
            note = association_notes.create(:association_type => 'FeatureName', :content => feature_names_note)
            self.spreadsheet.imports.create(:item => note) if note.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
          end
          puts "Feature name note #{feature_names_note} could not be saved for feature #{self.feature.pid}" if note.nil?
        end
      end
      name = Array.new(total)
      1.upto(total) do |i|
        n = i-1
        name_str = self.fields.delete("#{i}.feature_names.name")
        if name_str.blank?
          name_str = self.fields.delete("#{i}.feature_names.existing_name")
          next if name_str.blank?
          name[n] = names.find_by(name: name_str)
          existing = true
        else
          existing = false
        end
        relationship_system_code = self.fields.delete("#{i}.feature_name_relations.relationship.code")
        if !relationship_system_code.blank?
          relationship_system = SimpleProp.get_by_code(relationship_system_code)
          if relationship_system.nil?
            puts "Phonetic or orthographic system with code #{relationship_system_code} was not found for feature #{self.feature.pid}."
          else
            if relationship_system.instance_of? OrthographicSystem
              orthographic_system = relationship_system
            elsif relationship_system.instance_of? PhoneticSystem
              phonetic_system = relationship_system
            elsif relationship_system.instance_of? AltSpellingSystem
              alt_spelling_system = relationship_system
            else
              puts "Relationship #{relationship_system_code} has to be either phonetic or orthographic for feature #{self.feature.pid}."
            end
          end
        else
          begin
            orthographic_system = OrthographicSystem.get_by_code_or_name(self.fields.delete("#{i}.orthographic_systems.code"), self.fields.delete("#{i}.orthographic_systems.name"))
          rescue Exception => e
            puts e.to_s
          end
          begin
            phonetic_system = PhoneticSystem.get_by_code_or_name(self.fields.delete("#{i}.phonetic_systems.code"), self.fields.delete("#{i}.phonetic_systems.name"))
          rescue Exception => e
            puts e.to_s
          end
        end
        if !existing
          conditions = {:name => name_str}
          begin
            language = Language.get_by_code_or_name(self.fields.delete("#{i}.languages.code"), self.fields.delete("#{i}.languages.name"))
          rescue Exception => e
            puts e.to_s
          end
          begin
            writing_system = WritingSystem.get_by_code_or_name(self.fields.delete("#{i}.writing_systems.code"), self.fields.delete("#{i}.writing_systems.name"))
            conditions[:writing_system_id] = writing_system.id if !writing_system.nil?
          rescue Exception => e
            puts e.to_s
          end
          begin
            alt_spelling_system = AltSpellingSystem.get_by_code_or_name(self.fields.delete("#{i}.alt_spelling_systems.code"), self.fields.delete("#{i}.alt_spelling_systems.name"))
          rescue Exception => e
            puts e.to_s
          end
          # if language is not specified it may be inferred.
          if language.nil?
            if phonetic_system.nil?
              language = Language.get_by_code('zho') if !writing_system.nil? && (writing_system.code == 'hant' || writing_system.code == 'hans')
            else
              language = Language.get_by_code('bod') if phonetic_system.code=='ethnic.pinyin.tib.transcrip' || phonetic_system.code=='tib.to.chi.transcrip'
            end
          end
          conditions[:language_id] = language.id if !language.nil?
          name[n] = names.find_by(conditions)
          is_primary = self.fields.delete("#{i}.feature_names.is_primary")
          conditions[:is_primary_for_romanization] = is_primary.downcase=='yes' ? 1 : 0 if !is_primary.blank?
          
          # now deal with relationships
          relation_conditions = Hash.new
          relation_conditions[:orthographic_system_id] = orthographic_system.id if !orthographic_system.nil?
          relation_conditions[:phonetic_system_id] = phonetic_system.id if !phonetic_system.nil?
          relation_conditions[:alt_spelling_system_id] = alt_spelling_system.id if !alt_spelling_system.nil?
          position = self.fields.delete("#{i}.feature_names.position")
          if name[n].nil? || !relation_conditions.empty? && name[n].parent_relations.find_by(relation_conditions).nil?
            conditions[:position] = position if !position.blank?
            name[n] = names.create(conditions.merge({:skip_update => true}))
            if !name[n].id.nil?
              self.spreadsheet.imports.create(:item => name[n]) if name[n].imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
              name_added = true if !name_added
            end
          elsif !position.blank?
            name[n].update_attribute(:position, position)
            self.spreadsheet.imports.create(:item => name[n]) if name[n].imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
            name_changed = true
          end
          if name[n].id.nil?
            puts "Name #{name_str} could not be added to feature #{self.feature.pid}."
            next
          end
        end
        0.upto(4) do |j|
          prefix = j==0 ? "#{i}.feature_names" : "#{i}.feature_names.#{j}"
          self.add_date(prefix, name[n])
          self.add_info_source(prefix, name[n])
          self.add_note(prefix, name[n])
        end
        is_translation_str = self.fields.delete("#{i}.feature_name_relations.is_translation")
        is_translation = is_translation_str.downcase=='yes' ? 1: 0 if !is_translation_str.blank?
        parent_node_str = self.fields.delete("#{i}.feature_name_relations.parent_node")
        parent_name_str = self.fields.delete("#{i}.feature_name_relations.parent_node.name") if parent_node_str.blank?
        # for now is_translation is the only feature_name_relation that can be specified for a present or missing (inferred) parent.
        # if no parent is specified, it is possible to infer the parent based on the relationship to an already existing name.
        if parent_node_str.blank? && parent_name_str.blank?
          # tibetan must be parent
          if !phonetic_system.nil? && (phonetic_system.code=='ethnic.pinyin.tib.transcrip' || phonetic_system.code=='tib.to.chi.transcrip')
            parent_name = FeatureExtensionForNamePositioning::HelperMethods.find_name_for_writing_system(prioritized_names, WritingSystem.get_by_code('tibt').id)
            if parent_name.nil?
              puts "No tibetan name was found to associate #{phonetic_system.code} to #{name_str} for feature #{self.feature.pid}."
            else
              name_relation = name[n].parent_relations.find_by(parent_node_id: parent_name.id)
              if name_relation.nil?
                name_relation = name[n].parent_relations.create(:skip_update => true, :parent_node_id => parent_name.id, :phonetic_system_id => phonetic_system.nil? ? nil : phonetic_system.id, :is_phonetic => 1, :is_translation => is_translation)
                if name_relation.nil?
                  puts "Could not associate #{name_str} to Tibetan name for feature #{self.feature.pid}."
                else
                  parent_name.update_hierarchy
                  name_positions_with_changed_relations << n if !name_positions_with_changed_relations.include? n
                end
              else
                name_relation.update_attributes(:phonetic_system_id => phonetic_system.nil? ? nil : phonetic_system.id, :is_phonetic => 1, :orthographic_system_id => nil, :is_orthographic => 0, :is_translation => is_translation)
              end
              self.spreadsheet.imports.create(:item => name_relation) if name_relation.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
            end                
          end
          # now check if there is simplified chinese and make it a child of trad chinese
          writing_system = name[n].writing_system
          if !writing_system.nil? && writing_system.code=='hant'
            simp_chi_name = FeatureExtensionForNamePositioning::HelperMethods.find_name_for_writing_system(prioritized_names, WritingSystem.get_by_code('hans').id)
            if !simp_chi_name.nil?
              name_relation = simp_chi_name.parent_relations.first
              if name_relation.nil?
                name_relation = name[n].child_relations.create(:skip_update => true, :is_orthographic => 1, :orthographic_system_id => OrthographicSystem.get_by_code('trad.to.simp.ch.translit').id, :is_translation => is_translation, :child_node_id => simp_chi_name.id)
                self.spreadsheet.imports.create(:item => name_relation) if name_relation.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
                if name_relation.nil?
                  puts "Could not make #{name_str} a parent of simplified chinese name for feature #{self.feature.pid}"
                else
                  simp_chi_name.update_hierarchy
                  name_positions_with_changed_relations << n if !name_positions_with_changed_relations.include? n
                end
              elsif !phonetic_system.nil? && phonetic_system.code=='tib.to.chi.transcrip'
                # only update if its tibetan
                name_relation.update_attributes(:phonetic_system_id => nil, :is_phonetic => 0, :orthographic_system_id => OrthographicSystem.get_by_code('trad.to.simp.ch.translit').id, :is_orthographic => 1, :is_translation => is_translation, :parent_node_id => name[n].id)
                self.spreadsheet.imports.create(:item => name_relation) if name_relation.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
              end
              # pinyin should be a child of the traditional and not the simplified chinese
              name_relation = simp_chi_name.child_relations.find_by(phonetic_system_id: PhoneticSystem.get_by_code('pinyin.transcrip').id)
              if !name_relation.nil?
                name_relation.update_attribute(:parent_node_id, name[n].id)
                self.spreadsheet.imports.create(:item => name_relation) if name_relation.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
              end
            end
          end
        else
          conditions = {:skip_update => true, :phonetic_system_id => phonetic_system.nil? ? nil : phonetic_system.id, :orthographic_system_id => orthographic_system.nil? ? nil : orthographic_system.id, :is_translation => is_translation, :alt_spelling_system_id => alt_spelling_system.nil? ? nil : alt_spelling_system.id}
          is_phonetic = self.fields.delete("#{i}.feature_name_relations.is_phonetic")
          if is_phonetic.blank?
            conditions[:is_phonetic] = phonetic_system.nil? ? 0 : 1
          else
            conditions[:is_phonetic] = is_phonetic.downcase=='yes' ? 1 : 0
          end
          is_orthographic = self.fields.delete("#{i}.feature_name_relations.is_orthographic")
          if is_orthographic.blank?
            conditions[:is_orthographic] = orthographic_system.nil? ? 0 : 1
          else
            conditions[:is_orthographic] = is_orthographic.downcase=='yes' ? 1: 0
          end
          is_alt_spelling = self.fields.delete("#{i}.feature_name_relations.is_alt_spelling")
          if is_alt_spelling.blank?
            conditions[:is_alt_spelling] = is_alt_spelling.nil? ? 0 : 1
          else
            conditions[:is_alt_spelling] = is_alt_spelling.downcase=='yes' ? 1: 0
          end
          if parent_node_str.blank?
            if !parent_name_str.blank?
              parent_name = prioritized_names.detect{|fn| fn.name==parent_name_str}
              if parent_name.nil?
                puts "Parent name #{parent_name_str} of #{name[n].name} for feature #{self.feature.pid} not found."
              else
                name << parent_name
                parent_position = name.size - 1
              end
            end
          else
            parent_position = parent_node_str.to_i-1
          end        
          relations_pending_save << { :relation => name[n].parent_relations.build(conditions), :parent_position => parent_position }
          name_positions_with_changed_relations << n if !name_positions_with_changed_relations.include? n
          name_positions_with_changed_relations << parent_position if !name_positions_with_changed_relations.include? parent_position
        end
      end
      relations_pending_save.each do |item|
        pending_relation = item[:relation]
        parent_node = name[item[:parent_position]]
        if parent_node.nil?
          puts "Parent name #{item[:parent_position]} of #{pending_relation.child_node.id} for feature #{self.feature.pid} not found."
        else
          relation = pending_relation.child_node.parent_relations.find_by(parent_node_id: parent_node.id)
          if relation.nil?
            pending_relation.parent_node = parent_node
            relation = pending_relation.save
            puts "Relation between names #{relation.child_note.name} and #{relation.parent_node.name} for feature #{self.feature.pid} could not be saved." if relation.nil?              
          end        
        end
      end

      # running triggers for feature_name
      if name_added
        views = self.feature.update_name_positions
        views = self.feature.update_cached_feature_names if views.blank? && name_changed
      end

      # running triggers for feature_name_relation
      name_positions_with_changed_relations.each{|pos| name[pos].update_hierarchy if !name[pos].nil?}
    end

    # Up to four optional geocode types can be specified. For each geocode type the required columns are
    # "i.geo_code_types.code"/"i.geo_code_types.name" (where i can range between 1 and 4) and
    # "i.feature_geo_codes.geo_code_value".
    # The following optional columns are also accepted:
    # "i.feature_geo_codes.info_source.id"/"i.feature_geo_codes.info_source.code" and
    # "i.feature_geo_codes.time_units.date".
    def process_geocodes(n)
      1.upto(n) do |i|
        begin
          geocode_type = GeoCodeType.get_by_code_or_name(self.fields.delete("#{i}.geo_code_types.code"), self.fields.delete("#{i}.geo_code_types.name"))
        rescue Exception => e
          puts e.to_s
        end
        next if geocode_type.nil?
        geocode_value = self.fields.delete("#{i}.feature_geo_codes.geo_code_value")
        if geocode_value.blank?
          puts "Geocode value #{geocode_value} required for #{geocode_type.name}."
          next
        end
        geocodes = self.feature.geo_codes
        geocode = geocodes.find_by(geo_code_type_id: geocode_type.id)
        if geocode.nil?
          conditions = {:geo_code_type_id => geocode_type.id, :geo_code_value => geocode_value}
          geocode = geocodes.find_by(conditions)
          geocode = geocodes.create(conditions) if geocode.nil?
          self.spreadsheet.imports.create(:item => geocode) if geocode.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
        end
        if geocode.nil?
          puts "Couldn't associate #{geocode_value} to #{geocode_type} for feature #{self.feature.pid}"
          next
        end
        second_prefix = "#{i}.feature_geo_codes"
        0.upto(3) do |j|
          third_prefix = j==0 ? second_prefix : "#{second_prefix}.#{j}"
          self.add_date(third_prefix, geocode)
          self.add_info_source(third_prefix, geocode)
          self.add_note(third_prefix, geocode)
        end
      end
    end

    # The optional column "feature_relations.related_feature.fid" can specify the THL ID for parent feature.
    # If such parent is specified, the following columns are required:
    # "perspectives.code"/"perspectives.name", "feature_relations.type.code"
    def process_feature_relations(n)
      feature_ids_with_changed_relations = Array.new
      delete_relations = self.fields.delete('feature_relations.delete')
      if !delete_relations.blank? && delete_relations.downcase == 'yes'
        self.feature.all_child_relations.clear
        self.feature.all_parent_relations.clear
      end
      replace_relations_str = self.fields.delete('feature_relations.replace')
      if replace_relations_str.blank?
        replace_relation = false
      else
        replace_relations = replace_relations_str.downcase == 'yes'
      end
      0.upto(n) do |i|
        prefix = i>0 ? "#{i}." : ''
        parent_fid = self.fields.delete("#{prefix}feature_relations.related_feature.fid")
        next if parent_fid.blank?
        parent = Feature.get_by_fid(parent_fid)
        if parent.nil?
          puts "Parent feature with THL #{parent_fid} not found."
          next
        end
        perspective_code = self.fields.delete("#{prefix}perspectives.code")
        perspective_name = self.fields.delete("#{prefix}perspectives.name")
        perspective = nil
        if perspective_code.blank? && perspective_name.blank?
          if !replace_relations
            puts "Perspective type is required to establish a relationship between feature #{self.feature.pid} and feature #{parent_fid}."
            next
          end
        else
          begin
            perspective = Perspective.get_by_code_or_name(perspective_code, perspective_name)
          rescue Exception => e
            puts e.to_s
          end
          if perspective.nil?
            puts "Perspective #{perspective_code || perspective_name} was not found."
            next
          end
        end
        relation_type_str = self.fields.delete("#{prefix}feature_relations.type.code")
        relation_type = nil
        if relation_type_str.blank?
          if !replace_relations
            puts "Feature relation type is required to establish a relationship between feature #{self.feature.pid} and feature #{parent_fid}."
            next
          end
        else
          relation_type = FeatureRelationType.get_by_code(relation_type_str)
          if relation_type.nil?
            relation_type = FeatureRelationType.get_by_asymmetric_code(relation_type_str)
            if relation_type.nil?
              puts "Feature relation type #{relation_type_str} was not found."
              next
            else
              conditions = { :parent_node_id => self.feature.id, :child_node_id => parent.id }
            end
          else
            conditions = { :parent_node_id => parent.id, :child_node_id => self.feature.id }
          end
        end
        conditions.merge!(:feature_relation_type_id => relation_type.id, :perspective_id => perspective.id) if !replace_relations
        feature_relation = FeatureRelation.find_by(conditions)
        changed = false
        if feature_relation.nil?
          feature_relation = FeatureRelation.create(conditions.merge({:skip_update => true}))
          self.spreadsheet.imports.create(:item => feature_relation) if feature_relation.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
          if feature_relation.nil?
            put "Failed to create feature relation between #{parent.pid} and #{self.feature.pid}"
          else
            changed = true
          end
        elsif replace_relations 
          feature_relation.feature_relation_type = relation_type if !relation_type.nil?
          feature_relation.perspective = perspective if !perspective.nil?
          if feature_relation.changed?
            feature_relation.skip_update = true
            feature_relation.save
            changed = true
          end
        end
        if changed
          feature_ids_with_changed_relations << parent.id if !feature_ids_with_changed_relations.include? parent.id
          feature_ids_with_changed_relations << self.feature.id if !feature_ids_with_changed_relations.include? self.feature.id
        end
        if feature_relation.nil?
          puts "Couldn't establish relationship #{relation_type_str} between feature #{self.feature.pid} and #{parent_fid}."
        else
          second_prefix = "#{prefix}feature_relations"
          0.upto(3) do |j|
            third_prefix = j==0 ? second_prefix : "#{second_prefix}.#{j}"
            self.add_date(third_prefix, feature_relation)
            self.add_info_source(third_prefix, feature_relation)
            self.add_note(third_prefix, feature_relation)
          end
        end
      end
      return feature_ids_with_changed_relations
    end

    # [i.]descriptions:
    # content, author.fullname, language.code/name
    def process_descriptions(n)
      descriptions = self.feature.descriptions
      delete_descriptions = self.fields.delete('descriptions.delete')
      descriptions.clear if !delete_descriptions.blank? && delete_descriptions.downcase == 'yes'
      0.upto(n) do |i|
        prefix = i>0 ? "#{i}.descriptions" : 'descriptions'
        description_content = self.fields.delete("#{prefix}.content")
        if !description_content.blank?
          description_content = "<p>#{description_content}</p>"
          author_name = self.fields.delete("#{prefix}.author.fullname")
          description_title = self.fields.delete("#{prefix}.title")
          author = author_name.blank? ? nil : AuthenticatedSystem::Person.find_by(fullname: author_name)
          description = description_title.blank? ? descriptions.find_by(content: description_content) : descriptions.find_by(title: description_title) # : descriptions.find_by(['LEFT(content, 200) = ?', description_content[0...200]])
          language = Language.get_by_code_or_name(self.fields.delete("#{prefix}.languages.code"), self.fields.delete("#{prefix}.languages.name"))
          attributes = {:content => description_content, :title => description_title}
          attributes[:language_id] = language.id if !language.nil?
          if description.nil?
            if language.nil?
              puts "Language needed to create description for feature #{self.feature.pid}."
              description = nil
            else
              description = descriptions.create(attributes)
            end
          else
            description.update_attributes(attributes)
          end
          if !description.nil?
            self.spreadsheet.imports.create(:item => description) if description.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
            description.authors << author if !author.nil? && !description.author_ids.include?(author.id)
          end
        end
      end    
    end
    
    # [i.]captions:
    # content, author.fullname  
    def process_captions(n)
      captions = self.feature.captions
      delete_captions = self.fields.delete('captions.delete')
      captions.clear if !delete_captions.blank? && delete_captions.downcase == 'yes'
      0.upto(n) do |i|
        prefix = i>0 ? "#{i}.captions" : 'captions'
        caption_content = self.fields.delete("#{prefix}.content")
        if !caption_content.blank?
          caption_content = "<p>#{caption_content}</p>"
          author_name = self.fields.delete("#{prefix}.author.fullname")
          language_str = self.fields.delete("#{prefix}.languages.code")
          if language_str.blank?
            puts "Language required in #{feature.fid} for caption #{caption_content}."
            next
          else
            language = Language.get_by_code(language_str)
            if language.nil?
              puts "Language #{language_str} not found in #{feature.fid} for caption #{caption_content}."
              next
            end
          end
          if author_name.blank?
            puts "Author required in #{feature.fid} for caption #{caption_content}."
            next
          else
            author = AuthenticatedSystem::Person.find_by(fullname: author_name)
            if author.nil?
              puts "Author #{author_name} not found in #{feature.fid} for caption #{caption_content}."
              next
            end
          end
          conditions = {language_id: language.id, author_id: author.id}
          attributes = {:content => caption_content}
          caption = captions.find_by(conditions)
          if caption.nil?
            caption = captions.create(conditions.merge(attributes))
          else
            caption.update_attributes(attributes)
          end
          if caption.id.nil?
            puts "Caption #{caption_content} not saved for #{feature.fid}."
            next
          end
          self.spreadsheet.imports.create(:item => caption) if caption.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
        end
      end
    end
    
    # [i.]summaries:
    # content, author.fullname  
    def process_summaries(n)
      summaries = self.feature.summaries
      delete_summaries = self.fields.delete('summaries.delete')
      summaries.clear if !delete_summaries.blank? && delete_summaries.downcase == 'yes'
      0.upto(n) do |i|
        prefix = i>0 ? "#{i}.summaries" : 'summaries'
        summary_content = self.fields.delete("#{prefix}.content")
        if !summary_content.blank?
          summary_content = "<p>#{summary_content}</p>"
          author_name = self.fields.delete("#{prefix}.author.fullname")
          language_str = self.fields.delete("#{prefix}.languages.code")
          if language_str.blank?
            puts "Language required in #{feature.fid} for summary #{summary_content}."
            next
          else
            language = Language.get_by_code(language_str)
            if language.nil?
              puts "Language #{language_str} not found in #{feature.fid} for summary #{summary_content}."
              next
            end
          end
          if author_name.blank?
            puts "Author required in #{feature.fid} for summary #{summary_content}."
            next
          else
            author = AuthenticatedSystem::Person.find_by(fullname: author_name)
            if author.nil?
              puts "Author #{author_name} not found in #{feature.fid} for summary #{summary_content}."
              next
            end
          end
          conditions = {language_id: language.id, author_id: author.id}
          attributes = {:content => summary_content}
          summary = summaries.find_by(conditions)
          if summary.nil?
            summary = summaries.create(conditions.merge(attributes))
          else
            summary.update_attributes(attributes)
          end
          if summary.id.nil?
            puts "Summary #{summary_content} not saved for #{feature.fid}."
            next
          end
          self.spreadsheet.imports.create(:item => summary) if summary.imports.find_by(spreadsheet_id: self.spreadsheet.id).nil?
          0.upto(4) do |j|
            subpref = j==0 ? prefix : "#{prefix}.#{j}"
            self.add_info_source(subpref, summary)
          end
        end
      end
    end
    
  end
end
