-- example: customer-tier-value-order
-- 問い：顧客を区分コードの値順に並べたとき、希望する業務順になるかを確認する。
-- 入力は customer-tier-labels.sql と同じ専用の 6 顧客で、結果の 1 行は 1 顧客を表す。
-- 顧客区分は premium / standard / guest、未定義の partner、未登録の NULL を含む。
-- VALUES はこの問い合わせ内だけの表であり、記述した行の順序を結果の順序として保証しない。
-- 希望する業務順は premium → standard → guest → 未定義のコード → NULL とする。
-- まず代替候補の直接的な ORDER BY を実行し、コードの値順との違いを観察する。
-- 文字列の値順は DB の照合順序に従う。この環境では guest → partner → premium → standard の順になる。
-- NULLS LAST は、昇順・降順や DBMS の既定値に任せず、NULL を最後に置く指定である。
-- 同じ premium の顧客 1 と 6 の順序は、第 2 キーの customer_id で確定する。
-- 期待する顧客 ID の順は 3、4、1、6、2、5 であり、希望する業務順とは異なる。
-- コードの値順自体が要件なら、この直接指定で十分である。独自の優先度がある場合は次の CASE を使う。
SELECT
    customer_id,
    customer_tier
FROM
    (
        VALUES
            (1, CAST('premium' AS VARCHAR(12))),
            (2, 'standard'),
            (3, 'guest'),
            (4, 'partner'),
            (5, CAST(NULL AS VARCHAR(12))),
            (6, 'premium')
    ) AS sample_customers (customer_id, customer_tier)
ORDER BY
    customer_tier ASC NULLS LAST,
    customer_id;

-- example: customer-tier-business-order
-- 問い：区分コードの値順に依存せず、希望する業務順で顧客一覧を表示する。
-- 入力・出力列・結果の粒度は直前と同じで、変えるのは最終 ORDER BY の第 1 キーだけである。
-- ORDER BY 内の CASE は並べ替え用の値を作る。表示する customer_tier 自体は変更しない。
-- 優先度は premium = 1、standard = 2、guest = 3、未定義コード = 4、NULL = 5 とする。
-- 顧客 1 / 6 は 1、顧客 2 は 2、顧客 3 は 3、顧客 4 は 4、顧客 5 は 5 となる。
-- この数値を昇順に使うことで、文字列の照合順序とは別に業務上の順序を表せる。
-- NULL はコードとの等値比較で真にならないため、IS NULL の分岐で明示的に 5 を返す。
-- ELSE 4 は未知のコードを受ける。既知の区分だけを列挙して終えると、未知コードの優先度が NULL になってしまう。
-- この例では並べ替えキーに NULL を返さず、未定義と未登録の置き場所を別々に決めている。
-- CASE のキーだけでは同じ premium の 2 行の前後は決まらない。
-- 第 2 キーの customer_id はこの専用入力で一意であり、同じ優先度の中の表示順を安定させる。
-- 期待する顧客 ID の順は 1、6、2、3、4、5 である。行数は 6 のままで、顧客は除外・集約しない。
-- この結果と直前の値順は、意図的に行順が異なる比較である。
-- 少数の固定ルールを一つの表示で使うため CASE を採用する。
-- 優先度を頻繁に変更したり多くの問い合わせで共有したりする場合は、優先度を管理する表との結合も候補になる。
-- その方式では区分コードの一意性や未定義コードの保持も必要になるため、ここでは永続表を追加しない。
SELECT
    customer_id,
    customer_tier
FROM
    (
        VALUES
            (1, CAST('premium' AS VARCHAR(12))),
            (2, 'standard'),
            (3, 'guest'),
            (4, 'partner'),
            (5, CAST(NULL AS VARCHAR(12))),
            (6, 'premium')
    ) AS sample_customers (customer_id, customer_tier)
ORDER BY
    CASE
        WHEN customer_tier = 'premium' THEN 1
        WHEN customer_tier = 'standard' THEN 2
        WHEN customer_tier = 'guest' THEN 3
        WHEN customer_tier IS NULL THEN 5
        ELSE 4
    END,
    customer_id;

-- example: customer-tier-business-order-derived
-- 問い：並べ替え用の CASE に名前を付けると、同じ業務順をどのように読めるか。
-- 入力は直前と同じ 6 顧客であり、CASE の対応、出力する 2 列、最終的な並び順も揃える。
-- 最も内側の VALUES が、顧客 ID と区分の表を作る。
-- その外の SELECT は、各顧客に business_priority という計算列を一つ付ける。
-- さらに外の問い合わせは、その結果を classified_customers という表として参照する。
-- このように FROM 内に置いた SELECT の結果を派生表と呼ぶ。行は 6 行のままである。
-- 最後に元の 2 列だけを表示し、優先度と顧客 ID で並べる。優先度を画面の列に含める必要はない。
-- 内側の SELECT に並べ替えは置かず、最終結果を返す外側の ORDER BY で順序を確定する。
-- 出力列・行・順序が直前の直接記述と一致する、同等な書き換えである。
-- 顧客 ID の順は 1、6、2、3、4、5 となり、二つの期待 CSV の内容も一致する。
-- 直接記述は短く、派生表は「優先度を付ける」「並べる」という段階とキーの名前を分けて読める。
-- 優先度を表示項目にも加えたい場合など、計算した値を外側で参照するときにも使える形である。
-- 派生表にしただけで高速になるとは説明しない。この比較の性能は未評価である。
SELECT
    customer_id,
    customer_tier
FROM
    (
        SELECT
            customer_id,
            customer_tier,
            CASE
                WHEN customer_tier = 'premium' THEN 1
                WHEN customer_tier = 'standard' THEN 2
                WHEN customer_tier = 'guest' THEN 3
                WHEN customer_tier IS NULL THEN 5
                ELSE 4
            END AS business_priority
        FROM
            (
                VALUES
                    (1, CAST('premium' AS VARCHAR(12))),
                    (2, 'standard'),
                    (3, 'guest'),
                    (4, 'partner'),
                    (5, CAST(NULL AS VARCHAR(12))),
                    (6, 'premium')
            ) AS sample_customers (customer_id, customer_tier)
    ) AS classified_customers
ORDER BY
    business_priority,
    customer_id;
