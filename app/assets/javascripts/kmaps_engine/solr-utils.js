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
      tree: 'places',
      featuresPath: "/features/%%ID%%"
    },
    Plugin = {};

  Plugin.init = function(options){
    var plugin = this;
    this.settings = $.extend({}, defaults, options);
    return plugin;
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
      var header = jQuery('<h6></h6>').html(feature_name +" "+ key);
      feature_block.append(header);
      var relation_subject_list = jQuery('<ul class="collapsibleList"></ul>');
      var relation_subjects_ordered = Object.keys(data[group_key][key]).sort();
      for(var relation_subject in relation_subjects_ordered){
        relation_subject = relation_subjects_ordered[relation_subject];
        var relation = jQuery('<li></li>');
        var feature_list = jQuery('<ul></ul>');
        var feature_count = 0;
        var sortedFeatures = data[group_key][key][relation_subject];
        for(var feature_index in sortedFeatures){
          var feature_item = jQuery('<li></li>');
          var currNode = sortedFeatures[feature_index];
          var currNodeID = currNode["related_"+plugin.settings.domain+"_id_s"].replace(plugin.settings.domain+"-","");
          var currItem = jQuery("<a href="+featuresPath.replace("%%ID%%",currNodeID)+">"+currNode["related_"+plugin.settings.domain+"_header_s"]+"</a>");
          var pop_container = jQuery('<span class="popover-kmaps" data-id="'+plugin.settings.domain+'-'+currNodeID+'"><span class="popover-kmaps-tip"></span><span class="icon shanticon-menu3"></span></span>');
          feature_item.append(currItem);
          feature_item.append(jQuery(pop_container));
          feature_list.append(feature_item);
          feature_count++;
        }
        relation.append(jQuery('<span class="glyphicon"></span> '));
        relation.append(relation_subject+" ("+feature_count+")");
        relation.append(feature_list);
        relation_subject_list.append(relation);
      }
      feature_block.append(relation_subject_list);
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
      "ancestor*",
      "caption_eng",
      "related_"+ plugin.settings.domain +"_feature_type_s",
      "related_"+ plugin.settings.domain +"_relation_label_s"
    ].join(",");
    if(plugin.settings.domain == "places"){
      fieldList += ",related_subjects_t";
    }
    var getSummaryElementsUrl = plugin.settings.termIndex + "/select?" +
      "&q=" + "{!child of=block_type:parent}id:" + plugin.settings.featureId +
      "&fl=related*,related_"+plugin.settings.domain+"_feature_types_t,uid,related_"+plugin.settings.domain+"_id_s,related_"+plugin.settings.domain+"_header_s" +","+ fieldList +
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
  Plugin.addSubjectsSummaryItems = function addPlacesSummaryItems(feature_label,featuresPath,group_key,data){
    var plugin = this;
    var container = $('.'+plugin.settings.domain+'-in-'+plugin.settings.domain);

    var feature_name = feature_label;
    for(var key in data[group_key]){ //parent,child, other
            var feature_block = jQuery('<div></div>').addClass('feature-block');
            var header = jQuery('<h6></h6>').append(jQuery('<span class="glyphicon"></span> '));
            header.append(feature_name +" "+ key);
            var relation_subject_list = jQuery('<ul style="list-stype:none;" class="collapsibleList"></ul>');
            var relation_subject_item = jQuery('<li class="collapsible_list_header"></li>');
            relation_subject_item.append(header);
            var related_subject_list = jQuery('<ul></ul>');
            var feature_count = 0;
            var sortedFeatures = data[group_key][key];
            for(var related_subject_index in sortedFeatures){
              var relation = jQuery('<li></li>');
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
      "ancestor*",
      "caption_eng",
      "related_"+ plugin.settings.domain +"_feature_type_s",
      "related_"+ plugin.settings.domain +"_relation_label_s"
    ].join(",");
    if(plugin.settings.domain == "places"){
      fieldList += ",related_subjects_t";
    }
    var getSummaryElementsUrl = plugin.settings.termIndex + "/select?" +
      "&q=" + "{!child of=block_type:parent}id:" + plugin.settings.featureId +
      "&fl=related*,related_"+plugin.settings.domain+"_feature_types_t,uid,related_"+plugin.settings.domain+"_id_s,related_"+plugin.settings.domain+"_header_s" +","+ fieldList +
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
    var url = plugin.settings.termIndex + '/select?q=id:' + currentFeatureId + '&fl=header,ancestor*&wt=json&json.wrf=?';
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
        var doc = data.response.docs[0];
        var ancestorskey  = "ancestor_ids_" + plugin.settings.perspective;
        var ancestorsnamekey  = "ancestors_" + plugin.settings.perspective;
        if( doc[ancestorskey] === undefined ) {
          ancestorskey  = "ancestor_ids_closest_" + plugin.settings.perspective;
          ancestorsnamekey  = "ancestors_closest_" + plugin.settings.perspective;
        }
        nodeinfo['ancestors'] = doc[ancestorskey] === undefined ? "" : doc[ancestorskey].reduce(function(acc,val,index){
          var currancestor = "<a href='"+featuresPath.replace("%%id%%",val)+"'>"+doc[ancestorsnamekey][index]+"</a>"
          acc += "/"+currancestor;
          return acc;
        }, "");
        nodeinfo['title'] = "<strong>" + doc["header"] + "</strong>";
        dfd.resolve(nodeinfo);
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
      "&fl=*level*,ancestor*" + plugin.settings.perspective + "*" +
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
        var url = plugin.settings.termIndex + "/select?" +
          "&q=" + "ancestor_id_" + plugin.settings.perspective + "_path:" + path +
          "&fl=*" +
          "&fq=tree:" + plugin.settings.tree +
          "&indent=true" +
          "&wt=json" +
          "&json.wrf=?" +
          "&rows=" + SOLR_ROW_LIMIT +
          "&fq=level_i:[" + 1 + "+TO+" + ( level + 1) + "]" +
          "&limit=" + SOLR_ROW_LIMIT;
        dfd.resolve([data]);
      }
    }).fail(function(data){
      dfd.resolve([]);
    });
    return dfd.promise();
  }
  Plugin.getAncestorTree = function getAncestorTree(options){
    const plugin = this;
    var loadDescendants = options["descendants"] ? !! options["descendants"] : false;
    var loadOnlyDirectAncestors = options["directAncestors"] ? !! options["directAncestors"] : true;
    loadOnlyDirectAncestors = true;
    const dfd = $.Deferred();
    const fieldList = [
      "header",
      "id",
      "ancestor*",
      "caption_eng",
    ].join(",");
    var url = plugin.settings.termIndex + "/select?";
    if(loadOnlyDirectAncestors) {
      if(plugin.settings.featureId){
        url += "&q=" + "id:" + plugin.settings.featureId;
      } else {
        url += "&q=*";
        url += "&df=header";
        url += "&fq=level_"+plugin.settings.perspective+"_i:[1 TO 1]";
      }
    } else { //TODO: In feature implementations we should define what to do to extract all ancestors not just direct, currently it always just gets the direct ancestors.
    }
    url += "&fl=" + fieldList +
      "&fq=tree:" + plugin.settings.tree +
      "&indent=true" +
      "&wt=json" +
      "&json.wrf=?" +
      "&rows=" + SOLR_ROW_LIMIT +
      "&limit=" + SOLR_ROW_LIMIT +
      "&sort=header_ssort+asc";
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
        const result = doc[ancestorsKey] === undefined ? [] : doc[ancestorsKey].reduceRight(function(acc,val,index){
          const node = {
            title: "<strong>" + doc[ancestorsNameKey][index] + "</strong>",
            key: plugin.settings.domain + "-" + val,
            expanded: true,
            href: plugin.settings.featuresPath.replace("%%ID%%",val),
            lazy: true,
            displayPath: doc[ancestorsNameKey].join("/"),
            //[].concat to handle the instance when the children are sent as an argument
            children: acc === undefined ? null : [].concat(acc)
          };
          if( Number(val) === Number(plugin.settings.featureId)) {
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
          const featureChildren = plugin.getDescendantTree(plugin.settings.featureId);
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
  Plugin.getDescendantTree = function getDescendantTree(featureId){
    const plugin = this;
    const dfd = $.Deferred();
    var fieldList = [
      "header",
      "id",
      "ancestor*",
      "caption_eng",
      "related_"+plugin.settings.domain+"_feature_type_s",
      "related_"+plugin.settings.domain+"_relation_label_s"
    ].join(",");
    if(plugin.settings.domain == "places"){
      fieldList += ",related_subjects_t";
    }
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
      "&sort=related_"+plugin.settings.domain+"_header_s+asc" +
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
          const child = {
            title: "<strong>" + currentNode["related_"+plugin.settings.domain+"_header_s"] + "</strong> (" +
            feature_type +
            currentNode["related_"+plugin.settings.domain+"_relation_label_s"]+")",
            displayPath: "",//currentNode[ancestorsNameKey].join("/"),
            key: plugin.settings.domain +"-"+key,
            expanded: false,
            lazy: true,
            href: plugin.settings.featuresPath.replace("%%ID%%",key),
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

  // END - Relations tree functions
  return Plugin;
} )( jQuery, window, document );
