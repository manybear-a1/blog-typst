Ankiにpdfを取り込みたい。pdfのまま取り込む方法もあるにはあるが、そのままだと検索や編集が大変なので、OCRをしてテキスト化して取り込みたい。しかし、ただのOCRでは数式が図が認識できないので、普通のOCRではなく、数式や図も認識できるつよいOCRがいる。

まずは適当に"OCR math"とかで検索してみると、いくつかのOCR用のモデルが見つかる。今回はUnlimitedOCRというモデルを使ってみる。UnlimitedOCRは数式や図も認識できる強力なOCRモデルで、オープンウェイトである。#link("https://huggingface.co/baidu/Unlimited-OCR")[UnlimitedOCR on Hugging Face]からダウンロードできる。

今回はColaboratory上で実行したいので、誰か別の人が既にColaboratory用のノートブックを作ってくれているかもしれないので、まずは検索してみる。#link("https://github.com/ocean-master0/unlimited-ocr-colab")[unlimited-ocr-colab]というリポジトリが見つかったので、これを使うことにする。

今回OCRするpdfは、#link("https://www.cambridge.org/core/services/aop-cambridge-core/content/view/18A13702FF264BBA3894B55E01832976/S0956796897002840a.pdf/a-functional-description-of-texs-formula-layout.pdf")[この論文]にする。
//v1

まずは一度ノートブックに従ってOCRを実行してみる。ここで、このモデルの重大な欠陥が判明する。なんと、OCRの結果をmarkdown形式に変換して出力してくれるのだが、その変換システムが本当にひどい。なんと、読み取り段階であったはずの、文章の種類（本文、見出し、脚注など）がすべて無視され、しかもすべてのテキストが一つの大きな段落として出力されてしまう。要するに、markdown形式に変換されるというのはほぼ嘘で、実際にはただのテキストとして出力されるだけである。さらに、この変換を阻止してくれるオプションもない。つまり、UnlimitedOCRを使うと、数式や図は認識できるが、文章の構造は完全に失われてしまうのである。#link("https://huggingface.co/baidu/Unlimited-OCR/discussions/18")[このディスカッション]でも同じ問題が報告されている。

しかし回避方法は一応あり、ターミナルに出力される返還前のOCR結果をリダイレクトして保存することで、文章の構造を保持したままOCR結果を取得することができる。（が、末尾に不必要な情報がついてしまうので、後で削除する必要がある。）

//v2

またノートブック側にも別の問題があり、OCRの結果を保存する際に、わざわざページごとに分けたり、図をすべて親切にも削除してくれる機能が付いていてこちらにも対処しなければならない。しかも図は変な場所に保存されるうえ、ページごとに0.png,1.png, 2.pngのように保存される（こっちはunlimited-ocrの仕様）なので、適当にまとめてしまうと、図の名前が変わりどの図がどのページのものか分からなくなってしまう。

どうやら複数ページ用には`infer`ではなく`infer_multi`という専用の関数が用意されているようなので、そちらを使うといいのかもしれない。

と思ったのだが、`infer_multi`を使うと、何故か結果が帰ってこず、ずっと計算していた。どうやら`infer_multi`はまだ不安定なようで、使うのはやめておいた方が良さそうだ。

とりあえず図を抽出するコードをGeminiに加えさせた。（改行の数が減ってしまったが、この修正は簡単）

//v3

ankiでcsvから画像を読み込む方法を調べようとしたらなんかankiのmanualのスタイルにアップデートが入っていた。内容は変わっていなさそう。

普通にimgタグで画像を読み込むことができるようだ。なので、csvに画像のパスを書いておけば、ankiに取り込む際に自動的に画像も取り込まれる。ということはmarkdownと画像をまとめてダウンロードして、穴埋め問題をcsvにまとめてしまえば、ankiに取り込む際に自動的に画像も取り込まれるということになる。

と、思っていたらなんとこのタイミングで別のOCRモデルがリリースされた。
#link("https://huggingface.co/datalab-to/indra-ocr")[Indra OCR]というモデルで1Mパラメータの軽量モデルで、数式が認識できるとても速いモデルらしい。これならColabに依存せずに動かせそう。ちょっと試したくなったので、早速試してみることにする。

ちょっと数式の認識も苦手なようだが（テキスト部分と数式部分の切り分けが上手くいかず、数式部分がテキストとして認識されてしまう）CPUでもとんでもなく速かった。UnlimitedOCRのように数式を正確に読んだり、図を認識したりすることはできないが、とにかく早いし、ライブラリがしっかりとしていてPythonから簡単に使えるので、複雑な数式や図の認識が必要ない場合はIndra OCRを使うのが良さそうだ。

```
Scripts outside the OCR list. OCR reads Latin, Cyrillic, Greek, Devanagari, Bengali and Chinese. Other scripts, including Arabic, Hebrew, Thai, Japanese kana and Korean Hangul, work only through a digital PDF's text layer. On scans and images they come out wrong; a Hangul line, for example, comes out as wrong Chinese characters.
```

よく注意書きを読んだら日本語に対応していなかった。ちょっと残念。（PDFのテキストレイヤーは読めるので、PDFのテキストレイヤーがある場合は日本語も読めるが、スキャンした画像からは日本語は読めない。数式内には日本語はあまり入らないので、日本語の文章でもどうにかなることもあるかもしれない）

とりあえず話を戻して、UnlimitedOCRの環境を整える続きをする。
