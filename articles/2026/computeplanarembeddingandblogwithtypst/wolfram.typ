#import "/template/template.typ": *
#show: show_blog_with_typst
= Wolfram Languageを使って、グラフの平面埋め込みを求めてみよう

@planar-graphs によると、Wolfram Languageというものを使って、グラフの平面埋め込みを求めることができる。したがって、今回はWolfram Languageを用いてグラフの平面埋め込みができるか判定し、できるのであれば、その埋め込みの一例を求めてみる。
== 環境の準備
まず、Wolfram Languageの実行環境を用意する。これには、公式サイトのPlayground(#link("https://www.wolfram.com/language/#playground"))にアクセスする,Wolfram CloudのNotebook(#link("https://www.wolframcloud.com/"))を使う、もしくはWolfram Engine(#link("https://www.wolfram.com/engine/"))をダウンロードする必要がある。
=== Playground(必要最小限)
Playgroundを使用した場合は、コードをブロックに書いて、右端のRunを押せば実行できる。実行例を@playgroundexample に示す。

#figure(caption: "実行例", image("asset/playgroundexample.png"))<playgroundexample>

=== Wolfram CloudのNotebook(推奨)
(#link("https://www.wolframcloud.com/"))にアクセスし、ログインする（アカウントがなければ作成する）。すると次の@cloud のような画面に遷移する。

#figure(caption: "クラウドの画面", image("asset/cloud.png"))<cloud>

New Notebookを押し、左側の画面にコードを貼りつける。Shift+Enter(もしくは上のEvaluation）で実行する。
#figure(caption: "クラウドでの実行結果", image("asset/rancloud.png"))<rancloud>
=== ローカル環境(Wolfram Engine)(玄人向け)
Wolfram Engineを使用する場合は、@How-do-I-set-up-the-Wolfram-Engine を参考にしながら進めると良い。ここでは、それに従いながら、@How-do-I-set-up-the-Wolfram-Engine に書かれていないもう少し先(VS Code用拡張機能の導入)までを説明する。

まず最初に、Wolfram Engineをダウンロードしなければならない。したがって、公式サイト(#link("https://www.wolfram.com/engine/"))からWolfram Download Managerをダウンロードし起動する。ダウンロードボタンを押した後もまだ公式サイトは閉じないこと。（次のステップで戻ってくる）私はWindows 10(21H2)+用のバージョン15.0のWolfram Download Managerをダウンロードした。（別のパッケージマネージャーを使う方法もある）そのダウンロードしたインストール用exeファイルを起動後、Wolfram Engineのダウンロードが始まるのだが、普通に2.16GB分のダウンロードを要求されるので、ディスク残量と次の予定の時間には注意しておくこと。

この間に、Wolfram Engineを使うのに必要なライセンス(License)を取得する。先ほどの公式サイトに戻ると、ページの内容が変化しており、次の@tolicense のようなページになる。ページ中央のGet your licenseボタンを押すと、別のページ(#link("https://account.wolfram.com/access/wolfram-engine/free"))に遷移する。Wolfram IDを作成するよう要求されるので作成する。（持っている場合はログインしておく）

するとこのページ(@getlicense)に遷移するはず（もし遷移しなければ、#link("https://account.wolfram.com/access/wolfram-engine/free に手動で移動する") ）なので、利用規約に同意しGet licenseを押す。
#figure(caption: "ダウンロードボタンを押した後のページ", image("asset/tolicense.png"))<tolicense>
#figure(caption: "利用規約同意画面", image("asset/getlicense.png"))<getlicense>
次にWolfram Download Managerのウィンドウに戻り、（ダウンロードが終わるのを待って、）Wolfram Engineをウィンドウ内のボタンから起動しセットアップを実行する。今度はさらに7GBくらい要求されるので、暇つぶしできるものを用意しておくこと。

ダウンロード後、ようやくWolfram Engineが起動する。（起動しない場合は Wolfram Scriptを検索して手動で起動する）@enterid のような画面が開き、今度はWolfram ID(email)とそのpasswordを要求されるので、頑張って入力する。

#figure(caption: "ID入力画面", image("asset/enterid.png"))<enterid>

入力し終えると、ようやくWolfram EngineがActivatedになり、使えるようになる。#footnote("このタイミングで、私の環境だとなぜかCTRL+Cでペーストから、右クリックでペーストに突然なったので、注意してください。")
ここまでが @How-do-I-set-up-the-Wolfram-Engine の内容である。

さてWolfram Engineをどう使えばいいのかだが、PlaygroundやNotebookとは異なり、コマンドライン上でそのまま例をコピーしてもグラフを描画してくれない。したがってさらに外部ツールを用いる必要がある。今回はVSCode上にWolfram Language拡張機能(WolframResearch.wolfram, @wolfram-extension )をインストールする。@wolfram-extension に示されているように、同じ名前の拡張機能が複数あるので、Wolfram Researchが提供しているものを選ぶ。

#figure(caption: "VSCodeのWolfram用拡張機能", image("asset/wolframextension.png"))<wolfram-extension>

本来はこの拡張機能をインストールすれば自動的にWolfram Engineの場所を見つけてくれるはずだが、私の環境では上手くいかずエラーが出た#footnote("Kernel is not found in the default location. Either change \"System Kernel\" in the configuration or Download Wolfram Engine for kernel support.")ので、手動で設定する。

Wolfram: System Pathを`C:\Program Files\Wolfram Research\Wolfram Engine\15.0`に設定しなおす。そして、再起動するとVSCode内でWolfram Languageを使えるようになる。

拡張機能が準備できたので、適当なファイル名でファイルを作り、拡張子を`.vsnb`にする。（`planarity.vsnb`とか）そして、そのファイルを開くと@notebooklocal のように表示される。

#figure(caption: "VSCodeで開かれた.vsnbファイル", image("asset/notebooklocal.png"))<notebooklocal>

上部中央の+Codeを押す。そして、コードを貼って左端の三角形を押すと実行される。実行結果は@ranlocal のようになる。

#figure(caption: "ローカル環境での実行結果", image("asset/ranlocal.png"))<ranlocal>

== 実際に平面埋め込みを書く

// Wolfram Languageでどのようにグラフを扱うかは(#link("https://reference.wolfram.com/language/#GraphsAndNetworks"))を参照すると良い。

まずは、あえて平面埋め込みできないグラフ、$K_5$（頂点数5の完全グラフ）を平面埋め込みさせてみる。

このグラフはWolfram Language側のプリセットとして`CompleteGraph[頂点数]`という形ですでに用意されている。(@wolfram-CompleteGraph を参照)というわけで実際に埋め込みを試みる。

実行コード:
```wolframalpha
g = CompleteGraph[5]
PlanarGraph[EdgeList[g]]
```
実行結果:
#image("asset/K_5.png")
PlanarGraph::nplanar: Graph[{1  2, 1  3, 1  4, 1  5, 2  3, 2  4, 2  5, 3  4, 3  5, 4  5}] is not a planar graph.

ちょっと文字化けしているけれども、しっかりとエラーが出て平面埋め込みできなかった。

最後に、適当なグラフの平面埋め込みを表示させる。結果は@grid-2-3-2 に示す。

実行コード:
```wolframalpha
{GridGraph[{2,3,2}],PlanarGraph[EdgeList[GridGraph[{2,3,2}]]]}
```

#figure(
  caption: "適当なグラフの平面埋め込み（左のグラフを右で平面埋め込みしている）",
  image("asset/grid-2-3-2.png"),
)<grid-2-3-2>

#bibliography("bibliography.yaml")

#include "typst-html.typ"
