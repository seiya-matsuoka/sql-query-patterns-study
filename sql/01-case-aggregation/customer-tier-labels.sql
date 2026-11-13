-- example: customer-tier-label-comparison
-- 問い：顧客区分のコードを表示用のラベルへ変換し、単純 CASE と検索 CASE を比べる。
-- 画面や帳票で使う短い区分名を、元のコードを残したまま求める場面を想定する。
-- この教材の入力は専用の 6 顧客であり、study.customers を読み書きしない。
-- FROM 内の VALUES は、丸括弧一つを 1 行として問い合わせ内だけの表を作る。
-- sample_customers はその表の名前、後ろの括弧は 2 列の名前である。
-- CAST は文字列や NULL の型を VARCHAR として示すために使う。
-- premium は優先、standard は通常、guest はゲストとし、それ以外はその他とする。
-- partner はこの表示規則に未定義のコード、NULL は区分自体が未登録であることを表す。
-- この問いでは、両方を意図的に同じ「その他」へまとめる。区別する例は次の問い合わせで扱う。
-- 結果の 1 行は 1 顧客で、元コードと、二つの書き方によるラベルを横に並べる。
-- 単純 CASE は一つの値を各 WHEN の値と等値比較するため、固定コードの対応が読みやすい。
-- 検索 CASE は各 WHEN に条件を書く。ここでは同じ等値比較を並べるので結果は同じになる。
-- 入力、比較する値、返すラベル、ELSE を揃えていることが、この書き換えの同等性の条件である。
-- NULL とコードの等値比較は真にならず、両方とも ELSE を選ぶ。
-- CASE は行を集約・除外せず、各入力行について一つの値を作る。6 顧客の結果は 6 行のままである。
-- 期待するラベルは ID 順に「優先、通常、ゲスト、その他、その他、優先」で、両列が一致する。
SELECT
    customer_id,
    customer_tier,
    CASE customer_tier
        WHEN 'premium' THEN '優先'
        WHEN 'standard' THEN '通常'
        WHEN 'guest' THEN 'ゲスト'
        ELSE 'その他'
    END AS simple_label,
    CASE
        WHEN customer_tier = 'premium' THEN '優先'
        WHEN customer_tier = 'standard' THEN '通常'
        WHEN customer_tier = 'guest' THEN 'ゲスト'
        ELSE 'その他'
    END AS searched_label
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
    customer_id;

-- example: customer-tier-null-and-else
-- 問い：未定義のコードと未登録の区分を、NULL 判定と ELSE の有無でどう区別できるか。
-- 入力は直前と同じ 6 顧客を VALUES で用意し、この問い合わせだけでも実行できるようにする。
-- 結果は 1 顧客 1 行で、三つの分類を並べる。これは結果の違いを観察する比較である。
-- simple_when_null_label は、単純 CASE に WHEN NULL を置いた場合をあえて完成形で示す。
-- 単純 CASE の WHEN NULL は IS NULL 判定ではなく、区分と NULL の等値比較になる。
-- NULL = NULL も真にはならないため、「未登録」の分岐を選ぶ行はない。
-- searched_null_label は、検索 CASE の IS NULL で未登録を明示し、未知の partner と区別する。
-- omitted_else_label は既知の 3 区分だけを列挙し、どれにも一致しない場合の ELSE を省略する。
-- この列では partner と NULL の両方が NULL になる。入力コードを残して、原因の違いを読めるようにする。
-- ELSE の省略は行の除外ではない。ラベルが NULL の顧客も結果に残る。
-- ID 4 は「その他、その他、NULL」、ID 5 は「その他、未登録、NULL」となる。
-- 既知の区分を持つ残り 4 顧客では、三つのラベルが一致する。
-- NULL を個別に扱うなら検索 CASE の IS NULL、未定義値を一括で受けるなら ELSE を使う。
-- NULL を空文字や仮のコードへ置き換える必要はない。仮の値には実データと衝突する危険もある。
-- THEN と ELSE は一つの結果列になるため、互換性のある型の値を返す。ここでは文字列に揃える。
SELECT
    customer_id,
    customer_tier,
    CASE customer_tier
        WHEN NULL THEN '未登録'
        WHEN 'premium' THEN '優先'
        WHEN 'standard' THEN '通常'
        WHEN 'guest' THEN 'ゲスト'
        ELSE 'その他'
    END AS simple_when_null_label,
    CASE
        WHEN customer_tier IS NULL THEN '未登録'
        WHEN customer_tier = 'premium' THEN '優先'
        WHEN customer_tier = 'standard' THEN '通常'
        WHEN customer_tier = 'guest' THEN 'ゲスト'
        ELSE 'その他'
    END AS searched_null_label,
    CASE customer_tier
        WHEN 'premium' THEN '優先'
        WHEN 'standard' THEN '通常'
        WHEN 'guest' THEN 'ゲスト'
    END AS omitted_else_label
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
    customer_id;
