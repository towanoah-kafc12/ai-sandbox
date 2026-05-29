# Claude Code の WSL 通知音設定

この環境では、Claude Code が応答を終えたときやユーザー入力・権限許可を待っているときに、Windows 標準の通知音を鳴らすようにしています。

別環境へ持っていくための一式は、`tools/claude-code-wsl-notify/` にまとめています。

## 設定場所

WSL 全体に効く global 設定として、次を使っています。

- 設定: `/root/.claude/settings.json`
- 通知 script: `/root/.claude/hooks/play-windows-notify.sh`

project-local の `.claude/settings.json` ではなく global 設定に入れているので、この WSL ユーザーで起動する Claude Code 全体に適用されます。

## 使っている Claude Code hook

`/root/.claude/settings.json` の `hooks` に次のイベントを設定しています。

- `Stop` — Claude Code が応答を終えたとき
- `Notification` — Claude Code がユーザー入力待ちや権限許可待ちになったとき

どちらも同じ script を呼び出します。

## 通知音

既定では Windows 標準の proximity notification 音を使います。

```text
/mnt/c/Windows/Media/Windows Notify.wav
```

このファイルがない場合は、次に fallback します。

```text
/mnt/c/Windows/Media/notify.wav
```

再生は WSL から `powershell.exe` を呼び出して、Windows 側の `System.Media.SoundPlayer` で行います。

## 音を変えたいとき

今後、違う音に調整する前提です。Claude Code を起動する shell で `CLAUDE_NOTIFY_SOUND` を指定すると、script を編集せずに別の `.wav` へ変更できます。

```bash
export CLAUDE_NOTIFY_SOUND="/mnt/c/Windows/Media/Windows Ding.wav"
```

永続化したい場合は、shell の起動設定などに入れてください。

候補を探すには次を使います。

```bash
ls /mnt/c/Windows/Media/*.wav
```

## 動作確認

手動で鳴るか確認するには、WSL で次を実行します。

```bash
/root/.claude/hooks/play-windows-notify.sh </dev/null
```

音が鳴らない場合は、まず次を確認します。

```bash
ls -l /mnt/c/Windows/Media/Windows\ Notify.wav
command -v powershell.exe
```

## 無効化したいとき

一時的に止めたい場合は、`/root/.claude/settings.json` の `hooks` ブロックを削除またはコメントアウト相当の形で退避してください。

JSON にはコメントを書けないので、編集後は必ず JSON として正しい形にしてください。

## 注意

hook は非対話で実行されるため、script は標準出力に余計な文字を出さないようにしています。失敗しても Claude Code の作業を止めないよう、音の再生エラーは無視します。
