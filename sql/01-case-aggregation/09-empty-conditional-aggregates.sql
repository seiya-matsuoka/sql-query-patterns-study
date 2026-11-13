-- example: empty-conditional-aggregate-overall
-- 問い：入力を 0 行にしたとき、条件付き AVG と ELSE 0.00 はどのような集約結果になるか。
-- 入力はこの比較専用の 2 注文で、顧客 1 の金額不明の支払済みと、顧客 2 の 80.00 の未払いである。
-- 共通表には触れず、WHERE customer_id = 6 で両行を除き、集約へ渡す入力を 0 行にする。
-- これは「顧客 6 を表す行を追加する」操作ではない。入力の中に顧客 6 の注文は存在しない。
-- GROUP BY のない集約なので、結果は空の入力全体をまとめた 1 行になる。
-- 結果の 1 行は顧客一覧の 1 顧客ではなく、WHERE を通った入力全体の集計を表す。
-- order_count、paid_order_count、known_paid_amount_count はすべて 0 になる。
-- ELSE 省略の CASE と FILTER には非 NULL の金額がなく、paid_average_case と paid_average_filter はともに NULL になる。
-- ELSE 0.00 のある CASE も、評価する入力行が 0 行なので、平均へ渡す 0.00 を作れない。
-- そのため else_zero_value_count も 0、paid_average_else_zero も NULL である。
-- 条件付き件数 0 と平均 NULL を持つ 1 行であり、ヘッダーだけの 0 行の結果とは異なる。
-- 未払い行が存在する顧客 2 の平均を ELSE 0.00 で 0 にする前教材とは、入力があるかどうかが違う。
-- この形は、検索対象の注文が 0 件でも全体の集計値を 1 行で返したい場合に適する。
-- NULL を 0 へ変える既定値の指定として ELSE を読むのではなく、各行での値の選択として読む。
SELECT
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
    AVG(
        CASE
            WHEN status = 'paid' THEN amount
        END
    ) AS paid_average_case,
    AVG(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS paid_average_filter,
    COUNT(
        CASE
            WHEN status = 'paid' THEN amount
            ELSE 0.00
        END
    ) AS else_zero_value_count,
    AVG(
        CASE
            WHEN status = 'paid' THEN amount
            ELSE 0.00
        END
    ) AS paid_average_else_zero
FROM
    (
        VALUES
            (
                101,
                1,
                CAST('paid' AS VARCHAR(12)),
                CAST(NULL AS DECIMAL(10, 2))
            ),
            (201, 2, 'unpaid', 80.00)
    ) AS sample_orders (order_id, customer_id, status, amount)
WHERE
    customer_id = 6;

-- example: empty-conditional-aggregate-grouped
-- 問い：同じ空の入力を顧客ごとに GROUP BY すると、結果はどう変わるか。
-- 入力の 2 注文・WHERE・集約式は直前と同じにし、customer_id の出力と GROUP BY を加える。
-- WHERE 通過後に顧客 ID が一つもないので、GROUP BY が作るグループは 0 個、結果も 0 行となる。
-- COUNT が 0、平均が NULL の顧客 6 の行を作るわけではない。顧客 ID が NULL の 1 行にもならない。
-- expected の CSV は列名だけを持ち、データ行を持たない。
-- 金額帯集計の NULL キーは「NULL キーを持つ入力行がある」ため 1 グループになるが、この空入力にはその行もない。
-- 前教材の顧客 2 も、元の未払い行を入力に残すからグループがあったのであり、支払済み件数 0 がグループを作ったわけではない。
-- この形は入力に存在する顧客ごとの一覧に適する。注文のない顧客も表示する要件は別途の入力設計が必要である。
-- 最終 ORDER BY は、グループがある場合の表示順も安定するように指定する。空のグループを補う効果はない。
-- 全体集約の 1 行と顧客別集約の 0 行は、結果の粒度が異なる比較であり、同等な書き換えではない。
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
    AVG(
        CASE
            WHEN status = 'paid' THEN amount
        END
    ) AS paid_average_case,
    AVG(amount) FILTER (
        WHERE
            status = 'paid'
    ) AS paid_average_filter,
    COUNT(
        CASE
            WHEN status = 'paid' THEN amount
            ELSE 0.00
        END
    ) AS else_zero_value_count,
    AVG(
        CASE
            WHEN status = 'paid' THEN amount
            ELSE 0.00
        END
    ) AS paid_average_else_zero
FROM
    (
        VALUES
            (
                101,
                1,
                CAST('paid' AS VARCHAR(12)),
                CAST(NULL AS DECIMAL(10, 2))
            ),
            (201, 2, 'unpaid', 80.00)
    ) AS sample_orders (order_id, customer_id, status, amount)
WHERE
    customer_id = 6
GROUP BY
    customer_id
ORDER BY
    customer_id;
