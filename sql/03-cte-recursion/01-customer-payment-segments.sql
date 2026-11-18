-- example: customer-payment-segments-cte
-- 主例：全顧客を支払済み注文の金額確定状況と合計で分類し、分類別の件数・判明合計を報告する。
-- WITH 名前 AS (問い合わせ) は、この 1 問い合わせ内で参照する結果に名前を付ける CTE の構文である。
-- 複数の CTE はカンマで区切り、後の CTE から先に定義した CTE を参照できる。
-- customer_paid_totals は顧客別集計、classified_customers は顧客別分類を表す名前である。
-- 注文から 1 顧客 1 行へ集計し、その粒度のまま分類した後、最後に 1 分類 1 行へ再集計する。
-- 段階の役割を名前から追えるため CTE を主例とする。名前は保存用の表を作るものではない。
-- 読解上の依存関係を表しており、上からの物理実行・必ず実体化されること・高速化を保証しない。
--
-- 全顧客を残すため customers から LEFT JOIN し、paid 条件は ON に置く。
-- COUNT(o.order_id) は実在する paid 注文、COUNT(o.amount) はそのうち金額が判明した注文を数える。
-- 結合なしの補完行を COUNT(*) で数えない。顧客 ID でまとめるので、同名の別顧客も統合しない。
-- 注文なしと未払いだけは、ともに no-paid-orders とする。両者の違いをこの帳票では分類しない。
-- paid があり金額 NULL を一つでも含めば amount-unknown とし、全額 NULL もここに含める。
-- 本帳票は全額の確定を要求するため、判明分だけで 500 に達する顧客 1 も不明ありを優先する。
-- 全額判明なら、合計 500.00 以上を known-at-least-500、未満を known-below-500 とする。
-- 実額 0 は判明額として数える。該当注文なし・全額 NULL の SUM は NULL のままにし、0 へ置換しない。
-- 最後の known_paid_total も判明分だけの合計であり、amount-unknown の全額が確定した値ではない。
WITH
    customer_paid_totals AS (
        SELECT
            c.customer_id,
            COUNT(o.order_id) AS paid_order_count,
            COUNT(o.amount) AS known_paid_amount_count,
            SUM(o.amount) AS known_paid_total
        FROM
            practice.customers AS c
            LEFT JOIN practice.orders AS o ON o.customer_id = c.customer_id
            AND o.status = 'paid'
        GROUP BY
            c.customer_id
    ),
    classified_customers AS (
        SELECT
            totals.customer_id,
            totals.paid_order_count,
            totals.known_paid_amount_count,
            totals.known_paid_total,
            CASE
                WHEN totals.paid_order_count = 0 THEN 'no-paid-orders'
                WHEN totals.known_paid_amount_count < totals.paid_order_count THEN 'amount-unknown'
                WHEN totals.known_paid_total >= 500.00 THEN 'known-at-least-500'
                ELSE 'known-below-500'
            END AS customer_group
        FROM
            customer_paid_totals AS totals
    )
SELECT
    classified.customer_group,
    COUNT(*) AS customer_count,
    SUM(classified.paid_order_count) AS paid_order_count,
    SUM(classified.known_paid_amount_count) AS known_paid_amount_count,
    SUM(classified.known_paid_total) AS known_paid_total
FROM
    classified_customers AS classified
GROUP BY
    classified.customer_group
ORDER BY
    classified.customer_group;

-- example: customer-payment-segments-derived
-- 同等な代替記述：同じ段階を FROM (問い合わせ) AS 名前 の派生表として内側へ入れる。
-- 派生表は FROM の入力となる問い合わせに別名を付ける。ここでは totals と classified が各段階に対応する。
-- 内側の顧客別集計から、その外の分類、最も外の分類別再集計へ読み進める。
-- CTE と同じ全顧客・paid 条件・NULL の扱い・分類規則・重複・粒度・列・最終順序を保つため同等である。
-- 単独の短い中間結果なら派生表でも読みやすい。この例では名前付きの段階を並べる CTE を採用する。
SELECT
    classified.customer_group,
    COUNT(*) AS customer_count,
    SUM(classified.paid_order_count) AS paid_order_count,
    SUM(classified.known_paid_amount_count) AS known_paid_amount_count,
    SUM(classified.known_paid_total) AS known_paid_total
FROM
    (
        SELECT
            totals.customer_id,
            totals.paid_order_count,
            totals.known_paid_amount_count,
            totals.known_paid_total,
            CASE
                WHEN totals.paid_order_count = 0 THEN 'no-paid-orders'
                WHEN totals.known_paid_amount_count < totals.paid_order_count THEN 'amount-unknown'
                WHEN totals.known_paid_total >= 500.00 THEN 'known-at-least-500'
                ELSE 'known-below-500'
            END AS customer_group
        FROM
            (
                SELECT
                    c.customer_id,
                    COUNT(o.order_id) AS paid_order_count,
                    COUNT(o.amount) AS known_paid_amount_count,
                    SUM(o.amount) AS known_paid_total
                FROM
                    practice.customers AS c
                    LEFT JOIN practice.orders AS o ON o.customer_id = c.customer_id
                    AND o.status = 'paid'
                GROUP BY
                    c.customer_id
            ) AS totals
    ) AS classified
GROUP BY
    classified.customer_group
ORDER BY
    classified.customer_group;
