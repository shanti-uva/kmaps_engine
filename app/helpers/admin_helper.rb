module AdminHelper
  def is_admin_area?
    params[:controller] =~ /^(admin|authenticated_system\/[^s])/
  end

  def admin_textarea(form_builder, field, **options)
    options[:cols] ||= 70
    options[:rows] ||= 10
    form_builder.text_area(field, **options)
  end

  #
  # Returns the base path of the current url (removes the query params)
  #
  def resolved_collection_path
    request.env['PATH_INFO']
  end

  def list_actions_for_item(item, **options)
    options[:edit_path] ||= edit_object_path(item)
    options[:view_path] ||= object_path(item)
    options[:delete_path] ||= object_path(item)
    items=[]
    items << edit_item_link(options[:edit_path], options[:edit_name]) unless options[:hide_edit]
    if !options[:manage_path].blank?
      items << manage_item_link(options[:manage_path], options[:manage_name]) unless options[:hide_manage]
    end
    items << view_item_link(options[:view_path], options[:view_name]) unless options[:hide_view]
    items << delete_item_link(options[:delete_path], options[:delete_name]) unless options[:hide_delete]
    ('<span class="listActions">'+items.join(' | ')+'</span>').html_safe
  end
  
  def stacked_parents
    if defined?(extended_stacked_parents)
      extended_stacked_parents
    else
      array = [:admin]
      if !parent_object.instance_of?(Feature) && parent_object.respond_to?(:feature)
        array << parent_object.feature
      end
      array << parent_object
      array
    end
  end
  
  def name_preferences_admin_resources
    menu = {}
    if authorized?(admin_alt_spelling_systems_path) || authorized?(admin_languages_path) || authorized?(admin_orthographic_systems_path) || authorized?(admin_phonetic_systems_path) || authorized?(admin_writing_systems_path)
      menu[AltSpellingSystem.model_name.human(:count => :many).titleize.s] = admin_alt_spelling_systems_path if authorized? admin_alt_spelling_systems_path
      menu[Language.model_name.human(:count => :many).titleize.s] = admin_languages_path if authorized? admin_languages_path
      menu[OrthographicSystem.model_name.human(:count => :many).titleize.s] = admin_orthographic_systems_path if authorized? admin_orthographic_systems_path
      menu[PhoneticSystem.model_name.human(:count => :many).titleize.s] = admin_phonetic_systems_path if authorized? admin_phonetic_systems_path
      menu[WritingSystem.model_name.human(:count => :many).titleize.s] = admin_writing_systems_path if authorized? admin_writing_systems_path
    end
    return menu
  end
  
  def user_admin_resources
    menu = {}
    if authorized?(admin_collections_path) || authorized?(authenticated_system_people_path) || authorized?(authenticated_system_roles_path)
      menu[Collection.model_name.human(:count => :many).titleize.s] = admin_collections_path if authorized? admin_collections_path
      menu[AuthenticatedSystem::Person.model_name.human(:count => :many).titleize.s] = authenticated_system_people_path if authorized? authenticated_system_people_path
      menu[AuthenticatedSystem::Role.model_name.human(:count => :many).titleize.s] = authenticated_system_roles_path if authorized? authenticated_system_roles_path
    end
    return menu
  end
  
  def data_management_admin_resources
    menu = {}
    if authorized?(admin_geo_code_types_path) || authorized?(admin_perspectives_path) || authorized?(admin_views_path) || authorized?(admin_oral_sources_path) || authorized?(admin_note_titles_path)
      menu[GeoCodeType.model_name.human(:count => :many).titleize.s] = admin_geo_code_types_path if authorized? admin_geo_code_types_path
      menu["Create new #{Feature.model_name.human.titleize.s}"] = new_admin_feature_path if authorized? new_admin_feature_path
      menu[FeatureRelationType.model_name.human(:count => :many).titleize.s] = admin_feature_relation_types_path if authorized? admin_feature_relation_types_path
      menu[Perspective.model_name.human(:count => :many).titleize.s] = admin_perspectives_path if authorized? admin_perspectives_path
      menu[View.model_name.human(:count => :many).titleize.s] = admin_views_path if authorized? admin_views_path
      menu[OralSource.model_name.human(:count => :many).titleize.s] = admin_oral_sources_path if authorized? admin_oral_sources_path
      menu[NoteTitle.model_name.human(:count => :many).titleize.s] = admin_note_titles_path if authorized? admin_note_titles_path
    end
    return menu
  end
  
  def admin_task_resources
    menu = {}
    if authorized?(admin_blurbs_path) || authorized?(admin_feature_pids_path) || authorized?(admin_importation_tasks_path)
      menu[Blurb.model_name.human(:count => :many).titleize.s] = admin_blurbs_path if authorized? admin_blurbs_path
      menu["#{Feature.human_attribute_name(:pid).s} Generator"] = admin_feature_pids_path if authorized? admin_feature_pids_path
      menu[ImportationTask.model_name.human(:count => :many).titleize.s] = admin_importation_tasks_path if authorized? admin_importation_tasks_path
    end
    return menu
  end
  
  def admin_resources
    resources = {}
    # resources['Admin Home'] = admin_root_path if authorized? admin_root_path
    resources['Name preferences'] = name_preferences_admin_resources
    resources['User admin'] = user_admin_resources
    resources['Data management'] = defined?(extended_data_management_admin_resources) ? extended_data_management_admin_resources : data_management_admin_resources
    resources['Admin tasks'] = admin_task_resources
    resources
  end

  def resource_nav
    path = "#{ActionController::Base.relative_url_root}/#{params[:controller]}"
    path = authenticated_system_people_path if path =~ /\/authenticated_system\/users/
    select_tag :resources, options_for_select(admin_resources.sort, path), id: :SelectNav, class: 'form-control form-select ss-select selectpicker'
  end

  def resource_search_form(**extra_hidden_fields)
    #extra_hidden_fields[:page] = params[:page] # keep the current page when clearing?
    html = "<div>"
    html += form_tag '', :method=>:get
    html += text_field_tag :filter, h(params[:filter]), class: [:text, 'text-full form-text']
    extra_hidden_fields.each do |k,v|
      html += hidden_field_tag k, h(v)
    end
    html += submit_tag 'Search', class: 'btn btn-primary form-submit'
    html += ' '
    html += link_to('clear', resolved_collection_path, extra_hidden_fields.merge({class: 'btn btn-primary form-submit', id: 'edit-cancel'})) if params[:filter]
    html += '</form></div>'
    html.html_safe
  end

  #
  # This is set on top of the column headers in a list table
  #
  def pagination_row(**options)
    # switch between the pagination and a non-breaking space:
    content = @collection.total_pages > 1 ? will_paginate(@collection) : '&nbsp;'
    "<tr>
      <th style='text-align:right;' class='paginationHeader' colspan=#{options[:colspan]}'>
        <div style='position:absolute;'>#{@collection.total_entries} Total</div>
        #{content}
      </th>
    </tr>".html_safe
  end

  def parent_resource_dependency_message
    "A #{model_name.titleize} can only be created from a resource that uses one.".html_safe
  end

  def empty_collection_message(message="No #{model_name.classify.constantize.model_name.human(:count => :many).titleize} found.")
    "<div class='info'>#{message}</div>".html_safe
  end

  #
  #
  #
  def page_title
    title = @page_title

    @page_title = 'THL Places Editor'
    unless respond_to? :model_name
      return [@page_title, title].join(': ')
    end

    # index, show, new, create, edit, update, delete
    name = model_name.titleize
    default = "#{params[:controller].sub(/admin\//,'').titleize}: #{params[:action].humanize.downcase}"
    map = {
      :index=>"Listing #{name.pluralize}",
      :show=>"Showing #{name}",
      :new=>"Creating #{name}",
      :create=>"Creating #{name}",
      :edit=>"Editing #{name}",
      :update=>"Editing #{name}",
      :delete=>"Deleting #{name}"
    }
    found = map[params[:action].to_sym]
    @page_title = [@page_title, (found.nil? ? default : found), title].join(': ').html_safe
  end

  #
  #
  #
  def yes_no_radios(form_builder, field, options={}, yes_options={}, no_options={})
    yes_value = 1
    no_value = 0
    if (form_builder.object.send field).nil?
      no_value = nil
    end
    "<div#{' class="'+options[:class]+'"' if options[:class]}>
      <label>
        #{form_builder.radio_button field, yes_value, yes_options} #{ts :affirmation}
      </label>
      <label>
        #{form_builder.radio_button field, no_value, no_options} #{ts :negation}
      </label>
    </div>".html_safe
  end

  #
  #
  #
  def feature_name_link(feature_name)
    link_to(feature_name, admin_feature_feature_name_path(feature_name.feature, feature_name))
  end

  #
  #
  #
  def features_link
    link_to_unless_current(Feature.model_name.human(:count => :many), admin_features_path)
  end

  #
  #
  #
  def model_label(model)
    case model.class.to_s
      when 'Feature'
        feature_label(model)
      else
        model.to_s
      end
  end

  #
  #
  #
  def model_link(model)
    case model.class.to_s
    when 'Feature'
      feature_link(model)
    else
      link_to(model.to_s.humanize, model_path(model))
    end
  end

  #
  # Wraps the block contents in a div
  # and adds a "Feature: " start crumb
  #
  def render_breadcrumbs
    #@breadcrumbs.unshift link_to_unless_current('features', admin_features_path)
    #@breadcrumbs.to_a.join(' > ').html_safe
    @breadcrumbs ||= []
    list = [link_to("#{ts('home.this')}:".html_safe, admin_root_path)]+@breadcrumbs[0...@breadcrumbs.size-1].collect{|e| "#{e}#{breadcrumb_separator}".html_safe} + [@breadcrumbs.last]
    content_tag :ol, list.collect{|e| "<li>#{e}</li>"}.join.html_safe, class: 'breadcrumb'
  end

  def add_breadcrumb_item(item)
    @breadcrumbs ||= []
    @breadcrumbs << item
  end

  def add_breadcrumb_items(*items)
    items.each {|item| add_breadcrumb_item item}
  end

  def add_breadcrumb_base
    # Notes are polymorphic,
    # so we've gotta support
    # breadcrumbs for each of the parent types!
    add_breadcrumb_item feature_link(contextual_feature)
    case parent_type
    when :description
      add_breadcrumb_item feature_descriptions_link(parent_object.feature)
      add_breadcrumb_item link_to(parent_object.id, admin_feature_description_path(parent_object.feature, parent_object))
    when :feature
    when :feature_name
      add_breadcrumb_item feature_names_link(parent_object.feature)
      add_breadcrumb_item link_to(parent_object.id, admin_feature_name_path(parent_object))
    when :feature_name_relation
      add_breadcrumb_item feature_names_link(parent_object.child_node.feature)
      add_breadcrumb_item link_to(parent_object.child_node.name, admin_feature_name_path(parent_object.child_node))
      add_breadcrumb_item link_to(ts('relation.this', :count => :many), admin_feature_name_feature_name_relations_path(parent_object.child_node))
      add_breadcrumb_item link_to(parent_object, admin_feature_name_feature_name_relation_path(parent_object.child_node, parent_object))
    when :feature_geo_code
      # parent_object is FeatureGeoCode
      add_breadcrumb_item link_to(FeatureGeoCode.model_name.human(:count => :many).s, admin_feature_feature_geo_codes_path(parent_object.feature))
      add_breadcrumb_item link_to(parent_object, admin_feature_geo_code_path(parent_object))
    when :feature_relation
      add_breadcrumb_item link_to(ts('relation.this', :count => :many), admin_feature_feature_relations_path(parent_object.child_node))
      add_breadcrumb_item feature_relation_role_label(parent_object.child_node, parent_object, :use_first=>false)
    when :time_unit
      add_breadcrumb_item link_to(ts('date.this', :count => :many), admin_time_units_path)
      add_breadcrumb_item link_to(parent_object.to_s, polymorphic_path([:admin, parent_object]))
    end
  end

  #
  # Pass in a set of root FeatureNames (having the same parent)
  # to build a ul list
  # "completed" is used only by this method
  #
  def feature_name_tr(feature, root_names=nil, completed=[])
    root_names = feature.names.roots.order('position') if feature
    root_names = root_names.sort{ |a, b| a.position <=> b.position }
    html=''
    root_names.each do |name|
      next if completed.include? name
      completed << name

      html += '<tr id="feature_name_'+name.id.to_s+'"><td class="centerText">';
      if @locating_relation
        html += form_tag new_admin_feature_name_feature_name_relation_path(feature), {:method=>:get}
        html += hidden_field_tag :target_id, name.id
        html += submit_tag 'Select'
        html += '</form>'
      else
        html += list_actions_for_item(name,
              delete_path: admin_feature_feature_name_path(name.feature, name),
              edit_path:   edit_admin_feature_feature_name_path(name.feature, name),
              view_path:   admin_feature_feature_name_path(name.feature, name))
      end
      html +=  '</td>'
      padding = name.all_parents.size * 25
      html +=  '<td style="padding-left: ' + padding.to_s + 'px">'
      html += (name.name) + '</td>'
      html += '<td>' + def_if_blank(name, :feature_name_type).to_s + '</td>'
      html += '<td>' + def_if_blank(name, :language).to_s + '</td>'
      html += '<td>' + def_if_blank(name, :writing_system).to_s + '</td>'
      html += '<td>' + fn_relationship(name).to_s + '</td>'
      html += '<td>' + name.position.to_s + '</td>'
      html += '<td>' + note_link_list_for(name) + new_note_link_for(name) + '</td>'
      html += '<td>' + time_unit_link_list_for(name) + new_time_unit_link_for(name) + '</td>'
      html += '</tr>'
      html += feature_name_tr(nil, name.children, completed).to_s
    end
    (html.blank? ? '' : "<ul style='margin:0;'>#{html}</ul>").html_safe
  end
  #
  #
  #
  def feature_relations_link(feature_instance=nil)
    if feature_instance.nil?
      link_to('feature relations', admin_feature_relations_path)
    else
      link_to('relations', admin_feature_feature_relations_path(feature_instance))
    end
  end

  #
  #
  #
  def citations_link
    link_to 'citations', admin_citations_path
  end

  #
  #
  #
  def feature_label(feature)
    "<span class='featureLabel' title='#{h feature.name}'>#{fname_labels(feature)}</span>".html_safe
  end

  #
  #
  #
  def feature_link(feature, *args)
    v = View.get_by_code(default_view_code)
    name = feature.prioritized_name(v)
    link_to(fname_labels(feature), admin_feature_path(feature.fid, *args), {class: :featureLabel, title: name.nil? ? feature.fid : name.name })
  end

  def feature_names_sorted(feature_names)
    list = []
    feature_names.roots.order('position').each do |r|
      list << r
      load_child_names(r, list)
    end
    list
  end

  def load_child_names(feature_name, list)
    return if feature_name.children.empty?
    feature_name.children.order('position').each do |c|
      list << c
      load_child_names(c, list)
    end
  end

  #
  #
  #
  def feature_names_link(feature=nil)
    feature.nil? ? link_to('feature names', admin_feature_names_path) : link_to('names', admin_feature_feature_names_path(feature))
  end

  #
  #
  #
  def feature_names_prioritize_link(feature=nil)
    feature.nil? ? link_to('admin', admin_path) : link_to('prioritize names', '/admin/feature_names/prioritize/' + feature.id.to_s)
  end

  def feature_descriptions_link(feature=nil)
    feature.nil? ? link_to('admin', admin_path) : link_to('essays', admin_feature_descriptions_path(feature))
  end
  #
  #
  #
  def feature_name_relations_link(feature_name=nil)
    feature_name.nil? ? link_to('feature name relations', admin_feature_name_relations_path) : link_to('relations', admin_feature_name_feature_name_relations_path(feature_name))
  end

  #
  #
  #
  def feature_name_label(feature_name)
    ('<span class="featureNameLabel">' + feature_name.to_s + '</span>').html_safe
  end

  #
  # Express the relationship relative to the "feature" arg node
  #
  def feature_relation_role_label(feature, relation, **opts)
    options={
      :use_first=>true,:use_second=>true,:use_relation=>true,
      :link_first=>true,:link_second=>true,:link_relation=>true
    }.merge(opts)
    relation.role_of?(feature) do |other,sentence|
      items=[]
      if options[:use_first]
        items << (options[:link_first] ?
          (options[:use_names] ? f_link(feature, admin_feature_path(feature.fid)) : feature_link(feature)) :
          feature_label(feature))
      end
      if options[:use_relation]
        sentence = sentence
        items << (options[:link_relation] ? link_to(sentence, admin_feature_feature_relation_path(feature, relation)) : sentence)
      end
      if options[:use_second]
        items << (options[:link_second] ?
          (options[:use_names] ? f_link(other, admin_feature_path(other.fid)) : feature_link(other)) :
          feature_label(other))
      end
      items.join(" ").html_safe
    end
  end

  def association_note_list_fieldset(association_type, **options)
    "<h4>General Notes</h4>
      #{highlighted_new_item_link new_polymorphic_path([:admin, @object, :association_note], :association_type => association_type), 'New Note'}
      <br class='clear'/>
      #{render :partial => 'admin/association_notes/list', :locals => { :list => @object.association_notes_for(association_type, :include_private => true), :options => {:hide_type => true, :hide_type_value => true, :hide_association_type => true, :hide_empty_collection_message => true} }}".html_safe
  end

  def note_list_fieldset(object=nil)
    object ||= @object
    html = "<fieldset>
      <legend>Notes</legend>
      <div class='left highlight'>
        #{new_item_link(new_polymorphic_path([:admin, object, :note]), 'New Note')}
      </div>
      <br class='clear'/>
      #{render :partial => 'admin/notes/list', :locals => { :list => object.notes, :options => {:hide_type => true, :hide_type_value => true} }}
    </fieldset>"
    html.html_safe
  end

  def citation_list_fieldset(**options)
    object = options[:object] || @object
    html = "<fieldset>
      <div class='left highlight'>
        #{new_item_link(new_polymorphic_path([:admin, object, :citation]), 'New Citation')}
      </div>
      <br class='clear'/>
      #{render :partial => 'admin/citations/citations_list', :locals => { :list => object.citations, :options => {:hide_type => true, :hide_type_value => true} }}
    </fieldset>"
    html.html_safe
  end

  def time_unit_list_fieldset(**options)
    object = options[:object] || @object
    html = "<fieldset>
      <legend>Dates</legend>
      <div class='left highlight'>
        #{new_item_link(new_polymorphic_path([:admin, object, :time_unit]), 'New Date')}
      </div>
      <br class='clear'/>
      #{render :partial => 'admin/time_units/list', :locals => { :list => object.time_units, :options => {:hide_type => true, :hide_type_value => true} }}
    </fieldset>"
    html.html_safe
  end

  def note_link_list_for(object)
    if object.respond_to?(:notes) && object.notes.length > 0
      object.notes.each_with_index.collect{|n, i|
        note_title = n.title.blank? ? "Note" : n.title
        note_authors = " by #{n.authors.collect(&:fullname).join(", ").s}" if n.authors.length > 0
        link_to "Note #{i+1}", polymorphic_path([:admin, object, n]), :title => h("#{note_title}#{note_authors}")
      }.join(', ').html_safe
    else
      ""
    end
  end

  def time_unit_link_list_for(object)
    if object.respond_to?(:time_units)
      time_units = object.time_units_ordered_by_date
      if time_units.length > 0
        time_units.each_with_index.collect{|tu, i|
          time_unit_title = tu.to_s.blank? ? "Date" : tu.to_s
          link_to "Date #{i+1}", polymorphic_path([:admin, object, tu]), :title => h("#{time_unit_title}")
        }.join(', ').html_safe
      else
        ""
      end
    else
      ""
    end
  end

  def new_note_link_for(object, **options)
    if object.respond_to?(:notes)
      new_item_link new_polymorphic_path([:admin, object, :note]), options[:include_text] ? "New Note" : ""
    else
      ""
    end
  end

  def new_time_unit_link_for(object, **options)
    if object.respond_to?(:time_units)
      new_item_link new_polymorphic_path([:admin, object, :time_unit]), options[:include_text] ? "New Date" : ""
    else
      ""
    end
  end

  def fn_relationship(feature_name)
    feature_name.display_string
  end
end
