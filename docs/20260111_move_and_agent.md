# 常駐エージェント + apply 拡張 設計

## 概要

2つの機能を追加する：

1. **tairu apply の拡張** - 他のディスプレイにあるウィンドウも移動して配置
2. **tairu agent** - ディスプレイ接続を監視し、自動でレイアウトを適用

---

## 1. apply コマンドの拡張

### 目的

レイアウト適用時に、対象ウィンドウが別のディスプレイ（仮想デスクトップ含む）にある場合でも、ターゲットディスプレイに移動してきてから配置する。

### 現状の問題

- 現在の `apply` は対象ディスプレイ上のウィンドウのみを対象にしている
- 別のディスプレイにあるウィンドウは検出されず、レイアウトが適用されない

### 解決策

`LayoutEngine.apply` で:
1. 全ディスプレイの全ウィンドウを取得
2. レイアウトのルールにマッチするウィンドウを検索
3. マッチしたウィンドウをターゲットディスプレイに移動して配置

### 実装変更

`Sources/TairuCore/Engine/LayoutEngine.swift` の `apply` メソッドを修正：

```swift
// Before: 対象ディスプレイのウィンドウのみ取得
let windowRefs = try WindowQueryService.getWindowRefs(on: display)

// After: 全ディスプレイのウィンドウを取得
let windowRefs = try WindowQueryService.getAllWindowRefs()
```

---

## 2. 常駐エージェント (tairu agent)

### 目的

ディスプレイの接続/切断を監視し、新しいディスプレイが接続されたら対応するレイアウトを自動適用する。

### CLI インターフェース

```bash
# フォアグラウンドで起動（デバッグ用）
tairu agent

# launchd に登録してバックグラウンド起動
tairu agent --install

# launchd から解除
tairu agent --uninstall

# 状態確認
tairu agent --status
```

### 実装

#### ファイル

- `Sources/TairuCore/Services/DisplayMonitor.swift`
- `Sources/TairuCLI/Commands/AgentCommand.swift`

#### DisplayMonitor

`CGDisplayRegisterReconfigurationCallback` を使用してディスプレイ変更を検出する。

```swift
public final class DisplayMonitor {
    public enum Event {
        case displayAdded(Display)
        case displayRemoved(uuid: String)
    }

    public var onDisplayChange: ((Event) -> Void)?

    public func start()
    public func stop()
}
```

#### AgentCommand

1. `DisplayMonitor` を起動
2. ディスプレイ追加イベントを受信
3. 追加されたディスプレイの UUID で `LayoutStore` を検索
4. 対応するレイアウトがあれば `LayoutEngine.apply` を実行
5. `RunLoop` で常駐

#### launchd 連携

`--install` で以下の plist を生成：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.tairu.agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/tairu</string>
        <string>agent</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

保存先: `~/Library/LaunchAgents/com.example.tairu.agent.plist`

---

## ディレクトリ構成（追加分）

```
Sources/
├─ TairuCLI/
│  └─ Commands/
│     └─ AgentCommand.swift     # 新規
│
└─ TairuCore/
   └─ Services/
      └─ DisplayMonitor.swift   # 新規
```

---

## 検証方法

### apply 拡張

```bash
swift build
# ウィンドウを別ディスプレイに移動しておく
tairu apply --name <layout> --dry-run  # 移動対象が表示されることを確認
tairu apply --name <layout>
```

### AgentCommand

```bash
swift build
tairu agent  # フォアグラウンドで起動
# 別ターミナルでディスプレイを接続/切断
# ログを確認して動作確認
# Ctrl+C で停止

tairu agent --install
launchctl list | grep tairu  # 登録確認
tairu agent --uninstall
```
