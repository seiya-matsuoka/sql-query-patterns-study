# 学習状況と実行手順

実在する教材、実行手順、確認結果、残件を記録する。
当初の学習順序と受入条件を参照する。 [初期計画](learning-guide.md)

## 教材一覧

| 区分                       | 教材                                                                          | 作成     | 実行検証            | 教材レビュー                  | 本人の学習 |
| -------------------------- | ----------------------------------------------------------------------------- | -------- | ------------------- | ----------------------------- | ---------- |
| CASE・条件付き集約・FILTER | [支払済み注文の件数と合計](../sql/01-case-aggregation/paid-order-summary.sql) | 作成済み | CLI で 5 問照合済み | 再レビュー済み・指摘 3 件解消 | 未確認     |

入力は [固定データ](../data/reset.sql) で定義する。
各期待 CSV は入力と問い合わせの意図から導いた値であり、実行結果の記録とは区別する。

| 問い合わせの識別子         | 読む内容                                                                 | 期待 CSV                                                                               |
| -------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| `paid-summary-case`        | 顧客 1 の支払済み 2 件と判明分の合計 100.00 を CASE で求める             | [CSV](../expected/01-case-aggregation/paid-order-summary/paid-summary-case.csv)        |
| `paid-summary-filter`      | 同じ条件と集計単位で FILTER の結果を比べる                               | [CSV](../expected/01-case-aggregation/paid-order-summary/paid-summary-filter.csv)      |
| `paid-summary-by-customer` | 支払済みがない顧客と金額不明の顧客で、NULL と `ELSE 0.00` の結果を比べる | [CSV](../expected/01-case-aggregation/paid-order-summary/paid-summary-by-customer.csv) |
| `no-paid-order-rows`       | 該当する注文の明細が 0 行となる場合を確認する                            | [CSV](../expected/01-case-aggregation/paid-order-summary/no-paid-order-rows.csv)       |
| `aggregate-on-empty-input` | 入力が 0 行でも、グループ分けしない集約は 1 行を返すことを確認する       | [CSV](../expected/01-case-aggregation/paid-order-summary/aggregate-on-empty-input.csv) |

### 期待 CSV の役割と担当

期待 CSV は、固定データに対して各問い合わせが返すべき列名と値を保存した照合用ファイルである。
教材を作成・修正する Codex が、問いと入力から期待結果を導いて作成・保守し、教材 SQL・固定データと一緒に Git で管理する。
本人の学習は、教材 SQL とコメントを読み、GUI または `run` の実行結果を確認して進める。
本人が学習のために CSV を出力・作成・編集する作業は不要である。
必要に応じて期待 CSV を結果の見本として参照できるが、学習の必須操作にはしない。

`verify` は既存の期待 CSV を読み、教材 SQL を実行して得た一時 CSV と比較する。
一時 CSV の削除は `scripts/study.sh` の `verify_lessons` に実装している。
同関数は専用の一時ディレクトリを作り、`EXIT` トラップで `verify` 全体の終了時に一時 CSV・抽出した SQL・管理用ファイルを削除し、ディレクトリも取り除く。
照合成功時と、SQL エラー・結果不一致などでスクリプトが終了する場合の両方で後片付けを行う。
本人や Codex が照合のたびに手動で削除する作業は不要であり、期待 CSV は書き換えない。
GUI の結果をエクスポートして期待 CSV を用意する操作は不要である。

## 環境と使い方

Git Bash でリポジトリのルートを開く。
Docker Desktop の起動後に、リポジトリ専用の Compose サービス `db` を使う。 [Compose 設定](../compose.yaml)
`.env` がなければ [`.env.example`](../.env.example) を `.env` にコピーし、`SQL_PATTERNS_DB_PASSWORD` に学習用のパスワードを設定する。
`.env` は Git の除外対象とする。

```bash
bash scripts/study.sh start
```

教材データを初めて準備するとき、または共通テーブルを固定データに戻したいときに `reset-data` を実行する。
対象は `study.customers` と `study.orders` で、既存の内容を再構築する。
接続先のデータベース名が `sql_patterns_study` の場合に限り、再構築へ進む。
`start`、`run`、`verify` はこの再構築を呼び出さない。

```bash
bash scripts/study.sh reset-data
```

`run` は指定した教材を表形式で表示する。
`verify` は教材を照合し、ファイル指定を省略した場合は作成済みの教材をすべて照合する。

```bash
bash scripts/study.sh run sql/01-case-aggregation/paid-order-summary.sql
bash scripts/study.sh verify sql/01-case-aggregation/paid-order-summary.sql
bash scripts/study.sh verify
```

CLI ではコンテナ内の `psql` が標準入力から SQL を読む。
`verify` は行頭の `-- example: 識別子` で分けた問い合わせを実行し、`sql/` 以下のファイル名と識別子に対応する `expected/` 以下の CSV と比較する。
識別子は小文字の英字で始め、英小文字・数字・ハイフンを使う。
同一ファイル内で一意とし、一つの識別子につき一つの問い合わせを書く。
CSV はヘッダーを含め、NULL の表示を `<NULL>` とする。
行数・重複・順序を含む差をそのまま照合し、結果不一致時は期待 CSV と実行結果の差を表示する。

学習を終えたら `stop` でサービスを停止する。
データはプロジェクト専用ボリュームに保持する。

```bash
bash scripts/study.sh stop
```

### SQL の整形

このリポジトリの SQL ファイルには、ワークスペースの [設定](../.vscode/settings.json) で `renesaarsoo.sql-formatter-vsc` を既定のフォーマッターとして指定する。
`SQL-Formatter-VSCode.dialect` は `postgresql` に固定し、PostgreSQL の構文として整形する。
`data/reset.sql` の接続先検査で使うドル引用は、標準の `sql` 方言では整形エラーになる。
SQL の実行可否とフォーマッターの構文対応は別に確認する。
フォーマッターは DB に接続せずに動作する。 [拡張の設定仕様](https://marketplace.visualstudio.com/items?itemName=renesaarsoo.sql-formatter-vsc)

## GUI の接続と確認

通常は Microsoft PostgreSQL を使う。
SQLTools での確認には、本体と PostgreSQL 用ドライバーを使う。

| 拡張                                 | ID                        |
| ------------------------------------ | ------------------------- |
| Microsoft PostgreSQL                 | `ms-ossdata.vscode-pgsql` |
| SQLTools                             | `mtxr.sqltools`           |
| SQLTools PostgreSQL/Cockroach Driver | `mtxr.sqltools-driver-pg` |

同じ学習用 DB に接続するため、両 GUI に次の接続情報を入力する。
Microsoft PostgreSQL は PostgreSQL ビューの接続追加から設定する。
SQLTools は接続ビューの **Add New Connection** から PostgreSQL ドライバーを選ぶ。
SQLTools の接続設定では **Use password** で **Ask on connect** を選ぶ。
接続時の入力欄に、ローカルの `.env` に設定した `SQL_PATTERNS_DB_PASSWORD` の値を入力する。

| 項目         | 値                                                           |
| ------------ | ------------------------------------------------------------ |
| ホスト       | `127.0.0.1`                                                  |
| ポート       | `15432`                                                      |
| データベース | `sql_patterns_study`                                         |
| ユーザー     | `study`                                                      |
| パスワード   | ローカルの `.env` に設定した `SQL_PATTERNS_DB_PASSWORD` の値 |
| SSL          | このループバック接続では無効                                 |

接続情報はローカルで扱い、共有するワークスペース設定にはパスワードを保存しない。
このワークスペースでは `pgsql.copilot.enable` を `false` に設定する。 [Microsoft の AI 設定の説明](https://learn.microsoft.com/en-us/azure/postgresql/developer/vs-code-extension/vs-code-github-copilot)

1. `start` で学習用 DB を起動する。教材データを初めて準備する場合は `reset-data` を実行する。
2. 両拡張を有効にした状態で、それぞれから同じ DB に接続する。
3. 各 GUI で `paid-summary-case` の問い合わせだけを選択して実行し、件数 2 と合計 100.00 を確認する。
4. 続いて教材ファイル全体を実行し、複数の結果表、0 行の明細、NULL の合計を確認する。
5. 確認できた結果表と、両方を有効にした際の干渉の有無を記録する。

## 検証結果と残件

| 確認対象             | 状態・結果                                                                                                                                                                                                                             |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Compose 設定         | `docker compose config --quiet` が成功した。設定値を表示せずに検証した                                                                                                                                                                 |
| シェルの構文         | Git Bash の `bash -n scripts/study.sh` が成功した                                                                                                                                                                                      |
| DB と接続先          | PostgreSQL 18.6 の起動と `127.0.0.1:15432` の公開を確認した。文字コードは UTF-8、タイムゾーンは UTC、日時書式は ISO・YMD であった                                                                                                      |
| 認証情報の管理       | `.env` が Git の除外対象で、追跡されていないことを確認した                                                                                                                                                                             |
| 初期化と再構築       | `start` 後の未準備状態では照合に失敗し、`reset-data` 後に成功した。既存の共通テーブルに対する再構築も確認した                                                                                                                          |
| 教材の実行と照合     | `run` で 5 問を表示した。個別・一括の `verify` で 5 問すべてが期待 CSV と一致した。0 行の明細はヘッダーだけを照合した                                                                                                                  |
| 照合の境界           | 一時的な確認用 SQL で、空文字・NULL・重複・順序のある結果を照合した。空文字と NULL の入れ替え、重複数の変化、行順の違いはそれぞれ不一致になった                                                                                        |
| 失敗検知             | SQL 構文エラー、期待 CSV の欠落、結果不一致、専用 DB の停止中に終了コード 1 を確認した。結果不一致時にも比較先の期待 CSV は変化しなかった                                                                                              |
| 実行条件と停止       | 確認用 SQL で照合時の読み取り専用設定を確認した。停止・再起動後に `reset-data` を挟まず 5 問を照合できた。検証後は停止し、専用ボリュームを保持した                                                                                     |
| VS Code 拡張の導入   | 本人から指定 3 拡張のインストール済みとの報告を受けた                                                                                                                                                                                  |
| GUI の接続と教材実行 | 本人が Microsoft PostgreSQL・SQLTools の両方で接続、問い合わせの単独実行、ファイル全体の実行、0 行の明細と NULL を含む集約結果の表示を確認した。両拡張を有効にした際の操作上の干渉はなかった                                           |
| SQL 整形設定         | 拡張 4.2.6 が同梱する SQL Formatter 15.8.2 で確認した。`data/reset.sql` は標準の `sql` 方言でエラーになり、`postgresql` 方言では初期化 SQL と教材 SQL の両方をメモリ上で整形できた。本人からも方言設定後の整形エラー解消の報告を受けた |
| 独立レビュー         | 読み取り専用の再レビュー済み。接続先検査、顧客 3 の説明、SQLTools の入力方式の指摘 3 件が解消した                                                                                                                                      |

制作側の実行検証と再レビューの記録は 2026-11-10 時点のものである。
拡張の導入、両 GUI の接続・単独実行・全体実行・結果表示、併用時の干渉なし、方言設定後の整形エラー解消の本人報告を 2026-11-11 に反映した。
SQL 整形設定の制作側の確認も同日に記録した。

### 独立レビュー指摘への対応

- `data/reset.sql` のトランザクションの冒頭で `current_database()` を確認し、学習用 DB と異なる場合は DDL の前に例外で中断するようにした。
- 教材の顧客 3 の説明に、唯一の注文が金額不明の支払済み行であることと、未払い行が加わった場合に `ELSE 0.00` 付きの合計だけが 0.00 になることを追記した。
- SQLTools の接続設定に、接続時のパスワード入力方式を選ぶ手順を追記した。

再レビューでは、上記 3 件の修正箇所を読み取り専用で確認した。

以下は制作側の実行検証の記録である。
既設の専用コンテナ内の `postgres` DB に読み取り専用で接続し、再構築 SQL が接続先の検査で失敗することを確認した。
エラー後に続行する設定でも後続文が拒否され、トランザクションがロールバックされた。
`sql_patterns_study` では再構築に成功し、個別・一括の `verify` がそれぞれ 5 問すべてで期待 CSV と一致した。
検証後はコンテナを正常停止し、既設のデータボリュームを保持した。

### 第2工程の判定と次の作業

2026-11-11 に Issue #1 と初期計画の第2工程を照合した。
制作側の実行検証記録、独立レビューと再レビューの結果、本人による GUI・整形の確認報告に基づき、実装・検証に関する受入条件を満たしている。
追加の実装・実行確認と、独立レビュー指摘への対応の残件はない。

2026-11-11 に、`feat/1-study-bootstrap` から `main` への [PR #2](https://github.com/seiya-matsuoka/sql-query-patterns-study/pull/2) がマージコミット `3fc62aa` で取り込まれたことを確認した。
ローカルの `main` と `origin/main` は同コミットを指しており、Issue #1 はクローズ済みである。
第2工程は完了し、次は `main` に取り込んだ初回 CASE/FILTER 教材 5 問をファイル内の順序で読み、実行結果の比較と質問対応へ進む。
本人の学習状態は未確認のままとし、本人から状態が伝えられた時点で学習欄を更新する。
