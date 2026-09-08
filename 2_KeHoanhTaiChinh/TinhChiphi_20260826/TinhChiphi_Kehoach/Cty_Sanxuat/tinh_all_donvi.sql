DECLARE @_StartDocDate DATE = '20260101';
DECLARE @_DocDate DATE;
DECLARE @_Year CHAR(4) = YEAR(@_StartDocDate);
DECLARE @_BranchCode CHAR(3);

DROP TABLE IF EXISTS #tbl_Br;
SELECT BranchCode
INTO #tbl_Br
FROM B00Branch
WHERE BranchCode NOT IN ( 'I00', 'T00', 'I99', 'I30', 'I01', 'I24' );

--2026-08-10
DELETE #tbl_Br WHERE BranchCode <> 'I09';

WHILE EXISTS (SELECT 1 FROM #tbl_Br)
BEGIN

    SELECT TOP 1
           @_BranchCode = BranchCode
    FROM #tbl_Br
    ORDER BY BranchCode;

    DROP TABLE IF EXISTS #tbl;

    ;WITH cte
    AS (SELECT EOMONTH(@_StartDocDate) AS DocDate
        UNION ALL
        SELECT EOMONTH(DATEADD(MONTH, 1, DocDate))
        FROM cte
        WHERE EOMONTH(DATEADD(MONTH, 1, DocDate)) <= EOMONTH(GETDATE()))
    SELECT DocDate
    INTO #tbl
    FROM cte
    OPTION (MAXRECURSION 0);

    WHILE EXISTS (SELECT 1 FROM #tbl)
    BEGIN

        SELECT TOP 1
               @_DocDate = DocDate
        FROM #tbl
        ORDER BY DocDate;

        DELETE FROM #tbl
        WHERE DocDate = @_DocDate;

        EXEC dbo.usp_B30FinPlanDetail_CalculateAndSavePlannedCOGS @_BranchCode = @_BranchCode
                                                                , @_DocDate = @_DocDate
                                                                , @_Year = @_Year
                                                                , @_nUserId = 1213
                                                                , @_SelectExec = 0;
    END;


	SELECT @_BranchCode +' Done!!!'
    DELETE FROM #tbl_Br
    WHERE BranchCode = @_BranchCode;
	
END;