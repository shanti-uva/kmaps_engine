# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # Required for truncate_html
  require 'rexml/parsers/pullparser'
  
  def side_column_links
    str = "<h3 class=\"head\">#{link_to 'Place Dictionary', '#nogo', {:hreflang => 'Manages geographical features.'}}</h3>\n<ul>\n"
    str += "<li>#{link_to 'Home', root_path, {:hreflang => 'Search and navigate through places.'}}</li>\n"
	  str += "<li>#{link_to 'Help', '#wiki=/access/wiki/site/c06fa8cf-c49c-4ebc-007f-482de5382105/thl%20place%20dictionary%20end%20user%20manual.html', {:hreflang => 'End User Manual'}}</li>"
    str += "<li>#{link_to 'Edit', admin_root_path, {:hreflang => 'Manage places.'}}</li>\n" if logged_in?
    str += "<li>#{link_to 'Editing Help', '#wiki=/access/wiki/site/c06fa8cf-c49c-4ebc-007f-482de5382105/thl%20place%20dictionary%20editorial%20manual.html', {:hreflang => 'Editorial Manual'}}</li>" if logged_in?
    str += "<li>#{link_to 'Feature Thesaurus', "#iframe=#{SubjectsIntegration::Feature.get_url('20')}", {:hreflang => 'Feature Thesaurus'}}</li>" if defined?(SubjectsIntegration)
    str += "</ul>"
    return str.html_safe
  end
  
  #
  #
  #
  def blank_label; '-'; end
  
  def breadcrumb_separator
    "<span class=\"icon shanticon-arrow3-right\"></span>"
  end
  
  def page_header_title
    if @feature.nil?
      ts('app.short')
    else
      name = @feature.prioritized_name(current_view)
      name.nil? ? @feature.pid : name.name
    end
  end
  
  #
  # Creates a breadcrumb trail to the feature
  #
  def f_breadcrumb
    if @feature.nil?
      content_tag :ol, "<li>#{link_to(ts('home.this'), root_path)}</li>".html_safe, class: 'breadcrumb'
    else
      list = @feature.closest_ancestors_by_perspective(current_perspective).collect do |r|
        name = r.prioritized_name(current_view)
        name = name.nil? ? r.pid : name.name
        link_to(name, feature_path(r.fid))
      end
      list = [link_to("#{ts('app.short')}:", root_path)] + list[0...list.size-1].collect{|e| "#{e}#{breadcrumb_separator}".html_safe} + [list.last]
      content_tag :ol, list.collect{|e| "<li>#{e}</li>"}.join.html_safe, class: 'breadcrumb'
    end
    # content_tag :div, acts_as_family_tree_breadcrumb(feature, breadcrumb_separator) {|r| f_link(r, feature_path(r.fid), {}, {:s => true})}, :class => "breadcrumbs"
  end
  
  #
  # Creates a breadcrumb trail to the feature name
  #
  def fname_breadcrumb(feature_name)
    acts_as_family_tree_breadcrumb(feature_name) {|r| fname_label(r)}
	end
	
	def concise_fname_breadcrumb(feature_name)
	  label = ""
	  feature_name.all_parents.size.times { label << "> "}
	  label << fname_label(feature_name)
    label.html_safe
	end
  
  #
  # Accepts an instance of an ActsAsFamilyTree node and creates a breadcrumb trail from it's ancestors
  # Can pass a block for item formatting
  #
  def acts_as_family_tree_breadcrumb(aaft_instance, sep=' &gt; ')
    if aaft_instance.parent.nil?
      grandparent = aaft_instance.all_parent_relations.collect(&:parent_node).detect(&:parent)
      trail = grandparent.nil? ? [aaft_instance] : grandparent.all_parents + [grandparent, aaft_instance]
    else
      trail = aaft_instance.all_parents + [aaft_instance]
    end
    trail.collect do |r|
      block_given? ? yield(r) : r.to_s
    end.join(sep)
  end
    
  #
  # Returns the blank_label method output
  # if the path to the value is invalid or blank
  # Can specify a different default value by supplying a block
  #
  # def_if_blank(feature_name, :type, :name)
  # def_if_blank(feature_name, :type, :name){'-'}
  #
  def def_if_blank(*resource_path)
    default = block_given? ? yield : blank_label
    obj = resource_path.shift
    resource_path.each do |method|
      return default if ! obj.respond_to?(method)
      current = obj.send(method)
      return default if current.to_s.blank?
      obj = current
    end
    obj
  end
  
  #
  #
  #
  def formatted_date(*dates)
    sep = block_given? ? yield : ' - '
    dates.compact.collect {|date| date.to_formatted_s(:us_date)}.join(sep)
  end
  
  #
  #
  #
  def f_label(feature, html_attrs={})
    html_attrs[:class] = html_attrs[:class].blank? ? 'feature_name' : "#{html_attrs[:class]} feature_name"
    html_attrs[:title] ||= h(feature.name)
    content_tag(:span, fname_labels(feature), html_attrs)
  end
  
  #
  #
  #
  def f_link(feature, url, html_attrs={}, options={})
    html_attrs[:class] = html_attrs[:class].blank? ? 'feature_name' : "#{html_attrs[:class]} feature_name"
    html_attrs[:title] ||= h(feature.name)
    # url = url_for iframe_feature_path(feature.id) if current_page?(Rails.application.routes.recognize_path iframe_feature_path(feature.id))
    name = fname_labels(feature)
    name = name.s if !options[:s].nil? && options[:s]
    link_to(name, url, html_attrs)
  end
  
  #
  # This should be getting the class from the writing system, not language
  #
  def fname_labels(feature)
    #return feature.pid if feature.names.empty?
    #items = apply_name_preference feature.names.sort
    #items.collect do |item|
    #  fname_label(item)
    #end.join(' | ')
    name = feature.prioritized_name(current_view)
    if name.nil?
      feature.pid
    else
      fname_label(name)
    end
  end
  
  def fname_label(feature_name)
    css_class=feature_name.writing_system.nil? ? nil : feature_name.writing_system.code
    content_tag(:span, h(feature_name.to_s), {:class=>css_class})
  end
  
  def description_title(d)
    title = d.title.blank? ? "Essay" : d.title
    authors = d.authors.empty? ? "" : " <span class='by'> by </span><span class='content_by'>#{join_with_and(d.authors.collect(&:fullname))}</span><span class='by'> in </span><span class='content_by'>#{d.language.name}</span>"
    date = " <span class='last_updated'>(#{h(d.updated_at.to_date.to_formatted_s(:long))})</span>"
    "#{title}#{authors}#{date}".html_safe
  end
  
  def description_simple_title(d)
    d.title.blank? ? "Essay" : d.title
  end
  
  #
  #
  #
  def note_popup_link_for(object, options={})
    unless options[:association_type].blank?
      if object.respond_to?(:association_notes_for) && object.association_notes_for(options[:association_type]).length > 0
        notes = object.association_notes_for(options[:association_type])
        link_url = polymorphic_path([object, :association_notes], :association_type => options[:association_type])
      end
    else
      if object.respond_to?(:notes) && object.public_notes.length > 0
        notes = object.public_notes
        link_url = polymorphic_path([object, :notes])
      end
    end
    unless notes.nil?
      link_title = notes.collect{|n| (n.title.nil? ? 'Note' : n.title) + (" by #{n.authors.collect(&:fullname).join(", ").s}" if n.authors.length > 0).to_s}.join(', ')
      link_classes = "draggable-pop no-view-alone overflow-y-auto height-350"
      ("<span class='has-draggable-popups note-popup-link'>" +
        link_to("", link_url, :class => "popup-link-icon note-popup-link-icon shanticon-stack "+link_classes, :title => Note.model_name.human(count: notes.count).titleize,  data: {:"js-kmaps-popup" => link_url }) +
        #link_to("See Note", link_url, :class => "note-popup-link-text "+link_classes, :title => Note.model_name.human(count: notes.count).titleize, data: {:"js-kmaps-popup" => link_url }) +
      "</span>").html_safe
    else
      ""
    end
  end
  def citation_popup_link_for(object, options={})
    if object.respond_to?(:citations) && !object.citations.empty?
      citations = object.citations
      link_url = polymorphic_path([object, :citations])
    end
    unless citations.nil?
      link_title = citations.collect{|c| (c.citable_type.nil? ? 'Citation' : c.citable_type) + (" source type: #{c.info_source_type}").to_s}.join(', ')
      link_classes = "draggable-pop no-view-alone overflow-y-auto height-350"
      ("<span class='has-draggable-popups citation-popup-link'>" +
        link_to("", link_url, :class => "popup-link-icon citation-popup-link-icon shanticon-sources "+link_classes, :title => Citation.model_name.human(count: citations.count).titleize, data: {:"js-kmaps-popup" => link_url }) +
        #link_to("See Citation", link_url, :class => "citation-popup-link-text "+link_classes, :title => Citation.model_name.human(count: citations.count).titleize, data: {:"js-kmaps-popup" => link_url }) +
      "</span>").html_safe
    else
      ""
    end
  end
  
  #
  #
  #
  def note_popup_link_list_for(object, options={})
    unless options[:association_type].blank?
      if object.respond_to?(:association_notes_for) && object.association_notes_for(options[:association_type]).length > 0
        notes = object.association_notes_for(options[:association_type])
      end
    else
      if object.respond_to?(:notes) && object.public_notes.length > 0
        notes = object.public_notes
        link_url = polymorphic_path([object, :notes])
      end
    end
    if !notes.nil? && notes.length > 0 
      # Wrapping this in a <p /> makes its font size incorrect, so for now, we'll achieve the top margin with
      # a <br />.
      ('<br />
      <strong>Notes:</strong>
      <ul class="note-popup-link-list">' +
        notes.collect{|n| "<li>#{note_popup_link(n)}</li>" }.join() +
      '</ul>').html_safe
    end
  end

  def citation_popup_link_list_for(object, options={})
    if object.respond_to?(:citations) && !object.citations.empty?
      citations = object.citations
      link_url = polymorphic_path([object, :citations])
    else
      citations = nil
    end
    unless citations.nil?
      # Wrapping this in a <p /> makes its font size incorrect, so for now, we'll achieve the top margin with
      # a <br />.
      ('<br />
      <strong>Citations:</strong>
      <ul class="citation-popup-link-list">' +
        citations.collect{|n| "<li>#{citation_popup_link(n)}</li>" }.join() +
      '</ul>').html_safe
    end
  end
  
  #
  #
  #
  def note_popup_link(note)
    note_title = note.title.nil? ? "Note" : note.title
    note_authors = " by #{note.authors.collect(&:fullname).join(", ").s}" if note.authors.length > 0
    note_date = " (#{formatted_date(note.updated_at)})"
    link_title = "#{note_title}#{note_authors}#{note_date}"
    link_url = polymorphic_path([note.notable, note])
    link_classes = "draggable-pop no-view-alone overflow-y-auto height-350"
    "<span class='has-draggable-popups'>
      #{link_to(link_title, link_url, class: link_classes, title: h(note_title))}
    </span>".html_safe
  end
  def citation_popup_link(citation)
    citation_citable_type = citation.citable_type.nil? ? "Citation" : citation.citable_type
    citation_info_source_type = citation.info_source_type
    citation_date = " (#{formatted_date(citation.updated_at)})"
    link_title = "#{citation_citable_type}-#{citation_info_source_type}#{citation_date}"
    link_url = polymorphic_path([citation.citable, citation])
    link_classes = "draggable-pop no-view-alone overflow-y-auto height-350"
    "<span class='has-draggable-popups'>
      #{link_to(link_title, link_url, class: link_classes, title: h(citation_citable_type))}
    </span>".html_safe
  end
  
  #
  #
  #
  def time_units_for(object, options={})
    if object.respond_to?(:time_units)
      if object.time_units.size > 0
        time_units_list = object.time_units_ordered_by_date.collect{|tu| "#{tu}#{note_popup_link_for(tu)}" }.reject{|str| str.blank?}.join("; ")
        "<span class='time-units'>(#{time_units_list})</span>".html_safe
      end
    end
  end
  
  #
  # Allows for specification of what model names should be displayed as to users (e.g. "location" instead of "shape")
  #
  def model_display_name(str)
    names = {
      'association_note' => Note.model_name.human,
      'description' => Description.model_name.human,
      'feature' => Feature.model_name.human,
      'feature_geo_code' => FeatureGeoCode.model_name.human,
      'feature_name' => FeatureName.model_name.human,
      'time_unit' => 'date'
    }
    names[str].nil? ? str : names[str]
  end
    
  #
  #
  #
  def yes_no(value)
    (value.nil? || value==0 || value=='false' || value == false) ? ts(:negation) : ts(:affirmation)
  end
  
  #
  #
  #
  def highlight(string)
    ('<span class="highlight">' + string + '</span>').html_safe
  end
    
  def custom_secondary_tabs(current_tab_id=:place)

    @tab_options ||= {}
    
    if @tab_options[:entity].blank?
      tabs = {}
    else
      tabs = custom_secondary_tabs_list
    end
    
    current_tab_id = :place unless (tabs.keys << :home).include? current_tab_id
    
    tabs = tabs.sort_by{ |t| t[1][:index] }.collect{|tab_id, tab|
      remove_tab = false
      if tab[:url].blank? && !@tab_options[:entity].blank?
        entity = @tab_options[:entity]
        url = nil
        count = nil
        case tab_id
        when :place
          url = feature_path(entity.fid)
        when :descriptions
          if entity.descriptions.empty?
            remove_tab = true
          else
            url = feature_description_path(entity.fid, entity.descriptions.first)
            count = entity.descriptions.size
          end
        when :related
          url = related_feature_path(entity.fid)
          count = entity.all_relations.size
        end
      else
        tab_url = tab[:url]
      end
      title = count.nil? ? tab[:title] : "#{tab[:title]} <span class=\"badge\">#{count}</span>"
      
      remove_tab ? nil : [tab_id, title, url, tab[:shanticon]]
    }.reject{|t| t.nil?}
    
    tabs
  end
  
  # TODO: Add rules here based on language of name and perspective.
  def apply_name_preference(names)
    return [] if names.empty?
    filtered = []
    # FIXME: This should be cleaned up; most direct implementation to get something working
    latin_names = names.select {|n| !n.writing_system.blank? and n.writing_system.is_latin?}
    latin_names.each do |name|
      unless name.language.blank?
        filtered << name if name.language.is_english?
        if name.language.is_chinese?
          related_name = name.relations.select {|r| !r.phonetic_system.blank? and r.phonetic_system.is_pinyin? }
          filtered << related_name.first.child_node unless related_name.empty?
        end
        if name.language.is_nepali?
          related_name = name.relations.select {|r| !r.phonetic_system.blank? and r.phonetic_system.is_ind_transcrip? }
          filtered << related_name.first.child_node unless related_name.empty?
          filtered << name if name.is_original? and related_name.empty?
        end
        if name.language.is_tibetan?
          related_name = name.relations.select {|r| !r.phonetic_system.blank? and r.phonetic_system.is_thl_simple_transcrip? }
          filtered << related_name.first.child_node unless related_name.empty?
        end
      end
    end
    # TODO: improve fallback. For now names transcript in latin script are better than nothing.
    if filtered.empty?
      latin_names
    else
      filtered.uniq # in case any dupes get added
    end
  end
  
  def join_with_and(list)
    size = list.size
    case size
    when 0 then nil
    when 1 then list.first
    when 2 then list.join(' and ')
    when 3 then [list[0..size-2].join(', '), list[size-1]].join(', and ')
    end.s
  end
  
  # Custom HTML truncate for PD descriptions, which don't always validate
  def truncate_html(input, len = 30, extension = "...")
    #output = input
    #output.gsub!(/<\/p>\s*<p>/iu, "<br /><br />")
    #output = sanitize(input, :tags => %w(br h1 h2 h3 h4 h5 h6 ul ol li))
    #output.gsub!(/<br.*?>/, "\v")
    
    # We need to be able to call .s on the input, but not on the extension, so we
    # have to use a modified version of truncate() instead of truncate() itself.
    # output = truncate(input, :length => len, :omission => extension)
    l = len - extension.size
    # Temporarily removing .s, as it takes a while to run on long strings
    #output = (chars.length > len ? chars[0...l].s + extension : input).to_s
    #output = input.size > len ? input[0...l] + extension : input
    
    output = strip_tags(input)
    output.strip!
    #output.gsub!(/\v/, "<br />")
    return (output.size < len ?  output : (output[0...l] + extension)).html_safe
  end
  
  # HTML truncate for valid HTML, requires REXML::Parsers::PullParser
  def truncate_well_formed_html(input, len = 30, extension = "...")
    def attrs_to_s(attrs)
      return '' if attrs.empty?
      attrs.to_a.map { |attr| %{#{attr[0]}="#{attr[1]}"} }.join(' ')
    end

    p = REXML::Parsers::PullParser.new(input)
      tags = []
      new_len = len
      results = ''
      while p.has_next? && new_len > 0
        p_e = p.pull
        case p_e.event_type
      when :start_element
        tags.push p_e[0]
        results << "<#{tags.last} #{attrs_to_s(p_e[1])}>"
      when :end_element
        results << "</#{tags.pop}>"
      when :text
        results << p_e[0].first(new_len)
        new_len -= p_e[0].length
      end
    end

    tags.reverse.each do |tag|
      results << "</#{tag}>"
    end

    (results.to_s + (input.length > len ? extension : '')).html_safe
  end
  
  # Override the default page_entries_info from will_paginate
  def page_entries_info(collection, options = {})
    entry_name = options[:entry_name] ||
      (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
    (if collection.total_pages < 2
      case collection.size
      when 0; "No #{entry_name.pluralize} found"
      when 1; "Displaying <b>1</b> #{entry_name}"
      else;   "Displaying <b>all #{collection.size}</b> #{entry_name.pluralize}"
      end
    else
      %{Showing #{entry_name.pluralize} <b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b>} % [
        collection.offset + 1,
        collection.offset + collection.length,
        collection.total_entries
      ]
    end).html_safe
  end
  
  def pictures_url(feature)
    pictures_associated_medium_path(feature.fid)
  end
  
  def videos_url(feature)
    videos_associated_medium_path(feature.fid)
  end
  
  def documents_url(feature)
    documents_associated_medium_path(feature.fid)
  end
  
  def object_authorized?(o)
    current_user.object_authorized?(o)
  end
  
  def contextual_feature
    return @contextual_feature if !@contextual_feature.nil?
    feature = nil
    feature = @feature if defined?(@feature) && !@feature.nil?
    feature = object if feature.nil? && defined?(object) && object.instance_of?(Feature)
    feature = case parent_type
    when :feature then parent_object
    when :description, :feature_name, :feature_geo_code then parent_object.feature
    when :feature_relation then parent_object.child_node
    when :feature_name_relation then parent_object.child_node.feature
    else nil
    end if feature.nil? && defined?(parent_type)
    if feature.nil? || feature.id.nil?
      context_id = session[:interface].blank? ? nil : session[:interface][:context_id]
      begin
        feature = Feature.find(context_id) if !context_id.blank?
      rescue ActiveRecord::RecordNotFound
        feature = nil
      end
    else
      session[:interface][:context_id] = feature.id
    end
    @contextual_feature = feature
  end
end
