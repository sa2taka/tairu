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

### 常駐エージェント

ディスプレイが接続されたときに自動でレイアウトを適用します。

```bash
# フォアグラウンドで起動（デバッグ用）
tairu agent

# launchd に登録してバックグラウンド起動
tairu agent --install

# 状態確認
tairu agent --status

# launchd から解除
tairu agent --uninstall
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

## JSON スキーマ

```json
{
  "schemaVersion": 1,
  "targetDisplay": {
    "displayUUID": "37D8832A-2D66-02CA-B9F7-8F30A301B230"
  },
  "windows": [
    {
      "appBundleId": "com.apple.Safari",
      "titleMatch": {
        "exact": "Apple"
      },
      "frameNorm": {
        "x": 0.0,
        "y": 0.0,
        "w": 0.5,
        "h": 1.0
      },
      "indexHint": 0
    }
  ]
}
```

### フィールド説明

| フィールド | 型 | 説明 |
|-----------|------|------|
| `schemaVersion` | Int | スキーマバージョン（現在は 1） |
| `targetDisplay.displayUUID` | String | 対象ディスプレイの UUID |
| `windows` | Array | ウィンドウルールの配列 |

### WindowRule

| フィールド | 型 | 説明 |
|-----------|------|------|
| `appBundleId` | String | アプリの Bundle ID |
| `titleMatch` | Object? | タイトルマッチ条件（省略可） |
| `frameNorm` | Object | 正規化されたフレーム座標 |
| `indexHint` | Int? | 同一アプリの複数ウィンドウ識別用インデックス |

### TitleMatch

タイトルマッチは以下のいずれか：

```json
{ "exact": "完全一致するタイトル" }
```

```json
{ "regex": "正規表現パターン" }
```

### NormalizedFrame

座標はディスプレイの `visibleFrame` に対する相対値（0.0〜1.0）：

| フィールド | 説明 |
|-----------|------|
| `x` | 左端からの相対位置 |
| `y` | 上端からの相対位置 |
| `w` | 幅の比率 |
| `h` | 高さの比率 |

例：画面左半分に配置する場合 → `x: 0.0, y: 0.0, w: 0.5, h: 1.0`

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
