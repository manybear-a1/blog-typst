
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
#show: it => show_blog_with_typst(it, title: "Create 日記 Day3")

= Create 日記 Day3
今日はアイアンファーム（鉄生産装置）を作る続きをするよ！
#figure(
  image("img/2026-11-05_19.45.23.png"),
  caption: "歯車を使って回転速度を上げる図",
)

前回、ふるいに砂利を投入してふるいにかけて鉄塊を作るところまでやった。今回はその続きとして、砂利も自動で供給されるようにして、アイアンファームを完成させる。

Createで砂利を作るには、まず、丸石を作って、その丸石をミルにかける必要がある。Createで丸石を作るためには、マグマと水、そして採掘用のドリルが必要だ。

ドリルを作成するには、安山岩合金三つと、鉄一つとあとは安山岩ケーシングで十分だ。レシピのスクショを取り忘れたので、レシピは#link("https://create.fandom.com/wiki/Mechanical_Drill")[Mechanical DrillのCreate Wikiページ]を見てください。

さて、次はマグマを探そう。近くにはないので、今回は地下に探しに行く。
#image("img/2026-11-05_19.48.28.png")
今回はFTB Ultimineを入れているのでシフトを押しながらホイールを回すことで、一括破壊のモードを変えることができる。Mining Tunnelモードにすると、斜め下に向かって階段状に掘ることができるので、今回はこのモードを使って地下に掘り進める。

#image("img/2026-11-05_19.52.44.png")
（ここに途中で作った全く関係のない畑の画像を挿入する）
#image("img/2026-11-05_19.56.17.png")
掘っていく途中でアメジストジオードを発見した。Createでアメジストを使うレシピがあった気がしないでもないので一応回収しておく。
#image("img/2026-11-05_20.06.30.png")
何の成果も！！得られませんでした！！
