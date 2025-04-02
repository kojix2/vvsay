# zunsay（仮）

VOICEVOX Engine の API を呼び出すための Crystal 製 CLI ツール。

このツールは作りかけなので、プロジェクトの名前からオプションまでコロコロ変わる可能性があります。

## 必要条件

- [VOICEVOX Engine](https://github.com/VOICEVOX/voicevox_engine) がインストールされ、起動していること

## インストール

### ソースからビルド

```bash
git clone https://github.com/kojix2/zunsay.git
cd zunsay
shards install
shards build --release
bin/zunsay --version
```

ビルドされた実行ファイル `zunsay` をパスの通った場所に配置してください。

## 使い方

### 話者一覧の表示

利用可能な話者（キャラクター）とそのスタイルの一覧を表示します：

```bash
zunsay speakers
```

### 音声合成

テキストから音声を合成します：

```bash
zunsay synthesis -t "こんにちは、世界" -s 1 -o output.wav
```

または：

```bash
zunsay -t "こんにちは、世界" -s 1 -o output.wav
```

### オプション

```
使用方法: zunsay [オプション] [コマンド]

コマンド:
  speakers    - 利用可能な話者一覧を表示
  synthesis   - テキストから音声を合成 (デフォルト)

共通オプション:
  -h HOST, --host=HOST       VOICEVOX Engine のホスト (デフォルト: 127.0.0.1)
  -p PORT, --port=PORT       VOICEVOX Engine のポート (デフォルト: 50021)

音声合成オプション:
  -t TEXT, --text=TEXT       合成するテキスト
  -s ID, --speaker=ID        話者ID (デフォルト: 1)
  -o FILE, --output=FILE     出力ファイル名 (デフォルト: output.wav)

その他:
  --help                     ヘルプを表示
  --version                  バージョンを表示
```

## 開発

このツールは、kojix2 が自分で使うためにマイペースに作っています。
たまに使って、気が向いたらメンテナンスします。

1. リポジトリをクローンします
2. 依存関係をインストールします: `shards install`
3. コードを変更します
4. テストを実行します: `crystal spec`

## 貢献

1. フォークします (<https://github.com/kojix2/zunsay/fork>)
2. 機能ブランチを作成します (`git checkout -b my-new-feature`)
3. 変更をコミットします (`git commit -am 'Add some feature'`)
4. ブランチにプッシュします (`git push origin my-new-feature`)
5. プルリクエストを作成します

## ライセンス

[MIT](LICENSE)
