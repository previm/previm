import { Parser, ConverterHTML } from 'org';
import '../../css/lib/vendor.css';

const parser = new Parser();

/**
 * Convert to html from orgmode text.
 *
 * @param code {String} orgmode text
 * @returns converted html
 **/
export function orgConvertToHtml(code) {
  const doc = parser.parse(code);
  const html = doc.convert(ConverterHTML, {});
  return html.toString();
}
