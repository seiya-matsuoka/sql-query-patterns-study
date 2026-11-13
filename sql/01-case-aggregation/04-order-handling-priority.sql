-- example: order-action-priority
-- 問い：未払いと高額の両方に該当する注文で、先に必要な対応を一つ選ぶ。
-- 出荷前の注文一覧に「次に行う対応」を付ける場面で、単なる金額帯から複数列の業務判断へ進む。
-- 入力は VALUES で用意する専用の 8 注文で、結果の 1 行も 1 注文を表す。
-- status の paid / unpaid だけを出荷判定の対象にする。refunded はこの規則では未定義の状態である。
-- NULL の状態は未登録、NULL の金額は不明であり、それぞれ別の情報である。
-- 共通の study.orders の状態制約は変更せず、未定義状態や状態 NULL はこの問い合わせ内だけで扱う。
-- 採用する左列の業務規則は、状態確認 → 入金待ち → 高額確認 → 金額確認 → 出荷可の順である。
-- 状態 NULL と未定義状態は先に状態確認へ分類し、既知の状態だけで未払い・金額の判断へ進む。
-- 分類後もすべての入力行を結果に残し、選んだ対応を元の状態・金額と並べて読む。
-- 未払いを先に選ぶのは、高額でも入金前には出荷確認を進めないという、この例の要件による。
-- 右列は高額確認を入金待ちより先に選ぶ別の業務規則である。二つの CASE は同等ではない。
-- ID 204 は unpaid かつ 500.00 なので、左は入金待ち、右は高額確認になる。
-- ID 202 は支払済みの高額、ID 203 は少額の未払いであり、両列の結果がそれぞれ一致する。
-- ID 205 の金額 NULL は大小比較が真にならず、金額確認になる。
-- ID 206 は金額 NULL でも未払いが分かるため、両列とも入金待ちを選ぶ。
-- ID 207 / 208 は 500.00 でも最初に状態確認となり、後ろの金額条件より状態の確認を優先する。
-- 検索 CASE は異なる列の条件や範囲条件を組み合わせるために適する。
-- 一つのコードを固定ラベルへ変えるだけなら、02-customer-tier-labels.sql の単純 CASE が読みやすい。
-- 複数の問題をすべて表示する要件なら、対応ごとのフラグ列などが適する。
-- ここでは最優先の一つだけを返す要件なので、一つの CASE を採用する。
SELECT
    order_id,
    status,
    amount,
    CASE
        WHEN status IS NULL THEN '状態確認'
        WHEN status <> 'paid'
        AND status <> 'unpaid' THEN '状態確認'
        WHEN status = 'unpaid' THEN '入金待ち'
        WHEN amount >= 500.00 THEN '高額確認'
        WHEN amount IS NULL THEN '金額確認'
        ELSE '出荷可'
    END AS payment_first_action,
    CASE
        WHEN status IS NULL THEN '状態確認'
        WHEN status <> 'paid'
        AND status <> 'unpaid' THEN '状態確認'
        WHEN amount >= 500.00 THEN '高額確認'
        WHEN status = 'unpaid' THEN '入金待ち'
        WHEN amount IS NULL THEN '金額確認'
        ELSE '出荷可'
    END AS amount_first_action
FROM
    (
        VALUES
            (
                201,
                CAST('paid' AS VARCHAR(12)),
                CAST(100.00 AS DECIMAL(10, 2))
            ),
            (202, 'paid', 500.00),
            (203, 'unpaid', 80.00),
            (204, 'unpaid', 500.00),
            (205, 'paid', CAST(NULL AS DECIMAL(10, 2))),
            (206, 'unpaid', CAST(NULL AS DECIMAL(10, 2))),
            (207, 'refunded', 500.00),
            (208, CAST(NULL AS VARCHAR(12)), 500.00)
    ) AS sample_orders (order_id, status, amount)
ORDER BY
    order_id;
