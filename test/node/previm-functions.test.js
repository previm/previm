'use strict';

const assert = require('assert');
const { describe, it, beforeEach } = require('node:test');
const {
  createMarkdownRenderer,
  hasTargetFileType,
  normalizeBaseUrl,
  isRelativeUrl,
  transform,
} = require('./previm-functions');

describe('hasTargetFileType', () => {
  it('matches single filetype', () => {
    assert.strictEqual(hasTargetFileType('markdown', ['markdown', 'mkd']), true);
  });

  it('matches compound filetype (dot-separated)', () => {
    assert.strictEqual(hasTargetFileType('liquid.markdown', ['markdown', 'mkd']), true);
  });

  it('does not match unrelated filetype', () => {
    assert.strictEqual(hasTargetFileType('python', ['markdown', 'mkd']), false);
  });

  it('matches mkd', () => {
    assert.strictEqual(hasTargetFileType('mkd', ['markdown', 'mkd']), true);
  });

  it('matches mermaid', () => {
    assert.strictEqual(hasTargetFileType('mermaid', ['mermaid', 'mmd']), true);
    assert.strictEqual(hasTargetFileType('mmd', ['mermaid', 'mmd']), true);
  });
});

describe('isRelativeUrl', () => {
  it('detects relative URLs', () => {
    assert.strictEqual(isRelativeUrl('image.png'), true);
    assert.strictEqual(isRelativeUrl('path/to/file.md'), true);
    assert.strictEqual(isRelativeUrl('../parent/file.txt'), true);
  });

  it('detects absolute URLs', () => {
    assert.strictEqual(isRelativeUrl('https://example.com'), false);
    assert.strictEqual(isRelativeUrl('http://example.com'), false);
    assert.strictEqual(isRelativeUrl('//cdn.example.com/lib.js'), false);
  });

  it('detects fragment-only URLs', () => {
    assert.strictEqual(isRelativeUrl('#section'), false);
  });

  it('detects absolute paths', () => {
    assert.strictEqual(isRelativeUrl('/absolute/path'), false);
  });
});

describe('normalizeBaseUrl', () => {
  it('prepends protocol to protocol-relative URLs', () => {
    assert.strictEqual(normalizeBaseUrl('//example.com/path', 'https:'), 'https://example.com/path');
  });

  it('returns non-protocol-relative URLs as-is', () => {
    assert.strictEqual(normalizeBaseUrl('https://example.com', 'http:'), 'https://example.com');
    assert.strictEqual(normalizeBaseUrl('/local/path', 'https:'), '/local/path');
  });
});

describe('transform', () => {
  let md;

  beforeEach(() => {
    md = createMarkdownRenderer();
  });

  it('renders basic markdown', () => {
    const result = transform(md, 'markdown', '# Hello\n\nworld');
    assert.ok(result.includes('<h1>Hello</h1>'));
    assert.ok(result.includes('<p>world</p>'));
  });

  it('renders markdown links with proper attributes', () => {
    const result = transform(md, 'markdown', '[link](https://example.com)');
    assert.ok(result.includes('href="https://example.com"'));
  });

  it('renders inline code', () => {
    const result = transform(md, 'markdown', 'use `console.log`');
    assert.ok(result.includes('<code>console.log</code>'));
  });

  it('renders code blocks', () => {
    const result = transform(md, 'markdown', '```js\nconsole.log("hi");\n```');
    assert.ok(result.includes('<code'));
    assert.ok(result.includes('console.log'));
  });

  it('strips YAML front matter', () => {
    const input = '---\ntitle: test\n---\n# Content';
    const result = transform(md, 'markdown', input);
    assert.ok(!result.includes('---'));
    assert.ok(result.includes('title: test'));
    assert.ok(result.includes('Content'));
  });

  it('strips TOML front matter', () => {
    const input = '+++\ntitle = "test"\n+++\n# Content';
    const result = transform(md, 'markdown', input);
    assert.ok(!result.includes('+++'));
    assert.ok(result.includes('title = &quot;test&quot;'));
    assert.ok(result.includes('Content'));
  });

  it('handles mkd filetype', () => {
    const result = transform(md, 'mkd', '**bold**');
    assert.ok(result.includes('<strong>bold</strong>'));
  });

  it('handles compound filetype', () => {
    const result = transform(md, 'liquid.markdown', '*italic*');
    assert.ok(result.includes('<em>italic</em>'));
  });

  it('converts mermaid filetype to mermaid code block', () => {
    const result = transform(md, 'mermaid', 'graph TD\nA-->B');
    assert.ok(result.includes('mermaid'));
    assert.ok(result.includes('graph TD'));
  });

  it('converts mmd filetype', () => {
    const result = transform(md, 'mmd', 'graph LR\nA-->B');
    assert.ok(result.includes('mermaid'));
  });

  it('returns HTML as-is for html filetype', () => {
    const html = '<div><p>Hello</p></div>';
    assert.strictEqual(transform(md, 'html', html), html);
  });

  it('returns error for unsupported filetype', () => {
    const result = transform(md, 'unknown', 'content');
    assert.ok(result.includes('not support'));
    assert.ok(result.includes('unknown'));
  });

  it('respects hardLineBreak option', () => {
    const input = 'line1\nline2';
    const soft = transform(md, 'markdown', input, { hardLineBreak: false });
    const hard = transform(md, 'markdown', input, { hardLineBreak: true });
    assert.ok(!soft.includes('<br'));
    assert.ok(hard.includes('<br'));
  });

  it('renders subscript', () => {
    const result = transform(md, 'markdown', 'H~2~O');
    assert.ok(result.includes('<sub>2</sub>'));
  });

  it('renders superscript', () => {
    const result = transform(md, 'markdown', 'x^2^');
    assert.ok(result.includes('<sup>2</sup>'));
  });

  it('renders footnotes', () => {
    const input = 'Text[^1]\n\n[^1]: Footnote content';
    const result = transform(md, 'markdown', input);
    assert.ok(result.includes('footnote'));
  });

  it('renders definition lists', () => {
    const input = 'Term\n:   Definition';
    const result = transform(md, 'markdown', input);
    assert.ok(result.includes('<dt>'));
    assert.ok(result.includes('<dd>'));
  });

  it('renders checkboxes', () => {
    const input = '- [x] done\n- [ ] todo';
    const result = transform(md, 'markdown', input);
    assert.ok(result.includes('checkbox'));
  });
});
