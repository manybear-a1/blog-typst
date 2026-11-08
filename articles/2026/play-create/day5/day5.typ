
//コード表示
// raw(block:true)を指定しないとレンダリングされないことに注意すること。
// 現時点(2026/10/25,codly:2.0.0)では、codlyはHTML出力に対応していなかった。
// #import "@preview/codly:2.0.0" as codly
// #import "@preview/codly-languages:0.1.8": codly-languages
// #show: codly.lang-set_(languages: codly-languages)
// #show raw.where(block: true): codly.new

//ブログ用テンプレートの読み込み
#import "/template/template.typ": *
//タイトル
#show: it => show_blog_with_typst(it, title: "Create 日記 Day4")
//自動小麦収穫機
