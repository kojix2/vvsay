# vvsay

[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fkojix2%2Fvvsay%2Flines)](https://tokei.kojix2.net/github/kojix2/vvsay)
[![build](https://github.com/kojix2/vvsay/actions/workflows/build.yml/badge.svg)](https://github.com/kojix2/vvsay/actions/workflows/build.yml)

VOICEVOX Engine の API を呼び出すための Crystal 製 CLI ツール。

このツールは作りかけなので、プロジェクトの名前からオプションまでコロコロ変わる可能性があります。

## 必要条件

- [VOICEVOX Engine](https://github.com/VOICEVOX/voicevox_engine) がインストールされ、起動していること

## インストール

### GitHub Release からバイナリを入手

右の[Release](https://github.com/kojix2/vvsay/releases)からダウンロード

※ MacOS版は動的リンクが決め打ちなので自分でビルドしないと動きません

### ソースからビルド

```bash
git clone https://github.com/kojix2/vvsay.git
cd vvsay
shards install
shards build --release
bin/vvsay --version
```

ビルドされた実行ファイル `vvsay` をパスの通った場所に配置してください。

## 使い方

### 話者一覧の表示

利用可能な話者（キャラクター）とそのスタイルの一覧を表示します：

```bash
vvsay speakers
```

### 音声合成

テキストから音声を合成します：

```bash
vvsay synthesis -t "こんにちは、世界" -s 1 -o output.wav
```

または：

```bash
vvsay -t "こんにちは、世界" -s 1 -o output.wav
```

### オプション

```
使用方法: vvsay <コマンド> [オプション]

コマンド:
    speakers                         speakers    利用可能な話者一覧を表示
    synthesis                        テキストから音声を合成
    query                            音声合成用クエリの操作

一般オプション:
    -t TEXT, --text=TEXT             合成するテキスト
    -s ID, --speaker=ID              話者ID (デフォルト: 1)
    -o FILE, --output=FILE           出力ファイル名 (デフォルト: output.wav)
    -S SCALE, --speed=SCALE          話速のスケール (デフォルト: 1.0)
    -T SCALE, --pitch=SCALE          音高のスケール (デフォルト: 0.0)
    -I SCALE, --intonation=SCALE     抑揚のスケール (デフォルト: 1.0)
    -V SCALE, --volume=SCALE         音量のスケール (デフォルト: 1.0)
    -P, --play                       音声合成後に自動再生する
    --host=HOST                      VOICEVOX Engine のホスト (デフォルト: 127.0.0.1)
    --port=PORT                      VOICEVOX Engine のポート (デフォルト: 50021)
    --stdin                          標準入力からテキストを読み込む
    --version                        バージョンを表示
    -d, --debug                      エラー時にバックトレースを表示
    -h, --help                       ヘルプを表示
```

## 開発

このツールは、kojix2 が自分で使うためにマイペースに作っています。
たまに使って、気が向いたらメンテナンスします。

1. リポジトリをクローンします
2. 依存関係をインストールします: `shards install`
3. コードを変更します
4. テストを実行します: `crystal spec`

## 貢献

1. フォークします (<https://github.com/kojix2/vvsay/fork>)
2. 機能ブランチを作成します (`git checkout -b my-new-feature`)
3. 変更をコミットします (`git commit -am 'Add some feature'`)
4. ブランチにプッシュします (`git push origin my-new-feature`)
5. プルリクエストを作成します

## ライセンス

[MIT](LICENSE)
