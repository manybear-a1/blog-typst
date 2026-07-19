
= おまけ:Typstでブログを書きたい！！！！
Typstを私はLaTeXの代替として愛用している。しかし、はてなブログはLaTeXしかサポートしていないし、Typstがサポートしている他の書き出し形式はpdf,pngとsvgしかない。画像データで出力してブログにするのはさすがに論外である。そうなると、困ってしまってわんわんわわん　わんわんわわん。

== 救世主現る。その名は#emph("Typst 0.13")。

しかし、およそ一年半前、Typst 0.13がリリースされた。それは黒船であった。pdf,png,svgがさながら三国志のように争いながら鎖国体制を築いていた、我らが島Typstに、HTMLという新しい国がやってきたのである。

=== 黒船、いきなり沈む。

さてでは実際にHTMLに書き出してみよう。適当なサンプルデータ（@sample） を用意したので、そのデータを実際にTypst 0.13でPDF(@output-pdf)とHTML(@output-html)で書き出してみる。
#figure(caption: "サンプルデータ", raw(read("asset/sample.typ"), lang: "typst", block: true))<sample>
#figure(caption: "PDFでの出力結果", image("asset/sample.pdf"))<output-pdf>
#figure(caption: "HTMLでの出力結果", image("asset/sample.png"))<output-html>

そう、このHTML出力は実験的な機能なので、まだ数式や図が上手く出力できないのである。というわけで黒船は沈みましたとさ。ちゃんちゃん。
=== 黒船、復活。
ところがどっこい。およそ半年前くらいにリリースされた0.15から実はHTML出力が数式に対応した。ちゃんと画像形式ではなくMathML形式で出力されるため、構文情報を失わずにHTML化できる。え？じゃあなんで一回失敗したのかって？そんなの筆者が怠惰でTypstのバージョンを更新していなかったからに決まっているじゃあないか。何を言っとるんだね君は。しかし今の段階でも、図の出力はまだ上手くいかない。そこで、今回は図の部分だけSVGでレンダリングするという回避策を用いてとりあえずなんとかした。#footnote([具体的には`html.frame(cetz.canvas(...))`とすることで、cetz.canvasの出力をSVGに変換してHTMLに埋め込むことができる。なお、普通にpngを読み込んでいる場合はこの回避策を用いる必要はなく、そのまま`image("path/to/image.png")`とすればよい。ただ、画像ファイルの中身をimageタグに埋め込む形で出力されるので、人によっては好ましくない場合があるかもしれない。])
#figure(caption: "HTMLでの出力結果その2", image("asset/sample2.png"))<output-html2>

== できた！
というわけで、HTML出力ができるようになったので、このままブログにして公開します。タイトルは「Wolfram Languageで平面描画を求め、Typstで結果をブログにしてみよう！」にしておきましょうか！
