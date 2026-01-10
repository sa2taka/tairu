# tiler

macOS 用ウィンドウレイアウト保存・復元 CLI ツール

## 要件

- macOS 15+
- Xcode 16+
- [Mint](https://github.com/yonaskolb/Mint)

## セットアップ

```bash
# Mint をインストール
brew install mint

# SwiftLint / SwiftFormat をインストール
mint bootstrap
```

## 開発コマンド

```bash
# ビルド
swift build

# テスト
swift test

# フォーマット
./scripts/format.sh

# lint チェック
./scripts/lint.sh
```
