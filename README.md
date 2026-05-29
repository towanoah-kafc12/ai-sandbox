# AI Agent Sandbox

AI エージェント向けの試作・検証用モノレポです。

## 使い分け

- `apps/` — アプリケーション系の試作
- `packages/` — 再利用できそうな小さなライブラリや共有コード
- `experiments/` — 使い捨て寄りの検証コード
- `tools/` — 補助スクリプトや開発用ツール
- `notes/` — まだ参照する作業メモやアイデア
- `notes/close/` — 古くなった、または不要になったメモの退避先

## 基本方針

この repository では、最初から大きな monorepo framework を入れず、必要になった段階で `package.json` workspaces や task runner を追加します。

新しい試作は、まず目的に合うトップレベルディレクトリの下に `kebab-case` のフォルダを作って始めます。作り込みたくなったものは、独立 repository へ切り出す前提で整理します。
