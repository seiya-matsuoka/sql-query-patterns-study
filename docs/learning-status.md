# 学習状況と実行手順

現在有効な学習設計は [学習ガイド](learning-guide.md)、制作・操作の規則は [AGENTS.md](../AGENTS.md) を参照する。
本書は現在地と利用手順を更新し、過去の制作日誌は Git 履歴・PR で参照する。

## 現在地

| 対象                 | 作成                 | CLI 検証     | 独立レビュー                   | 本人の学習             |
| -------------------- | -------------------- | ------------ | ------------------------------ | ---------------------- |
| CASE 01～09・22 問   | main に取り込み済み  | 回帰照合済み | 確認済み・残る指摘なし         | 本人の申告に基づき完了 |
| CASE 10～12・6 問    | main に取り込み済み  | 回帰照合済み | 静的レビュー済み・必須修正なし | 本人の申告に基づき完了 |
| EXISTS 01～04・14 問 | 作成済み・未取り込み | 照合済み     | 静的レビュー済み・指摘なし     | 未確認                 |
| CTE・再帰 CTE        | 未着手               | 未実施       | 未実施                         | 未確認                 |
| ウィンドウ関数       | 未着手               | 未実施       | 未実施                         | 未確認                 |

本人の申告に基づき、2026-11-15 に 10～12 の学習完了を反映した。
これにより、第1区分「CASE・条件付き集約・FILTER」の全 12 ファイル・28 問の本人の学習が完了した。
学習済み 01～09 の SQL・期待 CSV・既存補足は維持し、新しい制作・説明・入力の基準は 10 以降へ適用する。

## 教材の入口

各ファイル内は example 識別子の記述順に読む。
期待 CSV は `expected/<区分>/<SQL の拡張子を除いた名前>/<example識別子>.csv` に対応する。
本人が学習用に CSV を出力・作成する必要はない。

### 第1区分：CASE・条件付き集約・FILTER

| 番号 | 教材                                                                                     |
| ---- | ---------------------------------------------------------------------------------------- |
| 01   | [支払済み注文の件数と合計](../sql/01-case-aggregation/01-paid-order-summary.sql)         |
| 02   | [顧客区分のラベル化](../sql/01-case-aggregation/02-customer-tier-labels.sql)             |
| 03   | [金額帯の分類](../sql/01-case-aggregation/03-order-amount-bands.sql)                     |
| 04   | [注文対応の優先順位](../sql/01-case-aggregation/04-order-handling-priority.sql)          |
| 05   | [顧客の業務順](../sql/01-case-aggregation/05-customer-business-order.sql)                |
| 06   | [金額帯別の集計](../sql/01-case-aggregation/06-amount-band-summary.sql)                  |
| 07   | [複数の条件別指標](../sql/01-case-aggregation/07-conditional-order-metrics.sql)          |
| 08   | [平均へ渡す値と分母](../sql/01-case-aggregation/08-conditional-average-denominators.sql) |
| 09   | [空入力の条件付き集約](../sql/01-case-aggregation/09-empty-conditional-aggregates.sql)   |
| 10   | [顧客区分別の注文抽出](../sql/01-case-aggregation/10-customer-tier-order-filtering.sql)  |
| 11   | [顧客区分別の合計判定](../sql/01-case-aggregation/11-customer-tier-total-filtering.sql)  |
| 12   | [売上・返金の純額](../sql/01-case-aggregation/12-sales-refund-net-totals.sql)            |

06～09 の既存補足は [集計の粒度と平均の分母](notes/01-case-aggregation/06-09-case-aggregation-grain-and-averages.md) にある。
10 は同等な代替記述、11 は条件位置で要件が変わる比較、12 は符号・重複・粒度を揃えた同等比較を主例の後に置く。

### 第2区分：EXISTS / NOT EXISTS

[Issue #9](https://github.com/seiya-matsuoka/sql-query-patterns-study/issues/9) の区分全体を 4 ファイル・14 問で扱う。
主例の採用理由と比較の成立条件を SQL 内のコメントに示す。

| 番号 | 教材                                                                           | 問数 | 主例と比較                                                        |
| ---- | ------------------------------------------------------------------------------ | ---- | ----------------------------------------------------------------- |
| 01   | [支払済み注文がある顧客](../sql/02-exists/01-paid-customer-existence.sql)      | 2    | EXISTS と JOIN + DISTINCT。複数注文と同名の別顧客                 |
| 02   | [注文なしと支払済み注文なし](../sql/02-exists/02-customers-without-orders.sql) | 5    | NOT EXISTS と LEFT JOIN + IS NULL。条件位置と非 NULL の判定列     |
| 03   | [顧客 ID 集合への所属・非所属](../sql/02-exists/03-customer-id-membership.sql) | 2    | IN / NOT IN と存在判定が同等になる非 NULL 条件                    |
| 04   | [NULL・空集合と抽出結果](../sql/02-exists/04-null-and-empty-membership.sql)    | 5    | 式の TRUE・FALSE・UNKNOWN と WHERE に残る行。左右の NULL と空集合 |

02 の条件位置・金額 NULL、04 の NULL を含む NOT IN は、当該要件では採用しない比較として区別する。
右の NULL を除いた NOT IN でも左の NULL の扱いは別途決める必要があり、04 ではその差も扱う。
本人の学習は未確認であり、main へ取り込んでから任意のまとまりで読む。

## 環境とデータの準備

リポジトリのルートを Git Bash で開き、既設の Docker Desktop と専用 Compose サービス db を使う。
接続先は DB `sql_patterns_study`、ユーザー `study`、ホスト `127.0.0.1`、ポート `15432` である。
ローカルの `.env` に `SQL_PATTERNS_DB_PASSWORD` を設定する。
新規準備時のサンプルは [`.env.example`](../.env.example) を参照し、実値は共有・追跡しない。

| 入力             | 対象と利用教材                                                                   | 定義                                 |
| ---------------- | -------------------------------------------------------------------------------- | ------------------------------------ |
| 初回の固定データ | study.customers・study.orders。01 の 5 問が参照する                              | [reset.sql](../data/reset.sql)       |
| 従来の専用入力   | 02～09 の各問い合わせ内の VALUES。学習済みのため維持する                         | 各教材 SQL                           |
| 共用の業務データ | practice.customers・practice.orders・practice.money_movements。10 以降で利用する | [practice.sql](../data/practice.sql) |

practice の顧客・注文は 13 顧客・20 注文で、区分 NULL・未定義区分、境界、同額の別注文、実額 0・金額 NULL を含む。
顧客 12 は注文なし、顧客 13 は顧客 1 と同じ表示名「顧客01」を持つ別顧客で、支払済み・金額 0.00 の注文 1301 を持つ。
顧客 9 は未払い注文のみであり、注文自体がない顧客と、支払済み注文がない顧客を区別できる。
売上・返金は対象期間の 6 記録で、顧客 1 は 100 + 100 - 20、顧客 2 は 300 - 300、顧客 3 は返金だけの -50 となる。
顧客 3 の元の売上は対象期間外とし、注文表の支払済み合計と売上・返金の純額を同じ指標とは扱わない。

| コマンド                                                                                 | 動作                                                                  |
| ---------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `bash scripts/study.sh start`                                                            | 専用サービスを起動する。データ準備は行わない                          |
| `bash scripts/study.sh reset-data`                                                       | 初回用の study の 2 表だけを再構築する                                |
| `bash scripts/study.sh reset-practice-data`                                              | practice の上記 3 表だけを再構築する。study は変更しない              |
| `bash scripts/study.sh run sql/01-case-aggregation/10-customer-tier-order-filtering.sql` | 指定ファイル全体を読み取り専用で表形式表示する                        |
| `bash scripts/study.sh verify`                                                           | 全教材を読み取り専用で照合する。末尾に SQL パスを付けると個別照合する |
| `bash scripts/study.sh stop`                                                             | サービスを停止し、データボリュームを保持する                          |

二つの再構築コマンドは、それぞれ既存の対象データを置き換える明示的な操作である。
初回準備や固定データへ戻す必要があるときに、対象と許可を確認して使う。
start・run・verify からは呼ばれず、データ未準備なら実行は失敗する。
通常の学習のたびに再構築する必要はない。

verify は教材の example ごとの SQL をそのまま実行し、ヘッダー・値・行数・重複・順序を期待 CSV と比較する。
NULL は `<NULL>` と表示し、差を隠す丸めや並べ替えは行わない。
生成した一時ファイルはスクリプトが成功時・失敗時とも終了時に削除し、期待 CSV は更新しない。

## GUI と SQL の整形

学習時は通常 Microsoft PostgreSQL を使い、必要なら SQLTools を選ぶ。
両方で全問を確認することは取り込みの条件にしない。
ループバック接続の SSL は無効とし、パスワードはローカルの `.env` の値を接続時に入力する。
SQLTools では PostgreSQL 用ドライバーを使い、Use password は Ask on connect を選ぶ。

| 拡張                                 | ID                        |
| ------------------------------------ | ------------------------- |
| Microsoft PostgreSQL                 | `ms-ossdata.vscode-pgsql` |
| SQLTools                             | `mtxr.sqltools`           |
| SQLTools PostgreSQL/Cockroach Driver | `mtxr.sqltools-driver-pg` |

SQL の整形は [ワークスペース設定](../.vscode/settings.json) の SQL Formatter と postgresql 方言を使う。
接続情報はローカルで扱い、共有設定にパスワードの実値を保存しない。

## 最新の確認結果

2026-11-15 に、第2区分の教材・期待 CSV・共用データ追加と、既存教材への影響を制作側で確認した。
接続先は専用 DB sql_patterns_study、PostgreSQL 18.6 で、読み取り実行は default_transaction_read_only=on、UTF-8、UTC、ISO・YMD であった。

| 確認                       | 結果                                                                                                                                                                                                                                                                                |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 変更前の基準               | データ変更前に既存 CASE 28 問を一括 verify し、すべて一致・終了コード 0 だった                                                                                                                                                                                                      |
| データ準備                 | ID の未使用を確認し、顧客 12・13 と注文 1301 だけを入力へ追加した。許可された reset-practice-data により practice の 3 表だけを再構築し、13 顧客・20 注文・6 売上返金記録を確認した                                                                                                 |
| 新教材                     | 01～04 をそれぞれ run・個別 verify し、全 14 問が一致・終了コード 0 だった                                                                                                                                                                                                          |
| 回帰照合                   | 追加後の一括 verify で、既存 CASE 28 問を含む全 42 問が一致・終了コード 0 だった                                                                                                                                                                                                    |
| データの保護               | study の顧客 4 行・注文 5 行、practice の既存 11 顧客・19 注文、売上返金 6 記録の内容ハッシュは変更前と一致した。再構築後の全データも教材実行前後で一致した                                                                                                                         |
| 期待値と既存ファイルの保護 | 全 42 CSV の SHA-256 は初回実行前と一致した。今回の変更対象である practice.sql・本書を除く既存の追跡ファイル 50 個も着手時と一致した                                                                                                                                                |
| 自己確認・静的確認         | 主例・比較の位置付け、粒度・相関条件・NULL・重複・空集合と期待値の対応を確認した。識別子・CSV 対応、1 識別子 1 問い合わせ、最終順序、同等比較の CSV、リンク、UTF-8・BOM なし・LF・最終改行・末尾空白、git diff --check は正常だった                                                 |
| 独立レビュー               | 2026-11-15 に別チャットで対象 20 ファイル全体を読み取り専用で静的レビューし、必須修正・任意提案ともになしだった。到達目標、主例と比較、顧客粒度・相関条件・同名顧客・重複、非存在判定、NULL・空集合、全 14 問と期待 CSV、共用データの既存 CASE への影響、文書・形式の整合を確認した |

独立レビューでは SQL 実行、DB・コンテナ操作、GUI 確認、性能測定は行っていない。
全 42 問の verify 成功と内容ハッシュ・SHA-256 の一致は制作側の実行記録を参照したものであり、レビュー側の実行結果とは区別する。
期待値は入力と要件から初回実行前に導出し、実行結果から更新していない。
検証用一時ディレクトリの残存はなく、開始前から稼働していた専用サービスは healthy のまま保持した。
study の再構築、イメージ取得、依存関係追加、環境設定変更は行っていない。
既存 CASE の SQL・期待 CSV・補足、実行補助は変更していない。
GUI の実行確認は今回行っておらず、本人の学習時に確認する。
性能測定は行っておらず、性能は未評価である。
構文の確認には PostgreSQL 18 公式文書の [副問い合わせ式](https://www.postgresql.org/docs/18/functions-subquery.html) と [外部結合・WHERE](https://www.postgresql.org/docs/18/queries-table-expressions.html) を用いた。

## 残件と次の作業

- 制作側の CLI 検証と独立した静的レビューは完了しており、未解決の指摘はない。
  本人が Issue #9 の変更を 1 PR として main に取り込む。
- 第1区分の本人の学習完了を維持し、第2区分の本人の学習は申告を受けて更新する。

独立レビュー結果の進捗記録への反映までを今回の停止地点とし、main への取り込みは未完了である。
後続区分は未着手のままとする。
