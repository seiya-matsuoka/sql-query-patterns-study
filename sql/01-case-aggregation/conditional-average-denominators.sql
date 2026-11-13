-- example: conditional-average-input-values
-- 問い：支払済み金額の平均を求める前に、ELSE 省略と ELSE 0.00 が各注文からどの値を渡すか。
-- 入力は conditional-order-metrics.sql の顧客 1 と同じ 5 注文で、1 注文 1 行の明細を保つ。
-- ここでは集約せず、後の AVG の分子・分母を、元の金額と二つの CASE の結果から追う。
-- paid_amount は支払済みなら金額、それ以外は ELSE 省略による NULL である。
-- paid_amount_else_zero は支払済みなら同じ金額、それ以外は 0.00 である。
-- ID 101 は両列に 100.00、ID 102 は両列に実額 0.00 を渡し、どちらも AVG の分母に含まれる。
-- ID 103 は条件が真なので THEN amount を返す。amount が NULL のため、ELSE 0.00 があっても NULL のままである。
-- ELSE は THEN が返した NULL を置き換えない。条件に該当しなかった行へ適用する分岐である。
-- 未払いの ID 104 と 105 は、左列では NULL、右列では作り出した 0.00 となる。
-- したがって左列の非 NULL 値は 100.00 と 0.00 の 2 個、右列はそれらと二つの 0.00 の 4 個である。
-- 左の平均は 100.00 / 2 = 50、右の平均は 100.00 / 4 = 25 となる。元の 5 行で割る計算ではない。
-- 右列では、実際に判明した 0 円と、未払いを平均の対象に入れるための 0 が同じ値になる。
-- この違いを保って支払済み判明金額だけの平均を求めるなら、左列の CASE または AVG(amount) の FILTER を選ぶ。
-- 右列は値と分母の変化を観察する比較であり、左列の同等な短縮・修正ではない。
-- 元金額は非負の DECIMAL、NULL は不明であり、並び順は一意な order_id で確定する。
SELECT
    order_id,
    status,
    amount,
    CASE
        WHEN status = 'paid' THEN amount
    END AS paid_amount,
    CASE
        WHEN status = 'paid' THEN amount
        ELSE 0.00
    END AS paid_amount_else_zero
FROM
    (
        VALUES
            (
                101,
                CAST('paid' AS VARCHAR(12)),
                CAST(100.00 AS DECIMAL(10, 2))
            ),
            (102, 'paid', 0.00),
            (103, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (104, 'unpaid', 60.00),
            (105, 'unpaid', 60.00)
    ) AS sample_orders (order_id, status, amount)
ORDER BY
    order_id;

-- example: conditional-average-denominator-comparison
-- 問い：金額 NULL・実額 0・支払済みなしを含む顧客ごとに、二つの平均とその分母を比較する。
-- 入力は conditional-order-metrics.sql と同じ 10 注文であり、結果は注文がある 1 顧客 1 行の 5 行である。
-- order_count は全注文数、paid_order_count は金額不明も含む支払済み注文数である。
-- known_paid_amount_count は支払済みで金額が非 NULL の件数で、paid_average_case と paid_average_filter の共通の分母になる。
-- 両平均は同じ条件と金額を使い、CASE 側は非該当を NULL にするため、同じ値・重複数を対象にする同等比較である。
-- 判明金額が 0 個なら両平均は NULL となる。平均を求められない状態を 0 円と断定しない。
-- else_zero_value_count は ELSE 0.00 を付けた CASE の非 NULL 値を数え、paid_average_else_zero の分母を見せる。
-- 同じ CASE を COUNT と AVG に使うため、右の平均がどの値の個数で割っているかを対応させられる。
-- この分母は「金額が判明した支払済みの件数 + 条件が真でない行の件数」であり、金額 NULL の支払済みは含まない。
-- この入力では状態が paid と unpaid だけなので、後半は未払い件数に等しい。全注文数と常に等しいわけではない。
-- 顧客 1 は 2 個から 4 個へ分母が増え、平均は 50 から 25 になる。支払済み件数 3 も全注文数 5 も分母ではない。
-- 顧客 2 は支払済みがないため左の平均は NULL、右は未払い 1 行から作った 0.00 / 1 = 0 になる。
-- 顧客 3 は唯一の行が金額 NULL の支払済みなので、ELSE の 0.00 を作る行がなく、右も分母 0・平均 NULL である。
-- 顧客 4 は実額 0 の支払済み 1 件で、両方とも分母 1・平均 0 になる。顧客 2 の作り出した 0 と意味が異なる。
-- 顧客 5 は支払済み 1 件でも判明金額がなく、左の平均は NULL となる。
-- 右はその金額 NULL を補わず、未払い行だけを 0.00 にするので分母 1・平均 0 になる。
-- ELSE 0.00 は平均の要件を変える。未払いも 0 として含める指標が必要なときに、その分母の定義と合わせて使う。
-- 支払済みの金額不明も 0 とみなして全注文数で割る指標は、この式とは異なる。ここでは不明金額の補完は行わない。
-- 顧客 6 の注文はないためグループもない。入力が 0 行の集約は empty-conditional-aggregates.sql で比較する。
-- AVG の値は丸めず、PostgreSQL の numeric の表示をそのまま使う。性能は未評価である。
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
