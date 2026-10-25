#!/usr/bin/env python3
"""Typst の記事を、はてなブログへ下書きとして投稿・更新する。

実処理は ``scripts/hatena_blog/`` 以下のモジュールに分割してある。
このファイルはコマンドラインから呼ぶための入口。

* 記事の抽出と投稿: ``hatena_blog.cli``
* はてなブログ AtomPub: ``hatena_blog.atom``
* 画像のアップロード: ``hatena_blog.fotolife`` / ``hatena_blog.images``
* Markdown モード向けの変換: ``hatena_blog.markdown_compat``
* 記事ごとの状態ファイル: ``hatena_blog.state``

使い方::

    # typ をコンパイルして下書き投稿（2 回目以降は同じ記事を更新）
    python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.typ \\
        --title "AIに例を与えて穴埋め問題を作らせた話"

    # API を叩かず、送信する XML を確認する
    python scripts/post_to_hatena.py articles/2026/anki-cloze/anki-cloze2.typ \\
        --title "..." --dry-run

    # 最近のエントリとメンバURIを見る
    python scripts/post_to_hatena.py --list
"""

from __future__ import annotations

import sys
from pathlib import Path

# スクリプトを直接実行したときも hatena_blog を import できるようにする。
sys.path.insert(0, str(Path(__file__).resolve().parent))

from hatena_blog.cli import main  # noqa: E402

if __name__ == "__main__":
    sys.exit(main())
