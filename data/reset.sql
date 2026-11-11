-- reset-data から明示的に実行する。固定データの再構築を一つのトランザクションにまとめる。
-- 再構築の対象は study スキーマ内の共通テーブル 2 個である。
BEGIN;

-- GUI からファイル全体を実行した場合も、別のデータベースで共通テーブルを変更しない。
-- トランザクション内で例外を発生させ、クライアントが続行しても後続の DDL を実行できない状態にする。
DO $check_database$
BEGIN
    IF pg_catalog.current_database() <> 'sql_patterns_study' THEN
        RAISE EXCEPTION 'Reset requires database sql_patterns_study (connected to %).',
            pg_catalog.current_database();
    END IF;
END;
$check_database$;

CREATE SCHEMA IF NOT EXISTS study;

-- 注文が顧客を参照するため、削除は注文、作成は顧客を先にする。
-- CASCADE は使わず、別の教材が依存している場合は再構築を失敗させる。
DROP TABLE IF EXISTS study.orders;

DROP TABLE IF EXISTS study.customers;

CREATE TABLE study.customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL,
    customer_tier VARCHAR(20) NOT NULL
);

CREATE TABLE study.orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES study.customers (customer_id),
    ordered_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(12) NOT NULL CHECK (status IN ('paid', 'unpaid')),
    -- NULL は金額が判明していないことを表す。支払状態とは別の情報である。
    amount DECIMAL(10, 2) CHECK (amount >= 0)
);

INSERT INTO
    study.customers (customer_id, customer_name, customer_tier)
VALUES
    (1, '佐藤', 'standard'),
    (2, '田中', 'premium'),
    (3, '高橋', 'standard'),
    (4, '鈴木', 'premium');

-- 顧客 1 は支払済みの金額 100 と NULL、未払いの金額 200 を持つ。
-- 顧客 2 は未払いのみ、顧客 3 は金額不明の支払済み注文のみ、顧客 4 は注文なしとする。
INSERT INTO
    study.orders (order_id, customer_id, ordered_at, status, amount)
VALUES
    (
        101,
        1,
        TIMESTAMP WITH TIME ZONE '2026-01-05 09:00:00+00:00',
        'paid',
        100.00
    ),
    (
        102,
        1,
        TIMESTAMP WITH TIME ZONE '2026-01-06 09:00:00+00:00',
        'paid',
        NULL
    ),
    (
        103,
        1,
        TIMESTAMP WITH TIME ZONE '2026-01-07 09:00:00+00:00',
        'unpaid',
        200.00
    ),
    (
        201,
        2,
        TIMESTAMP WITH TIME ZONE '2026-01-07 10:00:00+00:00',
        'unpaid',
        80.00
    ),
    (
        301,
        3,
        TIMESTAMP WITH TIME ZONE '2026-01-08 09:00:00+00:00',
        'paid',
        NULL
    );

COMMIT;
