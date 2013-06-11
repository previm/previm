(function() {
  var REFRESH_INTERVAL = 1000;
  var converter = new Showdown.converter();

  function loadPreview() {
    if (typeof getFileName === 'function') {
      $('#markdown-file-name').text(getFileName());
    }
    if (typeof getLastModified === 'function') {
      $('#last-modified').text(getLastModified());
    }
    if (typeof getContent === 'function') {
      $('#preview').text('');
      $('#preview').append(converter.makeHtml(getContent()));
    }
  }

  setInterval(function(){
    $.getScript('js/previm-function.js', loadPreview)
  }, REFRESH_INTERVAL);

  loadPreview();
})();
