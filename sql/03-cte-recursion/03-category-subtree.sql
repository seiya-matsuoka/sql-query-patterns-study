-- example: product-category-subtree
-- 主例：商品カテゴリを対象とする帳票のため、指定カテゴリ自身とすべての子孫を深さ付きで取得する。
-- 入力は「商品 → 食品・雑貨」「食品 → 飲料・菓子」「雑貨 → 文具」と、別の根「サービス」である。
-- 直下の子だけでなく深さが変わる子孫も同じ規則でたどるため、再帰 CTE を採用する。
-- category_subtree の列名リストは、両項が返す列に位置順で名前を付ける。
-- 非再帰項は category_id = 1 の商品自身を深さ 0 とする。深さはこの起点からの辺の数である。
-- 再帰項は child.parent_category_id = parent.category_id で、現在の親集合の直下の子を探す。
-- parent は現在の反復で得た行集合である。商品から食品・雑貨へ、そこから飲料・菓子・文具へ枝分かれする。
-- 子を持たない枝は次の行を作らず、全枝で新しい行がなくなると終了する。
-- category_id が一意で各行の親は一つ、かつ有限で循環しない入力なので、1 カテゴリ 1 行になる。
-- UNION ALL を重複対策として変更する必要はない。循環がある入力の終了をこの SQL は保証しない。
-- 自己参照の外部キーが保証するのは親の存在であり、循環の防止ではない。
-- 最終 ORDER BY は深さ順、同じ深さでは ID 順に表示する。再帰項が行を訪れる計算順は指定しない。
-- 別の根「サービス」へは子方向の結合で到達しないため、この帳票には含まれない。
WITH RECURSIVE
    category_subtree (
        category_id,
        category_name,
        parent_category_id,
        depth
    ) AS (
        SELECT
            c.category_id,
            c.category_name,
            c.parent_category_id,
            0
        FROM
            practice.categories AS c
        WHERE
            c.category_id = 1
        UNION ALL
        SELECT
            child.category_id,
            child.category_name,
            child.parent_category_id,
            parent.depth + 1
        FROM
            practice.categories AS child
            INNER JOIN category_subtree AS parent ON child.parent_category_id = parent.category_id
    )
SELECT
    category_id,
    category_name,
    parent_category_id,
    depth
FROM
    category_subtree
ORDER BY
    depth,
    category_id;

-- example: food-category-subtree
-- 要件が変わる比較：指定カテゴリを食品へ変え、食品自身とその子孫だけを取得する。
-- 変えるのは非再帰項の起点だけである。親をたどる条件ではないため、商品・雑貨の枝は含まれない。
-- 食品の parent_category_id は元の表どおり 1 のままでも、この取得の起点なので深さは 0 になる。
-- 深さは表全体の根から固定した値ではない。飲料・菓子は食品からの深さ 1 となる。
-- 最終結果から食品を除く WHERE を足せば子孫だけの別要件になるが、ここでは起点自身も必要である。
WITH RECURSIVE
    category_subtree (
        category_id,
        category_name,
        parent_category_id,
        depth
    ) AS (
        SELECT
            c.category_id,
            c.category_name,
            c.parent_category_id,
            0
        FROM
            practice.categories AS c
        WHERE
            c.category_id = 2
        UNION ALL
        SELECT
            child.category_id,
            child.category_name,
            child.parent_category_id,
            parent.depth + 1
        FROM
            practice.categories AS child
            INNER JOIN category_subtree AS parent ON child.parent_category_id = parent.category_id
    )
SELECT
    category_id,
    category_name,
    parent_category_id,
    depth
FROM
    category_subtree
ORDER BY
    depth,
    category_id;
