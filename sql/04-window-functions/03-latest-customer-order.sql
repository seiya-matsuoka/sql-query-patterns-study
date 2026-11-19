-- example: latest-order-per-customer
-- 状態・金額を問わず、注文履歴がある顧客ごとの最新注文を 1 件選ぶ。
-- ROW_NUMBER で顧客ごとに番号を付け、注文日時が新しい順、同日時なら注文 ID が大きい順に選ぶ。
-- 1 行に決める要件のため、同日時にも選択順を定める。顧客 1 は同時刻の 101・102 から 102 が選ばれ、105 は日時が古い。
WITH
    numbered_orders AS (
        SELECT
            order_id,
            customer_id,
            status,
            amount,
            ordered_at,
            ROW_NUMBER() OVER (
                PARTITION BY
                    customer_id
                ORDER BY
                    ordered_at DESC,
                    order_id DESC
            ) AS newest_position
        FROM
            practice.orders
    )
SELECT
    customer_id,
    order_id,
    ordered_at,
    status,
    amount
FROM
    numbered_orders
WHERE
    newest_position = 1
ORDER BY
    customer_id;
