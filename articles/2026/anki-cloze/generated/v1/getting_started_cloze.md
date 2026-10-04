# MathML を始めよう: Anki Cloze カード

Anki の「Cloze」ノートタイプで使用してください。各コードブロック内の 1 行が 1 ノートです。

## 基本

```text
MathML の数式を HTML 文書に挿入する要素は {{c1::<math>}} である。
```

```text
MathML は HTML と同じく、{{c1::要素と属性のツリー}}で構文を表す。
```

```text
分数を表す MathML 要素は {{c1::<mfrac>}} である。
```

```text
<mfrac> 要素では、{{c1::最初の子要素}}が分子、{{c2::2 つ目の子要素}}が分母になる。
```

```html
<!-- 1/3 を表す MathML -->
<math>
  <mfrac>
    <mn>{{c1::1}}</mn>
    <mn>{{c2::3}}</mn>
  </mfrac>
</math>
```

```text
MathML の数式を段落内のテキストと同じ行に表示する状態を、{{c1::インライン数式}}という。
```

```text
<math> 要素を独立したブロックとして表示するには、{{c1::display="block"}} 属性を付ける。
```

```text
<math display="block"> を使うと、数式は通常、{{c1::中央揃え}}で表示される。
```

```text
<math display="block"> では、数式の読みやすさを優先するため、インライン表示より{{c1::縦の空間}}が大きくなる。
```

```text
MathML の display="block" は、LaTeX の {{c1::\\[...\\]}} で囲む表示数式に対応する。
```

```text
MathML のインライン表示は、LaTeX の {{c1::$...$}} で囲むインライン数式に対応する。
```

## グループ化

```text
<math> 要素は、基本的に複数の子要素を{{c1::一列に並べて}}表示する。
```

```text
MathML で「1 + 2 + 3」を表す演算子要素は {{c1::<mo>}} である。
```

```html
<math>
  <mn>1</mn>
  <mo>{{c1::+}}</mo>
  <mn>2</mn>
  <mo>+</mo>
  <mn>3</mn>
</math>
```

```text
<mrow> は、MathML のサブツリーを{{c1::グループ化}}する汎用コンテナーである。
```

```text
<mrow> は MathML のサブツリーの{{c1::どこにでも}}配置できる。
```

```html
<!-- (1 + 2) / 3 を表す MathML -->
<math>
  <mfrac>
    <mrow>
      <mn>1</mn>
      <mo>+</mo>
      <mn>2</mn>
    </mrow>
    <mn>{{c1::3}}</mn>
  </mfrac>
</math>
```

```text
上の分数で、分子「1 + 2」をまとめている要素は {{c1::<mrow>}} である。
```

## 数値要素

```text
MathML で数値を表す要素は {{c1::<mn>}} である。
```

```text
MathML で演算子（+, -, = など）を表す要素は {{c1::<mo>}} である。
```

```text
MathML のテキスト要素には、数値用の {{c1::<mn>}} と演算子用の {{c2::<mo>}} がある。
```

## 入れ子になった式

```html
<!-- 1/2 + 2/3 -->
<math>
  <mfrac>
    <mn>{{c1::1}}</mn>
    <mn>2</mn>
  </mfrac>
  <mo>+</mo>
  <mfrac>
    <mn>2</mn>
    <mn>{{c2::3}}</mn>
  </mfrac>
</math>
```

```text
「1 + 2 + 3」が「4 + 5」の上にある分数では、分子と分母をそれぞれ {{c1::<mrow>}} でグループ化する。
```

```html
<!-- (1 + 2 + 3) / (4 + 5) -->
<math>
  <mfrac>
    <mrow>
      <mn>1</mn><mo>+</mo><mn>2</mn><mo>+</mo><mn>3</mn>
    </mrow>
    <mrow>
      <mn>4</mn><mo>+</mo><mn>5</mn>
    </mrow>
  </mfrac>
</math>
```

```text
分数の中にさらに分数を入れることを、MathML の {{c1::入れ子}}と呼ぶ。
```

```html
<!-- (1/4) / (2 + 3) -->
<math>
  <mfrac>
    <mfrac>
      <mn>1</mn>
      <mn>4</mn>
    </mfrac>
    <mrow>
      <mn>2</mn><mo>+</mo><mn>3</mn>
    </mrow>
  </mfrac>
</math>
```

## CSS と互換性

```text
<math display="block"> などによる数式の外観の変化は、CSS の {{c1::math-style}} プロパティで制御される。
```

```text
math-style の初期値は、display="block" の場合は {{c1::normal}}、それ以外では {{c2::compact}} である。
```

```text
MathML に対応していないブラウザーでは、分数が「1 3」のように表示されることがある。
```

## まとめ

```text
この記事で扱った主要な MathML 要素は、数式の外枠が {{c1::<math>}}、分数が {{c2::<mfrac>}}、グループ化が {{c3::<mrow>}} である。
```

```text
次に詳しく扱う MathML の要素群は {{c1::テキストコンテナー}}である。
```
