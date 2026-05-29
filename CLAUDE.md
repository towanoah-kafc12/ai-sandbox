# AI Agent Sandbox

このディレクトリは、AI エージェント向けの試作・検証用モノレポです。

## 方針

- 小さな実験や試作はこの repository 内で行う。
- 作り込みたくなったものは、別 repository として独立させる。
- Claude Code 用の project-local 設定は `.claude/settings.json` に置く。
- 最初から重い monorepo framework は入れず、複数 package の連携が必要になった時点で `package.json` workspaces や task runner を追加する。
- 新しい試作は、目的に合うトップレベルディレクトリの下に `kebab-case` の専用ディレクトリを作る。

## ディレクトリ

- `apps/` — アプリケーション系の試作
- `packages/` — 再利用できそうな小さなライブラリや共有コード
- `experiments/` — 使い捨て寄りの検証コード
- `tools/` — 補助スクリプトや開発用ツール
- `notes/` — まだ参照する作業メモやアイデア
- `notes/close/` — 古くなった、または不要になったメモの退避先

## メモ運用

- 作業メモ、アイデア、調査ログは `notes/` 直下に置く。
- 古くなったメモや不要になったメモは削除せず、原則として `notes/close/` に移動する。
- Claude Code の長期記憶に入れるべき内容は、リポジトリ内メモではなく通常の memory ルールに従う。
- 一時的な実験ログや再現手順は、関連する `experiments/` や `notes/` に置く。

## 拡張判断

- 1つの成果物として起動・配布したいものは `apps/` に置く。
- 複数の試作から再利用したいコードは `packages/` に置く。
- 検証が主目的で寿命が短いものは `experiments/` に置く。
- 開発作業を補助する CLI や script は `tools/` に置く。
