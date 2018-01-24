// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
;( function( $, window, document, undefined ) {

	"use strict";

		// undefined is used here as the undefined global variable in ECMAScript 3 is
		// mutable (ie. it can be changed by someone else). undefined isn't really being
		// passed in so we can ensure the value of it is truly undefined. In ES5, undefined
		// can no longer be modified.

		// window and document are passed through as local variables rather than global
		// as this (slightly) quickens the resolution process and can be more efficiently
		// minified (especially when both are regularly referenced in your plugin).

		// Create the defaults once
		var pluginName = "kmapsCollapsibleList",
			defaults = {
        recurse: false,
				selector: "collapsibleList"
			};

		// The actual plugin constructor
		function kmapsCollapsibleListPlugin ( element, options ) {
			this.element = element;

			// jQuery has an extend method which merges the contents of two or
			// more objects, storing the result in the first object. The first object
			// is generally empty as we don't want to alter the default options for
			// future instances of the plugin
			this.settings = $.extend( {}, defaults, options );
			this._defaults = defaults;
			this._name = pluginName;
			this.init();
		}

		// Avoid Plugin.prototype conflicts
		$.extend( kmapsCollapsibleListPlugin.prototype, {
			init: function() {
        var plugin = this;
        $(plugin.element).children('li').each(function(){
            var li = this;
            $(li).click(plugin.handleClick);
            $(li).addClass('collapsibleListClosed');
            $(li).children('ul').addClass('collapsibleListClosed').each(function(){
              var ul = this;
              $(ul).css('display', 'none');
            });
        });
			},
      handleClick: function(e){
        var li = e.target;
        if(!$(li).is("li")){
          li = $(li).closest("li")[0];
        }
        var ul = li.getElementsByTagName('ul');
        const open = $(ul).hasClass('collapsibleListClosed');
        $(ul).css('display',(open ? 'block' : 'none'));
        $(ul).removeClass('collapsibleListOpen');
        $(ul).removeClass('collapsibleListClosed');
        $(ul).addClass('collapsibleList' + (open ? 'Open' : 'Closed'));
        $(li).removeClass('collapsibleListOpen');
        $(li).removeClass('collapsibleListClosed');
        $(li).addClass('collapsibleList' + (open ? 'Open' : 'Closed'));
        $(".collapsible_all_btn").removeClass("collapsible_all_btn_selected");
      },
      toggleTo: function(li,open){
        var status = (!open ? 'Open' : 'Closed');
        var altStatus = (open ? 'Open' : 'Closed');
        $(li).each(function(){
          var li = this;
          var ul = li.getElementsByTagName('ul.collapsibleList'+status);
          $(li).removeClass('collapsibleList'+status);
          $(li).addClass('collapsibleList'+altStatus);
          $(li).children('ul').removeClass('collapsibleList'+status).addClass('collapsibleList'+altStatus).each(function(){
            var ul = this;
            $(ul).css('display',(open ? 'block' : 'none'));
          });
        });
      },
      expandAll: function(){
        var plugin = this;
        $(plugin.element).children('li.collapsibleListClosed').each(function(){
          var li = this;
          plugin.toggleTo(li,true);
        });
      },
      collapseAll: function(){
        var plugin = this;
        $(plugin.element).children('li.collapsibleListOpen').each(function(){
          var li = this;
          plugin.toggleTo(li,false);
        });

      }
		} );

    // See https://github.com/jquery-boilerplate/jquery-boilerplate/wiki/Extending-jQuery-Boilerplate
    $.fn[pluginName] = function (options) {
        var args = arguments;

        if (options === undefined || typeof options === 'object') {
            return this.each(function () {
                if (!$.data(this, 'plugin_' + pluginName)) {
                    $.data(this, 'plugin_' + pluginName, new kmapsCollapsibleListPlugin(this, options));
                }
            });
        } else if (typeof options === 'string' && options[0] !== '_' && options !== 'init') {
            var returns;

            this.each(function () {
                var instance = $.data(this, 'plugin_' + pluginName);
                if (instance instanceof kmapsCollapsibleListPlugin && typeof instance[options] === 'function') {
                    returns = instance[options].apply(instance, Array.prototype.slice.call(args, 1));
                }
                if (options === 'destroy') {
                    $.data(this, 'plugin_' + pluginName, null);
                }
            });
            return returns !== undefined ? returns : this;
        }
    };

} )( jQuery, window, document );
