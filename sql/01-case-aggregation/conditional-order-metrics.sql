-- example: conditional-metrics-case
-- 問い：顧客ごとの全注文件数と、支払済み・未払いそれぞれの件数・判明金額の合計・平均を一緒に求める。
-- 支払済みだけを抽出するのではなく、未払いも含む注文状況を横に並べて報告する場面を想定する。
-- 入力の 10 行は別々の注文であり、status は paid または unpaid、amount の NULL は金額不明を表す。
-- 顧客 1 は支払済みの 100.00・0.00・NULL と、未払いの 60.00・60.00 を持つ。
-- 顧客 2 は未払いのみ、顧客 3 は金額不明の支払済みのみ、顧客 4 は実額 0 の支払済みのみである。
-- 顧客 5 は金額不明の支払済みと、40.00 の未払いを持つ。顧客 6 の注文は入力にない。
-- GROUP BY customer_id により、結果の 1 行は「入力に注文がある 1 顧客」の集計になる。
-- 全注文を入力に残すので、支払済みが 0 件の顧客 2 も残る。顧客 6 の行は自動では作られない。
-- order_count はその顧客の全注文である。条件付き COUNT は THEN 1 を使い、金額不明でも状態に該当すれば数える。
-- known_paid_amount_count と known_unpaid_amount_count は THEN amount を数え、状態に該当し、金額も非 NULL の注文だけを数える。
-- CASE の ELSE を省略すると、条件が真でない行は NULL となり、COUNT(式)・SUM・AVG の対象値から外れる。
-- known_paid_total と known_unpaid_total は、各状態の判明金額だけの合計である。不明分を含む総額を保証しない。
-- known_paid_average と known_unpaid_average は、その合計を各 known_*_amount_count で割る平均である。
-- 注文の件数と金額の件数を分ける理由は、状態に該当しても金額 NULL の行は AVG の分母に入らないためである。
-- 顧客 1 の支払済みは 3 件でも、平均は (100.00 + 0.00) / 2 = 50 になる。0 は判明した金額なので含む。
-- 同じ顧客の未払いは別注文 2 件で、合計 120.00・平均 60 となる。同額を DISTINCT で除去しない。
-- 顧客 2 は支払済み件数 0、顧客 3 と 5 は 1 だが判明件数 0 であり、いずれも支払済み合計・平均は NULL となる。
-- 顧客 4 は支払済み件数と判明件数がともに 1、合計と平均が 0 であり、上記の NULL と区別できる。
-- COUNT の CASE に ELSE 0 を足すと、非該当の 0 まで数える。SUM・AVG に足す場合も同等とは限らない。
-- 次の FILTER 版は、同じ入力・各条件・金額式・顧客単位・重複の扱いで同じ列を返す同等比較である。
-- CASE は値を選ぶ方法を各集約に共通して読める。FILTER を使える DBMS では、対象行の条件を集約ごとに分けて表せる。
-- 各比較は可読性と集約対象の意味を扱い、性能は未評価である。最終 ORDER BY で顧客順を安定させる。
SELECT
    customer_id,
    COUNT(*) AS order_count,
    COUNT(
        CASE
            WHEN status = 'paid' THEN 1
        END
    ) AS paid_order_count,
    COUNT(
        CASE
            WHEN status = 'paid' THEN amount
        END
    ) AS known_paid_amount_count,
    SUM(
        CASE
            WHEN status = 'paid' THEN amount
        END
    ) AS known_paid_total,
    AVG(
        CASE
            WHEN status = 'paid' THEN amount
        END
    ) AS known_paid_average,
    COUNT(
        CASE
            WHEN status = 'unpaid' THEN 1
        END
    ) AS unpaid_order_count,
    COUNT(
        CASE
            WHEN status = 'unpaid' THEN amount
        END
    ) AS known_unpaid_amount_count,
    SUM(
        CASE
            WHEN status = 'unpaid' THEN amount
        END
    ) AS known_unpaid_total,
    AVG(
        CASE
            WHEN status = 'unpaid' THEN amount
        END
    ) AS known_unpaid_average
FROM
    (
        VALUES
            (
                101,
                1,
                CAST('paid' AS VARCHAR(12)),
                CAST(100.00 AS DECIMAL(10, 2))
            ),
            (102, 1, 'paid', 0.00),
            (103, 1, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (104, 1, 'unpaid', 60.00),
            (105, 1, 'unpaid', 60.00),
            (201, 2, 'unpaid', 80.00),
            (301, 3, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (401, 4, 'paid', 0.00),
            (501, 5, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (502, 5, 'unpaid', 40.00)
    ) AS sample_orders (order_id, customer_id, status, amount)
GROUP BY
    customer_id
ORDER BY
    customer_id;

-- example: conditional-metrics-filter
-- 問い：全注文件数を残し、支払済みと未払いの指標を集約ごとの FILTER で表す。
-- 入力は直前と同じ 10 注文であり、顧客ごとの 5 集計行と出力列も揃える。
-- FILTER (WHERE 条件) は、それを付けた一つの集約へ渡す行だけを選ぶ。
-- 問い合わせ全体の入力を除く WHERE とは異なり、他の集約やグループ自体を除去しない。
-- order_count の COUNT(*) には FILTER がないので、未払いも金額 NULL も含む全注文を数える。
-- 状態別の COUNT(*) はその状態の全注文、COUNT(amount) はそのうち金額が判明している注文だけを数える。
-- 状態別の SUM(amount) と AVG(amount) も金額 NULL を使わず、平均の分母は状態別の COUNT(amount) である。
-- CASE 版で条件が真でない行を NULL にすることと、ここで集約へ渡さないことは、これらの集約では同じ値をもたらす。
-- 同じ条件が真の行を選び、同じ amount を使い、非 NULL の値とその重複数・集計単位を揃えるのが同等条件である。
-- COUNT の THEN 1 は FILTER 後の COUNT(*)、THEN amount は FILTER 後の COUNT(amount) に対応する。
-- 金額 NULL の支払済みも存在するため、この二つの COUNT を取り違えると件数が変わる。
-- 顧客 1 の全注文は 5、支払済みは 3、判明した支払済み金額は 2 個、支払済みの平均は 50 となる。
-- 顧客 2 のグループは残り、支払済みの二つの件数は 0、合計と平均は NULL となる。
-- 顧客 3 と 5 は支払済み 1 件でも判明金額がなく平均 NULL、顧客 4 は判明した 0 円の平均 0 である。
-- 顧客 6 は入力そのものがないので、この版でも行がない。FILTER は欠けた顧客の行を補わない。
-- CASE の ELSE 0 は対象外の非 NULL 値を増やすため、この FILTER と一律に同等とは扱わない。
SELECT
    customer_id,
    COUNT(*) AS order_count,
    COUNT(*) FILTER (
        WHERE
            status = 'paid'
    ) AS paid_order_count,
    COUNT(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS known_paid_amount_count,
    SUM(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS known_paid_total,
    AVG(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS known_paid_average,
    COUNT(*) FILTER (
        WHERE
            status = 'unpaid'
    ) AS unpaid_order_count,
    COUNT(amount) FILTER (
        WHERE
            status = 'unpaid'
    ) AS known_unpaid_amount_count,
    SUM(amount) FILTER (
        WHERE
            status = 'unpaid'
    ) AS known_unpaid_total,
    AVG(amount) FILTER (
        WHERE
            status = 'unpaid'
    ) AS known_unpaid_average
FROM
    (
        VALUES
            (
                101,
                1,
                CAST('paid' AS VARCHAR(12)),
                CAST(100.00 AS DECIMAL(10, 2))
            ),
            (102, 1, 'paid', 0.00),
            (103, 1, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (104, 1, 'unpaid', 60.00),
            (105, 1, 'unpaid', 60.00),
            (201, 2, 'unpaid', 80.00),
            (301, 3, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (401, 4, 'paid', 0.00),
            (501, 5, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (502, 5, 'unpaid', 40.00)
    ) AS sample_orders (order_id, customer_id, status, amount)
GROUP BY
    customer_id
ORDER BY
    customer_id;

-- example: conditional-metrics-where-paid
-- 問い：直前の SELECT に問い合わせ全体の WHERE を加えると、何が変わるか。
-- 元の入力・出力列・集約の FILTER は揃え、GROUP BY の前に WHERE status = 'paid' を加える。
-- これは意図した結果の差を観察する比較であり、全注文を残す CASE・FILTER 版の同等な書き換えではない。
-- 処理を追うと、10 注文から未払いの 4 行を除き、支払済み 6 行を顧客ごとに集約する。
-- 未払いしかない顧客 2 は入力が 0 行になり、GROUP BY が作る結果からグループごと消える。
-- 残る顧客は 1・3・4・5 であり、order_count も「WHERE 通過後の注文」の件数へ変わる。
-- 顧客 1 の order_count は 5 から 3、顧客 5 は 2 から 1 になる。列名が同じでも対象は元の全注文ではない。
-- 支払済みの行はすべて残るため、残った顧客の支払済み件数・判明件数・合計・平均は直前と同じである。
-- ただし未払いの指標へ渡せる行はなく、未払いの二つの件数は 0、合計と平均は NULL になる。
-- 顧客 1 の元の未払い 2 件・合計 120.00・平均 60 は、この問い合わせからは求められない。
-- FILTER が WHERE で除いた行を復元するわけではない。各 FILTER は既に絞られた入力に対して働く。
-- 支払済みの顧客だけを支払済み注文の範囲で報告する要件なら WHERE が適する。
-- 全注文件数や未払いの指標も同じ行で報告したい要件なら、直前の版のように状態を全体の WHERE に書かない。
-- 支払済みの金額 NULL は WHERE を通る。顧客 3 と 5 の平均 NULL を 0 へ置き換える操作ではない。
-- 結果の粒度は残った 1 顧客 1 行であり、最終 ORDER BY でその顧客順を確定する。
SELECT
    customer_id,
    COUNT(*) AS order_count,
    COUNT(*) FILTER (
        WHERE
            status = 'paid'
    ) AS paid_order_count,
    COUNT(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS known_paid_amount_count,
    SUM(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS known_paid_total,
    AVG(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS known_paid_average,
    COUNT(*) FILTER (
        WHERE
            status = 'unpaid'
    ) AS unpaid_order_count,
    COUNT(amount) FILTER (
        WHERE
            status = 'unpaid'
    ) AS known_unpaid_amount_count,
    SUM(amount) FILTER (
        WHERE
            status = 'unpaid'
    ) AS known_unpaid_total,
    AVG(amount) FILTER (
        WHERE
            status = 'unpaid'
    ) AS known_unpaid_average
FROM
    (
        VALUES
            (
                101,
                1,
                CAST('paid' AS VARCHAR(12)),
                CAST(100.00 AS DECIMAL(10, 2))
            ),
            (102, 1, 'paid', 0.00),
            (103, 1, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (104, 1, 'unpaid', 60.00),
            (105, 1, 'unpaid', 60.00),
            (201, 2, 'unpaid', 80.00),
            (301, 3, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (401, 4, 'paid', 0.00),
            (501, 5, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (502, 5, 'unpaid', 40.00)
    ) AS sample_orders (order_id, customer_id, status, amount)
WHERE
    status = 'paid'
GROUP BY
    customer_id
ORDER BY
    customer_id;
