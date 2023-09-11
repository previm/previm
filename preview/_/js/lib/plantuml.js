function encode64(a) {
  var r = "";
  for (var i = 0; i < a.length; i += 3) {
    if (i + 2 == a.length) {
      r += append3bytes(a.charCodeAt(i), a.charCodeAt(i + 1), 0)
    } else {
      if (i + 1 == a.length) {
        r += append3bytes(a.charCodeAt(i), 0, 0)
      } else {
        r += append3bytes(a.charCodeAt(i), a.charCodeAt(i + 1), a.charCodeAt(i + 2))
      }
    }
  }
  return r
}

function append3bytes(c, b, a) {
  var c1 = c >> 2;
  var c2 = ((c & 3) << 4) | (b >> 4);
  var c3 = ((b & 15) << 2) | (a >> 6);
  var c4 = a & 63;
  var r = "";
  r += encode6bit(c1 & 63);
  r += encode6bit(c2 & 63);
  r += encode6bit(c3 & 63);
  r += encode6bit(c4 & 63);
  return r
}

function encode6bit(a) {
  if (a < 10) {
    return String.fromCharCode(48 + a)
  }
  a -= 10;
  if (a < 26) {
    return String.fromCharCode(65 + a)
  }
  a -= 26;
  if (a < 26) {
    return String.fromCharCode(97 + a)
  }
  a -= 26;
  if (a == 0) {
    return "-"
  }
  if (a == 1) {
    return "_"
  }
  return "?"
}

function compress(prefix, a) {
  a = unescape(encodeURIComponent(a));
  if (prefix) {
    return prefix + encode64(zip_deflate(a, 9));
  }
  return "http://plantuml.com/plantuml/img/" + encode64(zip_deflate(a, 9));
}

function loadPlantUML() {
  var umls = document.querySelectorAll('code.language-plantuml');
  var prefix = getOptions().imagePrefix;
  Array.prototype.slice.call(umls).forEach(function(el) {
    var text = el.textContent
    var url = compress(prefix, text);
    var div = document.createElement('div');
    div.innerHTML = '<div><img src="' + url + '" /></div>'
    el.parentNode.replaceWith(div);
  });
}
