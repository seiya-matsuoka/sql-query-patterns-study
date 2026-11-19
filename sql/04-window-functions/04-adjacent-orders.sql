-- example: adjacent-orders-lag-lead
-- 顧客ごとに、状態・金額を問わず前回・次回の注文 ID と日時を現在の注文に添える。
-- LAG・LEAD は顧客内で直前・直後の 1 行を直接参照できるため、主例に使う。
-- 同日時では注文 ID の小さい方を先とする。4 つの関数で使う同じウィンドウに WINDOW で名前を付ける。
-- 対応する行がなければ NULL を返す。注文 ID は非 NULL なので、その結果から前後行の有無を判定できる。
SELECT
    customer_id,
    order_id,
    ordered_at,
    LAG(order_id) OVER customer_history AS previous_order_id,
    LAG(ordered_at) OVER customer_history AS previous_ordered_at,
    LEAD(order_id) OVER customer_history AS next_order_id,
    LEAD(ordered_at) OVER customer_history AS next_ordered_at
FROM
    practice.orders
WINDOW
    customer_history AS (
        PARTITION BY
            customer_id
        ORDER BY
            ordered_at,
            order_id
    )
ORDER BY
    customer_id,
    ordered_at,
    order_id;

-- example: adjacent-orders-self-join
-- 同等な代替記述。同じ対象・計算順で顧客別の連番を作り、前後 1 番の注文を自己結合する。
-- 顧客 ID と連番の組に対して結合先は高々 1 行である。LEFT JOIN が端の行も残し、対応する列を NULL にする。
WITH
    numbered_orders AS (
        SELECT
            customer_id,
            order_id,
            ordered_at,
            ROW_NUMBER() OVER (
                PARTITION BY
                    customer_id
                ORDER BY
                    ordered_at,
                    order_id
            ) AS order_position
        FROM
            practice.orders
    )
SELECT
    o.customer_id,
    o.order_id,
    o.ordered_at,
    previous_order.order_id AS previous_order_id,
    previous_order.ordered_at AS previous_ordered_at,
    next_order.order_id AS next_order_id,
    next_order.ordered_at AS next_ordered_at
FROM
    numbered_orders AS o
    LEFT JOIN numbered_orders AS previous_order ON previous_order.customer_id = o.customer_id
    AND previous_order.order_position = o.order_position - 1
    LEFT JOIN numbered_orders AS next_order ON next_order.customer_id = o.customer_id
    AND next_order.order_position = o.order_position + 1
ORDER BY
    o.customer_id,
    o.ordered_at,
    o.order_id;

-- example: orders-on-adjacent-calendar-days
-- 要件が変わる比較。顧客ごとに注文日の前日・翌日に注文があるかを調べる。
-- 日時から日付を取り出し、暦上の 1 日前・1 日後を照合する。EXISTS なら同じ日に複数件あっても明細は 1 行のままである。
-- 注文 104 の次回注文は 103 である。104 の注文日の翌日は注文がなく、翌日の有無は FALSE になる。
WITH
    orders_with_date AS (
        SELECT
            customer_id,
            order_id,
            ordered_at,
            CAST(ordered_at AS DATE) AS order_date
        FROM
            practice.orders
    )
SELECT
    o.customer_id,
    o.order_id,
    o.order_date,
    EXISTS (
        SELECT
            1
        FROM
            orders_with_date AS previous_day
        WHERE
            previous_day.customer_id = o.customer_id
            AND previous_day.order_date = CAST(o.order_date - INTERVAL '1' DAY AS DATE)
    ) AS has_order_on_previous_day,
    EXISTS (
        SELECT
            1
        FROM
            orders_with_date AS next_day
        WHERE
            next_day.customer_id = o.customer_id
            AND next_day.order_date = CAST(o.order_date + INTERVAL '1' DAY AS DATE)
    ) AS has_order_on_next_day
FROM
    orders_with_date AS o
ORDER BY
    o.customer_id,
    o.ordered_at,
    o.order_id;
