-- example: paid-order-metrics-window
-- 支払済みの各注文に、顧客別の判明合計・平均と、その合計に占める注文金額の割合を添える。
-- OVER は関数が参照するウィンドウを指定する。PARTITION BY customer_id で集計対象を顧客ごとに分ける。
-- OVER 内の ORDER BY は計算に使う順序を、フレームはその行の集計に含める範囲を指定する。
-- ここでは OVER 内の ORDER BY とフレーム指定を省き、WHERE で残した支払済み注文を顧客ごとにすべて集計する。
-- 集計前後とも 1 注文 1 行のまま顧客別の値を付けられるため、ウィンドウ集計を主例とする。
-- SUM・AVG は金額 NULL を除外する。平均の分母は判明額の件数で、実額 0 も数える。全額 NULL なら両方 NULL になる。
-- 構成比の分母は顧客の判明合計である。NULLIF で合計 0 を NULL に変え、金額・分母が不明の場合も構成比は NULL とする。
-- 分母が正なら実額 0 の構成比は 0% になる。平均と有効な構成比は小数第 2 位に丸める。
WITH
    paid_order_metrics AS (
        SELECT
            order_id,
            customer_id,
            amount,
            SUM(amount) OVER (
                PARTITION BY
                    customer_id
            ) AS known_paid_total,
            AVG(amount) OVER (
                PARTITION BY
                    customer_id
            ) AS known_paid_average
        FROM
            practice.orders
        WHERE
            status = 'paid'
    )
SELECT
    o.customer_id,
    c.customer_name,
    o.order_id,
    o.amount,
    o.known_paid_total,
    ROUND(o.known_paid_average, 2) AS known_paid_average,
    ROUND(100 * o.amount / NULLIF(o.known_paid_total, 0), 2) AS share_pct
FROM
    paid_order_metrics AS o
    JOIN practice.customers AS c ON c.customer_id = o.customer_id
ORDER BY
    o.customer_id,
    o.order_id;

-- example: paid-order-metrics-grouped-join
-- 同等な代替記述。同じ paid_orders から顧客別に 1 行ずつ集約し、顧客 ID で元の明細に結合する。
-- 各明細に対し、集約結果は GROUP BY、顧客は主キーと外部キーにより 1 行ずつ対応する。
-- 対象行・集計式・NULL と 0 の扱い・最終表示順を揃えると、ウィンドウ集計と同じ明細が得られる。
WITH
    paid_orders AS (
        SELECT
            order_id,
            customer_id,
            amount
        FROM
            practice.orders
        WHERE
            status = 'paid'
    ),
    customer_paid_metrics AS (
        SELECT
            customer_id,
            SUM(amount) AS known_paid_total,
            AVG(amount) AS known_paid_average
        FROM
            paid_orders
        GROUP BY
            customer_id
    )
SELECT
    o.customer_id,
    c.customer_name,
    o.order_id,
    o.amount,
    m.known_paid_total,
    ROUND(m.known_paid_average, 2) AS known_paid_average,
    ROUND(100 * o.amount / NULLIF(m.known_paid_total, 0), 2) AS share_pct
FROM
    paid_orders AS o
    JOIN customer_paid_metrics AS m ON m.customer_id = o.customer_id
    JOIN practice.customers AS c ON c.customer_id = o.customer_id
ORDER BY
    o.customer_id,
    o.order_id;
