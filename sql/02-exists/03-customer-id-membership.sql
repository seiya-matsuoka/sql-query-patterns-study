-- example: paid-customers-in
-- 主例：支払済み注文の顧客 ID 集合に所属する顧客を選ぶ。
-- IN (副問い合わせ) は、左の値と等しい値が右の 1 列の結果にあれば TRUE を返す。
-- 単一の ID 集合への所属として読むなら IN が簡潔であり、01 の EXISTS と同等な代替記述になる。
-- 同じ paid 条件と顧客列・順序を使う。右の ID に重複があっても、外側の顧客行は増えない。
-- 顧客の主キーと注文の customer_id はともに非 NULL で、この入力では IN と相関した等値 EXISTS の真偽も一致する。
-- 複数の条件で関連行の存在を問う場合は、01 のように EXISTS 内で対応をまとめて読める。
SELECT
    c.customer_id,
    c.customer_name
FROM
    practice.customers AS c
WHERE
    c.customer_id IN (
        SELECT
            o.customer_id
        FROM
            practice.orders AS o
        WHERE
            o.status = 'paid'
    )
ORDER BY
    c.customer_id;

-- example: customers-without-paid-not-in
-- 同等な代替記述：同じ ID 集合に所属しない顧客を NOT IN で選ぶ。
-- 左の customer_id は主キー、右の customer_id は NOT NULL であり、等値比較に UNKNOWN が混ざらない。
-- この制約と同じ母集団・注文条件の下では、02 の「支払済み注文なし」の NOT EXISTS と同等になる。
-- 外部キーだけでは一般に NULL を禁止しないため、非 NULL 性は NOT NULL の定義も確認する。
-- NULL を許す別の列・入力へこの書き換えを広げることはできない。次の 04 で条件式と抽出結果を比較する。
SELECT
    c.customer_id,
    c.customer_name
FROM
    practice.customers AS c
WHERE
    c.customer_id NOT IN (
        SELECT
            o.customer_id
        FROM
            practice.orders AS o
        WHERE
            o.status = 'paid'
    )
ORDER BY
    c.customer_id;
