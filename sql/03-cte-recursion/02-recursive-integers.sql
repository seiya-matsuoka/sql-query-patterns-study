-- example: recursive-integers-descending
-- 導入例：1 から 5 までの整数列を作り、再帰の開始・反復・終了を追う。
-- WITH RECURSIVE は CTE 自身の結果を参照する再帰を許す。integers(n) は CTE 名と出力列名である。
-- 最初の VALUES (1) は、自分を参照せず開始行を作る非再帰項である。
-- UNION ALL の後の SELECT は、integers を参照して次の行を作る再帰項である。
-- 再帰項が参照するのは現在の反復の行集合であり、それまでの累積結果全体ではない。
-- 開始行 1 から +1 で 2、3、4、5 を得る。n = 5 では n < 5 が偽となり、次の行を作らない。
-- 新しい行集合が空になると反復が終了する。外側の LIMIT で打ち切る仕組みにはしない。
-- UNION ALL は各反復で得た行を重複除去せず結果へ加える。この規則では同じ整数を二度作らない。
-- 最終 ORDER BY は表示を 5 から 1 の降順にする。再帰で次の行を作る規則や計算順の指定ではない。
WITH RECURSIVE
    integers (n) AS (
        VALUES
            (1)
        UNION ALL
        SELECT
            n + 1
        FROM
            integers
        WHERE
            n < 5
    )
SELECT
    n
FROM
    integers
ORDER BY
    n DESC;
