-- example: net-sales-case
-- 主例：対象期間の売上から返金を引き、記録がある顧客ごとの純額を求める。
-- 台帳の 1 行は一つの売上または返金で、amount は判明した非負の金額、種別は sale / refund に制約されている。
-- CASE は記録ごとに加算する値を選ぶ。売上は amount、返金は -amount とし、その式を SUM に渡す。
-- 同じ台帳の種別だけで符号が変わるため、この要件では CASE で共通の集約へ渡す主例を採用する。
-- 同額の別記録も両方を加算する。全額返金なら 0、期間外の売上に対する返金だけなら負の純額もあり得る。
SELECT
    customer_id,
    SUM(
        CASE movement_type
            WHEN 'sale' THEN amount
            WHEN 'refund' THEN - amount
        END
    ) AS net_amount
FROM
    practice.money_movements
GROUP BY
    customer_id
ORDER BY
    customer_id;

-- example: net-sales-union-all
-- 同等な代替記述：売上と返金を分けて符号を付け、UNION ALL で縦に結合してから同じ顧客単位で集約する。
-- 両枝は customer_id・signed_amount の列と型・1 記録 1 行の粒度を揃え、元の全記録を重複なく振り分ける。
-- UNION に変えると同じ顧客の同額記録が消え得る。顧客 1 の 100.00 の 2 件も残すため ALL が必要である。
-- この入力・符号・重複数・集約単位なら主例と同じ結果となる。種別ごとに別の結合や抽出が必要なら枝を分ける形が適する。
SELECT
    customer_id,
    SUM(signed_amount) AS net_amount
FROM
    (
        SELECT
            customer_id,
            amount AS signed_amount
        FROM
            practice.money_movements
        WHERE
            movement_type = 'sale'
        UNION ALL
        SELECT
            customer_id,
            - amount AS signed_amount
        FROM
            practice.money_movements
        WHERE
            movement_type = 'refund'
    ) AS signed_movements
GROUP BY
    customer_id
ORDER BY
    customer_id;
