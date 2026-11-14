-- example: tier-order-filter-case
-- 主例：顧客区分別の基準以上となる支払済み注文を、購入後のフォロー対象として選ぶ。
-- CASE customer_tier WHEN 値 THEN 基準 END は区分に対応する数値を返し、WHERE で amount >= その値を判定する。
-- 区分による違いを基準値へまとめると、共通の「以上」という比較を一つの形で読める。
-- standard は 500.00、premium は 300.00 を基準とし、境界と等しい注文も含める。
-- 金額 NULL・区分 NULL・未定義の partner は比較が真にならないため一覧に含めず、確認待ちとして扱う。
-- 顧客表の主キーで区分を一つ参照する。結果は 1 注文 1 行で、顧客別の合計ではない。
SELECT
    o.order_id,
    o.customer_id,
    c.customer_tier,
    o.amount
FROM
    practice.orders AS o
    INNER JOIN practice.customers AS c ON c.customer_id = o.customer_id
WHERE
    o.status = 'paid'
    AND o.amount >= CASE c.customer_tier
        WHEN 'standard' THEN 500.00
        WHEN 'premium' THEN 300.00
        ELSE CAST(NULL AS DECIMAL(10, 2))
    END
ORDER BY
    o.order_id;

-- example: tier-order-filter-direct
-- 同等な代替記述：区分と金額の条件を AND で組にし、OR でつなぐ。
-- OR 全体を括弧で囲み、両区分に支払状態の条件を掛ける。外すと premium の未払いも通ってしまう。
-- 同じ入力・区分対応・境界・不明値の扱いなら、WHERE が選ぶ行は主例と同じになる。
-- FALSE と UNKNOWN が同じ真偽値という意味ではない。どちらも WHERE を通らないことを利用している。
-- 区分ごとに金額以外の条件も変わる場合は、規則を条件の組として読めるこの形が適する。
SELECT
    o.order_id,
    o.customer_id,
    c.customer_tier,
    o.amount
FROM
    practice.orders AS o
    INNER JOIN practice.customers AS c ON c.customer_id = o.customer_id
WHERE
    o.status = 'paid'
    AND (
        (
            c.customer_tier = 'standard'
            AND o.amount >= 500.00
        )
        OR (
            c.customer_tier = 'premium'
            AND o.amount >= 300.00
        )
    )
ORDER BY
    o.order_id;
