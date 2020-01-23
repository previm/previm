[README in English](https://github.com/previm/previm/blob/master/README-en.mkd)

## Previm

[![TravisCI](https://travis-ci.org/previm/previm.svg?branch=master)](https://travis-ci.org/previm/previm) [![AppVeyor](https://ci.appveyor.com/api/projects/status/r12pom6aaiom3kqy?svg=true)](https://ci.appveyor.com/project/mattn/previm)


プレビュー用のVimプラグインです。  

![previm](https://raw.github.com/wiki/previm/previm/images/previm-example.gif)

## 対応フォーマット

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
* reStructuredText
* textile
* AsciiDoc

## 依存

### 変換のため

Markdownとtextileの場合は必須なものはありません。  
reStructuredTextの場合は`rst2html.py`が必要です。  
`docutils`をインストールすると`rst2html.py`コマンドが使えるようになります。

    % pip install docutils
    % rst2html.py --version
    rst2html.py (Docutils 0.12 [release], Python 2.7.5, on darwin)

### プレビューを開くため

必須なものはありません。  
[open-browser.vim](https://github.com/tyru/open-browser.vim)は任意で使用できます。


## 使い方(Markdownの場合)

1. .vimrc にて `g:previm_open_cmd` を定義します
    * この値はコマンドラインから実行できるコマンドです
    * たとえばMacなら `open -a Safari` などです
    * `:help g:previm_open_cmd` を参照してください
    * open-browserを使う場合は設定不要です
2. `filetype` がMarkdownのファイルの編集を開始します
3. `:PrevimOpen` を実行してブラウザを開きます
4. 元のVimバッファに戻り編集を続けます
5. 変更の度にブラウザの表示内容が更新されます

Safari13.0.3ではブラウザが「Loading...」のままで止まってしまうことが報告されています

previmを動作させるために以下の設定をしてください

1. メニューバーの Safari > 環境設定 > 詳細 > メニューバーに"開発"メニューを表示にチェック
2. メニューバーの 開発 > ローカルファイルの制限を無効にする を選択

### mermaid

[mermaid](http://knsv.github.io/mermaid/)に対応しています。

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

[PlantUML](https://github.com/plantuml/plantuml) に対応しています。

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
