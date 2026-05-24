# AI Agent Sandbox

このディレクトリは、AI エージェント向けの試作・検証用モノレポです。

## 方針

- 小さな実験や試作はこの repository 内で行う。
- 作り込みたくなったものは、別 repository として独立させる。
- Claude Code 用の project-local 設定は `.claude/settings.json` に置く。

## ディレクトリ

- `apps/` — アプリケーション系の試作
- `packages/` — 再利用できそうな小さなライブラリや共有コード
- `experiments/` — 使い捨て寄りの検証コード
- `tools/` — 補助スクリプトや開発用ツール
