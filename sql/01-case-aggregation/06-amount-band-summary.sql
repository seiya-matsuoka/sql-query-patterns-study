-- example: amount-band-summary-direct
-- 問い：注文を金額帯に分類し、金額帯ごとの件数・判明金額の合計・平均を求める。
-- 注文ごとの金額帯を読む段階から、どの金額帯に何件あるかを報告する場面へ進む。
-- 入力は専用の 10 注文で、1 行は 1 注文を表す。金額は非負の DECIMAL、NULL は金額不明である。
-- 既存の金額帯の境界に、同額の別注文と金額不明の別注文を加え、共通表は変更しない。
-- 分類キー amount_band_no は、1 が 100.00 未満、2 が 100.00 以上 500.00 未満、3 が 500.00 以上を表す。
-- 金額不明はキーも NULL にする。これは未分類を表す値であり、注文が存在しない意味ではない。
-- 検索 CASE は金額不明を先に扱い、残りは大きい境界から判定する。
-- 100.00 はキー 2、500.00 はキー 3 になり、実額 0.00 はキー 1 に入る。
-- GROUP BY は各注文で得た分類キーが同じ行をまとめ、結果の 1 行を 1 金額帯にする。
-- 金額自体や order_id はグループのキーにしない。同じ帯の異なる金額・別注文を一緒に集計するためである。
-- NULL キー同士も一つのグループになる。NULL = NULL が真という意味ではなく、GROUP BY のまとめ方である。
-- order_count は金額不明も含む注文件数、known_amount_count は金額が判明している注文の件数である。
-- known_total は判明金額だけの合計、known_average はその合計を known_amount_count で割った平均である。
-- AVG は NULL を分母に含めず、実額 0.00 は含める。COUNT(*) を平均の分母にしているわけではない。
-- キー 1 は 99.99 / 2 = 49.995、キー 2 は 800.00 / 4 = 200、キー 3 は 1000.01 / 2 = 500.005 となる。
-- ID 103 と 109 の 100.00 は別注文なので両方を含む。DISTINCT で同額を取り除く集計ではない。
-- NULL キーの 2 注文は、件数 2・判明件数 0・合計 NULL・平均 NULL となる。
-- 金額不明を 0 円と確定したり、NULL キーのグループ自体を除去したりしない。
-- SELECT と GROUP BY に同じ分類式を書くことで、表示するキーとまとめるキーを揃える。
-- 次の派生表版とは、入力の重複数・分類規則・集約対象・出力列・順序を揃えた同等比較である。
-- 直接記述は問い合わせの階層が少ない。分類式を複数箇所で保守しにくい場合は次の形を選べる。
-- 最終 ORDER BY の NULLS LAST で未分類を最後に置く。GROUP BY 自体は表示順を保証しない。
-- AVG の表示桁は PostgreSQL の numeric の出力に従い、照合のための丸めや NULL の置換は行わない。
SELECT
    CASE
        WHEN amount IS NULL THEN CAST(NULL AS INTEGER)
        WHEN amount >= 500.00 THEN 3
        WHEN amount >= 100.00 THEN 2
        ELSE 1
    END AS amount_band_no,
    COUNT(*) AS order_count,
    COUNT(amount) AS known_amount_count,
    SUM(amount) AS known_total,
    AVG(amount) AS known_average
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
            (108, CAST(NULL AS DECIMAL(10, 2))),
            (109, 100.00),
            (110, CAST(NULL AS DECIMAL(10, 2)))
    ) AS sample_orders (order_id, amount)
GROUP BY
    CASE
        WHEN amount IS NULL THEN CAST(NULL AS INTEGER)
        WHEN amount >= 500.00 THEN 3
        WHEN amount >= 100.00 THEN 2
        ELSE 1
    END
ORDER BY
    amount_band_no NULLS LAST;

-- example: amount-band-summary-derived
-- 問い：分類する段階を派生表へ分けても、同じ金額帯別の集計を得られるか。
-- 入力は直前と同じ 10 注文である。問い合わせ単独でも読めるよう VALUES を再掲する。
-- 最も内側の VALUES は 1 注文 1 行であり、その外の SELECT で amount_band_no を付ける。
-- この内側の SELECT は集約せず、注文を増減させない。分類後も 10 行であり、同額の別注文も残る。
-- classified_orders は FROM 内の SELECT の結果を表として参照する名前であり、永続表を作らない。
-- 外側では amount_band_no を入力列として GROUP BY し、10 明細行を 4 集計行へまとめる。
-- 分類式を内側の 1 箇所へ置けるため、分類規則と集約の役割を分けて追いたい場合に適する。
-- 内側に order_id を残す必要はないが、ID を表示しないこと自体は重複除去を意味しない。
-- 100.00 の 2 行と NULL の 2 行は、それぞれ元の注文の数だけ外側へ渡る。
-- order_count は帯の全注文、known_amount_count は帯の非 NULL 金額を持つ注文を数える。
-- SUM と AVG はその非 NULL 金額を使い、AVG の分母は known_amount_count である。
-- キーが NULL の 2 行も同じグループにまとまり、件数 2・判明件数 0・合計と平均 NULL を返す。
-- 同じ入力・分類式・重複数・集約単位なら直接記述と同等になる。
-- 内側で行を絞る、重複を除く、金額を置換する、キーの境界を変える場合は、この同等条件から外れる。
-- 両版とも最終結果をキーの昇順・NULL を最後に並べるため、期待 CSV の列・行・順序も一致する。
-- 派生表にしたことは物理的な一時保存や評価回数の保証ではない。性能は両版とも未評価である。
SELECT
    amount_band_no,
    COUNT(*) AS order_count,
    COUNT(amount) AS known_amount_count,
    SUM(amount) AS known_total,
    AVG(amount) AS known_average
FROM
    (
        SELECT
            amount,
            CASE
                WHEN amount IS NULL THEN CAST(NULL AS INTEGER)
                WHEN amount >= 500.00 THEN 3
                WHEN amount >= 100.00 THEN 2
                ELSE 1
            END AS amount_band_no
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
                    (108, CAST(NULL AS DECIMAL(10, 2))),
                    (109, 100.00),
                    (110, CAST(NULL AS DECIMAL(10, 2)))
            ) AS sample_orders (order_id, amount)
    ) AS classified_orders
GROUP BY
    amount_band_no
ORDER BY
    amount_band_no NULLS LAST;
