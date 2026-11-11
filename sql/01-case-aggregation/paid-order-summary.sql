-- example: paid-summary-case
-- 顧客 1 の支払済み注文件数と、判明している支払済み金額の合計を 1 行で求める。
-- study.orders の 1 行は 1 注文を表す。WHERE で顧客を選んだ後、同じ入力から二つの値を集計する。
-- 顧客 1 の注文は、支払済みが 100.00 と NULL、未払いが 200.00 の計 3 件である。
-- COUNT(式) が数えるのは、式の結果が NULL でない行である。
-- 支払済みなら金額にかかわらず 1 を返すため、金額が不明な支払済み注文も数えられる。
-- ELSE を省略すると、条件が真でない行の CASE は NULL となる。未払いは COUNT の対象から外れる。
-- SUM には支払済みの金額を渡す。未払いと支払済みの金額 NULL はともに加算されない。
-- 期待する件数は 2、判明分の合計は 100.00 である。合計は不明分を含む総額ではない。
SELECT
    COUNT(
        CASE
            WHEN status = 'paid' THEN 1
        END
    ) AS paid_order_count,
    SUM(
        CASE
            WHEN status = 'paid' THEN amount
        END
    ) AS known_paid_total
FROM
    study.orders
WHERE
    customer_id = 1;

-- example: paid-summary-filter
-- 直前の CASE 版と同じ顧客・支払条件・集計の粒度で、件数と合計を比較する。
-- FILTER は、それを付けた集約へ渡す行を選ぶ。COUNT(*) は選んだ行を金額 NULL も含めて数える。
-- SUM は選んだ行のうち、金額が NULL でない値を足す。結果は CASE 版と同じ 2 件、100.00 である。
-- COUNT(amount) に変えると判明している金額の個数になり、この入力では 1 件となる。
-- 集計ごとに条件を分けたい場合は FILTER が意図を表しやすい。
-- 問い合わせ全体の WHERE で未払いを除くと、同じ SELECT の他の集約でも未払いを使えなくなる。
SELECT
    COUNT(*) FILTER (
        WHERE
            status = 'paid'
    ) AS paid_order_count,
    SUM(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS known_paid_total
FROM
    study.orders
WHERE
    customer_id = 1;

-- example: paid-summary-by-customer
-- 注文がある顧客ごとに、全注文件数、支払済み件数、判明金額の件数と、三つの合計を比べる。
-- FROM が注文表なので、注文がない顧客 4 の行は作られない。
-- 支払状態を WHERE に書かないため、未払いしかない顧客 2 の集計行も残る。
-- SUM に対する ELSE 省略の CASE と FILTER は、加算する非 NULL の値が同じになる。
-- 顧客 1 は、三つとも 100.00 になる。既知の金額があるこのケースだけでは ELSE の差は見えない。
-- 顧客 2 は、支払済みが 0 件なので、ELSE 省略と FILTER の合計は NULL になる。
-- ELSE 0.00 を指定すると、顧客 2 の未払い行が 0.00 に変わり、合計も 0.00 になる。
-- 顧客 3 の唯一の注文は、金額不明の支払済み注文である。その行は WHEN に入り、ELSE が 0.00 を渡す行はない。
-- したがって三つの合計はすべて NULL であり、判明金額の件数は 0 である。
-- 未払い注文が加わると、その行を 0.00 にする ELSE 付きの合計だけが 0.00 になる。
-- 支払済みの判明金額の件数は 0 のままで、ELSE 省略と FILTER の合計は引き続き NULL である。
-- 0 円と合計を求められない状態を区別するには、合計と件数の意味を揃えて読む。
-- 期待 CSV と行順を照合できるよう、結果を顧客 ID 順に並べる。
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
    SUM(
        CASE
            WHEN status = 'paid' THEN amount
        END
    ) AS paid_total_case,
    SUM(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS paid_total_filter,
    SUM(
        CASE
            WHEN status = 'paid' THEN amount
            ELSE 0.00
        END
    ) AS paid_total_else_zero
FROM
    study.orders
GROUP BY
    customer_id
ORDER BY
    customer_id;

-- example: no-paid-order-rows
-- 顧客 2 の支払済み注文を集約せずに取り出す。
-- 顧客 2 には未払い注文があるが、両方の WHERE 条件を満たす行はない。
-- 結果は列名だけで、データ行は 0 件である。顧客 2 の集計行や NULL 値を持つ 1 行とは区別する。
SELECT
    order_id,
    amount
FROM
    study.orders
WHERE
    customer_id = 2
    AND status = 'paid'
ORDER BY
    order_id;

-- example: aggregate-on-empty-input
-- 注文がない顧客 4 を選び、入力が 0 行の状態で件数と合計を求める。
-- GROUP BY のない集約なので、空の入力から集計結果が 1 行返る。
-- COUNT(*) と条件付き COUNT はともに 0 を返す。三つの SUM はすべて NULL を返す。
-- ELSE 0.00 を指定しても、CASE を評価する入力行がないため、足し合わせる 0.00 は発生しない。
-- 顧客 2 の「未払い行があって支払済みがない」と、顧客 4 の「注文自体がない」の差を確かめる。
SELECT
    COUNT(*) AS order_count,
    COUNT(
        CASE
            WHEN status = 'paid' THEN 1
        END
    ) AS paid_order_count,
    SUM(
        CASE
            WHEN status = 'paid' THEN amount
        END
    ) AS paid_total_case,
    SUM(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS paid_total_filter,
    SUM(
        CASE
            WHEN status = 'paid' THEN amount
            ELSE 0.00
        END
    ) AS paid_total_else_zero
FROM
    study.orders
WHERE
    customer_id = 4;
