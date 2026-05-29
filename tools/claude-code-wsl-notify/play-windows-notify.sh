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
