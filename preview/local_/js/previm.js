'use strict';

(function(_doc, _win) {
  var REFRESH_INTERVAL = 1000;
  var md = new _win.markdownit({html: true, linkify: true})
                   .use(_win.markdownitAbbr)
                   .use(_win.markdownitDeflist)
                   .use(_win.markdownitFootnote)
                   .use(_win.markdownitSub)
                   .use(_win.markdownitSup)
                   .use(_win.markdownitIns)
                   .use(_win.markdownitMark)
                   .use(_win.markdownitMathjax())
                   .use(_win.markdownitEmoji)
                   .use(_win.markdownitCheckbox)
                   .use(_win.markdownitMultimdTable, {multiline: true, rowspan:true, headerless:true})
                   .use(_win.markdownitContainer, 'dynamic_block', {
                     validate: function(params) {
                       return params.trim().match(/^@\S+.*$/);
                     },
                     render: function (tokens, idx) {
                       var m = tokens[idx].info.trim().split(/\s+/);
                       if (tokens[idx].nesting === 1) {
                         // opening tag
                         var opentag = '<div class="' + m[0].slice(1) + '" id="' + idx + '" data-count="' + (m.length - 1) + '"';
                         for (var i = 1; i < m.length; i++) {
                             opentag += ' data-arg' + i + '="' + md.utils.escapeHtml(m[i]) + '"';
                         }
                         return opentag + '>';
                       } else {
                         // closing tag
                         return '</div>\n';
                       }
                     }
                   })
/* markdownitContainer Start */
/* markdownitContainer End */
                   .use(_win.markdownItAnchor, { permalink: true, permalinkBefore: true, permalinkSymbol: '§' } )
                   .use(_win.markdownItTocDoneRight )
                   .use(_win.markdownitCjkBreaks);

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

  function loadPreview() {
    if ((typeof getContent === 'function') && (typeof getFileType === 'function')) {
      var beforePageYOffset = _win.pageYOffset;
      _doc.getElementById('preview').innerHTML = transform(getFileType(), getContent());

      mermaid.init();

      loadPlantUML();

      Array.prototype.forEach.call(_doc.querySelectorAll('pre code'), hljs.highlightBlock);
      renderMathInElement(document.body);
/* Custom Render Start */
/* Custom Render End */
      autoScroll('body', beforePageYOffset);
      style_header();
    }
  }

  loadPreview();
})(document, window);
