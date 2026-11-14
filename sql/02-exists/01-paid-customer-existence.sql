-- example: paid-customers-exists
-- 主例：支払済み注文が一つでもある顧客を、連絡対象として 1 顧客 1 行で選ぶ。
-- EXISTS (副問い合わせ) は、条件に合う行があれば TRUE、なければ FALSE を返す。
-- o.customer_id = c.customer_id が、外側で見ている顧客の注文だけを調べる相関条件である。
-- 相関条件を外すと、誰かの支払済み注文があるだけで全顧客が対象になってしまう。
-- SELECT 1 は行の存在だけを見る意図を示す。1 を件数として数えたり返したりする構文ではない。
-- 注文の列や件数は不要なので、顧客の行を増やさず存在を表せる EXISTS を主例にする。
-- 金額の条件はない。実額 0 の注文も金額 NULL の注文も、paid の行があれば対象になる。
-- 顧客 ID を残し、同名でも顧客 1 と顧客 13 を別の顧客として表示する。
SELECT
    c.customer_id,
    c.customer_name
FROM
    practice.customers AS c
WHERE
    EXISTS (
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

-- example: paid-customers-join-distinct
-- 同等な代替記述：同じ条件の注文を INNER JOIN し、顧客列の重複を DISTINCT で除く。
-- JOIN は該当注文ごとに顧客行を作る。顧客 1 の支払済み注文 4 件からは、同じ顧客列が 4 行できる。
-- DISTINCT は選択列全体に作用する。顧客 ID・名前だけを選ぶため、主例と同じ顧客粒度に戻せる。
-- 名前だけにすると同名の別顧客を統合し、order_id まで選ぶと注文ごとの差が残るため同等でなくなる。
-- 同じ顧客母集団・注文条件・顧客列・最終順序を保つ比較である。注文の明細も必要なら JOIN を選ぶ。
SELECT DISTINCT
    c.customer_id,
    c.customer_name
FROM
    practice.customers AS c
    INNER JOIN practice.orders AS o ON c.customer_id = o.customer_id
WHERE
    o.status = 'paid'
ORDER BY
    c.customer_id;
