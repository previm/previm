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

  _win.setInterval(function(){
	var script = _doc.createElement("script");

	script.type = 'text/javascript';
	script.src = 'js/previm-function.js?t=' + new Date().getTime();

	script.addEventListener("load", function(){
		loadPreview();
		_wiin.setTimeout( function(){
			script.parentNode.removeChild(script);
		}, 160 );
	}, false );

	_doc.getElementsByTagName("head")[0].appendChild(script);

  }, REFRESH_INTERVAL);

  loadPreview();
})(document, window);
