# macOS Window Layout Tiler — 詳細設計

基本設計（`20260110_first_design.md`）を補完する詳細仕様。

---

## 1. TitleMatch 仕様

### 型定義

```swift
enum TitleMatch: Codable {
    case exact(String)       // 完全一致
    case regex(String)       // 正規表現
}
```

### マッチング動作

| 種別 | 動作 |
|------|------|
| `exact` | `String.==` で比較 |
| `regex` | `NSRegularExpression` で全体マッチを評価 |
| `nil` | タイトルは無視（bundleIdのみで判定） |

### JSON フォーマット

```json
{
  "titleMatch": {
    "regex": ".*\\.swift$"
  }
}
```

または

```json
{
  "titleMatch": {
    "exact": "Untitled"
  }
}
```

---

## 2. WindowMatcher アルゴリズム

### マッチング手順

```
1. bundleId フィルタ
   └─ 対象アプリのウィンドウのみ抽出

2. titleMatch 評価
   ├─ titleMatch が指定されていれば正規表現/完全一致でフィルタ
   └─ マッチするウィンドウが1つ → 確定

3. indexHint による解決
   ├─ 複数ウィンドウがマッチ or titleMatch未指定の場合
   ├─ indexHint で順序指定（0-indexed）
   └─ indexHintがなければ最初のウィンドウを使用
```

### 同一Ruleへの重複マッチ防止

- 一度マッチしたウィンドウは候補から除外
- ルールは定義順に処理

### マッチ失敗時の動作

- スキップして次のルールへ
- 最後に警告ログを出力（どのルールがスキップされたか）

---

## 3. NormalizedFrame 計算

### 正規化（Save時）

```swift
let visibleFrame = display.visibleFrame

let normalizedFrame = NormalizedFrame(
    x: (window.frame.origin.x - visibleFrame.origin.x) / visibleFrame.width,
    y: (window.frame.origin.y - visibleFrame.origin.y) / visibleFrame.height,
    w: window.frame.width / visibleFrame.width,
    h: window.frame.height / visibleFrame.height
)
```

### 復元（Apply時）

```swift
let visibleFrame = display.visibleFrame

let absoluteFrame = CGRect(
    x: visibleFrame.origin.x + normalizedFrame.x * visibleFrame.width,
    y: visibleFrame.origin.y + normalizedFrame.y * visibleFrame.height,
    width: normalizedFrame.w * visibleFrame.width,
    height: normalizedFrame.h * visibleFrame.height
)
```

### 座標系

- macOS のスクリーン座標系（左下原点）をそのまま使用
- `visibleFrame` はメニューバー・Dock を除いた領域
- 複数ディスプレイ環境では各ディスプレイの `visibleFrame` を基準に正規化

---

## 4. エラー型設計

```swift
enum TilerError: Error, LocalizedError {
    // 権限
    case accessibilityNotGranted

    // ディスプレイ
    case displayNotFound(uuid: String)
    case noDisplaysAvailable

    // レイアウト
    case layoutNotFound(name: String)
    case layoutAlreadyExists(name: String)
    case invalidLayoutFormat(detail: String)

    // ウィンドウ操作
    case windowOperationFailed(app: String, reason: String)

    // ファイルI/O
    case fileWriteFailed(path: String, underlying: Error)
    case fileReadFailed(path: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return "Accessibility permission not granted. Enable in System Settings > Privacy & Security > Accessibility."
        case .displayNotFound(let uuid):
            return "Display not found: \(uuid)"
        case .noDisplaysAvailable:
            return "No displays available"
        case .layoutNotFound(let name):
            return "Layout not found: \(name)"
        case .layoutAlreadyExists(let name):
            return "Layout already exists: \(name)"
        case .invalidLayoutFormat(let detail):
            return "Invalid layout format: \(detail)"
        case .windowOperationFailed(let app, let reason):
            return "Failed to move window for \(app): \(reason)"
        case .fileWriteFailed(let path, let underlying):
            return "Failed to write file \(path): \(underlying.localizedDescription)"
        case .fileReadFailed(let path, let underlying):
            return "Failed to read file \(path): \(underlying.localizedDescription)"
        }
    }
}
```

---

## 5. CLI コマンド

### 全コマンド一覧

| コマンド | 説明 |
|---------|------|
| `tiler doctor` | 環境診断（AX権限、ディスプレイ、検出ウィンドウ数） |
| `tiler displays` | ディスプレイ一覧（UUID / name / visibleFrame） |
| `tiler layouts` | 保存済みレイアウト一覧 |
| `tiler save --display <uuid> --name <layout>` | レイアウト保存 |
| `tiler apply --display <uuid> --name <layout>` | レイアウト適用 |
| `tiler delete --name <layout>` | レイアウト削除 |

### 共通オプション

| オプション | 説明 |
|-----------|------|
| `--dry-run` | 実際の操作を行わず、実行内容を表示 |
| `--verbose` | 詳細ログを出力 |

### 出力例

#### `tiler layouts`

```
Available layouts:
  - coding      (Display: ABC-123-DEF)
  - meeting     (Display: ABC-123-DEF)
  - presentation (Display: GHI-456-JKL)
```

#### `tiler save --display ABC-123 --name coding --dry-run`

```
[dry-run] Would save layout 'coding' for display ABC-123-DEF
[dry-run] Capturing 5 windows:
  - com.apple.Terminal: "Terminal — zsh" (0, 23, 800, 600)
  - com.microsoft.VSCode: "main.swift" (800, 23, 1120, 600)
  ...
```

---

## 6. Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "tiler",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "tiler", targets: ["TilerCLI"]),
        .library(name: "TilerCore", targets: ["TilerCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "TilerCLI",
            dependencies: [
                "TilerCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "TilerCore",
            dependencies: []
        ),
        .testTarget(
            name: "TilerCoreTests",
            dependencies: ["TilerCore"]
        )
    ]
)
```

---

## 7. ディレクトリ構成（更新版）

```
tiler/
├─ Package.swift
├─ Sources/
│  ├─ TilerCLI/
│  │  ├─ TilerCLI.swift          # @main エントリポイント
│  │  ├─ Commands/
│  │  │  ├─ DoctorCommand.swift
│  │  │  ├─ DisplaysCommand.swift
│  │  │  ├─ LayoutsCommand.swift  # 追加
│  │  │  ├─ SaveCommand.swift
│  │  │  ├─ ApplyCommand.swift
│  │  │  └─ DeleteCommand.swift   # 追加
│  │  └─ CLIHelpers.swift
│  │
│  └─ TilerCore/
│     ├─ Domain/
│     │  ├─ Display.swift
│     │  ├─ Window.swift
│     │  ├─ Layout.swift
│     │  ├─ TitleMatch.swift      # 追加
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
│        ├─ FrameNormalizer.swift  # 追加（正規化ロジック分離）
│        └─ LayoutEngine.swift
│
└─ Tests/
   └─ TilerCoreTests/
      ├─ LayoutEngineTests.swift
      ├─ WindowMatcherTests.swift
      ├─ FrameNormalizerTests.swift  # 追加
      ├─ TitleMatchTests.swift       # 追加
      └─ DisplayServiceTests.swift
```

---

## 8. テストケース詳細

### FrameNormalizerTests

- 正規化 → 復元で元の座標に戻ること
- 異なるディスプレイサイズでも正規化値が同じなら同じ比率になること
- 境界値（0, 1）の処理

### TitleMatchTests

- `exact` マッチの正常系・異常系
- `regex` マッチの正常系（部分一致、全体一致）
- 無効な正規表現のハンドリング

### WindowMatcherTests

- bundleId のみでのマッチ
- bundleId + titleMatch でのマッチ
- bundleId + indexHint でのマッチ
- 重複マッチ防止の動作確認
- マッチ失敗時のスキップ動作

### DisplayServiceTests

- ウィンドウの所属ディスプレイ判定（交差面積最大）
- 複数ディスプレイにまたがるウィンドウの判定

---

## 9. 将来の拡張ポイント

現在は CLI のみだが、以下の拡張を想定した設計：

- **常駐Agent**: LayoutEngine / WindowMatcher をそのまま利用可能
- **ホットキー対応**: macOS の HotKey API と組み合わせ
- **ディスプレイ変更検知**: `CGDisplayRegisterReconfigurationCallback` で検知し自動apply
