# WSL Ubuntu Claude Code 通知音 hook 永続化設計書

## 目的

WSL Ubuntu 環境で、Claude Code が次の状態になったときに Windows 側の通知音を鳴らす。

- Claude Code の応答が完了したとき
- Claude Code がユーザー入力待ちになったとき
- Claude Code がコマンド実行などの権限確認待ちになったとき

この設定は Ubuntu の最初に作成した通常ユーザーだけが使う前提で、`~/.claude/settings.json` に永続化する。

## スコープ

### 対象

- Windows 上の WSL Ubuntu
- Ubuntu 初回作成時の通常ユーザー 1 名
- その通常ユーザーで起動する Claude Code
- ユーザー単位の Claude Code global settings

### 対象外

- root ユーザーの Claude Code 設定
- 複数 Linux ユーザーへの一括適用
- WSL Ubuntu 以外の distro
- Windows native Claude Code への適用
- 音源ファイル自体の repository 管理

## 最終状態

導入後、Ubuntu 通常ユーザーの home 配下に次が存在する。

```text
~/.claude/
├── settings.json
└── hooks/
    └── play-windows-notify.sh
```

`~/.claude/settings.json` には次の hook が設定される。

- `Stop`
- `Notification`
- `PermissionRequest`

hook command は通常ユーザーの home にある script を指す。

```text
/home/<ubuntu-user>/.claude/hooks/play-windows-notify.sh
```

## 固定設定値

### hook script path

```text
~/.claude/hooks/play-windows-notify.sh
```

絶対 path の形式は次。

```text
/home/<ubuntu-user>/.claude/hooks/play-windows-notify.sh
```

`<ubuntu-user>` は Ubuntu の最初に作成した通常ユーザー名に置き換える。

### default sound

Windows 側の path:

```text
C:\Windows\Media\Windows Notify.wav
```

WSL 側の path:

```text
/mnt/c/Windows/Media/Windows Notify.wav
```

### fallback sound

```text
/mnt/c/Windows/Media/notify.wav
```

### Claude Code hook events

```text
Stop
Notification
PermissionRequest
```

### 再生方式

WSL から `powershell.exe` を呼び出し、Windows の `System.Media.SoundPlayer` で `.wav` を再生する。

## 前提条件

Ubuntu 通常ユーザーで次が成り立つこと。

```bash
ls -l /mnt/c/Windows/Media
ls -l "/mnt/c/Windows/Media/Windows Notify.wav"
command -v powershell.exe
```

`Windows Notify.wav` が存在しない場合でも、`notify.wav` があれば fallback で鳴る。

```bash
ls -l /mnt/c/Windows/Media/notify.wav
```

## 導入手順

以下は Ubuntu の通常ユーザーで実行する。`sudo` は使わない。

### 1. hooks ディレクトリを作る

```bash
mkdir -p ~/.claude/hooks
```

### 2. hook script を配置する

この repository を持っている場合は repository root から次を実行する。

```bash
cp tools/claude-code-wsl-notify/play-windows-notify.sh ~/.claude/hooks/play-windows-notify.sh
chmod +x ~/.claude/hooks/play-windows-notify.sh
```

repository がない環境で手作業する場合は、次の内容で作成する。

```bash
cat > ~/.claude/hooks/play-windows-notify.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Consume hook JSON from stdin so Claude Code can send event data without blocking.
cat >/dev/null || true

sound="${CLAUDE_NOTIFY_SOUND:-/mnt/c/Windows/Media/Windows Notify.wav}"

if [[ ! -f "$sound" ]]; then
  sound="/mnt/c/Windows/Media/notify.wav"
fi

if [[ -f "$sound" ]] && command -v powershell.exe >/dev/null 2>&1; then
  win_sound="$(wslpath -w "$sound")"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
    "try { Add-Type -AssemblyName System.Windows.Forms; \$p = New-Object System.Media.SoundPlayer '$win_sound'; \$p.PlaySync() } catch { [System.Media.SystemSounds]::Asterisk.Play() }" \
    >/dev/null 2>&1 || true
elif command -v printf >/dev/null 2>&1; then
  printf '\a' >/dev/tty 2>/dev/null || true
fi
EOF
chmod +x ~/.claude/hooks/play-windows-notify.sh
```

### 3. script 単体の動作確認

```bash
bash -n ~/.claude/hooks/play-windows-notify.sh
~/.claude/hooks/play-windows-notify.sh </dev/null
```

ここで音が鳴れば script は正しく動いている。

### 4. `~/.claude/settings.json` に永続設定を入れる

`~/.claude/settings.json` が存在しない場合は、次の内容で作成する。

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/<ubuntu-user>/.claude/hooks/play-windows-notify.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/<ubuntu-user>/.claude/hooks/play-windows-notify.sh"
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/home/<ubuntu-user>/.claude/hooks/play-windows-notify.sh"
          }
        ]
      }
    ]
  }
}
```

`<ubuntu-user>` は実際のユーザー名に置き換える。

ユーザー名を確認するには次を使う。

```bash
whoami
```

実際の path は次で確認できる。

```bash
printf '%s\n' "$HOME/.claude/hooks/play-windows-notify.sh"
```

既存の `~/.claude/settings.json` がある場合は、既存設定を消さずに `hooks` だけ merge する。

既存の `hooks.Stop`、`hooks.Notification`、`hooks.PermissionRequest` がない場合は追加する。既にある場合は、既存配列を消さずにこの command hook を追加する。

## 完成形の `settings.json` 例

通常ユーザー名が `ubuntu` の場合。

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/ubuntu/.claude/hooks/play-windows-notify.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/ubuntu/.claude/hooks/play-windows-notify.sh"
          }
        ]
      }
    ]
  }
}
```

通常ユーザー名が `noah` の場合。

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/noah/.claude/hooks/play-windows-notify.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/noah/.claude/hooks/play-windows-notify.sh"
          }
        ]
      }
    ]
  }
}
```

## JSON 検証

`node` がある場合。

```bash
node -e "JSON.parse(require('fs').readFileSync(process.env.HOME + '/.claude/settings.json', 'utf8'))"
```

`jq` がある場合。

```bash
jq empty ~/.claude/settings.json
```

どちらも何も出ず終了すれば JSON として正しい。

## Claude Code 側の反映

`~/.claude/settings.json` に保存するため、設定は永続化される。

ただし、既に起動中の Claude Code が即時に反映しない場合がある。その場合は次のどちらかを行う。

- Claude Code を再起動する
- Claude Code の `/hooks` 画面を開いて設定を確認する

## 動作確認

### 完了通知の確認

Claude Code で何か短い依頼を実行し、応答完了時に音が鳴ることを確認する。

### 権限確認通知の確認

Claude Code がコマンド実行などの権限確認待ちになったときに音が鳴ることを確認する。

この設計では、入力待ちなどは `Notification` hook、コマンド実行などの権限確認 prompt は `PermissionRequest` hook で鳴らす。`PermissionRequest` の matcher は `Bash` にして、shell command 実行許可の確認に合わせている。

## 音を変更する場合

script は環境変数 `CLAUDE_NOTIFY_SOUND` を優先する。

一時的に変更する例。

```bash
export CLAUDE_NOTIFY_SOUND="/mnt/c/Windows/Media/Windows Ding.wav"
```

永続的に変更したい場合は、Claude Code を起動する shell の設定に追加する。

```bash
# ~/.bashrc など
export CLAUDE_NOTIFY_SOUND="/mnt/c/Windows/Media/Windows Ding.wav"
```

候補音源の確認。

```bash
ls /mnt/c/Windows/Media/*.wav
```

独自音源を使う例。

```bash
export CLAUDE_NOTIFY_SOUND="/mnt/c/Users/<WindowsUser>/Music/claude-notify.wav"
```

## 音量の扱い

この設計では再生時の音量増幅はしない。

音量を変えたい場合は次で対応する。

- Windows 側の音量設定を変更する
- より大きい `.wav` を `CLAUDE_NOTIFY_SOUND` で指定する
- 音量調整済みの独自 `.wav` を指定する

## PowerShell 起動コスト

この設計では通知のたびに `powershell.exe` を起動する。

理由は、WSL Ubuntu から Windows 標準音源を壊れにくく再生するため。

通常の Claude Code 通知頻度では実用上問題になりにくい。より軽量化したい場合は、将来的に次を検討する。

- WSL 側の `paplay` / `pw-play` / `aplay` を優先利用する
- 小さな Windows helper `.exe` を作る
- terminal bell のみにする

## 無効化

`~/.claude/settings.json` から、追加した `Stop`、`Notification`、`PermissionRequest` の hook を削除する。

この通知 hook だけが `hooks` に入っている場合は、`hooks` ブロックごと削除してよい。

script も不要なら削除する。

```bash
rm ~/.claude/hooks/play-windows-notify.sh
```

## トラブルシュート

### 音が鳴らない

```bash
ls -l "/mnt/c/Windows/Media/Windows Notify.wav"
ls -l /mnt/c/Windows/Media/notify.wav
command -v powershell.exe
bash -n ~/.claude/hooks/play-windows-notify.sh
~/.claude/hooks/play-windows-notify.sh </dev/null
```

### `settings.json` の path が間違っている

次で現在のユーザー用 path を確認する。

```bash
printf '%s\n' "$HOME/.claude/hooks/play-windows-notify.sh"
```

`~/.claude/settings.json` の `command` がこの path と一致している必要がある。

### JSON を壊したかもしれない

```bash
node -e "JSON.parse(require('fs').readFileSync(process.env.HOME + '/.claude/settings.json', 'utf8'))"
```

または

```bash
jq empty ~/.claude/settings.json
```

### Claude Code 上で鳴らないが script 単体では鳴る

次を試す。

- Claude Code を再起動する
- Claude Code の `/hooks` 画面を開く
- `~/.claude/settings.json` の `command` が正しい絶対 path か確認する

## 導入完了条件

次をすべて満たせば完了。

- `~/.claude/hooks/play-windows-notify.sh` が存在する
- `~/.claude/hooks/play-windows-notify.sh` に実行権限がある
- `~/.claude/settings.json` に `Stop` hook がある
- `~/.claude/settings.json` に `Notification` hook がある
- `~/.claude/settings.json` に `PermissionRequest` hook があり、matcher が `Bash` になっている
- `command` が `/home/<ubuntu-user>/.claude/hooks/play-windows-notify.sh` を指している
- `~/.claude/hooks/play-windows-notify.sh </dev/null` で音が鳴る
- Claude Code の応答完了時に音が鳴る
- Claude Code の権限確認待ちまたは入力待ちで音が鳴る

## repository 内の関連ファイル

```text
tools/claude-code-wsl-notify/
├── README.md
├── UBUNTU-SETUP-DESIGN.md
├── play-windows-notify.sh
└── settings-hooks.snippet.json
```
