# tairu

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

# ビルド
swift build
```

## 使い方

### 初回設定

アクセシビリティ権限が必要です。初回実行時に許可を求められるか、以下で確認できます：

```bash
tairu doctor
```

権限がない場合は「システム設定 > プライバシーとセキュリティ > アクセシビリティ」で tairu を許可してください。

### ディスプレイ一覧を確認

```bash
tairu displays
```

出力例：
```
Built-in Retina Display
  UUID: 37D8832A-2D66-02CA-B9F7-8F30A301B230
  Frame: 0,0 1800x1169
  Visible: 0,0 1800x1125
```

### レイアウトを保存

```bash
# 指定ディスプレイの現在のウィンドウ配置を保存
tairu save --display <UUID> --name <レイアウト名>

# 例
tairu save --display 37D8832A-2D66-02CA-B9F7-8F30A301B230 --name work

# 既存のレイアウトを上書き
tairu save --display <UUID> --name <レイアウト名> --force

# 何が保存されるか確認（実際には保存しない）
tairu save --display <UUID> --name <レイアウト名> --dry-run
```

### 保存済みレイアウト一覧

```bash
tairu layouts
```

### レイアウトを適用

```bash
# 保存したレイアウトを適用（保存時のディスプレイに適用）
tairu apply --name <レイアウト名>

# 別のディスプレイに適用
tairu apply --display <UUID> --name <レイアウト名>

# 何が適用されるか確認（実際には適用しない）
tairu apply --name <レイアウト名> --dry-run
```

### レイアウトを削除

```bash
tairu delete --name <レイアウト名>
```

### 環境診断

```bash
tairu doctor
```

アクセシビリティ権限、ディスプレイ情報、検出可能なウィンドウ数、保存済みレイアウトを確認できます。

## 保存先

レイアウトは以下に JSON 形式で保存されます：

```
~/Library/Application Support/tairu/layouts/<name>.json
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
