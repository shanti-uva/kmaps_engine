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
      mandalaURL: "https://mandala.shanti.virginia.edu/%%APP%%/%%ID%%/%%REL%%/nojs",
      solrUtils: {} //requires solr-utils.js library
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
            var pop_container = $('<span class="popover-kmaps" data-app="places" data-id="'+key+'"><span class="popover-kmaps-tip"></span><span class="icon shanticon-menu3"></span></span>');
            $(elem).append($(pop_container));
            $(pop_container).kmapsPopup({
              featuresPath: plugin.options.featuresPath,
              domain: plugin.options.domain,
              featureId:  "",
              mandalaURL: plugin.options.mandalaURL,
              solrUtils: plugin.options.solrUtils

            });
          }
          return data;
        },
      });

      function makeStringPath(data) {
        return $.makeArray(data.node.getParentList(false, true).map(function (x) {
          return x.title;
        })).join("/");
      }

    },
    getAncestorPath: function() {
      const plugin = this;
      return plugin.options.solrUtils.getAncestorPath();
    },
    getAncestorTree: function(options){
      const plugin = this;
      return plugin.options.solrUtils.getAncestorTree(options);
    },
    getDescendantTree: function(featureId){
      const plugin = this;
      return plugin.options.solrUtils.getDescendantTree(featureId);
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

