# 学習状況と実行手順

現在有効な学習設計は [学習ガイド](learning-guide.md)、制作・操作の規則は [AGENTS.md](../AGENTS.md) を参照する。
本書は現在地と利用手順を更新し、過去の制作日誌は Git 履歴・PR で参照する。

## 現在地

| 対象                         | 作成                | CLI 検証     | 独立レビュー                   | 本人の学習             |
| ---------------------------- | ------------------- | ------------ | ------------------------------ | ---------------------- |
| CASE 01～09・22 問           | main に取り込み済み | 回帰照合済み | 確認済み・残る指摘なし         | 本人の申告に基づき完了 |
| CASE 10～12・6 問            | main に取り込み済み | 回帰照合済み | 静的レビュー済み・必須修正なし | 本人の申告に基づき完了 |
| EXISTS 01～04・14 問         | main に取り込み済み | 回帰照合済み | 静的レビュー済み・指摘なし     | 本人の申告に基づき完了 |
| CTE・再帰 CTE 01～03・5 問   | main に取り込み済み | 回帰照合済み | 静的レビュー済み・指摘なし     | 本人の申告に基づき完了 |
| ウィンドウ関数 01～05・11 問 | main に取り込み済み | 照合済み     | 静的レビュー済み・必須修正なし | 本人の申告に基づき完了 |

2026-11-19 の本人の申告に基づき、全 4 区分・24 ファイル・58 問の学習は完了している。
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

### 第3区分：CTE・再帰 CTE

[Issue #11](https://github.com/seiya-matsuoka/sql-query-patterns-study/issues/11) の区分全体を 3 ファイル・5 問で扱う。
2026-11-16 に独立した静的レビューが完了し、2026-11-18 に main へ取り込まれた。[PR #12](https://github.com/seiya-matsuoka/sql-query-patterns-study/pull/12)

| 番号 | 教材                                                                                       | 問数 | 主例と比較                                                       |
| ---- | ------------------------------------------------------------------------------------------ | ---- | ---------------------------------------------------------------- |
| 01   | [顧客別集計・分類・分類別再集計](../sql/03-cte-recursion/01-customer-payment-segments.sql) | 2    | CTE と派生表の同等比較。名前付けと各段階の粒度                   |
| 02   | [再帰の開始・反復・終了](../sql/03-cte-recursion/02-recursive-integers.sql)                | 1    | 1～5 の整数列を生成し、最終表示は降順にする                      |
| 03   | [指定カテゴリ自身と子孫](../sql/03-cte-recursion/03-category-subtree.sql)                  | 2    | 商品と食品を起点にした部分木。相対的な深さ・枝分かれ・対象外の枝 |

01 は全顧客を対象とし、支払済み注文なし、金額不明あり、全額判明かつ合計 500.00 以上／未満へ分類する。
実額 0 は判明額として扱い、該当注文なし・全額 NULL の合計は NULL のまま保持する。
不明額を含む分類の合計は判明分だけであり、全額が確定した値ではない。
03 の食品への起点変更は要件が変わる比較であり、商品の部分木と同等な結果を求める比較ではない。
構文の読み方と採用理由は各 SQL 内のコメントを参照する。

### 第4区分：ウィンドウ関数

区分全体を 5 ファイル・11 問で扱う。
2026-11-19 に main へ取り込まれ、関連 Issue は完了としてクローズされた。[PR #14](https://github.com/seiya-matsuoka/sql-query-patterns-study/pull/14)・[Issue #13](https://github.com/seiya-matsuoka/sql-query-patterns-study/issues/13)

| 番号 | 教材                                                                                          | 問数 | 主例と比較                                                    |
| ---- | --------------------------------------------------------------------------------------------- | ---- | ------------------------------------------------------------- |
| 01   | [支払済み注文明細の顧客別指標](../sql/04-window-functions/01-customer-paid-order-metrics.sql) | 2    | 合計・平均・構成比を添えるウィンドウ集計と、集約結果との JOIN |
| 02   | [支払済み注文の金額上位](../sql/04-window-functions/02-top-paid-orders.sql)                   | 3    | RANK・ROW_NUMBER・DENSE_RANK による抽出の違い                 |
| 03   | [顧客ごとの最新注文](../sql/04-window-functions/03-latest-customer-order.sql)                 | 1    | ROW_NUMBER による 1 件の選択と同日時の決め方                  |
| 04   | [前回・次回の注文](../sql/04-window-functions/04-adjacent-orders.sql)                         | 3    | LAG / LEAD と自己結合の同等比較、前日・翌日の注文有無         |
| 05   | [累積額と移動平均の計算範囲](../sql/04-window-functions/05-order-aggregation-frames.sql)      | 2    | ROWS の行順・件数と RANGE の日時範囲                          |

## 環境とデータの準備

リポジトリのルートを Git Bash で開き、既設の Docker Desktop と専用 Compose サービス db を使う。
接続先は DB `sql_patterns_study`、ユーザー `study`、ホスト `127.0.0.1`、ポート `15432` である。
ローカルの `.env` に `SQL_PATTERNS_DB_PASSWORD` を設定する。
新規準備時のサンプルは [`.env.example`](../.env.example) を参照し、実値は共有・追跡しない。

| 入力             | 対象と利用教材                                                                                                          | 定義                                 |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| 初回の固定データ | study.customers・study.orders。01 の 5 問が参照する                                                                     | [reset.sql](../data/reset.sql)       |
| 従来の専用入力   | 02～09 の各問い合わせ内の VALUES。学習済みのため維持する                                                                | 各教材 SQL                           |
| 共用の業務データ | practice.customers・practice.orders・practice.money_movements・practice.categories。第1区分 10 以降で必要な表を利用する | [practice.sql](../data/practice.sql) |

practice の顧客・注文は 13 顧客・20 注文で、区分 NULL・未定義区分、境界、同額の別注文、実額 0・金額 NULL を含む。
顧客 12 は注文なし、顧客 13 は顧客 1 と同じ表示名「顧客01」を持つ別顧客で、支払済み・金額 0.00 の注文 1301 を持つ。
顧客 9 は未払い注文のみであり、注文自体がない顧客と、支払済み注文がない顧客を区別できる。
第4区分の時系列例は、タイムゾーンを持たない注文日時 practice.orders.ordered_at を参照する。
顧客 1 には最新日時が同じ 2 注文と、注文のない日を挟む履歴がある。
注文 ID の大小と日時順が異なる入力も含む。
売上・返金は対象期間の 6 記録で、顧客 1 は 100 + 100 - 20、顧客 2 は 300 - 300、顧客 3 は返金だけの -50 となる。
顧客 3 の元の売上は対象期間外とし、注文表の支払済み合計と売上・返金の純額を同じ指標とは扱わない。
カテゴリは 7 行で、商品・サービスの二つの根と、食品・雑貨からの枝分かれを持つ。
根の親 ID は NULL とし、主キーと自己参照の外部キーを定義する。
再帰教材は有限で循環しない入力を前提とし、外部キーだけで循環を防げるとは扱わない。

| コマンド                                                                                 | 動作                                                                  |
| ---------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `bash scripts/study.sh start`                                                            | 専用サービスを起動する。データ準備は行わない                          |
| `bash scripts/study.sh reset-data`                                                       | 初回用の study の 2 表だけを再構築する                                |
| `bash scripts/study.sh reset-practice-data`                                              | practice の上記 4 表だけを再構築する。study は変更しない              |
| `bash scripts/study.sh run sql/01-case-aggregation/10-customer-tier-order-filtering.sql` | 指定ファイル全体を読み取り専用で表形式表示する                        |
| `bash scripts/study.sh verify`                                                           | 全教材を読み取り専用で照合する。末尾に SQL パスを付けると個別照合する |
| `bash scripts/study.sh stop`                                                             | サービスを停止し、データボリュームを保持する                          |

二つの再構築コマンドは、それぞれ既存の対象データを置き換える明示的な操作である。
初回準備や固定データへ戻す必要があるときに、対象と許可を確認して使う。
第4区分 03～05 の実行・個別照合と、全教材の一括照合には `practice.orders.ordered_at` が必要である。
日時列を含まない旧データを使う場合は、これらの操作の前に `reset-practice-data` で日時列を反映する。
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

### 制作側の CLI 検証と自己確認

2026-11-18 に、第4区分の制作側の確認を PostgreSQL 18.6 の専用 DB sql_patterns_study で行った。
run と verify の接続は読み取り専用を既定とし、文字コードは UTF-8、日時の設定は UTC・ISO・YMD だった。
専用サービス db は作業開始時と終了時に healthy だった。

| 確認           | 結果                                                                                                                                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 変更前の基準   | 注文日時の反映前に、既存の全 47 問が一括 verify で一致した                                                                                                                                        |
| データ準備     | reset-practice-data で practice の 4 表を再構築し、ordered_at が TIMESTAMP NOT NULL で全 20 注文に入っていることを確認した                                                                        |
| 保護対象の確認 | practice 4 表の既存列の値、study 2 表の内容、既存列の定義と制約が再構築前後で一致した。照合後も日時列を含むデータと定義は一致した                                                                 |
| 新教材         | 01～05 の run が成功し、全 11 問が個別 verify で実行前に導出した期待 CSV と一致した                                                                                                               |
| 回帰照合       | 既存の 47 問を含む全 58 問が追加後の一括 verify で一致した                                                                                                                                        |
| 自己確認       | 主例・比較の要件、粒度、NULL と 0、同順位と表示順、前後の注文と暦日、フレームの境界を確認した。識別子と期待 CSV の対応、同等比較 2 組の一致、既存教材・CSV の差分、リンクとファイル形式を確認した |

構文の確認には PostgreSQL 18 の公式文書を用いた。[ウィンドウ関数の入門](https://www.postgresql.org/docs/18/tutorial-window.html)、[順位・前後行の関数](https://www.postgresql.org/docs/18/functions-window.html)、[フレームの構文](https://www.postgresql.org/docs/18/sql-expressions.html)
本人による第4区分の GUI 実行状況は未確認であり、性能は未評価である。

### 独立静的レビュー

2026-11-18 に第4区分全体を独立して静的レビューし、必須修正 0 件、任意提案 1 件だった。
入力と要件から独立に算出した期待値は、新規 11 CSV のヘッダー、全 167 データ行の値と行順に一致した。
識別子と SQL・期待 CSV の対応、既存 4 表の行・既存列の定義と値・制約、既存 19 SQL・47 期待 CSV の維持を確認した。
任意提案を採用し、日時列の反映が必要な操作を準備手順に明記した。
レビュー側では SQL の実行、DB・コンテナの確認、GUI 確認、性能測定は未実施である。

## 残件と次の作業

残る作業は、初めて利用する人向けのルート `README.md` の作成である。
作成依頼を受けた後に着手する。
