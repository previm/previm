'use strict';

const markdownit = require('markdown-it');
const markdownitAbbr = require('markdown-it-abbr');
const markdownitDeflist = require('markdown-it-deflist');
const markdownitFootnote = require('markdown-it-footnote');
const markdownitSub = require('markdown-it-sub');
const markdownitSup = require('markdown-it-sup');
const markdownitCheckbox = require('markdown-it-checkbox');
const markdownitCjkBreaks = require('markdown-it-cjk-breaks');

function createMarkdownRenderer() {
  return markdownit({html: true, linkify: true})
    .use(markdownitAbbr)
    .use(markdownitDeflist)
    .use(markdownitFootnote)
    .use(markdownitSub)
    .use(markdownitSup)
    .use(markdownitCheckbox)
    .use(markdownitCjkBreaks);
}

function hasTargetFileType(filetype, targetList) {
  const ftlist = filetype.split('.');
  for (let i = 0; i < ftlist.length; i++) {
    if (targetList.indexOf(ftlist[i]) > -1) {
      return true;
    }
  }
  return false;
}

function normalizeBaseUrl(baseUrl, protocol) {
  if (/^\/\//.test(baseUrl)) {
    return protocol + baseUrl;
  }
  return baseUrl;
}

function isRelativeUrl(url) {
  return !/^(?:[a-z][a-z0-9+.-]*:|\/\/|#|\/)/i.test(url);
}

function transform(md, filetype, content, options) {
  options = options || {};

  if (hasTargetFileType(filetype, ['mermaid', 'mmd'])) {
    content = '```mermaid\n'
            + content.replace(/</g, '&lt;')
                     .replace(/>/g, '&gt;')
            + '\n```';
    filetype = 'markdown';
  }

  if (hasTargetFileType(filetype, ['markdown', 'mkd'])) {
    content = content
      .replace(/^---\s*\n((?:[^\n]+\n)*)---\s*\n/, '```yaml\n$1```\n')
      .replace(/^\+\+\+\s*\n((?:[^\n]+\n)*)\+\+\+\s*\n/, '```toml\n$1```\n');
    if (options.hardLineBreak) {
      md.set({ breaks: true });
      md.disable('cjk_breaks');
    } else {
      md.set({ breaks: false });
      md.enable('cjk_breaks');
    }
    return md.render(content);
  } else if (hasTargetFileType(filetype, ['html'])) {
    return content;
  } else if (hasTargetFileType(filetype, ['textile'])) {
    return 'textile-not-supported-in-node';
  } else if (hasTargetFileType(filetype, ['asciidoc'])) {
    return 'asciidoc-not-supported-in-node';
  }
  return 'Sorry. It is a filetype(' + filetype + ') that is not support<br /><br />' + content;
}

module.exports = {
  createMarkdownRenderer,
  hasTargetFileType,
  normalizeBaseUrl,
  isRelativeUrl,
  transform,
};
