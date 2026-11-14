-- reset-practice-data が明示的に再構築する、10 以降の共用入力である。
BEGIN;

-- ファイルを GUI から実行した場合も、別の DB で DDL を続行させない。
DO $check_database$
BEGIN
    IF pg_catalog.current_database() <> 'sql_patterns_study' THEN
        RAISE EXCEPTION 'Practice reset requires database sql_patterns_study (connected to %).',
            pg_catalog.current_database();
    END IF;
END;
$check_database$;

CREATE SCHEMA IF NOT EXISTS practice;

-- 再構築対象を列挙する。依存する別の教材があれば CASCADE で消さずに失敗させる。
DROP TABLE IF EXISTS practice.money_movements;

DROP TABLE IF EXISTS practice.orders;

DROP TABLE IF EXISTS practice.customers;

CREATE TABLE practice.customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL,
    customer_tier VARCHAR(20)
);

CREATE TABLE practice.orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES practice.customers (customer_id),
    status VARCHAR(12) NOT NULL CHECK (status IN ('paid', 'unpaid')),
    amount DECIMAL(10, 2) CHECK (amount >= 0)
);

CREATE TABLE practice.money_movements (
    movement_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES practice.customers (customer_id),
    movement_type VARCHAR(6) NOT NULL CHECK (movement_type IN ('sale', 'refund')),
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0)
);

INSERT INTO
    practice.customers (customer_id, customer_name, customer_tier)
VALUES
    (1, '顧客01', 'standard'),
    (2, '顧客02', 'standard'),
    (3, '顧客03', 'premium'),
    (4, '顧客04', 'premium'),
    (5, '顧客05', 'standard'),
    (6, '顧客06', 'standard'),
    (7, '顧客07', NULL),
    (8, '顧客08', 'partner'),
    (9, '顧客09', 'standard'),
    (10, '顧客10', 'standard'),
    (11, '顧客11', 'premium'),
    (12, '顧客12', 'standard'),
    (13, '顧客01', 'standard');

-- 顧客 1 は個々の注文が基準未満でも判明合計で到達し、顧客 10 は不明分が残る。
-- 実額 0、全額 NULL、未払いのみ、区分不明は別の顧客・注文で区別する。
INSERT INTO
    practice.orders (order_id, customer_id, status, amount)
VALUES
    (101, 1, 'paid', 250.00),
    (102, 1, 'paid', 250.00),
    (103, 1, 'paid', 0.00),
    (104, 1, 'paid', NULL),
    (105, 1, 'unpaid', 900.00),
    (201, 2, 'paid', 500.00),
    (202, 2, 'paid', 100.00),
    (301, 3, 'paid', 300.00),
    (302, 3, 'paid', 0.00),
    (303, 3, 'unpaid', 900.00),
    (401, 4, 'paid', 299.99),
    (501, 5, 'paid', 0.00),
    (601, 6, 'paid', NULL),
    (701, 7, 'paid', 900.00),
    (801, 8, 'paid', 900.00),
    (901, 9, 'unpaid', 900.00),
    (1001, 10, 'paid', 499.99),
    (1002, 10, 'paid', NULL),
    (1101, 11, 'paid', 300.01),
    (1301, 13, 'paid', 0.00);

-- 対象期間の売上・返金台帳であり、上の注文金額との一致は前提にしない。
-- 顧客 3 の返金に対応する売上は対象期間外である。
INSERT INTO
    practice.money_movements (movement_id, customer_id, movement_type, amount)
VALUES
    (1, 1, 'sale', 100.00),
    (2, 1, 'sale', 100.00),
    (3, 1, 'refund', 20.00),
    (4, 2, 'sale', 300.00),
    (5, 2, 'refund', 300.00),
    (6, 3, 'refund', 50.00);

COMMIT;
