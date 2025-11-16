function encode6bit(b) {
  if (b < 10) return String.fromCharCode(48 + b);
  b -= 10;
  if (b < 26) return String.fromCharCode(65 + b);
  b -= 26;
  if (b < 26) return String.fromCharCode(97 + b);
  b -= 26;
  if (b === 0) return "-";
  if (b === 1) return "_";
  return "?";
}

function append3bytes(b1, b2, b3) {
  const c1 = b1 >> 2;
  const c2 = ((b1 & 0x3) << 4) | (b2 >> 4);
  const c3 = ((b2 & 0xF) << 2) | (b3 >> 6);
  const c4 = b3 & 0x3F;
  return encode6bit(c1 & 0x3F) + encode6bit(c2 & 0x3F) + encode6bit(c3 & 0x3F) + encode6bit(c4 & 0x3F);
}

function encode64(data) {
  let r = "";
  for (let i = 0; i < data.length; i += 3) {
    if (i + 2 === data.length) {
      r += append3bytes(data.charCodeAt(i), data.charCodeAt(i + 1), 0);
    } else if (i + 1 === data.length) {
      r += append3bytes(data.charCodeAt(i), 0, 0);
    } else {
      r += append3bytes(
        data.charCodeAt(i),
        data.charCodeAt(i + 1),
        data.charCodeAt(i + 2)
      );
    }
  }
  return r;
}

function compress(prefix, txt) {
  txt = unescape(encodeURIComponent(txt));

  const zipped = zip_deflate(txt, 9);
  const encoded = encode64(zipped);

  if (prefix) return prefix + encoded;
  return "http://plantuml.com/plantuml/img/" + encoded;
}

function loadPlantUML() {
  const umls = document.querySelectorAll("code.language-plantuml");
  const prefix = getOptions().imagePrefix;

  Array.prototype.slice.call(umls).forEach(function(el) {
    const text = el.textContent.replace(/^'\s*---/gm, "'—"); // avoid md-hr detection

    const url = compress(prefix, text);
    const div = document.createElement("div");
    div.innerHTML = '<div><img src="' + url + '" /></div>';
    el.parentNode.replaceWith(div);
  });
}

