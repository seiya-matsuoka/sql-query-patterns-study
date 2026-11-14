-- example: nullable-membership-truth
-- 主例：照合候補の 1・2・NULL を、参照値の集合 {1, NULL} と比較して条件式の値を見る。
-- NULL は不明値であり、NULL = NULL も TRUE にはならない。Boolean 式の NULL は UNKNOWN を表す。
-- IN は一致があれば TRUE、一致せず不明な比較が残れば UNKNOWN となる。NOT UNKNOWN も UNKNOWN である。
-- EXISTS 内の WHERE は TRUE の行だけを残すため、等しい行がなければ EXISTS は FALSE、NOT EXISTS は TRUE となる。
-- したがって「等しい行がない」と「どの値とも等しくないと確定する」は異なる。
-- PostgreSQL の表示では TRUE / FALSE が t / f、NULL は既存の run・verify で <NULL> になる。
-- 結果は 1 候補 1 行である。candidate_no は NULL を含む値の表示順を安定させるための番号である。
SELECT
    c.candidate_no,
    c.candidate_value,
    c.candidate_value IN (
        SELECT
            b.reference_value
        FROM
            (
                VALUES
                    (1),
                    (CAST(NULL AS INTEGER))
            ) AS b (reference_value)
    ) AS in_result,
    c.candidate_value NOT IN (
        SELECT
            b.reference_value
        FROM
            (
                VALUES
                    (1),
                    (CAST(NULL AS INTEGER))
            ) AS b (reference_value)
    ) AS not_in_result,
    EXISTS (
        SELECT
            1
        FROM
            (
                VALUES
                    (1),
                    (CAST(NULL AS INTEGER))
            ) AS b (reference_value)
        WHERE
            b.reference_value = c.candidate_value
    ) AS exists_result,
    NOT EXISTS (
        SELECT
            1
        FROM
            (
                VALUES
                    (1),
                    (CAST(NULL AS INTEGER))
            ) AS b (reference_value)
        WHERE
            b.reference_value = c.candidate_value
    ) AS not_exists_result
FROM
    (
        VALUES
            (1, 1),
            (2, 2),
            (3, CAST(NULL AS INTEGER))
    ) AS c (candidate_no, candidate_value)
ORDER BY
    c.candidate_no;

-- example: nullable-candidates-not-exists
-- 主例：参照値と等しい行を確認できない候補を残す。未判明の候補も残す方針である。
-- 同じ入力で NOT EXISTS を WHERE に置くと、候補 2 と NULL が残る。
-- 業務上 NULL を対象外にするなら c.candidate_value IS NOT NULL を外側へ追加する必要がある。
-- 正の IN と等値 EXISTS はこの入力で TRUE となる候補 1 が同じだが、上の式の値まで同じとはいえない。
SELECT
    c.candidate_no,
    c.candidate_value
FROM
    (
        VALUES
            (1, 1),
            (2, 2),
            (3, CAST(NULL AS INTEGER))
    ) AS c (candidate_no, candidate_value)
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            (
                VALUES
                    (1),
                    (CAST(NULL AS INTEGER))
            ) AS b (reference_value)
        WHERE
            b.reference_value = c.candidate_value
    )
ORDER BY
    c.candidate_no;

-- example: nullable-candidates-not-in
-- 当該要件では採用しない例：直前の NOT EXISTS を、NULL を含む NOT IN に置き換える。
-- WHERE は FALSE と UNKNOWN をともに除く。候補 1 は FALSE、2 と NULL は UNKNOWN のため結果は 0 行になる。
-- 「等しい行がない候補を残す」という主例の要件を満たさない。
SELECT
    c.candidate_no,
    c.candidate_value
FROM
    (
        VALUES
            (1, 1),
            (2, 2),
            (3, CAST(NULL AS INTEGER))
    ) AS c (candidate_no, candidate_value)
WHERE
    c.candidate_value NOT IN (
        SELECT
            b.reference_value
        FROM
            (
                VALUES
                    (1),
                    (CAST(NULL AS INTEGER))
            ) AS b (reference_value)
    )
ORDER BY
    c.candidate_no;

-- example: nullable-candidates-filtered-not-in
-- 要件が変わる比較：右の NULL を除いた NOT IN は、判明した候補 2 だけを残す。
-- 右の NULL を除くだけでは、左の NULL の判定は UNKNOWN のままであり、主例の NULL 候補は戻らない。
-- 「判明した候補のうち、判明した参照値にないもの」という方針なら使える。
-- 一般の入力でも左の NULL を必ず除外するなら、外側に IS NOT NULL を明示する。空集合の場合は末尾の例のとおり挙動が異なる。
SELECT
    c.candidate_no,
    c.candidate_value
FROM
    (
        VALUES
            (1, 1),
            (2, 2),
            (3, CAST(NULL AS INTEGER))
    ) AS c (candidate_no, candidate_value)
WHERE
    c.candidate_value NOT IN (
        SELECT
            b.reference_value
        FROM
            (
                VALUES
                    (1),
                    (CAST(NULL AS INTEGER))
            ) AS b (reference_value)
        WHERE
            b.reference_value IS NOT NULL
    )
ORDER BY
    c.candidate_no;

-- example: empty-membership-truth
-- 要件が変わる比較：同じ候補を、照合対象が 0 行の空集合と比較する。
-- WHERE FALSE は参照値 1 を入力から除き、空集合を作る。NULL の 1 行がある集合とは異なる。
-- 空集合への IN と EXISTS はすべて FALSE、NOT IN と NOT EXISTS はすべて TRUE になる。
-- 左が NULL でもこの結果となり、WHERE に NOT IN / NOT EXISTS を置けば NULL の候補も残る。
-- 不明な候補を含めるかは業務要件で決め、空集合だけから NULL を常に除外できるとは考えない。
SELECT
    c.candidate_no,
    c.candidate_value,
    c.candidate_value IN (
        SELECT
            b.reference_value
        FROM
            (
                VALUES
                    (1)
            ) AS b (reference_value)
        WHERE
            FALSE
    ) AS in_result,
    c.candidate_value NOT IN (
        SELECT
            b.reference_value
        FROM
            (
                VALUES
                    (1)
            ) AS b (reference_value)
        WHERE
            FALSE
    ) AS not_in_result,
    EXISTS (
        SELECT
            1
        FROM
            (
                VALUES
                    (1)
            ) AS b (reference_value)
        WHERE
            FALSE
            AND b.reference_value = c.candidate_value
    ) AS exists_result,
    NOT EXISTS (
        SELECT
            1
        FROM
            (
                VALUES
                    (1)
            ) AS b (reference_value)
        WHERE
            FALSE
            AND b.reference_value = c.candidate_value
    ) AS not_exists_result
FROM
    (
        VALUES
            (1, 1),
            (2, 2),
            (3, CAST(NULL AS INTEGER))
    ) AS c (candidate_no, candidate_value)
ORDER BY
    c.candidate_no;
