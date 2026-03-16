CREATE OR REPLACE PROCEDURE CHECK_NULL_COUNTS(FULL_TABLE_NAME STRING, COLUMN_LIST STRING, KEY_COLUMN_LIST STRING)
RETURNS TABLE (COLUMN_NAME STRING, NULL_COUNT NUMBER)
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
    // Split the column list into an array
    var cols = COLUMN_LIST.split(',').map(function(item) {
        return item.trim();
    });

    if (cols.length === 0 || (cols.length === 1 && cols[0] === "")) {
        // Return empty result set if no columns provided
        return snowflake.execute({sqlText: "SELECT CAST(NULL AS STRING) AS COLUMN_NAME, CAST(NULL AS NUMBER) AS NULL_COUNT WHERE 1=0"});
    }

    // To perform a single scan of the table, we calculate all null counts first
    var countExpressions = cols.map(function(col) {
        var escaped = col.replace(/"/g, '""');
        return `COUNT_IF("${escaped}" IS NULL) AS "${escaped}"`;
    }).join(", ");

    var baseQuery = `SELECT ${countExpressions} FROM IDENTIFIER(:1)`;

    // We then unpivot the results using UNION ALL on the single row of counts
    var unionParts = cols.map(function(col) {
        var escaped = col.replace(/"/g, '""');
        return `SELECT '${escaped.replace(/'/g, "''")}' AS COLUMN_NAME, "${escaped}" AS NULL_COUNT FROM __COUNTS__`;
    }).join(" UNION ALL ");

    var finalSql = `WITH __COUNTS__ AS (${baseQuery}) SELECT * FROM (${unionParts}) WHERE NULL_COUNT > 0`;

    try {
        var statement = snowflake.createStatement({
            sqlText: finalSql,
            binds: [FULL_TABLE_NAME]
        });
        return statement.execute();
    } catch (err) {
        throw "Error executing procedure: " + err.message + "\nSQL: " + finalSql;
    }
$$;
