## Previm

[![TravisCI](https://travis-ci.org/previm/previm.svg?branch=master)](https://travis-ci.org/previm/previm) [![AppVeyor](https://ci.appveyor.com/api/projects/status/r12pom6aaiom3kqy?svg=true)](https://ci.appveyor.com/project/mattn/previm)

Vim plugin for preview.

### ScreenShot

![previm](https://raw.github.com/wiki/previm/previm/images/previm-example.gif)

## Supported file formats

* Markdown
    * [CommonMark](http://commonmark.org/)
    * [PHP markdown extra style abbreviation](https://github.com/markdown-it/markdown-it-abbr)
    * [Pandoc style definition list](https://github.com/markdown-it/markdown-it-deflist)
    * [Pandoc style footnote](https://github.com/markdown-it/markdown-it-footnote)
    * [Pandoc style subscript](https://github.com/markdown-it/markdown-it-sub)
    * [Pandoc style superscript](https://github.com/markdown-it/markdown-it-sup)
    * [East Asian Line Breaks](https://github.com/markdown-it/markdown-it-cjk-breaks)
    * [mermaid](http://knsv.github.io/mermaid/index.html)
    * [PlantUML](https://github.com/plantuml/plantuml).
* reStructuredText(required rst2html.py)
* textile
* AsciiDoc

## Dependencies

### For conversion

There is nothing essential in the case of textile and Markdown.  
`rst2html.py` is required in the case of reStructuredText.  
It will become available `rst2html.py` command when you install the `docutils.`

    % pip install docutils
    % rst2html.py --version
    rst2html.py (Docutils 0.12 [release], Python 2.7.5, on darwin)

### For open preview

No need for extra libraries or plug-ins.

It can, however, be integrated with [open-browser.vim](https://github.com/tyru/open-browser.vim). For detailed usages, please see below.

## Usage

1. Define `g:previm_open_cmd` in .vimrc
    * This command is used in terminal for opening your browser.
    * For example, uses Safari on Mac `let g:previm_open_cmd = 'open -a Safari'`
    * `:help g:previm_open_cmd` for more details
    * You can skip this setting if you're using open-browser.
2. Start editing the file of Markdown.(`filetype` is `markdown`)
3. Run `:PrevimOpen` to open browser to preview
4. Back to Vim to edit your file
5. Update the file, and the content for previewing will be updated automatically

To force a refresh run `:PrevimRefresh`. To clear the preview cache (in dir PLUGIN_INSTALL/preview) run `:PrevimWipeCache`.

There is an issue using Safari 13.0.3, which page transition stops after "Loading...".

You need to set up below to make previm work on Safari.

1. Safari > Preference > Advanced > check "Show develop menu" in menubar
2. Develop > Disable Local File Restrictions

### mermaid

Support [mermaid](http://knsv.github.io/mermaid/)

<pre>
```mermaid
graph TD;
    A-->B;
    A-->C;
    B-->D;
    C-->E;
```
</pre>

![previm](https://raw.github.com/wiki/previm/previm/images/previm-example-mermaid.png)

### PlantUML

Support [PlantUML](https://github.com/plantuml/plantuml).

<pre>
```plantuml
@startuml
Alice -> Bob: Authentication Request
Bob --> Alice: Authentication Response

Alice -> Bob: Another authentication Request
Alice <-- Bob: another authentication Response
@enduml
```
</pre>

![PlantUML preview](https://user-images.githubusercontent.com/546312/72982432-6acf4480-3e22-11ea-856e-4d0042452539.png)
