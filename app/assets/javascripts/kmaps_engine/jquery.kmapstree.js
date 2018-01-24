// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
;(function ($, window, document, undefined) {

    "use strict";

    // undefined is used here as the undefined global variable in ECMAScript 3 is
    // mutable (ie. it can be changed by someone else). undefined isn't really being
    // passed in so we can ensure the value of it is truly undefined. In ES5, undefined
    // can no longer be modified.

    // window and document are passed through as local variable rather than global
    // as this (slightly) quickens the resolution process and can be more efficiently
    // minified (especially when both are regularly referenced in your plugin).

    var SOLR_ROW_LIMIT = 2000;
    var DEBUG = false;

    // Create the defaults once
    var pluginName = "kmapsTree",
        defaults = {
            termindex_root: "",
            kmindex_root: "",
            type: "subjects",
            root_kmapid: 0,
            root_kmap_path: "/", // "/13735/13740/13734"
            config: function () {
            },
            expand_path: null,
            // baseUrl: "http://subjects.kmaps.virginia.edu/"
        };

    // copied from jquery.fancytree.js to support moved loadKeyPath function
    function _makeResolveFunc(deferred, context) {
        return function () {
            deferred.resolveWith(context);
        };
    }

    // The actual plugin constructor
    function KmapsTreePlugin(element, options) {
        this.element = element;
        // jQuery has an extend method which merges the contents of two or
        // more objects, storing the result in the first object. The first object
        // is generally empty as we don't want to alter the default options for
        // future instances of the plugin
        this.settings = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = pluginName;
        this.init();
    }

    function log(msg) {
        if (DEBUG) {
            console.log(msg);
            $('#debug').append(msg + "<br/>");
        }
    }

    var cleanPath = function (path, parentOnly, rootSlash) {
        log("cleanPath() args: " + JSON.stringify(arguments, undefined, 2));
        log("cleanPath() in: " + path);
        // Eliminate initial/terminal slash
        path = path.replace(/^\/+/, '');
        path = path.replace(/\/$/, '');
        var p = path.split('/');
        if (parentOnly) {
            p.splice(-1, 1)
        }
        path = rootSlash ? "/" : "";
        path += p.join('/');
        var msg = "cleanPath() out: " + path;
        log(msg);
        return path;
    };

    ////  Cleanup and re-root the paths
    var fixPath = function (path, i) {
        path = cleanPath(path);

        var rootpath = cleanPath(plugin.settings.root_kmap_path, true, false);
        log("fixPath(): rootpath = " + rootpath);
        log("fixPath(): path = " + path);

        // truncate the beginning of the path according to kmap_root_path
        path = path.replace(rootpath, "");
        log("fixPath(): fixed path = " + path);

        // truncate the beginning of the path according to kmap_root_path
        var clean = cleanPath(path, false, true);
        log("fixPath(): fixed clean = " + clean);

        return clean;
    };

    $.extend(KmapsTreePlugin.prototype, {
        debug: false,
        init: function () {
            // Place initialization logic here
            // You already have access to the DOM element and
            // the options via the instance, e.g. this.element
            // and this.settings
            // you can add more functions like the one below and
            // call them like so: this.yourOtherFunction(this.element, this.settings).
            var plugin = this;
            this.element = $(plugin.element);

            // create unique ID if it doesn't have one already
            $(this).uniqueId();


            var perspectivePath = plugin.getPerspectivePath();
            perspectivePath.then(function(pathValue){
              plugin.settings.expand_path = plugin.settings.expand_path == "" ? pathValue : plugin.settings.expand_path;

              //
              // Fancytree plugin
              //
              $(plugin.element).fancytree({
                extensions: ["filter", "glyph"],
                generateIds: false,
                quicksearch: false,
                checkbox: false,
                selectMode: 2,
                minExpandLevel: 1, // TODO: reconcile this with lazy loading.  Only "1" is supported currently.
                theme: 'bootstrap',
                debugLevel: 0,
                autoScroll: false,
                filter: {
                  highlight: true,
                  counter: false,
                  mode: "hide",
                  leavesOnly: false
                },
                cookieId: this.id,
                idPrefix: this.id,
                source: {
                  url: plugin.buildQuery(
                    plugin.settings.termindex_root,
                    plugin.settings.type,
                    plugin.settings.root_kmap_path,
                    1,
                    plugin.settings.root_kmap_path.split('/').length
                  ),
                  dataType: 'jsonp',
                  jsonp: 'json.wrf'
                },

                // User Event Handlers
                select: function (event, data) {
                  plugin.sendEvent("SELECT", event, data);
                },
                focus: function (event, data) {
                  data.node.scrollIntoView(true);
                  plugin.sendEvent("FOCUS", event, data);
                },
                keydown: function (event, data) {
                  plugin.sendEvent("KEYDOWN", event, data);
                },
                activate: function (event, data) {
                  plugin.sendEvent("ACTIVATE", event, data);
                },

                // Fancytree Building Event Handlers
                createNode: function (event, data) {
                  data.node.span.childNodes[2].innerHTML = '<span id="ajax-id-' + data.node.key + '">' +
                    data.node.title + ' ' +
                    ( data.node.data.path || "") + '</span>';

                  var path = plugin.makeStringPath(data);
                  var elem = data.node.span;
                  var key = data.node.key;
                  var type = plugin.settings.type;
                  var title = data.node.title;
                  var caption = data.node.data.caption;
                  var theIdPath = data.node.data.path;
                  var displayPath = data.node.data.displayPath;

                  if(plugin.settings.displayPopup){
                    decorateElementWithPopover(elem, key, title, displayPath, caption);
                  }

                  return data;
                },
                renderNode: function (event, data) {
                  if (!data.node.isStatusNode()) {
                    var keystr = (plugin.settings.showIDs) ? ' [' + data.node.key + ']' : '';
                    data.node.span.childNodes[2].innerHTML =
                      '<span id="ajax-id-' + data.node.key + '">'
                      + data.node.title
                      + keystr
                      + ' <span class="count"></span></span>';

                    var path = plugin.makeStringPath(data);

                    // decorateElementWithPopover(data.node.span, data.node.key,data.node.title, data.node.path, data.node.data.caption);
                    //$(data.node.span).find('#ajax-id-' + data.node.key).once('nav', function () {
                    $(data.node.span).find('#ajax-id-' + data.node.key+":not(.nav-processed)").addClass('nav-processed').each(function () {
                      var base = $(this).attr('id');
                      var argument = $(this).attr('argument');
                      /*
                       * TODO:
                       * fix this for agnostic purposes, currently just setting a window location
                      var url = location.origin + location.pathname.substring(0, location.pathname.indexOf(plugin.settings.type)) + plugin.settings.type + '/' + data.node.key + '/overview/nojs';
                            Drupal.ajax[base] = new Drupal.ajax(base, this, {
                                url: url,
                                event: 'navigate',
                                progress: {
                                    type: 'throbber'
                                }
                            });
                      */
                    });
                  }
                  return data;
                },

                postProcess: function (event, data) {
                  log("postProcess!");
                  data.result = [];

                  var docs = data.response.response.docs;
                  var facet_counts = data.response.facet_counts.facet_fields["ancestor_id_"+plugin.settings.perspective+"_path"];
                  var rootbin = {};
                  var countbin = {};

                  docs.sort(function (a, b) {
                    var aName = a["ancestor_id_"+plugin.settings.perspective+"_path"].toLowerCase();
                    var bName = b["ancestor_id_"+plugin.settings.perspective+"_path"].toLowerCase();
                    return ((aName < bName) ? -1 : ((aName > bName) ? 1 : 0));
                  });

                  for (var i = 0; i < facet_counts.length; i += 2) {
                    var path = facet_counts[i];
                    var count = facet_counts[i + 1];
                    countbin[path] = (count - 1);
                  }

                  for (var i = 0; i < docs.length; i++) {
                    var doc = docs[i];
                    var ancestorIdPath = docs[i]["ancestor_id_"+plugin.settings.perspective+"_path"];
                    var ancestors = docs[i]["ancestors_"+plugin.settings.perspective];
                    var parentIdPath = ancestorIdPath.split('/');
                    var localId = ancestorIdPath;

                    if (parentIdPath && parentIdPath.length != 0) {
                      localId = parentIdPath.pop();
                    } else {
                      parentIdPath = [];
                      localId = "";
                    }

                    var caption = (docs[i]['caption_eng'] && $.isArray(docs[i]['caption_eng'])) ? docs[i]['caption_eng'][0] : null;
                    var displayPath = (ancestors) ? ancestors.join("/") : "";
                    var parentPath = (parentIdPath) ? parentIdPath.join("/") : "";
                    var n =
                      {
                        key: localId,
                        title: doc.header,
                        parent: parentPath,
                        path: ancestorIdPath,
                        displayPath: displayPath,
                        caption: caption,
                        level: doc["level_" + plugin.settings.perspective + "_i"],
                        lazy: (countbin[ancestorIdPath]) ? true : false,
                      };

                    rootbin[ancestorIdPath] = n;  // save for later
                  }


                  //if (DEBUG) console.log("ROOT BIN");
                  //if (DEBUG) console.log(JSON.stringify(rootbin));
                  var props = Object.getOwnPropertyNames(rootbin);
                  for (var i = 0; i < props.length; i++) {
                    var node = rootbin[props[i]];
                    if (DEBUG) console.log("node: " + node.path + "  parent:" + node.parent);

                    if (rootbin[node.parent]) {
                      var p = rootbin[node.parent];
                      if (!p.children) {
                        p.children = []
                      }
                      p.children.push(node);
                      p.lazy = false;
                      delete rootbin[props[i]];
                    }
                  }
                  var x = Object.getOwnPropertyNames(rootbin);
                  for (var i = 0; i < x.length; i++) {
                    data.result.push(rootbin[x[i]]);
                  }
                  if (DEBUG) console.dir({log: "result", "data": data.result});
                  //data.result.sortChildren();
                },

                lazyLoad: function (event, data) {
                  var id = data.node.key;
                  var lvla = 1 + data.node.data.level;
                  var lvlb = 1 + data.node.data.level;
                  var path = data.node.data.path;
                  var termIndexRoot = plugin.settings.termindex_root;
                  var type = plugin.settings.type;
                  data.result = {
                    url: plugin.buildQuery(termIndexRoot, type, path, lvla, lvlb),
                    dataType: 'jsonp',
                    jsonp: 'json.wrf'
                  };
                },

                init: function (event, data) {
                  var path = "";
                  var safe_path = "";
                  var focus_id = "";

                  log("initing!");
                  /* TODO: need to clean this up, added the kmaps_path and the focus_id to
                   * the default object so it can be passed as an argument. In Drupal it was
                   * intended to be a setting but for a more agnostic approach it was changed.
                   *
                    if (Drupal
                        && Drupal.settings
                        && Drupal.settings.kmaps_explorer
                        && Drupal.settings.kmaps_explorer.kmaps_path
                    ) {
                        path = Drupal.settings.kmaps_explorer.kmaps_path
                        focus_id = Drupal.settings.kmaps_explorer.kmaps_id
                    }
                    */
                  path = plugin.settings.expand_path ? plugin.settings.expand_path : path;
                  focus_id = plugin.settings.activeNodeId ? plugin.settings.activeNodeId : focus_id;
                  if (DEBUG) console.error("path = " + path + " focus_id = " + focus_id);

                  if (path) {
                    focus_id = focus_id || path.split("/").pop();
                    if (DEBUG) console.log("Auto Loading " + path);
                    var tree = $(event.target).fancytree('getTree');
                    tree.loadKeyPath(path, function (key, status) {
                      if (status === "error") {
                        if (DEBUG) console.log("error with key = " + key)
                        // Cut down the path...
                        safe_path = (path + "/").split('/' + key + '/')[0];  // "left of the match"
                        if (DEBUG) console.log("safe_path = " + safe_path);
                      }
                    }).done(
                      function () {
                        if (safe_path) {
                          focus_id = focus_id || path.split("/").pop();
                          if (DEBUG) console.warn("safe focus_id = " + focus_id);
                        }
                        if (DEBUG) console.log("using focus_id = " + focus_id);
                        if(focus_id) {
                          var active_node = tree.activateKey(String(focus_id));
                          if (active_node){
                            active_node.setExpanded(true);
                            plugin.scrollToActiveNode();
                          }
                        }
                      }
                    )
                  } else {
                    if (plugin.settings.expand_path) {
                      /* if (DEBUG) */ console.log("Auto-expandeing expand_path = " + plugin.settings.expand_path);
                      $(event.target).fancytree('getTree').loadKeyPath(plugin.settings.expand_path, function(x) { if (typeof(x.setExpanded) == "function") { x.setExpanded(true); }});
                    }
                  }

                },
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

                create: function (evt, ctx) {
                },

                loadChildren: function (evt, ctx) {
                  if (DEBUG) {
                    console.log("loadChildren...");
                  }

                  ctx.node.sortChildren(null, true);

                }
              }).on('fancytreeinit', function (x, y) {

              });
            });


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
                                //if (DEBUG) console.log("Captioning: " + caption);
                                return popover;
                            },
                            title: function () {
                                return title + "<span class='kmapid-display'>" + key + "</span>";
                            },
                            trigger: 'hover',
                            placement: 'left',
                            delay: {hide: 5},
                            container: 'body'
                        }
                    );

                    jQuery(elem).on('shown.bs.popover', function (x) {
                        $("body > .popover").removeClass("related-resources-popover"); // target css styles on search tree popups
                        $("body > .popover").addClass("search-popover"); // target css styles on search tree popups

                        var countsElem = $("#infowrap" + key + " .counts-display");
                        countsElem.html("<span class='assoc-resources-loading'>loading...</span>\n");
                        countsElem.append("<span style='display: none' class='associated'><i class='icon shanticon-sources'></i><span class='badge' >?</span></span>");
                        countsElem.append("<span style='display: none' class='associated'><i class='icon shanticon-audio-video'></i><span class='badge' >?</span></span>");
                        countsElem.append("<span style='display: none' class='associated'><i class='icon shanticon-photos'></i><span class='badge' >?</span></span>");
                        countsElem.append("<span style='display: none' class='associated'><i class='icon shanticon-texts'></i><span class='badge' >?</span></span>");
                        countsElem.append("<span style='display: none' class='associated'><i class='icon shanticon-visuals'></i><span class='badge' >?</span></span>");
                        countsElem.append("<span style='display: none' class='associated'><i class='icon shanticon-places'></i><span class='badge' >?</span></span>");
                        countsElem.append("<span style='display: none' class='associated'><i class='icon shanticon-subjects'></i><span class='badge' >?</span></span>");

                        // highlight matching text (if/where they occur).
                        var txt = $('#searchform').val();
                        // $('.popover-caption').highlight(txt, {element: 'mark'});


                        var fq = plugin.settings.solr_filter_query;

                        var project_filter = (fq) ? ("&" + fq) : "";
                        var kmidxBase = plugin.settings.kmindex_root;
                        if (!kmidxBase) {
                            console.error("plugin.settings.kmindex_root not set!");
                        }

                        var termidxBase = plugin.settings.termindex_root;
                        if (!termidxBase) {
                            console.error("plugin.settings.termindex_root not set!");
                        }

                        // Update counts from asset index
                        var assetCountsUrl =
                            kmidxBase + '/select?q=kmapid:' + plugin.settings.type + '-' + key + project_filter + '&start=0&facets=on&group=true&group.field=asset_type&group.facet=true&group.ngroups=true&group.limit=0&wt=json&json.wrf=?';
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
                            termidxBase + '/select?q={!child of=block_type:parent}id:' + plugin.settings.type + '-' + key + project_filter + '&wt=json&indent=true&group=true&group.field=block_child_type&group.limit=0&wt=json&json.wrf=?';
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

                        var subjectsRelatedPlacesCountQuery = termidxBase + "/select?indent=on&q={!parent%20which=block_type:parent}related_subject_uid_s:" + plugin.settings.type + '-' + key + "%20OR%20feature_type_id_i:" + key + "&wt=json&json.wrf=?&group=true&group.field=tree&group.limit=0";

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

                    var av = elem.find('i.shanticon-audio-video ~ span.badge');
                    if (typeof(counts["audio-video"]) != "undefined") {
                        (counts["audio-video"]) ? av.html(counts["audio-video"]).parent().show() : av.parent().hide();
                    }
                    if (Number(av.text()) > 0) {
                        av.parent().show();
                    }

                    var photos = elem.find('i.shanticon-photos ~ span.badge');
                    if (typeof(counts.picture) != "undefined") {
                        photos.html(counts.picture);
                    }
                    (Number(photos.text()) > 0) ? photos.parent().show() : photos.parent().hide();

                    var places = elem.find('i.shanticon-places ~ span.badge');
                    if (typeof(counts.related_places) != "undefined") {
                        places.html(counts.related_places);
                    }
                    if (Number(places.text()) > 0) {
                        places.parent().show();
                    }

                    var texts = elem.find('i.shanticon-texts ~ span.badge');
                    if (typeof(counts.texts) != "undefined") {
                        texts.html(counts["texts"]);
                    }
                    if (Number(texts.text()) > 0) {
                        texts.parent().show();
                    }

                    var subjects = elem.find('i.shanticon-subjects ~ span.badge');

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
                        subjects.parent().show();
                    }


                    var visuals = elem.find('i.shanticon-visuals ~ span.badge');
                    if (typeof(counts.visuals) != "undefined") {
                        visuals.html(counts.visuals);
                    }
                    if (Number(visuals.text()) > 0) {
                        visuals.parent().show();
                    }

                    var sources = elem.find('i.shanticon-sources ~ span.badge');
                    if (typeof(counts.sources) != "undefined") {
                        sources.html(counts.sources);
                    }
                    if (Number(sources.text()) > 0) {
                        sources.parent().show();
                    }

                    elem.find('.assoc-resources-loading').hide();

                }

                return elem;
            };

            function decorateElemWithDrupalAjax(theElem, theKey, theType) {
                //if (DEBUG) console.log("decorateElementWithDrupalAjax: "  + $(theElem).html());
                //$(theElem).once('nav', function () {
                //    //if (DEBUG) console.log("applying click handling to " + $(this).html());
                //    var base = $(this).attr('id') || "ajax-wax-" + theKey;
                //    var argument = $(this).attr('argument');
                //    var url = location.origin + location.pathname.substring(0, location.pathname.indexOf(theType)) + theType + '/' + theKey + '/overview/nojs';
                //
                //    var element_settings = {
                //        url: url,
                //        event: 'navigate',
                //        progress: {
                //            type: 'throbber'
                //        }
                //    };
                //
                //    // if (DEBUG) console.log("Adding to ajax to " + base);
                //
                //    Drupal.ajax[base] = new Drupal.ajax(base, this, element_settings);
                //    //this.click(function () {
                //    //    if (DEBUG) console.log("pushing state for " + url);
                //    //    window.history.pushState({tag: true}, null, url);
                //    //});
                //});
            }


        },
        getPerspectivePath: function() {
          const plugin = this;
          const dfd = $.Deferred();

            const fieldList = [
                "id",
                "ancestor*" + plugin.settings.perspective + "*path",
                "*level*" + plugin.settings.perspective + "*"
            ].join(",");
            const url =
                plugin.settings.termindex_root + "/select?" +
                "&q=id:" + plugin.settings.type+"-"+ plugin.settings.activeNodeId +
                "&wt=json" +
                "&limit=" + SOLR_ROW_LIMIT +
                "&fl=" + fieldList +
                "&indent=true" +
                "&fq=tree:" + plugin.settings.type +
                "&wt=json" +
                "&json.wrf=?" +
                "&rows=" + SOLR_ROW_LIMIT;
          $.ajax({
            url: url,
            dataType: 'jsonp',
            jsonp: 'json.wrf'
          }).done(function(data){
            const response = data.response;
            if(response.numFound < 1) {
              dfd.resolve("");
            } else {
              const level = response.docs[0]["level_" + plugin.settings.perspective + "_i"];
              var path = response.docs[0]["ancestor_id_" + plugin.settings.perspective + "_path"];
              if( level === undefined) {
                plugin.settings.activeNodeId = path.split('/').pop();
              }
              path = path === undefined ? "" : path;
              dfd.resolve(path);
            }
          }).fail(function(data){
            dfd.resolve("");
          });
          return dfd.promise();
        },
        scrollToActiveNode: function() {
          var plugin = this;
          var tree = $(plugin.element).fancytree('getTree');
          var active = tree.getActiveNode();
          active.makeVisible().done(
            function() {
              var totalOffset =$(active.li).offset().top-$(active.li).closest('.view-wrap').offset().top;
              $(active.li).closest('.view-wrap').scrollTop(totalOffset);
            }
          );
        },
        yourOtherFunction: function (elem, settings) {
            // some logic
        },
        makeStringPath: function (data) {
            return $.makeArray(data.node.getParentList(false, true).map(function (x) {
                return x.title;
            })).join("/");
        },
        buildQuery: function (termIndexRoot, type, path, lvla, lvlb) {
          var plugin = this;
            path = path.replace(/^\//, "").replace(/\s\//, " ");  // remove root slashes
            if (path === "") {
                path = "*";
            }

            var fieldList = [
                "header",
                "id",
                "ancestor*",
                "caption_eng",
                "level_" +plugin.settings.perspective+ "_i"
            ].join(",");

            var result =
                termIndexRoot + "/select?" +
                //"df=ancestor_id_path" +
                "df=ancestor_id_" + plugin.settings.perspective +"_path" +
                "&q=" + path +
                "&wt=json" +
                "&indent=true" +
                "&limit=" + SOLR_ROW_LIMIT +
                "&facet=true" +
                "&fl=" + fieldList +
                "&indent=true" +

                "&fq=tree:" + type +
                //"&fq=level_i:[" + lvla + "+TO+" + (lvlb + 1) + "]" +
                //"&fq={!tag=hoot}level_i:[" + lvla + "+TO+" + lvlb + "]" +
                "&fq=level_" + plugin.settings.perspective + "_i:[" + lvla + "+TO+" + (lvlb + 1) + "]" +
                "&fq={!tag=hoot}level_" + plugin.settings.perspective + "_i:[" + lvla + "+TO+" + lvlb + "]" +

                "&facet.mincount=2" +
                "&facet.limit=-1" +
                "&sort=level_" +plugin.settings.perspective+ "_i+ASC" +
                "&facet.sort=ancestor_id_"+plugin.settings.perspective+"_path" +
                "&facet.field={!ex=hoot}ancestor_id_"+plugin.settings.perspective+"_path" +

                "&wt=json" +
                "&json.wrf=?" +

                "&rows=" + SOLR_ROW_LIMIT;

            if (DEBUG) {
                console.log("buildQuery():SOLR QUERY=" + result)
            }

            return result;
        },
        showPaths: function (paths, callback) {

            //console.log("ARGY!");
            //console.dir(arguments);
            var plugin = this;

            var cleanPath = function (path, parentOnly, rootSlash) {
                log("cleanPath() args: " + JSON.stringify(arguments, undefined, 2));
                log("cleanPath() in: " + path);
                // Eliminate initial/terminal slash
                path = path.replace(/^\/+/, '');
                path = path.replace(/\/$/, '');
                var p = path.split('/');
                if (parentOnly) {
                    p.splice(-1, 1)
                }
                path = rootSlash ? "/" : "";
                path += p.join('/');
                var msg = "cleanPath() out: " + path;
                log(msg);
                return path;
            };

            ////  Cleanup and re-root the paths
            var fixPath = function (path, i) {
                path = cleanPath(path);

                var rootpath = cleanPath(plugin.settings.root_kmap_path, true, false);
                log("fixPath(): rootpath = " + rootpath);
                log("fixPath(): path = " + path);

                // truncate the beginning of the path according to kmap_root_path
                path = path.replace(rootpath, "");
                log("fixPath(): fixed path = " + path);

                // truncate the beginning of the path according to kmap_root_path
                var clean = cleanPath(path, false, true);
                log("fixPath(): fixed clean = " + clean);

                return clean;
            };


            // ensure it is an array
            if (!$.isArray(paths)) {
                // wrap a single bare path into a single-value array.
                paths = [paths];
            }

            if (DEBUG) log("paths " + paths);

            // cleanup the paths
            paths = $.map(paths, fixPath);
            paths = $.grep(paths, function (x) {
                return (x !== "/")
            })

            if (DEBUG) {
                console.dir(paths);
            }

            var pathlist = [];
            for (var i = 0; i < paths.length; i++) {
                if (DEBUG) log("======> processing path:" + paths[i]);
                if (paths[i].length > 0 && this.element.fancytree('getTree').getNodeByKey(paths[i].substring(paths[i].lastIndexOf('/') + 1)) == null) {
                    pathlist.push(paths[i]);
                }
            }
            // if (DEBUG)
            //     log("loadKeyPath " + pathlist);

            if (paths !== null) {
                if (pathlist.length == 0) { // all paths to show have already been loaded
                    var ret = this.element.fancytree('getTree').filterNodes(function (x) {
                        if (DEBUG) log("     filt:" + x.getKeyPath());
                        return $.inArray(x.getKeyPath(), paths) !== -1;
                        // unfortunately filterNodes does not implement a cal
                        // Terminal callback");
                            if (DEBUG) console.dir(node);
                            if (DEBUG) console.dir(state);

                            if (node === null) {
                                console.error("HEY NODE IS NULL");
                                console.error("paths = " + JSON.stringify(pathlist));
                            }

                            if (state === "ok") {
                                log("state = OK");
                                if (node != null) {
                                    if (DEBUG) log("ok " + node);
                                    var ret = node.tree.filterNodes(function (x) {
                                        if (DEBUG) log("     filt:" + x.getKeyPath());
                                        return $.inArray(x.getKeyPath(), paths) !== -1;
                                        // unfortunately filterNodes does not implement a callback for when it is done AFAICT
                                    }, {autoExpand: true});
                                    if (DEBUG) log("filterNodes returned: " + ret);
                                }
                            } else if (state == "loading") {
                                if (DEBUG) log("loading " + node);
                            } else if (state == "loaded") {
                                if (DEBUG) log("loaded" + node);
                            } else if (state == "error") {
                                console.log("ERROR: state was " + state + " for " + node);
                            }

                        }
                      /*
                    ).always(
                        // The logic here is not DRY, so will need to refactor.
                        function () {
                            if (callback) {
                                if (DEBUG) {
                                    log("Calling back! ");
                                    console.dir(arguments);
                                }
                                callback();
                            }
                        }
                    );
                    */
                    );
                }
            } else {
                if (callback) callback();
            }
        },
        loadKeyPath: function (tree, keyPathList, callback, _rootNode) {
            var deferredList, dfd, i, path, key, loadMap, node, root, segList,
                sep = tree.options.keyPathSeparator,
                self = tree;

            if (!$.isArray(keyPathList)) {
                keyPathList = [keyPathList];
            }
            // Pass 1: handle all path segments for nodes that are already loaded
            // Collect distinct top-most lazy nodes in a map
            loadMap = {};

            for (i = 0; i < keyPathList.length; i++) {
                root = _rootNode || self.rootNode;
                path = keyPathList[i];
                // strip leading slash
                if (path.charAt(0) === sep) {
                    path = path.substr(1);
                }
                // traverse and strip keys, until we hit a lazy, unloaded node
                segList = path.split(sep);
                while (segList.length) {
                    key = segList.shift();
//                node = _findDirectChild(root, key);
                    node = root._findDirectChild(key);
                    if (!node) {
                        self.info("loadKeyPath: key not found: " + key + " (parent: " + root + ", path: " + path + ")");
                        callback.call(self, key, "error");
                        break;
                    } else if (segList.length === 0) {
                        callback.call(self, node, "ok");
                        break;
                    } else if (!node.lazy || (node.hasChildren() !== undefined )) {
                        callback.call(self, node, "loaded");
                        root = node;
                    } else {
                        callback.call(self, node, "loaded");
//                    segList.unshift(key);
                        if (loadMap[key]) {
                            loadMap[key].push(segList.join(sep));
                        } else {
                            loadMap[key] = [segList.join(sep)];
                        }
                        break;
                    }
                }
            }
//        alert("loadKeyPath: loadMap=" + JSON.stringify(loadMap));
            // Now load all lazy nodes and continue itearation for remaining paths
            deferredList = [];
            // Avoid jshint warning 'Don't make functions within a loop.':
            function __lazyload(key, node, dfd) {
                callback.call(self, node, "loading");
                node.load().done(function () {
                    self.loadKeyPath.call(self, loadMap[key], callback, node).always(_makeResolveFunc(dfd, self));
                }).fail(function (errMsg) {
                    self.warn("loadKeyPath: error loading: " + key + " (parent: " + root + ")");
                    callback.call(self, node, "error");
                    dfd.reject();
                });
            }

            for (key in loadMap) {
                node = root._findDirectChild(key);
                if (node == null) {
                    node = self.getNodeByKey(key);
                }
//            alert("loadKeyPath: lazy node(" + key + ") = " + node);
                dfd = new $.Deferred();
                deferredList.push(dfd);
                __lazyload(key, node, dfd);
            }
            // Return a promise that is resovled, when ALL paths were loaded
            return $.when.apply($, deferredList).promise();
        },
        getNodeByKey: function (key, root) {
            return this.element.fancytree("getTree").getNodeByKey(key, root);
        },
        hideAll: function (cb) {
            var ftree = this.element.fancytree("getTree");
            ftree.filter(function (x) {
                return false;
            });
            cb(ftree);
        },
        reset: function (cb) {
            this.element.fancytree("getTree").clearFilter();
            if (cb) {
                cb();
            }
        },
        // Utility Functions
        sendEvent: function (handler, event, data) {
            function encapsulate(eventtype, event, n) {
                if (!n) {return {};}
                return {
                    eventtype: eventtype, // "useractivate","codeactivate"
                    title: n.title,
                    key: n.key,
                    path: "/" + n.data.path,
                    level: n.data.level,
                    parent: "/" + n.data.parent,
                    event: event
                };
            }

            // log("HANDLER:  " + handler);
            if (data.node == null) {
                return;
            }
            var kmapid = this.settings.type + "-" + data.node.key;
            var path = "/" + data.node.data.path;
            var origEvent = (event.originalEvent) ? event.originalEvent.type : "none";
            var keyCode = "";
            if (event.keyCode) {
                keyCode = "(" + event.keyCode + ")";
            }
            if (event.type === "fancytreeactivate" && origEvent === "click") {
                // This was a user click
                //console.error("USER CLICKED: " + data.node.title);
                $(this.element).trigger("useractivate", encapsulate("useractivate", event, data.node));
              //TODO: Fix this to have a more elegant way to handle the activate for nodes
              //var url= this.settings.baseUrl +"/"+data.node.key;
              var url= this.settings.baseUrl.replace("%%ID%%",data.node.key);
              window.location.href = url;
            } else if (event.type === "fancytreekeydown" && origEvent === "keydown") {
                // This was a user arrow key (or return....)
                //console.error("USER KEYED: " + data.node.tree.getActiveNode() + " with " + event.keyCode);
                $(this.element).trigger("useractivate", encapsulate("useractivate", event, data.node.tree.getActiveNode()));
            } else if (event.type === "fancytreefocus" && origEvent === "none") {
                // console.error("FOCUS: " + data.node.title);
            } else if (event.type === "fancytreeactivate" && origEvent === "none") {
                // console.error("ACTIVATE: " + data.node.title);
                $(this.element).trigger("activate", encapsulate("codeactivate", event, data.node.tree.getActiveNode()));
            } else {
                log("UNHANDLED EVENT: " + event);
                console.dir(event);
            }
        }

    });


    // See https://github.com/jquery-boilerplate/jquery-boilerplate/wiki/Extending-jQuery-Boilerplate
    $.fn[pluginName] = function (options) {
        var args = arguments;

        if (options === undefined || typeof options === 'object') {
            return this.each(function () {
                if (!$.data(this, 'plugin_' + pluginName)) {
                    $.data(this, 'plugin_' + pluginName, new KmapsTreePlugin(this, options));
                }
            });
        } else if (typeof options === 'string' && options[0] !== '_' && options !== 'init') {
            var returns;

            this.each(function () {
                var instance = $.data(this, 'plugin_' + pluginName);
                if (instance instanceof KmapsTreePlugin && typeof instance[options] === 'function') {
                    returns = instance[options].apply(instance, Array.prototype.slice.call(args, 1));
                }
                if (options === 'destroy') {
                    $.data(this, 'plugin_' + pluginName, null);
                }
            });
            return returns !== undefined ? returns : this;
        }
    };


})(jQuery, window, document);
