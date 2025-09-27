module FeatureNamesHelper
  def names_row(feature, citation_count)
    line = [feature.fid, 1]
    names = feature.names.order('position')
    names.each do |name|
      line += [name.name, name.language.code, name.writing_system.code, name.etymology, name.is_primary_for_romanization? ? 1 : 0]
      parent_relation = name.parent_relations.first
      if parent_relation.nil?
        line += [nil, nil, nil, nil]
      else
        system = parent_relation.phonetic_system
        code = system&.code
        if code.nil?
          system = parent_relation.orthographic_system
          code = system&.code
        end
        alt_spelling = parent_relation.alt_spelling_system
        parent = parent_relation.parent_node
        parent_id = parent.id
        parent_index = names.index{|n| n.id == parent_id }
        parent_index += 1 if !parent_index.nil?
        line+= [parent_index, parent_relation.is_translation? ? 1 : 0, code, alt_spelling&.code]
      end
      citations = name.citations.to_a
      while citations.size < citation_count
        citations << nil
      end
      for citation in citations
        if citation.nil?
          line += [nil, nil, nil, nil]
        else
          line += [citation.info_source_id, citation.notes]
          page = citation.pages.first
          if page.nil?
            line += [nil, nil]
          else
            pages = page.start_page.to_s
            pages << "-#{page.end_page}" if !page.end_page.nil?
            line += [page.volume, pages]
          end
        end
      end
    end
    line
  end

  def names_matrix_cleanup(matrix)
    to_be_deleted = []
    num_rows = matrix.size
    (matrix.first.size-1).downto(0) do |j|
      i = 1
      blank = true
      while blank && i<num_rows
        row = matrix[i]
        blank = false if j<row.size && !row[j].blank?
        i+=1
      end
      to_be_deleted << j if blank
    end
    to_be_deleted.each{ |j| matrix.each{ |row| row.delete_at(j) if j<row.size } }
    matrix
  end
end
