-- example: top-paid-orders-with-ties
-- 主例は、支払済みで金額が判明している注文から、同額を含めて金額上位 8 位まで確認する。
-- PARTITION BY を省くと候補全体で順位を付ける。ウィンドウ内は金額降順で、同額は同順位になる。
-- RANK は金額が上の注文数に 1 を加えた順位を返す。1 位が 2 行なら次は 3 位となる。
-- 順位は内側の SELECT で求め、外側の WHERE で絞る。表示のための注文 ID は最後の ORDER BY に置く。
WITH
    ranked_orders AS (
        SELECT
            order_id,
            customer_id,
            amount,
            RANK() OVER (
                ORDER BY
                    amount DESC
            ) AS amount_rank
        FROM
            practice.orders
        WHERE
            status = 'paid'
            AND amount IS NOT NULL
    )
SELECT
    order_id,
    customer_id,
    amount,
    amount_rank
FROM
    ranked_orders
WHERE
    amount_rank <= 8
ORDER BY
    amount DESC,
    order_id;

-- example: top-paid-orders-fixed-limit
-- 要件が変わる比較。確認枠が最大 8 件なら、各行に異なる番号を付ける ROW_NUMBER を使う。
-- 同額なら注文 ID の小さい行を先に選ぶ。境界の 250.00 では 101 が残り、102 は確認枠の外になる。
WITH
    numbered_orders AS (
        SELECT
            order_id,
            customer_id,
            amount,
            ROW_NUMBER() OVER (
                ORDER BY
                    amount DESC,
                    order_id
            ) AS review_position
        FROM
            practice.orders
        WHERE
            status = 'paid'
            AND amount IS NOT NULL
    )
SELECT
    order_id,
    customer_id,
    amount,
    review_position
FROM
    numbered_orders
WHERE
    review_position <= 8
ORDER BY
    amount DESC,
    order_id;

-- example: top-paid-order-amount-levels
-- 要件が変わる比較。高い方から異なる 8 種類の金額に該当する注文を確認する。
-- DENSE_RANK は同額をまとめ、次の異なる金額へ進むたびに順位を 1 増やす。
-- 1 位が 2 行でも次は 2 位となり、この入力では 100.00 の注文まで含む。
WITH
    ranked_amounts AS (
        SELECT
            order_id,
            customer_id,
            amount,
            DENSE_RANK() OVER (
                ORDER BY
                    amount DESC
            ) AS amount_level_rank
        FROM
            practice.orders
        WHERE
            status = 'paid'
            AND amount IS NOT NULL
    )
SELECT
    order_id,
    customer_id,
    amount,
    amount_level_rank
FROM
    ranked_amounts
WHERE
    amount_level_rank <= 8
ORDER BY
    amount DESC,
    order_id;
