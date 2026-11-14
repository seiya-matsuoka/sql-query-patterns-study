-- example: tier-customer-total-having
-- 主例：支払済みの判明合計が、顧客区分別の基準以上となる顧客を選ぶ。
-- CASE は区分に応じた基準値を返し、HAVING で SUM(o.amount) と比較する。
-- WHERE は合計する注文の状態を、HAVING は集計後に残す顧客を決める。
-- 顧客表で区分が一つに定まるため、顧客 ID と区分でまとめた結果は 1 顧客 1 行になる。
-- COUNT(*) は金額不明も含む支払済み件数、COUNT(o.amount) と SUM は判明した金額を対象とする。
-- 金額は非負とし、判明分だけで基準へ達していれば、不明額が残っていても対象とする。
-- 判明分が基準未満で不明額が残る顧客は保留である。区分 NULL・未定義区分も基準を決めず、一覧に含めない。
-- 全額 NULL の合計は NULL、実額 0 の合計は 0 であり、一覧に出ないことだけで理由を同一視しない。
SELECT
    o.customer_id,
    c.customer_tier,
    COUNT(*) AS paid_order_count,
    COUNT(o.amount) AS known_paid_amount_count,
    SUM(o.amount) AS known_paid_total
FROM
    practice.orders AS o
    INNER JOIN practice.customers AS c ON c.customer_id = o.customer_id
WHERE
    o.status = 'paid'
GROUP BY
    o.customer_id,
    c.customer_tier
HAVING
    SUM(o.amount) >= CASE c.customer_tier
        WHEN 'standard' THEN 500.00
        WHEN 'premium' THEN 300.00
        ELSE CAST(NULL AS DECIMAL(10, 2))
    END
ORDER BY
    o.customer_id;

-- example: tier-customer-order-threshold-grouping
-- 要件が変わる比較：合計の基準を個々の注文へ移す形は、主例の顧客判定には採用しない。
-- 顧客 1 は 250.00 の別注文 2 件の合計で基準へ達するが、WHERE で両方を除くと顧客ごと消える。
-- 顧客 2 は小額注文を失って合計が変わり、顧客 3 は実額 0 の注文を失って件数が変わる。
-- 同じ列名でも、件数と合計は「基準以上の支払済み注文だけ」を対象とする値へ変わる。
-- その高額注文だけを顧客別に報告する別の要件なら使える。顧客の全支払済み判明合計を判定する形とは同等でない。
SELECT
    o.customer_id,
    c.customer_tier,
    COUNT(*) AS paid_order_count,
    COUNT(o.amount) AS known_paid_amount_count,
    SUM(o.amount) AS known_paid_total
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
GROUP BY
    o.customer_id,
    c.customer_tier
ORDER BY
    o.customer_id;
