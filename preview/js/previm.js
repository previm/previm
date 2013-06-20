(function(_doc, _win) {
  var REFRESH_INTERVAL = 1000;
  var converter = new Showdown.converter();

  function loadPreview() {
    if (typeof getFileName === 'function') {
      _doc.getElementById("markdown-file-name").innerHTML = getFileName();
    }
    if (typeof getLastModified === 'function') {
      _doc.getElementById("last-modified").innerHTML = getLastModified();
    }
    if (typeof getContent === 'function') {
      _doc.getElementById("preview").innerHTML = converter.makeHtml(getContent());
    }
  }

  _win.setInterval(function() {
    var script = _doc.createElement("script");

    script.type = 'text/javascript';
    script.src = 'js/previm-function.js?t=' + new Date().getTime();

    AddEventListener(script, "load", (function() {
      loadPreview();
      _win.setTimeout(function() {
        script.parentNode.removeChild(script);
      }, 160);
    })());

    _doc.getElementsByTagName("head")[0].appendChild(script);

  }, REFRESH_INTERVAL);

  loadPreview();
})(document, window);

function AddEventListener(target, type, listener) {
    if (target.addEventListener) {
        target.addEventListener(type, listener, false);
    } else if (target.attachEvent) {
        target.attachEvent('on' + type,
            function() { listener.apply(target, arguments); } );
    } else {
    }
}
