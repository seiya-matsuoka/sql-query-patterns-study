-- example: running-paid-amount-by-row-and-time
-- 主例は支払済み注文を顧客ごとに並べ、注文を 1 件処理するたびに判明額の累積を出す。
-- フレームは BETWEEN 開始 AND 終了 で読む。UNBOUNDED PRECEDING は顧客の先頭を指す。
-- ROWS の CURRENT ROW は現在の 1 行までである。注文 ID で同日時の処理順を決めると、101 から 102 へ累積値が進む。
-- 要件が変わる比較として日時時点の累積も示す。RANGE の CURRENT ROW は同じ計算用の並び値の全行を含める。
-- RANGE は日時だけで並べるため、101 と 102 に同じ累積額が載る。最後の ORDER BY で表示順を揃える。
-- SUM はフレーム内の判明額だけを合計し、全額 NULL のときは NULL を返す。
SELECT
    customer_id,
    order_id,
    ordered_at,
    amount,
    SUM(amount) OVER (
        PARTITION BY
            customer_id
        ORDER BY
            ordered_at,
            order_id ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS running_amount_by_row,
    SUM(amount) OVER (
        PARTITION BY
            customer_id
        ORDER BY
            ordered_at RANGE BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS running_amount_by_time
FROM
    practice.orders
WHERE
    status = 'paid'
ORDER BY
    customer_id,
    ordered_at,
    order_id;

-- example: moving-paid-average-by-count-and-time
-- 主例は直近 3 件までの支払済み注文の平均を出す。ROWS の 2 PRECEDING は現在行の 2 行前を指す。
-- 顧客の先頭付近では、現在行と実在する前の行だけをフレームに含める。
-- 要件が変わる比較として、RANGE では現在の日時から 1 日前までの注文を両端を含めて集計する。
-- 日時差で範囲を指定する RANGE は計算用の並び値を日時列 1 つにし、同日時の全行を含める。
-- 24 時間を超える間隔がある 1002 では、ROWS だけが 1001 を含む。両方とも AVG の分母はフレーム内の判明額の件数である。
SELECT
    customer_id,
    order_id,
    ordered_at,
    amount,
    ROUND(
        AVG(amount) OVER (
            PARTITION BY
                customer_id
            ORDER BY
                ordered_at,
                order_id ROWS BETWEEN 2 PRECEDING
                AND CURRENT ROW
        ),
        2
    ) AS moving_average_last_three_orders,
    ROUND(
        AVG(amount) OVER (
            PARTITION BY
                customer_id
            ORDER BY
                ordered_at RANGE BETWEEN INTERVAL '1' DAY PRECEDING
                AND CURRENT ROW
        ),
        2
    ) AS moving_average_last_day
FROM
    practice.orders
WHERE
    status = 'paid'
ORDER BY
    customer_id,
    ordered_at,
    order_id;
