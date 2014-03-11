(function(_doc, _win) {
  var REFRESH_INTERVAL = 1000;

  function loadPreview() {
    var need_reload = false;
    // These functions are defined as the file generated dynamically.
    //   generator-file: preview/autoload/previm.vim
    //   generated-file: preview/js/previm-function.js
    if (typeof getFileName === 'function') {
      if (_doc.getElementById("markdown-file-name").innerHTML != getFileName()) {
        _doc.getElementById("markdown-file-name").innerHTML = getFileName();
        need_reload = true;
      }
    } else {
      need_reload = true;
    }
    if (typeof getLastModified === 'function') {
      if (_doc.getElementById("last-modified").innerHTML != getLastModified()) {
        _doc.getElementById("last-modified").innerHTML = getLastModified();
        need_reload = true;
      }
    } else {
      need_reload = true;
    }
    if (need_reload && (typeof getContent === 'function')) {
      _doc.getElementById("preview").innerHTML = marked(getContent());
    }
  }

  _win.setInterval(function() {
    var script = _doc.createElement("script");

    script.type = 'text/javascript';
    script.src = 'js/previm-function.js?t=' + new Date().getTime();

    _addEventListener(script, "load", (function() {
      loadPreview();
      _win.setTimeout(function() {
        script.parentNode.removeChild(script);
      }, 160);
    })());

    _doc.getElementsByTagName("head")[0].appendChild(script);

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
})(document, window);
