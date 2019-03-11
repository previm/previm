'use strict';

(function(_doc, _win) {
  var REFRESH_INTERVAL = 1000;
  var toc;
  var md = new _win.markdownit({html: true, linkify: true, breaks: true})
                   .use(_win.markdownitAbbr)
                   .use(_win.markdownitDeflist)
                   .use(_win.markdownitFootnote)
                   .use(_win.markdownitSub)
                   .use(_win.markdownitSup)
                   .use(_win.markdownitTaskLists, { enabled: true })
                   .use(_win.markdownitEmoji);

  // Override default 'fence' ruler for 'mermaid' support
  var original_fence = md.renderer.rules.fence;
  md.renderer.rules.fence = function fence(tokens, idx, options, env, slf) {
    var token = tokens[idx];
    var langName = token.info.trim().split(/\s+/g)[0];
    if (langName === 'mermaid') {
      return '<div class="mermaid">' + token.content + '</div>';
    }
    return original_fence(tokens, idx, options, env, slf);
  };

  function transform(filetype, content) {
    if(hasTargetFileType(filetype, ['markdown', 'mkd'])) {
      return md.render(content);
    } else if(hasTargetFileType(filetype, ['rst'])) {
      // It has already been converted by rst2html.py
      return content;
    } else if(hasTargetFileType(filetype, ['textile'])) {
      return textile(content);
    } else if(hasTargetFileType(filetype, ['asciidoc'])) {
      return new Asciidoctor().convert(content, { attributes: { showtitle: true } });
    }
    return 'Sorry. It is a filetype(' + filetype + ') that is not support<br /><br />' + content;
  }

  function hasTargetFileType(filetype, targetList) {
    var ftlist = filetype.split('.');
    for(var i=0;i<ftlist.length; i++) {
      if(targetList.indexOf(ftlist[i]) > -1){
        return true;
      }
    }
    return false;
  }

  // NOTE: Experimental
  //   ここで動的にpageYOffsetを取得すると画像表示前の高さになってしまう
  //   そのため明示的にpageYOffsetを受け取るようにしている
  function autoScroll(id, pageYOffset) {
    var relaxed = 0.95;
    var obj = document.getElementById(id);
    if((_doc.documentElement.clientHeight + pageYOffset) / _doc.body.clientHeight > relaxed) {
      obj.scrollTop = obj.scrollHeight;
    } else {
      obj.scrollTop = pageYOffset;
    }
  }

  function style_header() {
    if (typeof isShowHeader === 'function') {
      var style = isShowHeader() ? '' : 'none';
      _doc.getElementById('header').style.display = style;
    }
  }

  function createTOC() {
    toc = $("#toc").tocify({selectors: "h2,h3,h4,h5,h6"}).data("toc-tocify");
  }

  function loadPreview() {
    var needReload = false;
    // These functions are defined as the file generated dynamically.
    //   generator-file: preview/autoload/previm.vim
    //   generated-file: preview/js/previm-function.js
    if (typeof getFileName === 'function') {
      if (_doc.getElementById('markdown-file-name').innerHTML !== getFileName()) {
        _doc.getElementById('markdown-file-name').innerHTML = getFileName();
        needReload = true;
      }
    } else {
      needReload = true;
    }
    if (typeof getLastModified === 'function') {
      if (_doc.getElementById('last-modified').innerHTML !== getLastModified()) {
        _doc.getElementById('last-modified').innerHTML = getLastModified();
        needReload = true;
      }
    } else {
      needReload = true;
    }
    if (needReload && (typeof getContent === 'function') && (typeof getFileType === 'function')) {
      var beforePageYOffset = _win.pageYOffset;
      _doc.getElementById('preview').innerHTML = transform(getFileType(), getContent());

      mermaid.init();
      Array.prototype.forEach.call(_doc.querySelectorAll('pre code'), hljs.highlightBlock);
      autoScroll('body', beforePageYOffset);
      style_header();
      // apply fancybox
      var i;
      for (i = 0; i < _doc.images.length; i++) {
        var elem = _doc.images[i];

        elem.setAttribute('class', 'fancybox-img'); // add Style Sheet Class
        elem.outerHTML = '<a href="" class="fancybox1" rel="fancybox" title="'+elem.alt+'">'+elem.outerHTML+'</a>'; // insert Before a tag
        _doc.images[i].parentNode.setAttribute('href', elem.src);  // copy src to parent a tag href (for fancybox)

        // clean up
        elem = null;
      }
      $(".fancybox1").fancybox();
      // external link
      for (i = 0; i < _doc.links.length; i++) {
        _doc.links[i].setAttribute('target', '_blank');
      }
      toc.update();
    }
  }

  _win.setInterval(function() {
    var script = _doc.createElement('script');

    script.type = 'text/javascript';
    script.src = 'js/previm-function.js?t=' + new Date().getTime();

    _addEventListener(script, 'load', (function() {
      loadPreview();
      _win.setTimeout(function() {
        script.parentNode.removeChild(script);
      }, 160);
    })());

    _doc.getElementsByTagName('head')[0].appendChild(script);

  }, REFRESH_INTERVAL);

  function _addEventListener(target, type, listener) {
    if (target.addEventListener) {
      target.addEventListener(type, listener, false);
    } else if (target.attachEvent) {
      // for IE6 - IE8
      target.attachEvent('on' + type, function() { listener.apply(target, arguments); });
    } else {
      // do nothing
    }
  }

  loadPreview();
  createTOC();
})(document, window);
