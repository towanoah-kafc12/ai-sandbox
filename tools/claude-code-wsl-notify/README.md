# Claude Code WSL Ubuntu 通知音 hook 導入ガイド

この guide は、WSL Ubuntu 上の Claude Code で、Claude が応答を終えたときや入力待ち・権限許可待ちになったときに Windows 側の通知音を鳴らすためのものです。

音源ファイルは repository に含めません。導入先 Windows に標準で入っている `.wav` を、WSL から `/mnt/c/Windows/Media/...` として参照します。

## できること

Claude Code の global hook に次を設定します。

- `Stop` — Claude Code が応答を終えたときに鳴る
- `Notification` — Claude Code がユーザー入力待ちなどになったときに鳴る
- `PermissionRequest` — コマンド実行などの権限確認 prompt が出る前に鳴る

この repository の `tools/claude-code-wsl-notify/` には、導入用に次を置いています。

- `play-windows-notify.sh` — hook から呼ぶ通知音再生 script
- `settings-hooks.snippet.json` — `~/.claude/settings.json` に merge する設定例
- `README.md` — この導入 guide

## 対象環境

想定環境は次です。

- Windows 上の WSL Ubuntu
- Claude Code を WSL Ubuntu 内で使っている
- Windows drive が WSL から `/mnt/c` として見えている
- WSL から `powershell.exe` を実行できる

確認コマンドです。

```bash
ls -l /mnt/c/Windows/Media
command -v powershell.exe
```

## 既定の通知音

既定では Windows 標準音源のこちらを使います。

```text
C:\Windows\Media\Windows Notify.wav
```

WSL からは次の path で参照します。

```text
/mnt/c/Windows/Media/Windows Notify.wav
```

このファイルが見つからない場合は、次へ fallback します。

```text
/mnt/c/Windows/Media/notify.wav
```

## 導入手順

### 1. script を Claude Code hooks 用ディレクトリへ配置する

この repository を持っている環境では、repository root から次を実行します。

```bash
mkdir -p ~/.claude/hooks
cp tools/claude-code-wsl-notify/play-windows-notify.sh ~/.claude/hooks/play-windows-notify.sh
chmod +x ~/.claude/hooks/play-windows-notify.sh
```

root ユーザーで Claude Code を使っている場合は、結果的に配置先が次になります。

```text
/root/.claude/hooks/play-windows-notify.sh
```

通常ユーザーで Claude Code を使っている場合は、次のようになります。

```text
/home/<user>/.claude/hooks/play-windows-notify.sh
```

### 2. `~/.claude/settings.json` に hooks を追加する

既存の `~/.claude/settings.json` を必ず壊さないように、`hooks` ブロックだけ merge します。

root ユーザー向けの例です。

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/root/.claude/hooks/play-windows-notify.sh"
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
            "command": "/root/.claude/hooks/play-windows-notify.sh"
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
            "command": "/root/.claude/hooks/play-windows-notify.sh"
          }
        ]
      }
    ]
  }
}
```

通常ユーザーで使う場合は、`command` を自分の home に変えます。

```json
"command": "/home/<user>/.claude/hooks/play-windows-notify.sh"
```

すでに `hooks` がある場合は、既存の `Stop`、`Notification`、`PermissionRequest` を消さず、必要なら配列に追加してください。

## 現在の script

`play-windows-notify.sh` の内容は次です。

```bash
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
```

## 動作確認

### script 単体の確認

```bash
~/.claude/hooks/play-windows-notify.sh </dev/null
```

音が鳴れば script は動いています。

### settings JSON の確認

`node` が使える場合です。

```bash
node -e "JSON.parse(require('fs').readFileSync(process.env.HOME + '/.claude/settings.json', 'utf8'))"
```

`jq` が使える場合です。

```bash
jq empty ~/.claude/settings.json
```

### Claude Code hook としての確認

この hook は `Stop` / `Notification` / `PermissionRequest` 用です。設定後、Claude Code の応答が終わったタイミング、入力待ちになったタイミング、またはコマンド実行などの権限確認 prompt が出る前に音が鳴ります。

設定したのに鳴らない場合は、Claude Code を再起動するか、Claude Code の `/hooks` 画面で設定を確認してください。

## 音を変えたい場合

script を編集せず、`CLAUDE_NOTIFY_SOUND` で差し替えできます。

```bash
export CLAUDE_NOTIFY_SOUND="/mnt/c/Windows/Media/Windows Ding.wav"
```

毎回同じ音にしたい場合は、Claude Code を起動する shell の設定に入れます。

```bash
# ~/.bashrc や ~/.zshrc など
export CLAUDE_NOTIFY_SOUND="/mnt/c/Windows/Media/Windows Ding.wav"
```

候補を探すには次を使います。

```bash
ls /mnt/c/Windows/Media/*.wav
```

独自の `.wav` も使えます。WSL から読める path を指定してください。

```bash
export CLAUDE_NOTIFY_SOUND="/mnt/c/Users/<WindowsUser>/Music/claude-notify.wav"
```

## 音量について

この script は Windows の `System.Media.SoundPlayer` で `.wav` を再生します。再生時に音量を増幅する仕組みは入れていません。

音量を変えたい場合は、まず次のどれかで調整します。

- Windows 側の音量設定を上げる
- より目立つ Windows 標準音へ `CLAUDE_NOTIFY_SOUND` で変更する
- 音量を上げた独自 `.wav` を作って指定する

## PowerShell 起動コストについて

WSL から Windows 音を鳴らすため、再生時に `powershell.exe` を起動します。音源を `/mnt/c` から読む負荷より、PowerShell 起動のほうが重いです。

通常の Claude Code 通知用途では問題になりにくいですが、軽量化したい場合は将来的に次の方式へ変えられます。

- WSL 側の `paplay` / `pw-play` / `aplay` を優先して鳴らす
- 小さな Windows helper `.exe` を用意して PowerShell を避ける
- terminal bell だけにする

この guide の script は、まず壊れにくさ優先で PowerShell 方式にしています。

## 無効化する方法

`~/.claude/settings.json` から、追加した `Stop` / `Notification` / `PermissionRequest` の hook 設定を削除します。

`hooks` がこの通知用途だけなら、`hooks` ブロックごと削除しても大丈夫です。

JSON はコメントを書けないので、編集後は JSON として正しい形にしてください。

## トラブルシュート

### 音が鳴らない

まず確認します。

```bash
ls -l "/mnt/c/Windows/Media/Windows Notify.wav"
ls -l /mnt/c/Windows/Media/notify.wav
command -v powershell.exe
bash -n ~/.claude/hooks/play-windows-notify.sh
~/.claude/hooks/play-windows-notify.sh </dev/null
```

### `settings.json` を編集したあと Claude Code の設定が効かない

JSON が壊れている可能性があります。

```bash
node -e "JSON.parse(require('fs').readFileSync(process.env.HOME + '/.claude/settings.json', 'utf8'))"
```

または、Claude Code を再起動するか `/hooks` で hook 設定を確認してください。

### 通常ユーザー環境で鳴らない

`settings.json` の `command` が root 向けのままになっていないか確認してください。

root 向け:

```json
"command": "/root/.claude/hooks/play-windows-notify.sh"
```

通常ユーザー向け:

```json
"command": "/home/<user>/.claude/hooks/play-windows-notify.sh"
```

### Windows の音源 path が違う

`C:` drive が `/mnt/c` ではない設定の WSL では、script 内の path や `CLAUDE_NOTIFY_SOUND` を環境に合わせて変えてください。

## この環境での現在値

この repository を作成した環境では、global 設定として次を使っています。

- hook script: `/root/.claude/hooks/play-windows-notify.sh`
- default sound: `/mnt/c/Windows/Media/Windows Notify.wav`
- fallback sound: `/mnt/c/Windows/Media/notify.wav`

repository 内の持ち運び用ファイルは次です。

```text
tools/claude-code-wsl-notify/
├── README.md
├── play-windows-notify.sh
└── settings-hooks.snippet.json
```
