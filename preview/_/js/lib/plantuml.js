async function rawDeflate(text) {
  if ("CompressionStream" in window) {
    const cs = new CompressionStream("deflate-raw");
    const writer = cs.writable.getWriter();
    writer.write(new TextEncoder().encode(text));
    writer.close();
    return new Uint8Array(await new Response(cs.readable).arrayBuffer());
  }
  throw new Error("raw-deflate unavailable");
}

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
  return encode6bit(c1) + encode6bit(c2) + encode6bit(c3) + encode6bit(c4);
}

function encode64(data) {
  let r = "";
  for (let i = 0; i < data.length; i += 3) {
    r += append3bytes(
      data[i],
      data[i + 1] || 0,
      data[i + 2] || 0
    );
  }
  return r;
}

async function compress(prefix, txt) {
  const bin = await rawDeflate(txt);
  const encoded = encode64(bin);
  return (prefix || "https://www.plantuml.com/plantuml/img/") + encoded;
}

function loadPlantUML() {
  const umls = document.querySelectorAll("code.language-plantuml");
  const prefix = getOptions().imagePrefix;

  umls.forEach(async (el) => {
    const text = el.textContent;
    const div = document.createElement("div");
    const value = await compress(prefix, text);
    div.innerHTML = `<div><img src="${value}"></div>`;
    el.parentNode.replaceWith(div);
  });
}

