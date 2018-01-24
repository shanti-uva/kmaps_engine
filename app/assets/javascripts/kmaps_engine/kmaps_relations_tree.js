/*
 *  Project: UVa KMaps
 *  Description: Plugin to handle the fancyTree implementation with Solr
 *  Author: djrc2r
 */

// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
;(function ( $, window, document, undefined ) {
  "use strict";

  var SOLR_ROW_LIMIT = 2000;
  var DEBUG = false;

  // undefined is used here as the undefined global variable in ECMAScript 3 is
  // mutable (ie. it can be changed by someone else). undefined isn't really being
  // passed in so we can ensure the value of it is truly undefined. In ES5, undefined
  // can no longer be modified.

  // window is passed through as local variable rather than global
  // as this (slightly) quickens the resolution process and can be more efficiently
  // minified (especially when both are regularly referenced in your plugin).

  // Create the defaults once
  var pluginName = 'kmapsRelationsTree',
    defaults = {
      termIndex: "http://localhost/solr/kmterms_dev",
      assetIndex: "http://localhost/solr/kmassets_dev",
      tree: "places",
      featuresPath: "/features/%%ID%%",
      domain: "places",
      featureId: 1,
      perspective: "pol.admin.hier",
      seedTree: {
        descendants: false,
        directAncestors: true
      },
      displayPopup: false,
      mandalaURL: "https://mandala.shanti.virginia.edu/%%APP%%/%%ID%%/%%REL%%/nojs"
    };

  // The actual plugin constructor
  function Plugin( element, options ) {
    this.element = element;

    // jQuery has an extend method which merges the contents of two or
    // more objects, storing the result in the first object. The first object
    // is generally empty as we don't want to alter the default options for
    // future instances of the plugin
    this.options = $.extend( {}, defaults, options) ;

    this._defaults = defaults;
    this._name = pluginName;

    this.init();
  }

  Plugin.prototype = {
    init: function () {
      const plugin = this;
      // Place initialization logic here
      // You already have access to the DOM element and the options via the instance,
      // e.g., this.element and this.options
      $(plugin.element).fancytree({
        extensions: ["filter", "glyph"],
        source: plugin.getAncestorTree(plugin.options.seedTree),
        glyph: {
          map: {
            doc: "",
            docOpen: "",
            error: "glyphicon glyphicon-warning-sign",
            expanderClosed: "glyphicon glyphicon-plus-sign",
            expanderLazy: "glyphicon glyphicon-plus-sign",
            // expanderLazy: "glyphicon glyphicon-expand",
            expanderOpen: "glyphicon glyphicon-minus-sign",
            // expanderOpen: "glyphicon glyphicon-collapse-down",
            folder: "",
            folderOpen: "",
            loading: "glyphicon glyphicon-refresh"
              //              loading: "icon-spinner icon-spin"
          }
        },
        activate: function(event, data){
          var node = data.node,
            orgEvent = data.originalEvent;
          if(node.data.href){
            window.location.href=node.data.href;
          }
        },
        lazyLoad: function(event,data){
          data.result = plugin.getDescendantTree(data.node.key);
        },
        createNode: function (event, data) {
          data.node.span.childNodes[2].innerHTML = '<span id="ajax-id-' + data.node.key + '">' +
            data.node.title + ' ' +
            ( data.node.data.path || "") + '</span>';

          var path = "";//plugin.makeStringPath(data);
          var elem = data.node.span;
          //var key = plugin.options.domain +"-" + data.node.key;
          var key = data.node.key;
          var title = data.node.title;
          var caption = data.node.data.caption;
          var theIdPath = data.node.data.path;
          //var displayPath = data.node.data.displayPath;
          var displayPath = data.node.getParentList(true,true).reduce(function(parentPath,ancestor) {
            var title_match = ancestor.title.match(/<strong>(.*?)<\/strong>/);
            var current_title = "";
            if(title_match != null){
              current_title = title_match[0];
            }
            var current_link = "<a href='"+ancestor.data.href+"'>"+
              current_title+"</a>";
            if(parentPath == ""){
              return current_link;
              return current_title;
            }
            return parentPath + "/" + current_link;
            return parentPath + "/" + current_title;
          }, "");
          if(plugin.options.displayPopup){
            //decorateElementWithPopover(elem, key, title, displayPath, caption);
            var pop_container = $('<span class="popover-kmaps" data-app="places" data-id="'+key+'"><span class="popover-kmaps-tip"></span><span class="icon shanticon-menu3"></span></span>');
            $(elem).append($(pop_container));
            decorateElementWithPopover(pop_container, key, title, displayPath, caption);
          }
          return data;
        },
      });

      function makeStringPath(data) {
        return $.makeArray(data.node.getParentList(false, true).map(function (x) {
          return x.title;
        })).join("/");
      }

      function decorateElementWithPopover(elem, key, title, path, caption) {
        //if (DEBUG) console.log("decorateElementWithPopover: "  + elem);

        if (jQuery(elem).popover) {
          jQuery(elem).attr('rel', 'popover');

          //if (DEBUG) console.log("caption = " + caption);
          jQuery(elem).popover({
            html: true,
            content: function () {
              caption = ((caption) ? caption : "");
              var popover = "<div class='kmap-path'>/" + path + "</div>" + "<div class='kmap-caption'>" + caption + "</div>" +
                "<div class='info-wrap' id='infowrap" + key + "'><div class='counts-display'>...</div></div>";
              popover = "<div id='popover-content-" + key +"'>" + path + "</div>";
              return popover;
            },
            title: function () {
              return title + "<span class='kmapid-display'>" + key + "</span>";
            },
            trigger: 'manual',
            placement: 'bottom',
            delay: {hide: 5},
            container: 'body'
          }
          ).on("mouseenter", function (e) {
            var _this = this;
            $(this).popover("show");
            var offsetW = $(".popover").width()/2;
            $(".popover").css({left: e.pageX-offsetW });
            $(".popover").on("mouseleave", function () {
              $(_this).popover('hide');
            });
          }).on("mouseleave", function () {
            var _this = this;
            setTimeout(function () {
              if (!$(".popover:hover").length) {
                $(_this).popover("hide");
              }
            }, 300);
          }).on('mousemove',function(e){
            var offsetH = $(".popover").height();
            var offsetW = $(".popover").width()/2;
            var _this = this;
            //$(this).popover("show");
            $(".popover").css({left: e.pageX-offsetW });
          });

          jQuery(elem).on('shown.bs.popover', function (x) {
            $("body > .popover").removeClass("related-resources-popover"); // target css styles on search tree popups
            $("body > .popover").addClass("search-popover"); // target css styles on search tree popups

            var popOverContent = $("#popover-content-"+key);
            var popOverFooter = $("<div class='popover-footer'></div>");
            popOverFooter.append("<div class='popover-footer-button'><a href='"+plugin.options.featuresPath.replace("%%ID%%",key.replace(plugin.options.domain+'-',""))+"' class='icon shanticon-link-external' target='_blank'>Full Entry</a></div>");
            popOverFooter.append("<div style='display: none' class='popover-footer-button'><a href='"+plugin.options.mandalaURL.replace("%%ID%%",key.replace(plugin.options.domain+'-',"")).replace("%%APP%%",plugin.options.domain).replace("%%REL%%","sources")+"' class='icon shanticon-sources' target='_blank'>Related sources (<span class='badge-count' >?</span>)</a></div>");
            popOverFooter.append("<div style='display: none' class='popover-footer-button'><a href='"+plugin.options.mandalaURL.replace("%%ID%%",key.replace(plugin.options.domain+'-',"")).replace("%%APP%%",plugin.options.domain).replace("%%REL%%","audio-video")+"' class='icon shanticon-audio-video' target='_blank'>Related audio-video (<span class='badge-count' >?</span>)</a></div>");
            popOverFooter.append("<div style='display: none' class='popover-footer-button'><a href='"+plugin.options.featuresPath.replace("%%ID%%",key.replace(plugin.options.domain+'-',""))+"#show_relationship=pictures' class='icon shanticon-photos' target='_blank'>Related photos (<span class='badge-count' >?</span>)</a></div>");
            popOverFooter.append("<div style='display: none' class='popover-footer-button'><a href='"+plugin.options.featuresPath.replace("%%ID%%",key.replace(plugin.options.domain+'-',""))+"#show_relationship=documents' class='icon shanticon-texts' target='_blank'>Related texts (<span class='badge-count' >?</span>)</a></div>");
            popOverFooter.append("<div style='display: none' class='popover-footer-button'><a href='"+plugin.options.mandalaURL.replace("%%ID%%",key.replace(plugin.options.domain+'-',"")).replace("%%APP%%",plugin.options.domain).replace("%%REL%%","visuals")+"' class='icon shanticon-visuals' target='_blank'>Related visuals (<span class='badge-count' >?</span>)</a></div>");
            popOverFooter.append("<div style='display: none' class='popover-footer-button'><a href='"+plugin.options.featuresPath.replace("%%ID%%",key.replace(plugin.options.domain+'-',""))+"#show_relationship=places' class='icon shanticon-places' target='_blank'>Related places (<span class='badge-count' >?</span>)</a></div>");
            popOverFooter.append("<div style='display: none' class='popover-footer-button'><a href='"+plugin.options.featuresPath.replace("%%ID%%",key.replace(plugin.options.domain+'-',""))+"#show_relationship=subjects' class='icon shanticon-subjects' target='_blank'>Related subjets (<span class='badge-count' >?</span>)</a></div>");
            popOverContent.append(popOverFooter);
            //var countsElem = $("#popover-content-" + key + " .counts-display");
            //countsElem.html("<span class='assoc-resources-loading'>loading...</span>\n");
            var countsElem = popOverFooter;
            countsElem.append("<span class='assoc-resources-loading'>loading...</span>\n");

            // highlight matching text (if/where they occur).
            var txt = $('#searchform').val();
            // $('.popover-caption').highlight(txt, {element: 'mark'});


            var fq = plugin.options.solr_filter_query;

            var project_filter = (fq) ? ("&" + fq) : "";
            var kmidxBase = plugin.options.assetIndex;
            if (!kmidxBase) {
              console.error("plugin.option.assetIndex not set!");
            }

            var termidxBase = plugin.options.termIndex;
            if (!termidxBase) {
              console.error("plugin.options.termIndex not set!");
            }

            // Update counts from asset index
            var assetCountsUrl =
              kmidxBase + '/select?q=kmapid:' + key + project_filter + '&start=0&facets=on&group=true&group.field=asset_type&group.facet=true&group.ngroups=true&group.limit=0&wt=json&json.wrf=?';
            $.ajax({
              type: "GET",
              url: assetCountsUrl,
              dataType: "jsonp",
              timeout: 90000,
              error: function (e) {
                console.error(e);
                // countsElem.html("<i class='glyphicon glyphicon-warning-sign' title='" + e.statusText);
              },
              beforeSend: function () {
              },

              success: function (data) {
                if (DEBUG) console.log("shown.bs.popover handler: data = " + JSON.stringify(data, undefined, 1));
                var updates = {};

                // extract the group counts -- index by groupValue
                $.each(data.grouped.asset_type.groups, function (x, y) {
                  var asset_type = y.groupValue;
                  var asset_count = y.doclist.numFound;
                  if (DEBUG) console.log(asset_type + " = " + asset_count);
                  updates[asset_type] = asset_count;
                });

                if (DEBUG) console.log("shown.bs.popover handler: " + key + "(" + title + ") : " + JSON.stringify(updates));
                update_counts(countsElem, updates)
              }
            });

            // Update related place and subjects counts from term index


            // {!child of=block_type:parent}id:places-22675&wt=json&indent=true&group=true&group.field=block_child_type&group.limit=0
            var relatedCountsUrl =
              termidxBase + '/select?q={!child of=block_type:parent}id:' + key + project_filter + '&wt=json&indent=true&group=true&group.field=block_child_type&group.limit=0&wt=json&json.wrf=?';
            if (DEBUG) console.error("relatedCountsUrl = " + relatedCountsUrl);
            $.ajax({
              type: "GET",
              url: relatedCountsUrl,
              dataType: "jsonp",
              timeout: 90000,
              error: function (e) {
                console.error(e);
                // countsElem.html("<i class='glyphicon glyphicon-warning-sign' title='" + e.statusText);
              },
              beforeSend: function () {
              },

              success: function (data) {
                if (DEBUG) console.log("shown.bs.popover handler: data = " + JSON.stringify(data, undefined, 1));
                var updates = {};

                // extract the group counts -- index by groupValue
                $.each(data.grouped.block_child_type.groups, function (x, y) {
                  var block_child_type = y.groupValue;
                  var rel_count = y.doclist.numFound;
                  if (DEBUG) console.log(block_child_type + " = " + rel_count);
                  updates[block_child_type] = rel_count;
                });

                if (DEBUG) console.log("shown.bs.popover handler: " + key + "(" + title + ") : " + JSON.stringify(updates));
                update_counts(countsElem, updates)
              }
            });

            // Another (parallel) query

            var subjectsRelatedPlacesCountQuery = termidxBase + "/select?indent=on&q={!parent%20which=block_type:parent}related_subject_uid_s:" + key + "&wt=json&json.wrf=?&group=true&group.field=tree&group.limit=0";

            $.ajax({
              type: "GET",
              url: subjectsRelatedPlacesCountQuery,
              dataType: "jsonp",
              timeout: 90000,
              error: function (e) {
                console.error(e);
                // countsElem.html("<i class='glyphicon glyphicon-warning-sign' title='" + e.statusText);
              },
              beforeSend: function () {
              },

              success: function (data) {
                if (DEBUG) console.log("shown.bs.popover handler: data = " + JSON.stringify(data, undefined, 1));
                var updates = {};
                // extract the group counts -- index by groupValue
                $.each(data.grouped.tree.groups, function (x, y) {
                  var tree = y.groupValue;
                  var rel_count = y.doclist.numFound;
                  if (DEBUG) console.error(tree + " = " + rel_count);
                  updates["related_" + tree] = rel_count;
                });

                update_counts(countsElem, updates)
              }
            });


          });
        }


        function update_counts(elem, counts) {

          // console.log("elem = ");
          // console.dir(elem);
          // console.error(JSON.stringify(counts,undefined,2));

          var av = elem.find('.shanticon-audio-video > span.badge-count');
          if (typeof(counts["audio-video"]) != "undefined") {
            (counts["audio-video"]) ? av.html(counts["audio-video"]).parent().show() : av.parent().hide();
          }
          if (Number(av.text()) > 0) {
            av.parent().parent().show();
          } else {
            av.parent().parent().hide();
          }

          var photos = elem.find('.shanticon-photos > span.badge-count');
          if (typeof(counts.picture) != "undefined") {
            photos.html(counts.picture);
          }
          (Number(photos.text()) > 0) ? photos.parent().parent().show() : photos.parent().parent().hide();

          var places = elem.find('.shanticon-places > span.badge-count');
          if (typeof(counts.related_places) != "undefined") {
            places.html(counts.related_places);
          }
          if (Number(places.text()) > 0) {
            places.parent().parent().show();
          } else {
            places.parent().parent().hide();
          }

          var texts = elem.find('.shanticon-texts > span.badge-count');
          if (typeof(counts.texts) != "undefined") {
            texts.html(counts["texts"]);
          }
          if (Number(texts.text()) > 0) {
            texts.parent().parent().show();
          } else {
            texts.parent().parent().hide();
          }

          var subjects = elem.find('.shanticon-subjects > span.badge-count');

          if (!counts.feature_types) {
            counts.feature_types = 0
          }
          ;
          if (!counts.related_subjects) {
            counts.related_subjects = 0
          }
          ;

          var s_counts = Number(counts.related_subjects) + Number(counts.feature_types);
          if (DEBUG) {
            console.error("related_subjects  = " + Number(counts.related_subjects));
            console.error("feature_types  = " + Number(counts.feature_types));
            console.error("Calculated subject count: " + s_counts);
          }
          if (s_counts) {
            subjects.html(s_counts);
          }
          if (Number(subjects.text()) > 0) {
            subjects.parent().parent().show();
          } else {
            subjects.parent().parent().hide();
          }


          var visuals = elem.find('.shanticon-visuals > span.badge-count');
          if (typeof(counts.visuals) != "undefined") {
            visuals.html(counts.visuals);
          }
          if (Number(visuals.text()) > 0) {
            visuals.parent().parent().show();
          } else {
            visuals.parent().parent().hide();
          }

          var sources = elem.find('.shanticon-sources > span.badge-count');
          if (typeof(counts.sources) != "undefined") {
            sources.html(counts.sources);
          }
          if (Number(sources.text()) > 0) {
            sources.parent().parent().show();
          } else {
            sources.parent().parent().hide();
          }

          elem.find('.assoc-resources-loading').hide();

        }

        return elem;
      };
    },
    getAncestorPath: function() {
      const plugin = this;
      const dfd = $.Deferred();
      var url = plugin.options.termIndex + "/select?" +
        "&q=" + "id:" + plugin.options.domain + "-" + plugin.options.featureId +
        "&fl=*level*,ancestor*" + plugin.options.perspective + "*" +
        "&fq=tree:" + plugin.options.tree +
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
         const path = response.docs[0]["ancestor_id_"+plugin.options.perspective+"_path"];
         const level = response.docs[0]["level_"+plugin.options.perspective+"_i"];
          var url = plugin.options.termIndex + "/select?" +
            "&q=" + "ancestor_id_" + plugin.options.perspective + "_path:" + path +
            "&fl=*" +
            "&fq=tree:" + plugin.options.tree +
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
    },
    getAncestorTree: function(options){
      var loadDescendants = options["descendants"] ? !!options["descendants"] : false;
      var loadOnlyDirectAncestors = options["directAncestors"] ? !! options["directAncestors"] : true;
      loadOnlyDirectAncestors = true;
      const dfd = $.Deferred();
      const plugin = this;
      const fieldList = [
        "header",
        "id",
        "ancestor*",
        "caption_eng",
      ].join(",");
      var url = plugin.options.termIndex + "/select?";
      if(loadOnlyDirectAncestors) {
        if(plugin.options.featureId){
          url += "&q=" + "id:" + plugin.options.domain + "-" + plugin.options.featureId;
        } else {
          url += "&q=*";
          url += "&df=header";
          url += "&fq=level_"+plugin.options.perspective+"_i:[1 TO 1]";
        }
      } else { //TODO: In feature implementations we should define what to do to extract all ancestors not just direct, currently it always just gets the direct ancestors.
      }
      url += "&fl=" + fieldList +
        "&fq=tree:" + plugin.options.tree +
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
          var ancestorsKey  = "ancestor_ids_" + plugin.options.perspective;
          var ancestorsNameKey  = "ancestors_" + plugin.options.perspective;
          if( doc[ancestorsKey] === undefined ) {
            ancestorsKey  = "ancestor_ids_closest_" + plugin.options.perspective;
            ancestorsNameKey  = "ancestors_closest_" + plugin.options.perspective;
          }
          const result = doc[ancestorsKey] === undefined ? [] : doc[ancestorsKey].reduceRight(function(acc,val,index){
            const node = {
              title: "<strong>" + doc[ancestorsNameKey][index] + "</strong>",
              key: plugin.options.domain + "-" + val,
              expanded: true,
              href: plugin.options.featuresPath.replace("%%ID%%",val),
              lazy: true,
              displayPath: doc[ancestorsNameKey].join("/"),
              //[].concat to handle the instance when the children are sent as an argument
              children: acc === undefined ? null : [].concat(acc)
            };
            if( Number(val) === Number(plugin.options.featureId)) {
              node.active = true;
              node.backColor= '#eaeaea';
            }
            return node;
          }, children);
          return [result];
        }
        if(response.numFound > 0){
          var doc = response.docs[0];
          if (loadDescendants && plugin.options.featureId) {
            const featureChildren = plugin.getDescendantTree(plugin.options.domain+"-"+plugin.options.featureId);
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
    },
    getDescendantTree: function(featureId){
      const dfd = $.Deferred();
      const plugin = this;
      var fieldList = [
        "header",
        "id",
        "ancestor*",
        "caption_eng",
        "related_"+plugin.options.domain+"_feature_type_s",
        "related_"+plugin.options.domain+"_relation_label_s"
      ].join(",");
      if(plugin.options.domain == "places"){
        fieldList += ",related_subjects_t";
      }
      var url = plugin.options.termIndex + "/select?" +
        //V3 child count
        "&q=" + "{!child of=block_type:parent}id:" + featureId +
        "&fl=child_count:[subquery],uid,related_"+plugin.options.domain+"_id_s,related_"+plugin.options.domain+"_header_s" +","+ fieldList +
        "&expand=true" +
        "&child_count.fq=related_kmaps_node_type:child" +
        "&child_count.fl=uid" +
        "&child_count.rows=" + "0" +
        "&child_count.q={!child of='block_type:parent'}{!term f=uid v=$row.related_"+plugin.options.domain+"_id_s}" +
        "&fq=related_kmaps_node_type:" + "child" +
        "&fq="+"{!collapse field=related_"+plugin.options.domain+"_id_s}" +
        //end of V3
        "&wt=json" +
        "&limit=" + SOLR_ROW_LIMIT +
        "&indent=true" +
        "&wt=json" +
        "&json.wrf=?" +
        "&sort=related_"+plugin.options.domain+"_header_s+asc" +
        "&rows=" + SOLR_ROW_LIMIT;
      $.ajax({
        url: url,
        dataType: 'jsonp',
        jsonp: 'json.wrf'
      }).done(function(data){
        const response = data.response;
        if(response.numFound > 0){
          const result = response.docs.reduce(function(acc,currentNode,index){
            const regex = new RegExp(plugin.options.domain+"-(.*)");
            const match = currentNode["related_"+plugin.options.domain+"_id_s"].match(regex);
            var key = !match ? "" : match[1] === undefined? "" : match[1];
            var feature_type = "";
            if(plugin.options.domain == "places"){
              const expanded_docs = data.expanded[currentNode["related_"+plugin.options.domain+"_id_s"]];
              const expanded = expanded_docs ? expanded_docs.docs[0] || [] : [];
              var related_subjects_s = expanded["related_subjects_t"] ? expanded["related_subjects_t"].join(",") + ": " : "";
              feature_type = related_subjects_s;
              if (related_subjects_s == "") {
                feature_type = currentNode["related_"+plugin.options.domain+"_feature_type_s"];
                feature_type = feature_type ? feature_type + ": " : " ";
              }
            }
            var ancestorsKey  = "ancestor_ids_" + plugin.options.perspective;
            var ancestorsNameKey  = "ancestors_" + plugin.options.perspective;
            if( currentNode[ancestorsKey] === undefined ) {
              ancestorsKey  = "ancestor_ids_closest_" + plugin.options.perspective;
              ancestorsNameKey  = "ancestors_closest_" + plugin.options.perspective;
            }
            const child = {
              title: "<strong>" + currentNode["related_"+plugin.options.domain+"_header_s"] + "</strong> (" +
              feature_type +
              currentNode["related_"+plugin.options.domain+"_relation_label_s"]+")",
              displayPath: "",//currentNode[ancestorsNameKey].join("/"),
              key: plugin.options.domain +"-"+key,
              expanded: false,
              lazy: true,
              href: plugin.options.featuresPath.replace("%%ID%%",key),
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
  };

  // You don't need to change something below:
  // A really lightweight plugin wrapper around the constructor,
  // preventing against multiple instantiations and allowing any
  // public function (ie. a function whose name doesn't start
  // with an underscore) to be called via the jQuery plugin,
  // e.g. $(element).defaultPluginName('functionName', arg1, arg2)
  $.fn[pluginName] = function ( options ) {
    var args = arguments;

    // Is the first parameter an object (options), or was omitted,
    // instantiate a new instance of the plugin.
    if (options === undefined || typeof options === 'object') {
      return this.each(function () {

        // Only allow the plugin to be instantiated once,
        // so we check that the element has no plugin instantiation yet
        if (!$.data(this, 'plugin_' + pluginName)) {

          // if it has no instance, create a new one,
          // pass options to our plugin constructor,
          // and store the plugin instance
          // in the elements jQuery data object.
          $.data(this, 'plugin_' + pluginName, new Plugin( this, options ));
        }
      });

      // If the first parameter is a string and it doesn't start
      // with an underscore or "contains" the `init`-function,
      // treat this as a call to a public method.
    } else if (typeof options === 'string' && options[0] !== '_' && options !== 'init') {

      // Cache the method call
      // to make it possible
      // to return a value
      var returns;

      this.each(function () {
        var instance = $.data(this, 'plugin_' + pluginName);

        // Tests that there's already a plugin-instance
        // and checks that the requested public method exists
        if (instance instanceof Plugin && typeof instance[options] === 'function') {

          // Call the method of our plugin instance,
          // and pass it the supplied arguments.
          returns = instance[options].apply( instance, Array.prototype.slice.call( args, 1 ) );
        }

        // Allow instances to be destroyed via the 'destroy' method
        if (options === 'destroy') {
          $.data(this, 'plugin_' + pluginName, null);
        }
      });

      // If the earlier cached method
      // gives a value back return the value,
      // otherwise return this to preserve chainability.
      return returns !== undefined ? returns : this;
    }
  };
}(jQuery, window, document));

