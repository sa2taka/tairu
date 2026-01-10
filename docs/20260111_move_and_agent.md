# ウィンドウ移動 + 常駐エージェント 設計

## 概要

2つの新機能を追加する：

1. **tairu move** - ウィンドウを別のディスプレイに移動
2. **tairu agent** - ディスプレイ接続を監視し、自動でレイアウトを適用

---

## 1. ウィンドウ移動コマンド (tairu move)

### 目的

指定したアプリのウィンドウを別のディスプレイに移動する。

### CLI インターフェース

```bash
# アプリのウィンドウを指定ディスプレイに移動
tairu move --app <bundle-id> --to <display-uuid>

# 例: Safari を外部ディスプレイに移動
tairu move --app com.apple.Safari --to 37D8832A-2D66-02CA-B9F7-8F30A301B230

# ソースディスプレイから全ウィンドウを移動
tairu move --from <source-uuid> --to <target-uuid>
```

### オプション

| オプション | 必須 | 説明 |
|-----------|------|------|
| `--app` | `--from` と排他 | 移動するアプリの Bundle ID |
| `--from` | `--app` と排他 | 移動元ディスプレイの UUID |
| `--to` | Yes | 移動先ディスプレイの UUID |
| `--dry-run` | No | 実際には移動せず、何が移動されるか表示 |

### 実装

#### ファイル

- `Sources/TairuCLI/Commands/MoveCommand.swift`

#### ロジック

1. `--to` で指定されたディスプレイの visibleFrame を取得
2. 対象ウィンドウを特定（`--app` または `--from` で絞り込み）
3. 各ウィンドウの相対位置を維持しつつ、ターゲットディスプレイの座標に変換
4. `AXService.setWindowFrame` で移動

#### 座標変換

```
移動先 X = targetDisplay.visibleFrame.origin.x + (window.x - sourceDisplay.visibleFrame.origin.x)
移動先 Y = targetDisplay.visibleFrame.origin.y + (window.y - sourceDisplay.visibleFrame.origin.y)
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

#### レイアウト検索ロジック

1. 新しいディスプレイの UUID を取得
2. `LayoutStore.list()` で全レイアウトを取得
3. 各レイアウトの `targetDisplay.displayUUID` と比較
4. マッチしたレイアウトを適用

---

## ディレクトリ構成（追加分）

```
Sources/
├─ TairuCLI/
│  └─ Commands/
│     ├─ MoveCommand.swift      # 新規
│     └─ AgentCommand.swift     # 新規
│
└─ TairuCore/
   └─ Services/
      └─ DisplayMonitor.swift   # 新規
```

---

## 実装順序

1. **MoveCommand** - 単純な機能追加、既存の Service で実現可能
2. **DisplayMonitor** - CoreGraphics のコールバック登録
3. **AgentCommand** - 常駐ロジック + launchd 連携

---

## 検証方法

### MoveCommand

```bash
swift build
tairu displays  # UUID を確認
tairu move --app com.apple.Safari --to <uuid> --dry-run
tairu move --app com.apple.Safari --to <uuid>
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
