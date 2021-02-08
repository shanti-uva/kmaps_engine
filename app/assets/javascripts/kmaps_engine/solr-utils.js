// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
; var kmapsSolrUtils = ( function( $, window, document, undefined ) {

  "use strict";

  var SOLR_ROW_LIMIT = 2000;

  // undefined is used here as the undefined global variable in ECMAScript 3 is
  // mutable (ie. it can be changed by someone else). undefined isn't really being
  // passed in so we can ensure the value of it is truly undefined. In ES5, undefined
  // can no longer be modified.

  // window and document are passed through as local variables rather than global
  // as this (slightly) quickens the resolution process and can be more efficiently
  // minified (especially when both are regularly referenced in your plugin).

  // Create the defaults once
  var pluginName = "kmapsSolrUtils",
    defaults = {
      termIndex: "http://localhost/solr/kmterms_dev",
      assetIndex: "http://localhost/solr/kmassets_dev",
      featureId: "places-1",
      domain: "places",
      perspective: "general",
      view: 'roman.scholar',
      tree: 'places',
      featuresPath: "/features/%%ID%%"
    },
    Plugin = {};

  Plugin.init = function(options){
    var plugin = this;
    var solrUtil = jQuery.extend(true, {}, plugin);
    solrUtil.settings = $.extend({}, defaults, options);
    return solrUtil;
  };
  Plugin.getDirectDescendantCount = function(){
    var plugin = this;
    var dfd = $.Deferred();
    var relatedCountsUrl =
      plugin.settings.termIndex + '/select?q={!child of=block_type:parent}id:' + plugin.settings.featureId + '&group=true&group.field=block_child_type&group.limit=0&wt=json&json.wrf=?';
    $.ajax({
      type: "GET",
      url: relatedCountsUrl,
      dataType: "jsonp",
      timeout: 90000,
      error: function (e) {
        console.error(e);
      },
      beforeSend: function () {
      },
      success: function (data) {
        var updates = {};
        $.each(data.grouped.block_child_type.groups, function (x, y) {
          var block_child_type = y.groupValue;
          var rel_count = y.doclist.numFound;
          updates[block_child_type] = rel_count;
        });
        dfd.resolve(updates["related_"+plugin.settings.domain]);
      }
    });
    return dfd.promise();
  };
  Plugin.addPlacesSummaryItems = function addPlacesSummaryItems(feature_label,featuresPath,group_key,data){
    var plugin = this;
    var container = $('.'+plugin.settings.domain+'-in-'+plugin.settings.domain);

    var feature_name = feature_label;
    for(var key in data[group_key]){ //parent,child, other
      var feature_block = jQuery('<div></div>').addClass('feature-block');
      var header = jQuery('<h6></h6>').html(feature_name +" "+ key).addClass('dontend');
      feature_block.append(header);
      var relation_subject_list = jQuery('<ul class="collapsibleList"></ul>');
      var relation_subjects_ordered = Object.keys(data[group_key][key]).sort();
      var relation_subjects_count = 0;
      for(var relation_subject in relation_subjects_ordered){
        relation_subjects_count++;
        relation_subject = relation_subjects_ordered[relation_subject];
        var relation = jQuery('<li></li>');
        var feature_list = jQuery('<ul></ul>');
        var feature_count = 0;
        var sortedFeatures = data[group_key][key][relation_subject];
        for(var feature_index in sortedFeatures){
          var feature_item = jQuery('<li class="dontsplit"></li>');
          var currNode = sortedFeatures[feature_index];
          var currNodeID = currNode["related_"+plugin.settings.domain+"_id_s"].replace(plugin.settings.domain+"-","");
          var currItem = jQuery("<a href="+featuresPath.replace("%%ID%%",currNodeID)+">"+currNode["related_"+plugin.settings.domain+"_header_s"]+"</a>");
          var pop_container = jQuery('<span class="popover-kmaps" data-id="'+plugin.settings.domain+'-'+currNodeID+'"><span class="popover-kmaps-tip"></span><span class="icon shanticon-menu3"></span></span>');
          feature_item.append(currItem);
          feature_item.append(jQuery(pop_container));
          feature_list.append(feature_item);
          feature_count++;
        }
        var relation_title = jQuery('<div class="dontsplit"></div>');
        relation_title.append(jQuery('<span class="glyphicon"></span> '));
        relation_title.append(relation_subject+" ("+feature_count+")");
        relation.append(relation_title);
        relation.append(feature_list);
        if(feature_count == 1) {relation.addClass('dontsplit');}
        relation_subject_list.append(relation);
      }
      feature_block.append(relation_subject_list);
      if(relation_subjects_count == 1 && feature_count == 1) {feature_block.addClass('dontsplit');}
      container.append(feature_block);
    }
  };
  Plugin.getPlacesSummaryElements = function getPlacesSummaryElements(){
    var plugin = this;
    var dfd = $.Deferred();
    var SOLR_ROW_LIMIT = 200;
    var fieldList = [
      "header",
      "id",
      "uid",
      "related_"+ plugin.settings.domain +"_feature_type_s",
      "related_"+ plugin.settings.domain +"_relation_label_s",
      "related_kmaps_node_type",
      "related_"+plugin.settings.domain+"_feature_types_t",
      "related_"+plugin.settings.domain+"_id_s",
      "related_"+plugin.settings.domain+"_header_s",
    ].join(",");
    if(plugin.settings.domain == "places"){
      fieldList += ",related_subjects_t";
    }
    var getSummaryElementsUrl = plugin.settings.termIndex + "/select?" +
      "&q=" + "{!child of=block_type:parent}id:" + plugin.settings.featureId +
      "&fl="+ fieldList +
      "&rows=" + SOLR_ROW_LIMIT +
      "&indent=true" +
      "&wt=json" +
      "&json.wrf=?" +
      "&sort=related_"+plugin.settings.domain+"_header_s+asc";
    $.ajax({
      url: getSummaryElementsUrl,
      dataType: 'jsonp',
      jsonp: 'json.wrf',
    }).done(function(data){
      var response = data.response;
      if(response.numFound > 0){
        var result = response.docs.reduce(function(acc,currentNode,index){
          var node_type = currentNode["related_kmaps_node_type"] ;
          if(node_type === undefined) {
            node_type = "other";
          }
          if(acc[node_type] === undefined){
            acc[node_type] =  [];
          }
          var relation_label = currentNode["related_"+ plugin.settings.domain +"_relation_label_s"];
          if(relation_label === undefined){
            return acc;
          }
          if(acc[node_type][relation_label] === undefined){
            acc[node_type][relation_label] = [];
          }
          for(var related_feature_type_key in currentNode["related_"+plugin.settings.domain+"_feature_types_t"]){
            var related_feature_type = currentNode["related_"+plugin.settings.domain+"_feature_types_t"][related_feature_type_key];
            if(acc[node_type][relation_label][related_feature_type] === undefined) {
              acc[node_type][relation_label][related_feature_type] = {};
            }
            var node_id = currentNode['related_'+plugin.settings.domain+'_id_s'];
            acc[node_type][relation_label][related_feature_type][node_id] = currentNode;
          }
          return acc;
        }, []);
        dfd.resolve(result);
      } else {
        dfd.resolve([]);
      }
    });
    return dfd.promise();
  }
  Plugin.addSubjectsSummaryItems = function addSubjectsSummaryItems(feature_label,featuresPath,group_key,data){
    var plugin = this;
    var container = $('.'+plugin.settings.domain+'-in-'+plugin.settings.domain);

    var feature_name = feature_label;
    for(var key in data[group_key]){ //parent,child, other
            var feature_block = jQuery('<div></div>').addClass('feature-block');
            var header = jQuery('<h6></h6>').addClass('dontend').append(jQuery('<span class="glyphicon"></span> '));
            header.append(feature_name +" "+ key);
            var relation_subject_list = jQuery('<ul style="list-stype:none;" class="collapsibleList"></ul>');
            var relation_subject_item = jQuery('<li class="collapsible_list_header"></li>');
            relation_subject_item.append(header);
            var related_subject_list = jQuery('<ul></ul>');
            var feature_count = 0;
            var sortedFeatures = data[group_key][key];
            for(var related_subject_index in sortedFeatures){
              var relation = jQuery('<li class="dontsplit"></li>');
                var currNode = sortedFeatures[related_subject_index];
                var currNodeID = currNode["related_"+plugin.settings.domain+"_id_s"].replace(plugin.settings.domain+"-","");
                relation.append("<a href="+featuresPath.replace("%%ID%%",currNodeID)+">"+currNode["related_"+plugin.settings.domain+"_header_s"]+"</a>");
                var pop_container = jQuery('<span class="popover-kmaps" data-id="'+plugin.settings.domain+'-'+currNodeID+'"><span class="popover-kmaps-tip"></span><span class="icon shanticon-menu3"></span></span>');
                relation.append(jQuery(pop_container));
                related_subject_list.append(relation);
                feature_count++;
            }
            relation_subject_item.append(related_subject_list);
            relation_subject_list.append(relation_subject_item);
            if(feature_count == 1) {relation_subject_list.addClass('dontsplit');}
            feature_block.append(relation_subject_list);
            container.append(feature_block);
    }
  };
  Plugin.getSubjectsSummaryElements = function getSubjectsSummaryElements(){
    var plugin = this;
    var dfd = $.Deferred();
    var SOLR_ROW_LIMIT = 200;
    var fieldList = [
      "header",
      "id",
      "related_"+ plugin.settings.domain +"_feature_type_s",
      "related_"+ plugin.settings.domain +"_relation_label_s"
    ].join(",");
    if(plugin.settings.domain == "places"){
      fieldList += ",related_subjects_t";
    }
    var getSummaryElementsUrl = plugin.settings.termIndex + "/select?" +
      "&q=" + "{!child of=block_type:parent}id:" + plugin.settings.featureId +
      "&fl=related_"+plugin.settings.domain+"_feature_types_t,uid,related_"+plugin.settings.domain+"_id_s,related_"+plugin.settings.domain+"_header_s" +","+ fieldList +
      "&rows=" + SOLR_ROW_LIMIT +
      "&indent=true" +
      "&wt=json" +
      "&json.wrf=?" +
      "&sort=related_"+plugin.settings.domain+"_header_s+asc";
    $.ajax({
      url: getSummaryElementsUrl,
      dataType: 'jsonp',
      jsonp: 'json.wrf',
    }).done(function(data){
      var response = data.response;
      if(response.numFound > 0){
        var result = response.docs.reduce(function(acc,currentNode,index){
          var node_type = currentNode["related_kmaps_node_type"] ;
          if(node_type === undefined) {
            node_type = "other";
          }
          if(acc[node_type] === undefined){
            acc[node_type] =  [];
          }
          var relation_label = currentNode["related_"+ plugin.settings.domain +"_relation_label_s"];
          if(relation_label === undefined){
            return acc;
          }
          if(acc[node_type][relation_label] === undefined){
            acc[node_type][relation_label] = [];
          }
          var node_id = currentNode['related_'+plugin.settings.domain+'_id_s'];
          acc[node_type][relation_label][node_id] = currentNode;
          return acc;
        }, []);
        dfd.resolve(result);
      } else {
        dfd.resolve([]);
      }
    });
    return dfd.promise();
  }
  //Popup functions
  Plugin.getNodeInfo =    function getNodeInfo(currentFeatureId,featuresPath) {
    var plugin = this;
    const dfd = $.Deferred();
    var nodeinfo = [];
    nodeinfo['always']='present';
    const fieldList = [
      "ancestors_" + plugin.settings.perspective,
      "ancestor_ids_" + plugin.settings.perspective,
      "ancestor_ids_closest_" + plugin.settings.perspective,
      "ancestors_closest_" + plugin.settings.perspective,
    ].join(',');
    var url = plugin.settings.termIndex + '/select?q=id:' + currentFeatureId + '&fl=header,'+ fieldList +'*&wt=json&json.wrf=?';
    $.ajax({
      url: url,
      dataType: 'jsonp',
      jsonp: 'json.wrf',
      error: function (e) {
        console.error(e);
        dfd.resolve([]);
      },
      beforesend: function () {
      },
      success: function (data) {
        if (data.response.docs.length > 0) {
          var doc = data.response.docs[0];
          var ancestorskey  = "ancestor_ids_" + plugin.settings.perspective;
          var ancestorsnamekey  = "ancestors_" + plugin.settings.perspective;
          if( doc[ancestorskey] === undefined ) {
            ancestorskey  = "ancestor_ids_closest_" + plugin.settings.perspective;
            ancestorsnamekey  = "ancestors_closest_" + plugin.settings.perspective;
          }
          nodeinfo['ancestors'] = doc[ancestorskey] === undefined ? "" : doc[ancestorskey].reduce(function(acc,val,index){
            var currancestor = "<a href='"+featuresPath.replace("%%ID%%",val)+"'>"+doc[ancestorsnamekey][index]+"</a>"
            acc += "/"+currancestor;
            return acc;
          }, "");
          nodeinfo['title'] = "<strong>" + doc["header"] + "</strong>";
          dfd.resolve(nodeinfo);
        }
      }
    });
    return dfd.promise();
  }
  Plugin.getNodeCaptions =    function getNodeCaptions(key) {
    var plugin = this;
    const dfd = $.Deferred();
    // Update counts from asset index
    var nodeCaptionsUrl =
      plugin.settings.termIndex + '/select?q=id:' + key + '&fl=caption_*&wt=json&json.wrf=?';
    $.ajax({
      type: "GET",
      url: nodeCaptionsUrl,
      dataType: "jsonp",
      jsonp: 'json.wrf',
      timeout: 90000,
      error: function (e) {
        console.error(e);
        dfd.resolve([]);
      },
      success: function (data) {
        var updates = {};
        if(data.response.docs.length > 0){
          $.each(data.response.docs[0], function (x, y) {
            var caption_key = x
            if (caption_key != null) {
              updates[caption_key] = y[0];
            }
          });
        }
        dfd.resolve(updates);
      }
    });
    return dfd.promise();
  }
  Plugin.getNodeAssetCount =    function getNodeAssetCount(key,project_filter,title) {
    var plugin = this;
    const dfd = $.Deferred();
    // Update counts from asset index
    var assetCountsUrl =
      plugin.settings.assetIndex + '/select?q=kmapid:' + key + project_filter + '&start=0&facets=on&group=true&group.field=asset_type&group.facet=true&group.ngroups=true&group.limit=0&wt=json&json.wrf=?';
    $.ajax({
      type: "GET",
      url: assetCountsUrl,
      dataType: "jsonp",
      jsonp: 'json.wrf',
      timeout: 90000,
      error: function (e) {
        console.error(e);
        dfd.resolve([]);
      },
      success: function (data) {
        var updates = {};
        // extract the group counts -- index by groupValue
        $.each(data.grouped.asset_type.groups, function (x, y) {
          var asset_type = y.groupValue;
          var asset_count = y.doclist.numFound;
          updates[asset_type] = asset_count;
        });
        dfd.resolve(updates);
      }
    });
    return dfd.promise();
  }
  Plugin.getNodeRelatedCount =    function getNodeRelatedCount(key,project_filter,title) {
    var plugin = this;
    const dfd = $.Deferred();
    var relatedCountsUrl =
      plugin.settings.termIndex + '/select?q={!child of=block_type:parent}id:' + key + project_filter + '&wt=json&indent=true&group=true&group.field=block_child_type&group.limit=0&wt=json&json.wrf=?';
    $.ajax({
      type: "GET",
      url: relatedCountsUrl,
      dataType: "jsonp",
      jsonp: 'json.wrf',
      timeout: 90000,
      error: function (e) {
        console.error(e);
        dfd.resolve([]);
      },
      success: function (data) {
        var updates = {};

        // extract the group counts -- index by groupValue
        $.each(data.grouped.block_child_type.groups, function (x, y) {
          var block_child_type = y.groupValue;
          var rel_count = y.doclist.numFound;
          updates[block_child_type] = rel_count;
        });

        dfd.resolve(updates);
      }
    });
    return dfd.promise();
  }
  Plugin.getNodeSubjectsRelatedPlacesCount =    function getNodeSubjectsRelatedPlacesCount(key,title) {
    var plugin = this;
    const dfd = $.Deferred();
    var subjectsRelatedPlacesCountQuery = plugin.settings.termIndex + "/select?indent=on&q={!parent%20which=block_type:parent}related_subject_uid_s:" + key + "&wt=json&json.wrf=?&group=true&group.field=tree&group.limit=0";

    $.ajax({
      type: "GET",
      url: subjectsRelatedPlacesCountQuery,
      dataType: "jsonp",
      jsonp: 'json.wrf',
      timeout: 90000,
      error: function (e) {
        console.error(e);
        dfd.resolve([]);
      },
      success: function (data) {
        var updates = {};
        // extract the group counts -- index by groupValue
        $.each(data.grouped.tree.groups, function (x, y) {
          var tree = y.groupValue;
          var rel_count = y.doclist.numFound;
          updates["related_" + tree] = rel_count;
        });
        dfd.resolve(updates);
      }
    });
    return dfd.promise();
  }
  // END - Popup functions
  // Relations tree functions
  Plugin.getAncestorPath = function getAncestorPath(){
    var plugin = this;
    const dfd = $.Deferred();
    var url = plugin.settings.termIndex + "/select?" +
      "&q=" + "id:" + plugin.settings.domain + "-" + plugin.settings.featureId +
      "&fl=level_"+plugin.settings.perspective+"_i,ancestor_id_" + plugin.settings.perspective + "_path" +
      "&fq=tree:" + plugin.settings.tree +
      "&indent=true" +
      "&wt=json" +
      "&json.wrf=?" +
      "&rows=" + SOLR_ROW_LIMIT +
      "&limit=" + SOLR_ROW_LIMIT;
    $.ajax({
      url: url,
      dataType: 'jsonp',
      jsonp: 'json.wrf'
    }).done(function(data){
      const response = data.response;
      if(response.numFound < 1) {
        dfd.resolve([]);
      } else {
        const path = response.docs[0]["ancestor_id_"+plugin.settings.perspective+"_path"];
        const level = response.docs[0]["level_"+plugin.settings.perspective+"_i"];
        dfd.resolve([data]);
      }
    }).fail(function(data){
      dfd.resolve([]);
    });
    return dfd.promise();
  }
  Plugin.getFullAncestorTree = function getFullAncestorTree(options){
    const plugin = this;
    var loadDescendants = options["descendants"] ? !! options["descendants"] : false;
    var loadOnlyDirectAncestors = options["directAncestors"] ? options["directAncestors"] : false;
    var sortBy = options["sortBy"] ? options["sortBy"] : "header_ssort+ASC"
    var extraFields = options["extraFields"] ? options["extraFields"] : []
    var nodeMarkerPredicates = options["nodeMarkerPredicates"] ? options["nodeMarkerPredicates"] : []
    const dfd = $.Deferred();
    const head = plugin.settings.view.blank? "header" : "header:name_"+plugin.settings.view
    const fieldList = head + [
      "id",
      "ancestor_id_"+plugin.settings.perspective+"_path",
      "level_"+plugin.settings.perspective+"_i"
    ].concat(extraFields).join(",");
    var url = plugin.settings.termIndex + "/select?";
    if(!loadOnlyDirectAncestors) {
      if(plugin.settings.featureId){
        url += "&q=" + "id:" + plugin.settings.featureId;
      } else {
        url += "&q=*";
        url += "&df=header";
        url += "&fq=level_"+plugin.settings.perspective+"_i:[1 TO 1]";
      }
    } else { //TODO: if we want direct ancestors use the method getAncestorTree
    }
    url += "&fl=" + fieldList +
      "&fq=tree:" + plugin.settings.tree +
      "&indent=true" +
      "&wt=json" +
      "&json.wrf=?" +
      "&rows=" + SOLR_ROW_LIMIT +
      "&limit=" + SOLR_ROW_LIMIT;
    $.ajax({
      url: url,
      dataType: 'jsonp',
      jsonp: 'json.wrf'
    }).done(function(data){
      const response = data.response;
      const buildAncestorTree = async function buildAncestorTree(doc,children) {
        var ancestorsKey  = "ancestor_id_" + plugin.settings.perspective+"_path";
        var ancestorNodes = doc[ancestorsKey].split("/");
        if( doc["level_"+plugin.settings.perspective+"_i"] === undefined ) {
          var lastElementIndex = ancestorNodes.length - 1 ;
          plugin.settings.featureId = plugin.settings.domain+"-"+ancestorNodes[lastElementIndex];
        }

        if (ancestorNodes === undefined ) {
          return [];
        }

        const recursiveAncestors = async function(acc,val,index){
          var ancestorsSiblings = [];
          var currentIndexInAncestorList = -1;
          var siblings = [];
          if(index != 0) {
            const ancestorVal = ancestorNodes[index - 1];
            const descendantsLevel = index + 1;
            siblings = await plugin.getDescendantsInPath(ancestorNodes.slice(0,index).join("/"),descendantsLevel,sortBy, extraFields, nodeMarkerPredicates);
          } else if( index == 0 ) { //Get all root nodes, nodes in level 1
            siblings = await plugin.getDescendantsInPath("*",1,sortBy, extraFields, nodeMarkerPredicates);
          }
          for (var i in siblings) {
            var sib = siblings[i];
            if(sib.key == (plugin.settings.domain +"-"+val)) {
              if(acc){
                sib.children = [].concat(acc);
              }
              sib.expanded = loadDescendants;
              if(sib.key == plugin.settings.featureId) {
                sib.active = true;
                sib.lazy = true;
                sib.backColor = '#eaeaea';
              }
              break;
            }
          }
          return siblings;
        };
        var resultTree = children;
        for (var i = ancestorNodes.length - 1; i >= 0; i--) {
          resultTree = await recursiveAncestors(resultTree,ancestorNodes[i],i);
        }
        return resultTree;
      };
      if(response.numFound > 0){
        var doc = response.docs[0];
        if (loadDescendants && plugin.settings.featureId) {
          var ancestorsKey  = "ancestor_id_" + plugin.settings.perspective+"_path";
          var currentLevelTag  = "level_" + plugin.settings.perspective+"_i";
          var ancestorNodes = doc[ancestorsKey].split("/");
          var currentLevel = doc[currentLevelTag];
          if( doc[currentLevelTag] === undefined ) {
            currentLevel  = ancestorNodes.length;
          }
          const featureChildren = plugin.getDescendantsInPath(doc[ancestorsKey],currentLevel + 1,sortBy, extraFields, nodeMarkerPredicates);
          featureChildren.then(function(children){
            var ancestorTree = buildAncestorTree(doc, children);
            ancestorTree.then(function(ancestorTree){ dfd.resolve(ancestorTree) });
          });
        } else {
          if(response.numFound >= 1){
            var ancestorTree = buildAncestorTree(doc);
            ancestorTree.then(function(ancestorTree){
              dfd.resolve(ancestorTree);
            });
          } else {
            const roots = plugin.getDescendantsInPath("*",1,sortBy,extraFields, nodeMarkerPredicates);
            roots.then(function(roots){
              dfd.resolve(roots);
            });
          }
        }
      } else {
        dfd.resolve([]);
      }
    });
    return dfd.promise();
  }
  Plugin.getDescendantsInPath = function getDescendantsInPath(path,level,sortBy,extraFields = [], nodeMarkerPredicates = []){
    const plugin = this;
    const dfd = $.Deferred();
    var fieldList = [
      "header:name_"+plugin.settings.view,
      "id",
      "ancestor_id_"+plugin.settings.perspective+"_path",
      "ancestor_ids_"+plugin.settings.perspective,
      "ancestors_"+plugin.settings.perspective,
      "ancestor_id_closest_"+plugin.settings.perspective+"_path",
      "ancestors_closest_"+plugin.settings.perspective,
      "level_"+plugin.settings.perspective+"_i",
      "related_"+plugin.settings.domain+"_feature_type_s",
      "related_"+plugin.settings.domain+"_relation_label_s",
    ].concat(extraFields).join(",");
    if(plugin.settings.domain == "places"){
      fieldList += ",related_subjects_t";
    }
    var url = plugin.settings.termIndex + "/select?" +
      //child count
      "&q=" +path+
      "&sort=" +sortBy+
      "&df=ancestor_id_"+plugin.settings.perspective+"_path" +
      "&fq=level_" + plugin.settings.perspective + "_i:[" + level + "+TO+" + (level + 1) + "]" +
      "&fq={!tag=children}level_" + plugin.settings.perspective + "_i:[" + level + "+TO+" + (level + 0) + "]" +
      "&facet.mincount=2" +
      "&facet.limit=-1" +
      "&facet.field={!ex=children}ancestor_id_"+plugin.settings.perspective+"_path" +
      //end child count
      "&fl=" + fieldList +
      "&facet=true" +
      "&wt=json" +
      "&limit=" + SOLR_ROW_LIMIT +
      "&indent=true" +
      "&wt=json" +
      "&json.wrf=?" +
      "&rows=" + SOLR_ROW_LIMIT;
    $.ajax({
      url: url,
      dataType: 'jsonp',
      jsonp: 'json.wrf'
    }).done(function(data){
      const response = data.response;
      const facetCount = data.facet_counts.facet_fields["ancestor_id_"+plugin.settings.perspective+"_path"]
      var facetHash = {};
      for (var i = 0; i < facetCount.length; i = i + 2) {
        facetHash[facetCount[i]] = facetCount[i+1];
      }
      if(response.numFound > 0){
        const result = response.docs.reduce(function(acc,currentNode,index){
          const regex = new RegExp(plugin.settings.domain+"-(.*)");
          const match = currentNode["id"].match(regex);
          var key = !match ? "" : match[1] === undefined? "" : match[1];
          var feature_type = "";
          var ancestorsKey  = "ancestor_ids_" + plugin.settings.perspective;
          var ancestorsNameKey  = "ancestors_" + plugin.settings.perspective;
          if( currentNode[ancestorsKey] === undefined ) {
            ancestorsKey  = "ancestor_ids_closest_" + plugin.settings.perspective;
            ancestorsNameKey  = "ancestors_closest_" + plugin.settings.perspective;
          }
          var marks = []
          if (nodeMarkerPredicates.length > 0){
            nodeMarkerPredicates.forEach(function(marker, index){
              //marker['field'] marker['value'] marker['operation'] marker['mark']
              if(marker['operation'] == '==') {
                if (JSON.stringify(currentNode[marker['field']]) == JSON.stringify(marker.value)) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == 'includes') {
                if (currentNode[marker['field']].includes(marker['value'])) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == '!includes') {
                if (currentNode[marker['field']] && !currentNode[marker['field']].includes(marker['value'])) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == 'markAll') {
                  marks.push(marker['mark']);
              }
            });
          }
          const child = {
            title: currentNode["header"],
            displayPath: "",//currentNode[ancestorsNameKey].join("/"),
            key: plugin.settings.domain +"-"+key,
            expanded: false,
            lazy: true,
            href: plugin.settings.featuresPath.replace("%%ID%%",key),
            marks: marks,
          };
          if(facetHash[currentNode["ancestor_id_"+plugin.settings.perspective+"_path"]] === undefined) {
              child.lazy = false;
          }
          return acc !== undefined ? acc.concat([child]): [child];
        }, []);
        dfd.resolve(result);
      } else {
        dfd.resolve([]);
      }
    });
    return dfd.promise();
  }
  Plugin.getAncestorTree = function getAncestorTree(options){
    const plugin = this;
    var loadDescendants = options["descendants"] ? !! options["descendants"] : false;
    var loadOnlyDirectAncestors = options["directAncestors"] ? !!options["directAncestors"] : false;
    var fullDetail = options["descendantsFullDetail"] ? !!options["descendantsFullDetail"] : false;
    var sortBy = options["sortBy"] ? options["sortBy"] : "header_ssort+ASC"
    var extraFields = options["extraFields"] ? options["extraFields"] : []
    var nodeMarkerPredicates = options["nodeMarkerPredicates"] ? options["nodeMarkerPredicates"] : []
    const dfd = $.Deferred();
    const fieldList = [
      "header:name_"+plugin.settings.view,
      "id",
      "ancestor_id_"+plugin.settings.perspective+"_path",
      "ancestor_ids_"+plugin.settings.perspective,
      "ancestors_"+plugin.settings.perspective,
      "ancestors_closest_"+plugin.settings.perspective,
      "ancestor_id_closest_"+plugin.settings.perspective+"_path",
      "ancestor_ids_closest_"+plugin.settings.perspective,
      "level_"+plugin.settings.perspective+"_i",
    ].concat(extraFields).join(",");
    var url = plugin.settings.termIndex + "/select?";
    if(loadOnlyDirectAncestors) {
      if(plugin.settings.featureId){
        url += "&q=" + "id:" + plugin.settings.featureId;
      } else {
        url += "&q=*";
        url += "&df=header";
        url += "&fq=level_"+plugin.settings.perspective+"_i:[1 TO 1]";
      }
    } else { //TODO: if we want all ancestors use the method getFullAncestorTree
    }
    url += "&fl=" + fieldList +
      "&fq=tree:" + plugin.settings.tree +
      "&indent=true" +
      "&wt=json" +
      "&json.wrf=?" +
      "&rows=" + SOLR_ROW_LIMIT +
      "&limit=" + SOLR_ROW_LIMIT+
      "&sort=" +sortBy;
    $.ajax({
      url: url,
      dataType: 'jsonp',
      jsonp: 'json.wrf'
    }).done(function(data){
      const response = data.response;
      const buildTree = function buildTree(doc,children) {
        var ancestorsKey  = "ancestor_ids_" + plugin.settings.perspective;
        var ancestorsNameKey  = "ancestors_" + plugin.settings.perspective;
        if( doc[ancestorsKey] === undefined ) {
          ancestorsKey  = "ancestor_ids_closest_" + plugin.settings.perspective;
          ancestorsNameKey  = "ancestors_closest_" + plugin.settings.perspective;
        }
          var marks = []
          if (nodeMarkerPredicates.length > 0){
            nodeMarkerPredicates.forEach(function(marker, index){
              //marker['field'] marker['value'] marker['operation'] marker['mark']
              if(marker['operation'] == '==') {
                if (JSON.stringify(currentNode[marker['field']]) == JSON.stringify(marker.value)) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == 'includes') {
                if (currentNode[marker['field']].includes(marker['value'])) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == '!includes') {
                if (!currentNode[marker['field']].includes(marker['value'])) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == 'markAll') {
                  marks.push(marker['mark']);
              }
            });
          }
        const result = doc[ancestorsKey] === undefined ? [] : doc[ancestorsKey].reduceRight(function(acc,val,index){
          const node = {
            title: "<strong>" + doc[ancestorsNameKey][index] + "</strong>",
            key: plugin.settings.domain + "-" + val,
            expanded: true,
            href: plugin.settings.featuresPath.replace("%%ID%%",val),
            lazy: true,
            displayPath: doc[ancestorsNameKey].join("/"),
            //[].concat to handle the instance when the children are sent as an argument
            children: acc === undefined ? null : [].concat(acc),
            marks: marks,
          };
          if( node.key === plugin.settings.featureId) {
            node.active = true;
            node.backColor= '#eaeaea';
          }
          return node;
        }, children);
        return [result];
      }
      if(response.numFound > 0){
        var doc = response.docs[0];
        if (loadDescendants && plugin.settings.featureId) {
          const featureChildren = plugin.getDescendantTree(plugin.settings.featureId,fullDetail,sortBy, extraFields, nodeMarkerPredicates);
          featureChildren.then(function(value){ dfd.resolve(buildTree(doc, value)) });
        } else {
          if(response.numFound > 1){
            var ancestorTree = [];
            for(var i = 0; i < response.numFound; i++){
              doc = response.docs[i];
              var builtTree = buildTree(doc);
              ancestorTree = ancestorTree.concat(buildTree(doc));
            }
            dfd.resolve(ancestorTree);
          } else {
            dfd.resolve(buildTree(doc));
          }
        }
      } else {
        dfd.resolve([]);
      }
    });
    return dfd.promise();
  }
  Plugin.getDescendantTree = function getDescendantTree(featureId,fullDetail,sortBy, extraFields = [], nodeMarkerPredicates =  []){
    const plugin = this;
    fullDetail = fullDetail || false;
    const dfd = $.Deferred();
    var fieldList = [
      "header:name_"+plugin.settings.view,
      "id",
      "ancestor_id_"+plugin.settings.perspective+"_path",
      "ancestors_"+plugin.settings.perspective,
      "ancestor_id_closest_"+plugin.settings.perspective+"_path",
      "ancestor_ids_closest_"+plugin.settings.perspective,
      "caption_eng",
      "related_"+plugin.settings.domain+"_feature_type_s",
      "related_"+plugin.settings.domain+"_relation_label_s"
    ].concat(extraFields).join(",");
    if(plugin.settings.domain == "places"){
      fieldList += ",related_subjects_t";
    }
    var sortByQuery = sortBy ? sortBy : "related_"+plugin.settings.domain+"_header_s+ASC";
    var url = plugin.settings.termIndex + "/select?" +
      //V3 child count
      "&q=" + "{!child of=block_type:parent}id:" + featureId +
      "&fl=child_count:[subquery],uid,related_"+plugin.settings.domain+"_id_s,related_"+plugin.settings.domain+"_header_s" +","+ fieldList +
      "&expand=true" +
      "&child_count.fq=related_kmaps_node_type:child" +
      "&child_count.fl=uid" +
      "&child_count.rows=" + "0" +
      "&child_count.q={!child of='block_type:parent'}{!term f=uid v=$row.related_"+plugin.settings.domain+"_id_s}" +
      "&fq=related_kmaps_node_type:" + "child" +
      "&fq="+"{!collapse field=related_"+plugin.settings.domain+"_id_s}" +
      //end of V3
      "&wt=json" +
      "&limit=" + SOLR_ROW_LIMIT +
      "&indent=true" +
      "&wt=json" +
      "&json.wrf=?" +
      "&sort="+ sortByQuery +
      "&rows=" + SOLR_ROW_LIMIT;
    $.ajax({
      url: url,
      dataType: 'jsonp',
      jsonp: 'json.wrf'
    }).done(function(data){
      const response = data.response;
      if(response.numFound > 0){
        const result = response.docs.reduce(function(acc,currentNode,index){
          const regex = new RegExp(plugin.settings.domain+"-(.*)");
          const match = currentNode["related_"+plugin.settings.domain+"_id_s"].match(regex);
          var key = !match ? "" : match[1] === undefined? "" : match[1];
          var feature_type = "";
          if(plugin.settings.domain == "places"){
            const expanded_docs = data.expanded[currentNode["related_"+plugin.settings.domain+"_id_s"]];
            const expanded = expanded_docs ? expanded_docs.docs[0] || [] : [];
            var related_subjects_s = expanded["related_subjects_t"] ? expanded["related_subjects_t"].join(",") + ": " : "";
            feature_type = related_subjects_s;
            if (related_subjects_s == "") {
              feature_type = currentNode["related_"+plugin.settings.domain+"_feature_type_s"];
              feature_type = feature_type ? feature_type + ": " : " ";
            }
          }
          var ancestorsKey  = "ancestor_ids_" + plugin.settings.perspective;
          var ancestorsNameKey  = "ancestors_" + plugin.settings.perspective;
          if( currentNode[ancestorsKey] === undefined ) {
            ancestorsKey  = "ancestor_ids_closest_" + plugin.settings.perspective;
            ancestorsNameKey  = "ancestors_closest_" + plugin.settings.perspective;
          }
          var title = "<strong>" + currentNode["related_"+plugin.settings.domain+"_header_s"] + "</strong>";
          if(fullDetail) {
            title += " (" +feature_type + currentNode["related_"+plugin.settings.domain+"_relation_label_s"]+")";
          }
          var marks = []
          if (nodeMarkerPredicates.length > 0){
            nodeMarkerPredicates.forEach(function(marker, index){
              //marker['field'] marker['value'] marker['operation'] marker['mark']
              if(marker['operation'] == '==') {
                if (JSON.stringify(currentNode[marker['field']]) == JSON.stringify(marker.value)) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == 'includes') {
                if (currentNode[marker['field']].includes(marker['value'])) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == '!includes') {
                if (!currentNode[marker['field']].includes(marker['value'])) {
                  marks.push(marker['mark']);
                }
              } else if(marker['operation'] == 'markAll') {
                  marks.push(marker['mark']);
              }
            });
          }
          const child = {
            title: title,
            displayPath: "",//currentNode[ancestorsNameKey].join("/"),
            key: plugin.settings.domain +"-"+key,
            expanded: false,
            lazy: true,
            href: plugin.settings.featuresPath.replace("%%ID%%",key),
            marks: marks,
          };
          if(currentNode["child_count"] !== undefined) {
            if(currentNode["child_count"]["numFound"] === 0) {
              child.lazy = false;
            }
          }
          return acc !== undefined ? acc.concat([child]): [child];
        }, []);
        dfd.resolve(result);
      } else {
        dfd.resolve([]);
      }
    });
    return dfd.promise();
  }

  Plugin.getRelatedMandalaTexts = function(){
    var plugin = this;
    var dfd = $.Deferred();
    var relatedUrl =
      plugin.settings.assetIndex + '/select?q=asset_type:texts* AND kmapid_strict:' + plugin.settings.domain+'-'+plugin.settings.featureId + '&wt=json&json.wrf=?';
    $.ajax({
      type: "GET",
      url: relatedUrl,
      dataType: "jsonp",
      timeout: 90000,
      error: function (e) {
        console.error(e);
      },
      beforeSend: function () {
      },
      success: function (data) {
        const response = data.response;
        if(response.numFound > 0){
          const result = response.docs.reduce(function(acc,currentNode,index){
            var currentElement = {
              id: currentNode["id"],
              uid: currentNode["uid"],
              title: currentNode["title"][0],
              related: currentNode["kmapid_strict"]
            };
            var resultado = acc.concat([currentElement]);
            return acc.concat([currentElement]);
          }, []);
          dfd.resolve(result);
        } else {
          dfd.resolve([]);
        }
      }
    });
    return dfd.promise();
  };


  // END - Relations tree functions
  return Plugin;
} )( jQuery, window, document );
