#let show_blog_with_typst(body) = context {
  set text(lang: "jp")
  // ここにcontextを二重につけてはいけない。
  show image: it => {
    if target() == "html" {
      // TODO:Typst 1.50では、デフォルト動作では画像データ自体をHTMLのimgタグのsrc属性に埋め込む仕様になっている。
      // これを回避しているのだが、渡されたsourceをそのままimgタグに埋め込む以外の方法がないため、フォルダー内に別のtypstファイルがあって、それをincludeしている場合などに、相対パスの位置が変わり時々壊れる。
      // https://typst.app/docs/reference/foundations/path/ pathをstringに戻せれば、imgタグにstr(path(it.source))のようにして渡すことで相対パスの位置を正しく計算できるの可能性があるが、現状ではそれも不可能なので、仕方なくsourceをそのままimgタグに埋め込む仕様にしている。]
      if (it.source.ends-with(".pdf")) {
        // PDFを埋め込む場合はembedタグを使う。embedタグはPDFを埋め込むことができるが、imgタグでパスを指定してもPDFを埋め込むことはできない。
        html.elem("embed", attrs: (
          src: it.source,
          style: "max-width: 100%; height: auto;",
        ))
      } else {
        html.elem("img", attrs: (src: it.source, style: "max-width: 100%; height: auto;"))
      }
    } else {
      it
    }
  }
  // TODO:html,headやbodyタグを消したいが、Typst 1.50では不可能そうなので応急処置として、そのまま張り付けると背景が真っ赤になって、警告されるようにしておく。背景が赤いと、ブログのHTML構造が崩れていることが一目でわかるので、Typstで書き出したHTMLの中身とstyleタグだけを取り出して、ブログに貼り付ける必要があることを思い出せるはず。
  if target() == "html" {
    html.elem("div", attrs: (id: "takehere", style: "background: red"))[
      #html.elem(
        "h1",
      )[警告:このTypstで書き出したHTMLはdiv\#takehereの中身とstyleタグだけを取り出して、ブログに貼り付ける必要があります。]
      #body

      この記事はTypst 1.50の実験的なHTML出力機能を用いて生成されました。

      ソースコードのリポジトリは#link("https://github.com/manybear-a1/blog-typst", "こちら")

      // 現時点では生成元のTypstファイル名の自動取得は不可能(https://github.com/typst/typst/discussions/2295)
      // 生成元のTypstファイル名は

    ]
  } else {
    body
  }
}
