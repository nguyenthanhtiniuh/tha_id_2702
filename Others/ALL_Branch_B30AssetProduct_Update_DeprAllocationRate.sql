DROP TABLE IF EXISTS #tbl
SELECT branchcode,
       datacode,
       0 AS _check
INTO #tbl
FROM b00branch
WHERE branchcode <> 'T00'

DECLARE @_datacode VARCHAR(24) = ''
DECLARE @_branchcode VARCHAR(24) = ''
DECLARE @_str_exec VARCHAR(4000) = ''

WHILE EXISTS (SELECT TOP 1 1 FROM #tbl WHERE _check = 0)
BEGIN

    SELECT TOP 1
           @_branchcode = branchcode,
           @_datacode = datacode
    FROM #tbl AS t
    WHERE _check = 0



    SELECT @_str_exec
        = '

    IF EXISTS (SELECT 1  FROM B3' + @_datacode + 'AssetProduct)
    BEGIN

        UPDATE B3' + @_datacode+ 'AssetProduct
        SET DeprAllocationRate = 1 
        WHERE ISNULL(DeprAllocationRate, 0) = 0

 
    END 
    '

    EXEC (@_str_exec)


    SELECT @_str_exec = '
     IF EXISTS (SELECT 1  FROM B3' + @_datacode + 'AssetProduct)
    BEGIN

    SELECT *
    FROM B3' + @_datacode + 'AssetProduct
    --WHERE ISNULL(DeprAllocationRate, 0) = 0

    END 
    '

    EXEC (@_str_exec)


    UPDATE #tbl
    SET _check = 1
    WHERE branchcode = @_branchcode
END

