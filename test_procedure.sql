-- Conceptual test script for Snowflake

-- 1. Create a dummy table for testing
CREATE OR REPLACE TABLE TEST_DATA (
    ID INT,
    NAME STRING,
    EMAIL STRING,
    AGE INT
);

-- 2. Insert test data
-- ID: 0 nulls
-- NAME: 1 null
-- EMAIL: 2 nulls
-- AGE: 0 nulls
INSERT INTO TEST_DATA (ID, NAME, EMAIL, AGE) VALUES
(1, 'Alice', 'alice@example.com', 30),
(2, NULL, 'bob@example.com', 25),
(3, 'Charlie', NULL, 35),
(4, 'David', NULL, 40);

-- 3. Call the procedure
-- Arguments: Full Table Name, Column List, Key Column List
CALL CHECK_NULL_COUNTS('TEST_DATA', 'NAME, EMAIL, AGE', 'ID');

-- Expected Result:
-- COLUMN_NAME | NULL_COUNT
-- ------------|-----------
-- NAME        | 1
-- EMAIL       | 2

-- Note: 'AGE' should not appear because its NULL_COUNT is 0.
