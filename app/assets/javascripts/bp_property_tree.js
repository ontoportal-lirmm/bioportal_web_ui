/*
* jQuery SimpleTree Drag&Drop plugin
* Update on 22th May 2008
* Version 0.3
*
* Licensed under BSD <http://en.wikipedia.org/wiki/BSD_License>
* Copyright (c) 2008, Peter Panov <panov@elcat.kg>, IKEEN Group http://www.ikeen.com
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the Peter Panov, IKEEN Group nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY Peter Panov, IKEEN Group ``AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL Peter Panov, IKEEN Group BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

(function($) {
  var NCBOPropertyTree = function(element, opt) {
    var obj = this;
    var OPTIONS;
    var ROOT_ID = "roots";

    OPTIONS = {
      autoclose:         false,
      beforeExpand:      false,
      afterExpand:       false,
      afterExpandError:  false,
      afterSelect:       false,
      afterJumpToClass:  false,
      timeout:           999999,
      treeClass:         "ncboTree",
      width:             350,
      ncboUIURL:         "http://bioportal.bioontology.org",
      apikey:            null,
      ontology:          null
    };

    OPTIONS = $.extend(OPTIONS, opt);

    // Required options
    if (OPTIONS.ontology == null)
      throw new Error("You must provide an ontology id for NCBO Property Tree Widget to operate");

    var $TREE_CONTAINER = element;
    var TREE = $("<ul>").append($("<li>").addClass("root"));
    var ROOT = $('.root', TREE);
    var mousePressed = false;
    TREE.css("width", OPTIONS.width);

    // Empty out the tree container
    $TREE_CONTAINER.html("");

    // Add the actual tree
    $TREE_CONTAINER.append(TREE);

    // Add provided class
    TREE.addClass(OPTIONS.treeClass);

    // format the nodes to match what simpleTree is expecting
    this.formatNodes = function(nodes) {
      var holder = $("<span>");
      var ul = $("<ul>");

      // Sort by prefLabel
      nodes.sort(function(a, b){
        var aName = a.prefLabel.toLowerCase();
        var bName = b.prefLabel.toLowerCase();
        return ((aName < bName) ? -1 : ((aName > bName) ? 1 : 0));
      });

      $.each(nodes, function(index, node){
        var li = $("<li>");
        var a = $("<a>").attr("href", obj.determineHTTPS(node["@id"])).html(node.prefLabel);
        a.attr("data-id", encodeURIComponent(node.id))
         .attr("data-label", node.label)
         .attr("data-definition", node.definition)
         .attr("data-parents", node.parents)
         .attr("data-prefLabel", node.prefLabel);

        ul.append(li.append(a));

        var hasChildrenNotExpanded = typeof node.children !== 'undefined' && node.hasChildren && node.children.length == 0;
        if (node.hasChildren && typeof node.children === 'undefined' || hasChildrenNotExpanded) {
          var ajax_ul = $("<ul>").addClass("ajax");
          var ajax_li = $("<li>");
          var ajax_a = $("<a>").attr("href", node.links.children);
          li.append(ajax_ul.append(ajax_li.append(ajax_a)));
        } else if (typeof node.children !== 'undefined' && node.children.length > 0) {
          var child_ul = obj.formatNodes(node.children);
          li.append(child_ul);
        }
      });

      holder.append(ul)
      return holder.html();
    }

    this.selectClass = function(cls){
      var foundClass = $(TREE.find("a[data-id='" + cls + "']"));
      $(TREE.find("a.active")[0]).removeClass("active");
      foundClass.addClass("active");
    }

    this.selectedClass = function(){
      var cls = $(TREE.find("a.active")[0]);
      if (cls.length == 0) {
        return null;
      } else {
        return {
          id: decodeURIComponent(cls.data("id")),
          prefLabel: cls.html(),
          URL: cls.attr("href")
        };
      }
    }

    this.closeNearby = function(obj) {
      $(obj).siblings().filter('.folder-open, .folder-open-last').each(function(){
        var childUl = $('>ul',this);
        var className = this.className;
        this.className = className.replace('open', 'close');
        childUl.hide();
      });
    };

    this.nodeToggle = function(obj) {
      var childUl = $('>ul',obj);
      if (childUl.is(':visible')) {
        obj.className = obj.className.replace('open','close');
        childUl.hide();
      } else {
        obj.className = obj.className.replace('close','open');
        childUl.show();
        if (OPTIONS.autoclose)
          obj.closeNearby(obj);
        if (childUl.is('.ajax'))
          obj.setAjaxNodes(childUl, obj.id);
      }
    };

    this.setAjaxNodes = function(node, parentId, successCallback, errorCallback) {
      if (typeof OPTIONS.beforeExpand == 'function') {
        OPTIONS.beforeExpand(node);
      }
      $TREE_CONTAINER.trigger("beforeExpand", node);

      var url = $.trim($('a', node).attr("href"));
      if (url) {
        $.ajax({
          type: "GET",
          url: url,
          data: {
            apikey: OPTIONS.apikey, 
            include: "prefLabel,hasChildren", 
            no_context: true
          },
          crossDomain: true,
          contentType: 'application/json',
          timeout: OPTIONS.timeout,
          success: function(response) {
            var nodes = obj.formatNodes(response.collection)
            node.removeAttr('class');
            node.html(nodes);
            $.extend(node, {url:url});
            obj.setTreeNodes(node, true);
            if (typeof OPTIONS.afterExpand == 'function') {
              OPTIONS.afterExpand(node);
            }
            $TREE_CONTAINER.trigger("afterExpand", node);
            if (typeof successCallback == 'function') {
              successCallback(node);
            }
          },
          error: function(response) {
            if (typeof OPTIONS.afterExpandError == 'function') {
              OPTIONS.afterExpandError(node);
            }
            if (typeof errorCallback == 'function') {
              errorCallback(node);
            }
            $TREE_CONTAINER.trigger("afterExpandError", node);
          }
        });
      }
    };

    this.setTreeNodes = function(target, useParent) {
      target = useParent ? target.parent() : target;
      $('li>a', target).addClass('text').bind('selectstart', function() {
        return false;
      }).click(function(){
        var parent = $(this).parent();
        var selectedNode = $(this);
        $('.active', TREE).attr('class', 'text');
        if (this.className == 'text') {
          this.className = 'active';
        }
        if (typeof OPTIONS.afterSelect == 'function') {
          OPTIONS.afterSelect(decodeURIComponent(selectedNode.data("id")), selectedNode.text(), selectedNode);
        }
        $TREE_CONTAINER.trigger("afterSelect", [decodeURIComponent(selectedNode.data("id")), selectedNode.text(), selectedNode]);
        return false;
      }).bind("contextmenu",function(){
        $('.active', TREE).attr('class', 'text');
        if (this.className == 'text') {
          this.className = 'active';
        }
        if (typeof OPTIONS.afterContextMenu == 'function') {
          OPTIONS.afterContextMenu(parent);
        }
        return false;
      }).mousedown(function(event) {
        mousePressed = true;
        cloneNode = $(this).parent().clone();
        var LI = $(this).parent();
        return false;
      });

      $('li', target).each(function(i) {
        var className = this.className;
        var open = false;
        var cloneNode=false;
        var LI = this;
        var childNode = $('>ul',this);
        if (childNode.size() > 0){
          var setClassName = 'folder-';
          if (className && className.indexOf('open') >= 0) {
            setClassName = setClassName + 'open';
            open = true;
          } else {
            setClassName = setClassName+'close';
          }
          this.className = setClassName + ($(this).is(':last-child') ? '-last' : '');

          if (!open || className.indexOf('ajax') >= 0)
            childNode.hide();

          obj.setTrigger(this);
        } else {
          var setClassName = 'doc';
          this.className = setClassName + ($(this).is(':last-child') ? '-last' : '');
        }
      }).before('<li class="line">&nbsp;</li>')
        .filter(':last-child')
        .after('<li class="line-last"></li>');
    };

    this.setTrigger = function(node) {
      $('>a',node).before('<img class="trigger" src="data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==" border=0>');
      var trigger = $('>.trigger', node);
      trigger.click(function(event){
        obj.nodeToggle(node);
      });
      // TODO: $.browser was removed in jQuery 1.9, check IE compatability
      // if (!$.browser.msie) {
      //   trigger.css('float','left');
      // }
    };

    this.determineHTTPS = function(url) {
      if (typeof url === 'undefined') { return url; }
      return url.replace("http:", ('https:' == document.location.protocol ? 'https:' : 'http:'));
    }

    // Populate roots and init tree
    this.init = function() {
      ROOT.html($("<span>").html("Loading...").css("font-size", "smaller"));
      $.ajax({
        url: obj.determineHTTPS(OPTIONS.ncboUIURL) + "/ajax/properties/tree",
        data: {
          apikey: OPTIONS.apikey, 
          ontology: OPTIONS.ontology, 
          no_context: true
        },
        contentType: 'application/json',
        crossDomain: true,
        success: function(roots) {
          if (roots.length > 0) {
            // Flatten potentially nested arrays
            roots = $.map([roots], function(n){
              return n;
            });
            ROOT.html(obj.formatNodes(roots));
            obj.setTreeNodes(ROOT, false);
          } else {
            ROOT.html("No properties exist for this ontology");
            ROOT.css("font-size", "14px").css("margin", "5px");
            jQuery("#prop_contents .spinner-border").hide()
          }

          if (typeof OPTIONS.onInit === 'function') { OPTIONS.onInit(); }
        },
        error: function(jqXHR, textStatus, errorThrown) {
          console.log(`NCBOPropertyTree error: ${textStatus} : ${errorThrown}`);
          ROOT.html($("<span>").html(`Problem retrieving properties: ${errorThrown}`).css("font-size", "smaller")); 
        }
      });
    };
  }

  $.fn.NCBOPropertyTree = function(options) {
    // Returns the original object(s) so they can be chained
    return this.each(function() {
      var $this = $(this);

      // Return early if this element already has a plugin instance
      if ($this.data('NCBOPropertyTree')) return;

      // pass options to plugin constructor
      var ncboPropertyTree = new NCBOPropertyTree($this, options);
      ncboPropertyTree.init();

      // Store plugin object in this element's data
      $this.data('NCBOPropertyTree', ncboPropertyTree);
    });
  }

}(jQuery));