# macOS Window Layout Tiler (Swift) — Coding Agent Task

## 目的

macOS 上で以下を満たす CLI ツールを Swift で実装する。

- 特定の **ディスプレイのみ** に属するウィンドウ配置を保存できる
- CLI から保存済みの配置パターンを **再現（apply）** できる
- 実装は Swift / SwiftPM を用いる
- アクセシビリティ（AX）API を使用する
- 後続で常駐 Agent を足せる構造にする（今回は CLI まで）

## 非目的（今回やらない）

- 自動タイルアルゴリズム（BSP 等）
- GUI
- App Store 配布対応
- フルスクリーンウィンドウの操作

---

## ディレクトリ / モジュール設計

### SwiftPM 構成

```
tiler/
├─ Package.swift
├─ Sources/
│  ├─ TilerCLI/              # executable
│  │  ├─ main.swift
│  │  ├─ Commands/
│  │  │  ├─ DoctorCommand.swift
│  │  │  ├─ DisplaysCommand.swift
│  │  │  ├─ SaveCommand.swift
│  │  │  └─ ApplyCommand.swift
│  │  └─ CLIModels.swift
│  │
│  └─ TilerCore/             # library
│     ├─ Domain/
│     │  ├─ Display.swift
│     │  ├─ Window.swift
│     │  ├─ Layout.swift
│     │  └─ Errors.swift
│     │
│     ├─ Services/
│     │  ├─ DisplayService.swift
│     │  ├─ AXService.swift
│     │  ├─ WindowQueryService.swift
│     │  └─ LayoutStore.swift
│     │
│     └─ Engine/
│        ├─ WindowMatcher.swift
│        └─ LayoutEngine.swift
│
└─ Tests/
   └─ TilerCoreTests/
      ├─ LayoutEngineTests.swift
      ├─ WindowMatcherTests.swift
      └─ DisplayNormalizationTests.swift
```

---

## ドメイン設計

### Display

```swift
struct Display {
  let uuid: String
  let name: String?
  let frame: CGRect
  let visibleFrame: CGRect
}
```

### WindowSnapshot

```swift
struct WindowSnapshot {
  let appBundleId: String
  let title: String?
  let frame: CGRect
  let isMinimized: Bool
}
```

### Layout（保存フォーマット）

```swift
struct Layout: Codable {
  let schemaVersion: Int
  let targetDisplay: TargetDisplay
  let windows: [WindowRule]
}

struct TargetDisplay: Codable {
  let displayUUID: String
}

struct WindowRule: Codable {
  let appBundleId: String
  let titleMatch: TitleMatch?
  let frameNorm: NormalizedFrame
  let indexHint: Int?
}

struct NormalizedFrame: Codable {
  let x: Double
  let y: Double
  let w: Double
  let h: Double
}
```

---

## コア仕様

### DisplayService

- ディスプレイ一覧取得
- UUID / visibleFrame を提供
- window frame から「所属ディスプレイ」を判定（交差面積最大）

### AXService

- アクセシビリティ権限の有無チェック
- ウィンドウ一覧取得（全アプリ）
- window の position / size 設定

### Save

- 指定 display に属する window のみ対象
- visibleFrame を基準に frame を正規化して保存
- JSON を `~/Library/Application Support/tiler/layouts/<name>.json` に書く

### Apply

- layout 読み込み
- 現在の window 一覧を取得
- WindowRule と実 window をマッチ
- 正規化 frame → 実座標に変換して適用
- 見つからない window はスキップ

---

## CLI 設計

### Commands

#### `tiler doctor`

- AX 権限有無
- ディスプレイ一覧
- 検出可能 window 数

#### `tiler displays`

- display UUID / name / visibleFrame

#### `tiler save --display <uuid> --name <layout>`

#### `tiler apply --display <uuid> --name <layout>`

> 全コマンドに `--dry-run` オプション対応

### エラーポリシー

- **権限不足** → 明示的エラーメッセージ + exit code
- **display 不在** → display 一覧を出して終了
- **window 操作失敗** → 続行して最後に警告表示

---

## テスト方針（Unit Test）

> ※ 実 window / AX はモック前提

### テスト対象

- 正規化 ↔ 復元座標の相互変換
- display 所属判定ロジック
- WindowRule マッチング（bundleId + titleMatch + indexHint）
- Layout JSON encode / decode

---

## 実装ルール

- Swift 5.9+
- Codable を使う
- Foundation / AppKit / ApplicationServices のみ使用
- ログは `os.Logger`
- 強制 unwrap 禁止
- AX 操作は失敗前提で書く

---

## 成果物

- 上記構成の SwiftPM プロジェクト
- `tiler doctor` が実行可能
- save / apply が実装され、dry-run で挙動確認できる
- Unit Test が `swift test` で通る

---

## 進め方

1. ドメインモデルとディレクトリ作成
2. DisplayService / LayoutEngine 実装
3. doctor / displays 実装
4. save / apply 実装
5. Unit Test 実装

> 迷った場合は **堅牢性・可読性を優先** し、拡張しやすい設計を選ぶこと。
