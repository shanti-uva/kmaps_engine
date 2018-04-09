#
#
#
# This is the helper for the **public** view
#
#
#
module FeaturesHelper
  def has_search_scope?
    !params[:search_scope].blank?
  end
  
  def is_global_search_scope?
    'global' == params[:search_scope]
  end
  
  def is_contextual_search_scope?
    'contextual' == params[:search_scope]
  end
  
  def is_fid_search_scope?
    'fid' == params[:search_scope]
  end
  
  def node_li_value(node, target)
    if target && node.id == target.id
      f_label(node, :class=>:selected)
    else
      f_link(node, features_path(:context_id=>node.id, :filter=>params[:filter]))
      # f_link(node, feature_path(node.fid), :class => :remote)
    end
  end
  
  #
  # Common html attributes for a popup/"Thickbox" link
  #
  def popup_attrs(feature)
    {
    :class=>'thickbox',
    :title=>link_to('Link to this Feature', feature_path(feature.fid))
    }
  end
  
  #
  # The common url params used for popup/"Thickbox"
  #
  def popup_params
    {:height=>500, :width=>500, :no_layout=>true}
  end
  
  #
  # Creates a link for a feature
  # if the @no_layout param is set (see application_controller) - use popup/"Thickbox"
  # else just a standard link
  #
  def feature_link_switch(feature)
    if @no_layout
      # show feature in popup
      f_link(feature, feature_path(feature.fid, popup_params), popup_attrs(feature))
    else
      # load feature as usual
      f_link(feature, feature_path(feature.fid))
    end
  end
  
  #
  #
  #
  def f_popup_link(feature)
    html_attrs = popup_attrs(feature)
    html_attrs[:class] += feature.id.to_s==params[:context_id] ? ' selected' : ''
    f_link(feature, feature_path(feature.fid, popup_params), html_attrs)
  end
  
  #
  # Pass in a set of root FeatureNames (having the same parent)
  # to build a ul list
  # "completed" is used only by this method
  #
  def feature_name_ul(feature, use_links=true, root_names=nil, completed=[])
    root_names = feature.names.roots.order('position') if feature
    html=''
    root_names.each do |name|
      next if completed.include? name
      completed << name
      html += '<li style="margin-left:1em; list-style:none;">'
      html += '<b>&gt;</b>&nbsp;' unless name.is_original?
      html += (use_links ? link_to(feature_name_display(name), admin_feature_name_path(name)) : feature_name_display(name, {:show_association_links => true}))
      html += feature_name_ul(nil, use_links, name.children.order('position'), completed)
      html += '</li>'
    end
    (html.blank? ? '' : "<ul style='margin:0; margin-top: 5px;'>#{html}</ul>").html_safe
  end
  
  def feature_name_display(name, options={})
    if options[:show_association_links]
      name_notes_link = note_popup_link_for(name)
      name_citations_link = citation_popup_link_for(name)
      name_time_units_link = time_units_for(name)
    end
    "#{name.detailed_name.s}#{name_notes_link}#{name_citations_link}#{name_time_units_link}"
  end
  
  def feature_name_header(feature)
    # names = apply_name_preference(feature.names).sort
    name = feature.prioritized_name(current_view)
    name.nil? ? feature.pid : name
  end

  def generate_will_paginate_link(page, text)
    # slippery way of getting this link to be ajaxy and to 'know' its url; see views/features/_descendants.html.erb
    "<a href='#' class='ajax_get' name='#{url_for(params.merge(:page => page != 1 ? page : nil))}'>#{text}</a>".html_safe
  end
  
  def active_menu_item
    !session[:interface].blank? && !session[:interface][:menu_item].blank? ? session[:interface][:menu_item] : 'browse'
  end
end
