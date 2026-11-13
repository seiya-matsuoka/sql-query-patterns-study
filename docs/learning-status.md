# 学習状況と実行手順

実在する教材、実行手順、確認結果、残件を記録する。
当初の学習順序と受入条件を参照する。 [初期計画](learning-guide.md)

## 教材一覧

| 区分                       | 教材                                                                          | 作成     | 実行検証            | 教材レビュー                     | 本人の学習 |
| -------------------------- | ----------------------------------------------------------------------------- | -------- | ------------------- | -------------------------------- | ---------- |
| CASE・条件付き集約・FILTER | [支払済み注文の件数と合計](../sql/01-case-aggregation/paid-order-summary.sql) | 作成済み | CLI で 5 問照合済み | 再レビュー済み・指摘 3 件解消    | 完了       |
| CASE・条件付き集約・FILTER | [顧客区分のラベル化](../sql/01-case-aggregation/customer-tier-labels.sql)     | 作成済み | CLI で 2 問照合済み | 静的な独立レビュー済み・指摘なし | 未確認     |
| CASE・条件付き集約・FILTER | [金額帯の分類](../sql/01-case-aggregation/order-amount-bands.sql)             | 作成済み | CLI で 2 問照合済み | 静的な独立レビュー済み・指摘なし | 未確認     |
| CASE・条件付き集約・FILTER | [注文対応の優先順位](../sql/01-case-aggregation/order-handling-priority.sql)  | 作成済み | CLI で 1 問照合済み | 静的な独立レビュー済み・指摘なし | 未確認     |
| CASE・条件付き集約・FILTER | [顧客の業務順](../sql/01-case-aggregation/customer-business-order.sql)        | 作成済み | CLI で 3 問照合済み | 静的な独立レビュー済み・指摘なし | 未確認     |

初回教材の入力は [固定データ](../data/reset.sql) で定義する。
分類・優先順位・業務順の教材は、それぞれの問い合わせ内の `VALUES` で専用入力を定義する。
各期待 CSV は入力と問い合わせの意図から導いた値であり、実行結果の記録とは区別する。

### 初回 CASE/FILTER 教材

| 問い合わせの識別子         | 読む内容                                                                 | 期待 CSV                                                                               |
| -------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| `paid-summary-case`        | 顧客 1 の支払済み 2 件と判明分の合計 100.00 を CASE で求める             | [CSV](../expected/01-case-aggregation/paid-order-summary/paid-summary-case.csv)        |
| `paid-summary-filter`      | 同じ条件と集計単位で FILTER の結果を比べる                               | [CSV](../expected/01-case-aggregation/paid-order-summary/paid-summary-filter.csv)      |
| `paid-summary-by-customer` | 支払済みがない顧客と金額不明の顧客で、NULL と `ELSE 0.00` の結果を比べる | [CSV](../expected/01-case-aggregation/paid-order-summary/paid-summary-by-customer.csv) |
| `no-paid-order-rows`       | 該当する注文の明細が 0 行となる場合を確認する                            | [CSV](../expected/01-case-aggregation/paid-order-summary/no-paid-order-rows.csv)       |
| `aggregate-on-empty-input` | 入力が 0 行でも、グループ分けしない集約は 1 行を返すことを確認する       | [CSV](../expected/01-case-aggregation/paid-order-summary/aggregate-on-empty-input.csv) |

### CASE の分類・優先順位・業務順

読む順序は、顧客区分のラベル化、金額帯の分類、注文対応の優先順位、顧客の業務順とする。
各ファイル内は、識別子の記述順に比較する。
この作業単位は制作・CLI 検証と静的な独立レビューが済み、修正が必要な指摘はない。
新教材は両 GUI での本人確認も完了しており、`main` への取り込みは未実施である。

| 問い合わせの識別子                     | 読む内容                                                      | 期待 CSV                                                                                                |
| -------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `customer-tier-label-comparison`       | 固定コードを変換する単純 CASE と検索 CASE の同等比較          | [CSV](../expected/01-case-aggregation/customer-tier-labels/customer-tier-label-comparison.csv)          |
| `customer-tier-null-and-else`          | WHEN NULL と IS NULL、未定義コード、ELSE 省略による結果の違い | [CSV](../expected/01-case-aggregation/customer-tier-labels/customer-tier-null-and-else.csv)             |
| `amount-band-equivalent-ranges`        | 上位からの下限判定と、重ならない金額範囲による同等比較        | [CSV](../expected/01-case-aggregation/order-amount-bands/amount-band-equivalent-ranges.csv)             |
| `amount-band-condition-order`          | 重なる条件の順序で、500.00 以上の分類だけが変わる比較         | [CSV](../expected/01-case-aggregation/order-amount-bands/amount-band-condition-order.csv)               |
| `order-action-priority`                | 未払いと高額が重なる注文で、業務規則に応じた対応を選ぶ        | [CSV](../expected/01-case-aggregation/order-handling-priority/order-action-priority.csv)                |
| `customer-tier-value-order`            | コードの値順を使い、希望する業務順との違いを観察する          | [CSV](../expected/01-case-aggregation/customer-business-order/customer-tier-value-order.csv)            |
| `customer-tier-business-order`         | ORDER BY CASE と一意な第 2 キーで業務順を安定させる           | [CSV](../expected/01-case-aggregation/customer-business-order/customer-tier-business-order.csv)         |
| `customer-tier-business-order-derived` | 派生表で優先度に名前を付け、同じ出力列・行順を得る            | [CSV](../expected/01-case-aggregation/customer-business-order/customer-tier-business-order-derived.csv) |

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

### 第2工程の判定と初回教材の学習

2026-11-11 に Issue #1 と初期計画の第2工程を照合した。
制作側の実行検証記録、独立レビューと再レビューの結果、本人による GUI・整形の確認報告に基づき、実装・検証に関する受入条件を満たしている。
追加の実装・実行確認と、独立レビュー指摘への対応の残件はない。

2026-11-11 に、`feat/1-study-bootstrap` から `main` への [PR #2](https://github.com/seiya-matsuoka/sql-query-patterns-study/pull/2) がマージコミット `3fc62aa` で取り込まれたことを確認した。
ローカルの `main` と `origin/main` は同コミットを指しており、Issue #1 はクローズ済みである。
第2工程は完了した。
2026-11-12 に本人から初回 CASE/FILTER 教材 5 問の学習完了の申告を受け、教材一覧の本人の学習欄を完了へ更新した。

## 第3工程：CASE の分類・優先順位・業務順

2026-11-12 に、[Issue #3](https://github.com/seiya-matsuoka/sql-query-patterns-study/issues/3) の教材 SQL 4 ファイル・8 問い合わせと、対応する期待 CSV 8 ファイルを作成した。
単純 CASE と検索 CASE、分類境界・条件の優先順位・NULL、業務上の表示順を、採用理由と代替記述の比較まで含めて扱う。
現在は作業ブランチでの制作・CLI 検証、静的な独立レビュー、両 GUI での本人確認が済んだ段階であり、修正が必要な指摘はない。
`main` への取り込みは未実施である。

### 専用入力と比較条件

専用の永続テーブルは追加せず、各問い合わせの `VALUES` を派生表として使う。
問い合わせ単独で実行できるよう、比較に使う同じ入力は各問い合わせへ意図的に再掲する。
初期計画の「必要な時点で専用データを追加する」方針を、今回は読み取り専用の入力として具体化した。
共通テーブルの定義・データ、初回教材 SQL と期待 CSV、実行スクリプト、環境設定は変更していない。

- 顧客の 6 行は、既知の 3 区分、未定義の `partner`、区分 NULL、同じ優先度になる 2 顧客を含む。
- 金額の 8 行は、0.00、99.99、100.00、100.01、499.99、500.00、500.01、NULL を含む。
  同等比較の入力範囲は 0 以上の金額と NULL とし、負数では前提が崩れることもコメントに示す。
- 対応判断の 8 行は、未払いかつ高額、支払済みかつ金額不明、未払いかつ金額不明、未定義状態、状態 NULL を含む。
  未払い優先と高額優先は異なる業務規則として比較する。
- 業務順では、直接の `ORDER BY CASE` と、派生表で優先度を計算する方法が同じ結果になる。
  コードの値順との比較は、意図した行順の違いとして扱う。

説明は SQL コメントにまとめた。
今回の範囲では、独立した補足文書は追加していない。

### 今回確認した実行手順

Docker Desktop が起動し、既設コンテナとローカルイメージがあることを確認してから実行した。
`start` は既設サービスを起動するために使用し、イメージ取得・データ再構築は行っていない。
リポジトリのルートを開いた Git Bash で、次を実行した。

```bash
bash scripts/study.sh start
bash scripts/study.sh run sql/01-case-aggregation/customer-tier-labels.sql
bash scripts/study.sh verify sql/01-case-aggregation/customer-tier-labels.sql
bash scripts/study.sh run sql/01-case-aggregation/order-amount-bands.sql
bash scripts/study.sh verify sql/01-case-aggregation/order-amount-bands.sql
bash scripts/study.sh run sql/01-case-aggregation/order-handling-priority.sql
bash scripts/study.sh verify sql/01-case-aggregation/order-handling-priority.sql
bash scripts/study.sh run sql/01-case-aggregation/customer-business-order.sql
bash scripts/study.sh verify sql/01-case-aggregation/customer-business-order.sql
bash scripts/study.sh verify
bash scripts/study.sh stop
```

### 制作・レビュー・本人確認の結果

制作側の確認と静的な独立レビューは 2026-11-12 の記録である。
GUI での本人確認は、2026-11-13 の本人報告に基づいて記録する。

| 確認対象           | 方法・結果                                                                                                                                                                                            |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 接続先と実行条件   | 専用 DB `sql_patterns_study`、PostgreSQL 18.6、読み取り専用の接続、UTC、ISO・YMD を確認した                                                                                                           |
| 教材全体の実行     | 新しい 4 ファイルをそれぞれ `run` し、8 問い合わせの表形式の結果を確認した                                                                                                                            |
| 新教材の個別照合   | 4 ファイルをそれぞれ `verify` し、計 8 問い合わせがすべて期待 CSV と一致した                                                                                                                          |
| 一括照合・回帰検証 | 引数なしの `verify` で、新教材 8 問と初回教材 5 問の全 13 問が一致した                                                                                                                                |
| 共通データの保護   | 実行前後に 2 テーブルを読み取り、顧客 4 行・注文 5 行の件数と、ID 順の行内容から求めた照合用ハッシュが一致した                                                                                        |
| 期待 CSV の保護    | 全 13 CSV の SHA-256 が実行前後で一致し、実行結果から更新していないことを確認した                                                                                                                     |
| 静的確認           | 新規 SQL と期待 CSV の対応、進捗文書の相対リンク 23 件、変更した 13 ファイルの UTF-8・LF・末尾空白、公開対象の情報を確認した。`git diff --check` も成功した                                           |
| 停止               | 今回起動した専用サービスを正常停止した。既設のデータボリュームは保持した                                                                                                                              |
| 独立レビュー       | 2026-11-12 に読み取り専用の静的レビュー済み・修正が必要な指摘なし。制作担当の自己確認・CLI 検証とは別に確認した                                                                                       |
| GUI の本人確認     | Microsoft PostgreSQL・SQLTools の両方で、新教材 8 問の単独・ファイル全体実行と結果表示を確認済み。NULL を含む分類、条件順序による差、業務順と同じ優先度の行順も確認済み。問題・未確認事項の報告はない |
| 本人の学習         | 新教材は未確認。初回教材の学習完了を維持する                                                                                                                                                          |

文字列の値順は既設 DB の照合順序に従う。
今回の入力では `guest`、`partner`、`premium`、`standard` の順になることを実行確認したが、任意の照合順序でも同じになるとは扱わない。
CASE が返す数値の業務優先度と、一意な顧客 ID による表示順は、このコードの値順と区別している。
性能は実測しておらず、各書き方の性能は未評価である。

### 独立レビュー（2026-11-12）

対象は新規 SQL 4 ファイル・8 問い合わせ、期待 CSV 8 ファイル、本書の今回の更新である。
読み取り専用の静的レビューで、修正が必要な指摘はなかった。
2026-11-13 に、教材一覧と確認結果へレビュー済み・指摘なしを反映した。

- 単純 CASE と検索 CASE の同等性、WHEN NULL と IS NULL、未知コードと未登録、ELSE 省略の説明が、入力・SQL・期待 CSV と対応していた。
- 非負の金額と NULL を前提とする同等比較、分類境界とその前後、条件順序による意図的な結果の違いを確認した。
  注文 204 では未払い優先と高額優先の差が現れ、金額 NULL・未定義状態・状態 NULL の結果も説明と一致した。
- 業務順の未知コード・NULL の位置と、一意な顧客 ID による表示順の安定化を確認した。
  直接の ORDER BY CASE と派生表は入力・出力列・行順が一致し、両期待 CSV も同一であった。
- 顧客入力 5 問い合わせと金額帯入力 2 問い合わせは、それぞれ同じ VALUES を使用していた。
  8 個の識別子と期待 CSV に過不足がなく、ヘッダー・値・NULL・行順が整合していた。
- コメントの説明と進捗の状態区分、対象 13 ファイルの文字コード・改行・末尾空白・最終改行、相対リンク 23 件、`git diff --check` を確認した。
  既存の共通データ定義、初回教材、実行基盤、環境設定に今回の差分はなかった。

独立レビューでは SQL 実行やコンテナ操作を行っていない。
全 13 問の実行照合、共通データと期待 CSV の実行前後の保護、専用コンテナの正常停止は、制作側の実行記録として区別する。
2026-11-13 の記録反映も本書のみの変更とし、状態の整合性、相対リンク、文字コード・改行、差分を静的に確認した。
この反映時に SQL やコンテナの再実行は行っていない。

### GUI の本人確認（2026-11-13 報告）

本人から、Microsoft PostgreSQL・SQLTools の両方で、新教材 4 ファイル・8 問い合わせの単独実行・ファイル全体の実行と結果表示を確認したとの報告を受けた。
NULL を含む分類、条件順序による結果の差、業務順と同じ優先度の行順も、すべて確認済みである。
問題や未確認事項の報告はない。

この GUI 確認は本人の実施結果であり、制作側の CLI 検証と静的な独立レビューとは区別する。
本書への反映では文書更新と静的確認のみを行い、SQL 実行やコンテナ操作は行っていない。
GUI の確認完了を、新教材の本人の学習完了として扱わない。

### 受入状況と次の作業

Issue #3 の教材制作・実行検証・静的な独立レビュー・両 GUI の本人確認が揃い、修正対応や確認待ちの残件はない。
本人の学習状態は未確認、性能は未評価のままとし、初回教材の学習完了を維持する。
次は、本人が教材 SQL・期待 CSV と進捗文書を目的別にコミットし、`feat/3-case-classification` から `main` への PR を準備する。
PR には変更内容、制作側の実行検証、静的な独立レビュー、GUI の本人確認、学習状態と性能の扱いを記載する。
本人が差分と確認結果を確認し、コミット・プッシュ・PR 作成・`main` への取り込みを判断する。
`main` への取り込み後に、新教材を本人の学習へ渡す。
後続教材の制作は、別の着手依頼を受けてから行う。

### 技術的な参照先

- [PostgreSQL 18 の CASE](https://www.postgresql.org/docs/18/functions-conditional.html#FUNCTIONS-CASE)：単純 CASE と検索 CASE、最初に真となる分岐、ELSE 省略、結果型の前提。
- [PostgreSQL 18 の VALUES](https://www.postgresql.org/docs/18/queries-values.html)：永続表を作らない定数の入力表と、列名を付ける書き方。
- [PostgreSQL 18 の ORDER BY](https://www.postgresql.org/docs/18/queries-order.html)：式による並べ替え、後続キー、NULL の配置。

CASE などの構文は標準 SQL を優先する。
文字列の照合順序、`VALUES` の列型の決定、CLI の結果形式については、この PostgreSQL 環境の確認結果として扱う。
