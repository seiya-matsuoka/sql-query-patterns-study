-- example: amount-band-equivalent-ranges
-- 問い：注文金額を三つの金額帯へ分類し、上位からの判定と、重ならない範囲の判定を比べる。
-- 注文一覧に金額帯を付け、後続の確認作業へ渡す場面を想定する。ここでは集計しない。
-- 入力は専用の 8 注文で、amount は 0 以上の金額、NULL は金額不明を表す。
-- VALUES を FROM 内の表として使い、列名を order_id と amount にする。共通の注文表は変更しない。
-- 金額は小数点以下 2 桁の固定値とし、CAST では金額と NULL の DECIMAL 型を示す。
-- 規則は 100.00 未満が少額、100.00 以上 500.00 未満が中額、500.00 以上が高額である。
-- 結果の 1 行は 1 注文で、元金額と、二つの分類を比較する。
-- high_first_band は大きい境界から調べる。500.00 は最初の金額条件で高額になる。
-- 100.00 以上の条件へ進むのは、既に 500.00 以上ではなかった行である。
-- そのため下限だけでも中額を表せるが、WHEN の順序が規則の一部となる。
-- disjoint_band は各範囲の上下限を明記する。条件が重ならないので、範囲の列挙順に依存しない。
-- 短く上位から読める形と、各範囲を独立に確認しやすい形の比較であり、性能の優劣は未評価である。
-- 同じ入力・境界・返却ラベル・NULL 判定を使い、金額は 0 以上という前提で両列は同等になる。
-- 負数を許すと左列は ELSE の少額、右列は該当する WHEN がなく NULL となり、この同等性は崩れる。
-- NULL の大小比較は真にならない。先に IS NULL を判定し、金額不明を少額へ混ぜない。
-- 99.99 / 100.00 / 100.01 と 499.99 / 500.00 / 500.01 で、境界とその前後を観察する。
-- 期待する分類は ID 順に「少額、少額、中額、中額、中額、高額、高額、金額不明」である。
SELECT
    order_id,
    amount,
    CASE
        WHEN amount IS NULL THEN '金額不明'
        WHEN amount >= 500.00 THEN '高額'
        WHEN amount >= 100.00 THEN '中額'
        ELSE '少額'
    END AS high_first_band,
    CASE
        WHEN amount IS NULL THEN '金額不明'
        WHEN amount >= 0.00
        AND amount < 100.00 THEN '少額'
        WHEN amount >= 100.00
        AND amount < 500.00 THEN '中額'
        WHEN amount >= 500.00 THEN '高額'
    END AS disjoint_band
FROM
    (
        VALUES
            (101, CAST(0.00 AS DECIMAL(10, 2))),
            (102, 99.99),
            (103, 100.00),
            (104, 100.01),
            (105, 499.99),
            (106, 500.00),
            (107, 500.01),
            (108, CAST(NULL AS DECIMAL(10, 2)))
    ) AS sample_orders (order_id, amount)
ORDER BY
    order_id;

-- example: amount-band-condition-order
-- 問い：同じ下限条件の順序だけを変えると、金額帯の分類がどの行で変わるか。
-- 入力は直前と同じ 8 注文であり、結果も 1 注文 1 行のままである。
-- 左列は 500.00 以上を先に判定し、右列はより広い 100.00 以上を先に判定する。
-- 500.00 以上の金額は両方の条件を満たすが、CASE が返す値は最初に真になった WHEN の値である。
-- 条件をすべて比べて最も大きい境界を自動で採用する仕組みではない。
-- broad_first_band の 500.00 以上の分岐は、既に 100.00 以上の分岐に選ばれるため到達できない。
-- ID 106 と 107 は左が高額、右が中額になり、他の 6 行は一致する。
-- 100.00 ちょうどは両方で中額であり、この値だけの確認では順序の問題を発見できない。
-- この右列は違いを観察する完成済みの比較対象であり、同等な書き換えや修正課題ではない。
-- 三つの金額帯が必要な要件では左列か、前の問い合わせの排他的な範囲を採用する。
-- NULL は両列で最初に金額不明へ分類するため、今回の差は NULL 判定の違いからは生じない。
SELECT
    order_id,
    amount,
    CASE
        WHEN amount IS NULL THEN '金額不明'
        WHEN amount >= 500.00 THEN '高額'
        WHEN amount >= 100.00 THEN '中額'
        ELSE '少額'
    END AS high_first_band,
    CASE
        WHEN amount IS NULL THEN '金額不明'
        WHEN amount >= 100.00 THEN '中額'
        WHEN amount >= 500.00 THEN '高額'
        ELSE '少額'
    END AS broad_first_band
FROM
    (
        VALUES
            (101, CAST(0.00 AS DECIMAL(10, 2))),
            (102, 99.99),
            (103, 100.00),
            (104, 100.01),
            (105, 499.99),
            (106, 500.00),
            (107, 500.01),
            (108, CAST(NULL AS DECIMAL(10, 2)))
    ) AS sample_orders (order_id, amount)
ORDER BY
    order_id;
