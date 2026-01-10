# Tairu コーディングルール for Claude

このドキュメントは、Claude がこのプロジェクトでコードを書く際に守るべきルールを定義する。

---

## 1. 基本原則

### MUST（必須）

- **強制アンラップ禁止**: `!` を使わない。`guard let` / `if let` / `??` を使う
- **AX操作は失敗前提**: アクセシビリティAPI呼び出しは常に失敗を想定し、適切にハンドリングする
- **Single Responsibility**: 1関数 = 1目的。複数のことをする関数は分割する
- **Early Return**: ネストを減らすため、異常系は早期リターンする
- **秘密情報をコードに含めない**

### SHOULD（推奨）

- **DRY**: 3回以上重複したら抽出を検討
- **関数は30行以内**: 超える場合は分割を検討
- **命名で意図を表現**: コメントがなくても読めるコードを目指す
- **SLAP（抽象レベルの統一）**: 高レベルの呼び出しと低レベルのロジックを混在させない

---

## 2. Swift 固有ルール

### 使用可能なフレームワーク

- Foundation
- AppKit
- ApplicationServices
- os（Logger用）

**サードパーティ依存は最小限に**。現在許可されているのは `swift-argument-parser` のみ。

### Codable

- ドメインモデルは `Codable` に準拠させる
- JSON キー名は camelCase（Swift デフォルト）

### ログ

```swift
import os

private let logger = Logger(subsystem: "com.example.tairu", category: "CategoryName")

logger.debug("Debug message")
logger.info("Info message")
logger.error("Error message")
```

### エラーハンドリング

```swift
// TairuError を使用
throw TairuError.displayNotFound(uuid: displayUUID)

// 呼び出し側
do {
    try someOperation()
} catch let error as TairuError {
    logger.error("\(error.localizedDescription)")
} catch {
    logger.error("Unexpected error: \(error)")
}
```

---

## 3. テストルール

### フレームワーク

Swift Testing を使用（`import Testing`）

### AAA パターン

```swift
@Test("when condition, should behavior")
func testSomething() {
    // Arrange
    let input = ...

    // Act
    let result = sut.doSomething(input)

    // Assert
    #expect(result == expected)
}
```

### 原則

- **1テスト = 1関心事**: 複数の振る舞いをテストするなら分割
- **テスト名は振る舞いを説明**: `"when [条件], should [振る舞い]"`
- **前提条件はテスト内に書く**: 共有セットアップに頼らない
- **モックは最小限**: 外部依存（AX API等）のみモック化

### 実行

```bash
swift test
```

---

## 4. フォーマット・Lint

### 実行タイミング

コードを書いたら必ず実行：

```bash
./scripts/format.sh  # 自動整形
./scripts/lint.sh    # チェック
```

### 主要ルール（.swiftlint.yml / .swiftformat より）

| ルール | 設定 |
|--------|------|
| インデント | 4スペース |
| 行の最大長 | 120文字 |
| trailing comma | 常に付ける |
| self | 省略（必要な場合のみ） |
| 関数本体 | 50行で警告、100行でエラー |

---

## 5. コーディングサイクル

### 基本方針

**細かい単位でコミットを積み重ねる**。大きな変更を一度にコミットしない。

### サイクル

```
1. 要件理解
   └─ 何を実装するか明確にする

2. TDD サイクル（1機能単位）
   ├─ テスト作成 (Red)
   ├─ 実装 (Green)
   ├─ リファクタリング（必要なら）
   ├─ format & lint 実行
   └─ コミット: "feat: implement X"

3. 次の機能へ → 1 に戻る
```

### コミットタイミング

| タイミング | コミットする |
|-----------|-------------|
| 1つの TDD サイクル完了 | Yes |
| バグを1つ修正した | Yes |
| 大きなリファクタリング | Yes（独立して） |
| 複数の機能をまとめて | No（分割する） |

### 例: WindowMatcher 実装の場合

```bash
# 1. bundleId マッチング（テスト + 実装）
feat: implement WindowMatcher bundleId matching

# 2. titleMatch（テスト + 実装）
feat: implement WindowMatcher titleMatch

# 3. indexHint（テスト + 実装）
feat: implement WindowMatcher indexHint

# 4. 大きめのリファクタ（必要なら独立コミット）
refactor: extract common matching logic in WindowMatcher
```

### やってはいけないこと

- テストなしで大量のコードを書く
- 複数の機能を1コミットにまとめる
- 「WIP」「作業中」のままコミットを放置
- lint/format を通さずにコミット

---

## 6. コミットルール

### 粒度

- 1コミット = 1論理的変更
- 独立してリバート可能な単位
- メッセージに「and」が必要なら分割

### フォーマット

```
<type>: <簡潔な説明>

types: feat | fix | refactor | test | docs | chore
```

### TDD リズム

```
feat: implement X         (Red → Green → Refactor を含む)
refactor: ...             (大きなリファクタは独立コミット)
```

---

## 8. ファイル構成

### 新規ファイル作成時

```
Sources/TairuCore/
├─ Domain/       # 値オブジェクト、エンティティ
├─ Services/     # 外部リソースとのやり取り
└─ Engine/       # ビジネスロジック
```

### 命名規則

| 種別 | 命名 | 例 |
|------|------|-----|
| 型 | UpperCamelCase | `WindowMatcher` |
| 関数/変数 | lowerCamelCase | `normalizedFrame` |
| 定数 | lowerCamelCase | `defaultTimeout` |
| ファイル | 型名と一致 | `WindowMatcher.swift` |

---

## 9. リファクタリング指針

以下を検出したら提案する：

- 同じセマンティクスが3箇所以上 → 抽出（DRY）
- 長い関数で関心が分離可能 → 分割（SLAP）
- 抽象レベルの混在 → 低レベル詳細を抽出
- 10行以上の類似コードブロック → 抽出してパラメータ化
- 型による条件分岐 → ポリモーフィズムを検討

---

## 10. チェックリスト

コードを書き終えたら確認：

- [ ] 強制アンラップ `!` を使っていない
- [ ] エラーケースを適切にハンドリングしている
- [ ] テストを書いた（または既存テストが通る）
- [ ] `./scripts/lint.sh` が通る
- [ ] `swift build` が通る
- [ ] `swift test` が通る
