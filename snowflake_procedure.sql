CREATE OR REPLACE PROCEDURE CHECK_NULL_COUNTS(FULL_TABLE_NAME STRING, COLUMN_LIST STRING, KEY_COLUMN_LIST STRING)
RETURNS TABLE (COLUMN_NAME STRING, NULL_COUNT NUMBER)
LANGUAGE SQL
EXECUTE AS CALLER
AS
DECLARE
    final_sql STRING;
    res RESULTSET;
BEGIN
    -- Construct the dynamic SQL using a query for string manipulation
    WITH cols AS (
        -- Split the comma-separated list into rows
        SELECT trim(value::string) as col
        FROM table(flatten(input => split(:COLUMN_LIST, ',')))
        WHERE col != ''
    ),
    count_expressions AS (
        -- Create the COUNT_IF expressions for the base scan
        SELECT listagg('COUNT_IF("' || replace(col, '"', '""') || '" IS NULL) AS "' || replace(col, '"', '""') || '"', ', ') as count_clause
        FROM cols
    ),
    unpivot_expressions AS (
        -- Create the UNION ALL parts to turn columns into rows
        SELECT listagg('SELECT ''' || replace(col, '''', '''''') || ''' AS COLUMN_NAME, "' || replace(col, '"', '""') || '" AS NULL_COUNT FROM __COUNTS__', ' UNION ALL ') as union_clause
        FROM cols
    )
    SELECT
        'WITH __COUNTS__ AS (SELECT ' || count_clause || ' FROM IDENTIFIER(''' || replace(:FULL_TABLE_NAME, '''', '''''') || ''')) ' ||
        'SELECT * FROM (' || union_clause || ') WHERE NULL_COUNT > 0'
    INTO :final_sql
    FROM count_expressions, unpivot_expressions;

    -- Execute the dynamic SQL and return the result set as a table
    res := (EXECUTE IMMEDIATE :final_sql);
    RETURN TABLE(res);
END;
