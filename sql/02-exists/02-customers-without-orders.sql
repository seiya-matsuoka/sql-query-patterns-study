-- example: customers-without-any-order
-- 主例：まだ一度も注文していない顧客を、初回利用の案内対象として選ぶ。
-- NOT EXISTS は、副問い合わせが 0 行のとき TRUE を返す。
-- 相関条件だけでその顧客の全注文を調べるため、注文の状態・金額は問わない。
-- 結果は 1 顧客 1 行である。注文なしの顧客 12 を選び、未払い注文がある顧客 9 は選ばない。
SELECT
    c.customer_id,
    c.customer_name
FROM
    practice.customers AS c
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            practice.orders AS o
        WHERE
            o.customer_id = c.customer_id
    )
ORDER BY
    c.customer_id;

-- example: customers-without-paid-order
-- 要件が変わる比較：支払済み注文がない顧客を、支払いまでの案内対象として選ぶ。
-- この問いの主例も NOT EXISTS とし、副問い合わせ内で存在判定の対象を paid に限定する。
-- 未払いだけの顧客 9 と注文なしの顧客 12 をともに含む。「未払いがある」とは異なる。
-- paid があれば金額 0・NULL でも除外する。ここでは入金額の判明や正の金額を条件にしない。
SELECT
    c.customer_id,
    c.customer_name
FROM
    practice.customers AS c
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            practice.orders AS o
        WHERE
            o.customer_id = c.customer_id
            AND o.status = 'paid'
    )
ORDER BY
    c.customer_id;

-- example: customers-without-paid-left-join
-- 同等な代替記述：支払済み注文だけを LEFT JOIN し、一つも結合できない顧客を残す。
-- ON は「該当する注文」の範囲を決める。該当なしでも顧客行は残り、注文側の列が NULL になる。
-- o.order_id は主キーで必ず非 NULL なので、IS NULL を「結合できなかった」の判定に使える。
-- 同じ母集団・相関条件・paid 条件なら直前の NOT EXISTS と同等で、DISTINCT は不要である。
-- 存在しないことだけを問う場合は NOT EXISTS が直接的である。外部結合を使う場合もこの成立条件を保つ。
SELECT
    c.customer_id,
    c.customer_name
FROM
    practice.customers AS c
    LEFT JOIN practice.orders AS o ON c.customer_id = o.customer_id
    AND o.status = 'paid'
WHERE
    o.order_id IS NULL
ORDER BY
    c.customer_id;

-- example: unpaid-or-missing-order-counterexample
-- 当該要件では採用しない例：全注文を結合し、WHERE で未払いまたは結合なしを選んでいる。
-- ON で paid だけを結合する形と異なり、「未払いが一つでもある、または注文なし」という問いになる。
-- 顧客 1 は paid と unpaid の両方を持つため、この条件では残るが「paid がない」には該当しない。
-- DISTINCT は JOIN による顧客行の重複を除くが、誤った存在条件を直すことはできない。
SELECT DISTINCT
    c.customer_id,
    c.customer_name
FROM
    practice.customers AS c
    LEFT JOIN practice.orders AS o ON c.customer_id = o.customer_id
WHERE
    o.status = 'unpaid'
    OR o.order_id IS NULL
ORDER BY
    c.customer_id;

-- example: nullable-amount-absence-counterexample
-- 当該要件では採用しない例：金額 NULL を、支払済み注文の不在判定に使っている。
-- amount は実在する注文でも NULL になり得る。顧客 6 の注文 601 は paid だが金額不明である。
-- o.amount IS NULL では「実在する金額不明」と「結合なし」を区別できない。
-- 原因を観察するため order_id・amount も表示する。複数の金額不明注文があれば顧客行も増える。
SELECT
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.amount
FROM
    practice.customers AS c
    LEFT JOIN practice.orders AS o ON c.customer_id = o.customer_id
    AND o.status = 'paid'
WHERE
    o.amount IS NULL
ORDER BY
    c.customer_id,
    o.order_id;
