DECLARE @_StartDocDate DATE='20260101';
DECLARE @_EndDocDate DATE='20261231';
DECLARE @_DocDate DATE;
DECLARE @_Year CHAR(4) =YEAR(@_StartDocDate);
DECLARE @_BranchCode CHAR(3);
DROP TABLE IF EXISTS #tbl_Br;
SELECT BranchCode
INTO #tbl_Br
FROM B00Branch
WHERE BranchCode NOT IN ('I00', 'T00', 'I99', 'I30', 'I01', 'I24');

--2026-08-10
--DELETE #tbl_Br WHERE BranchCode<>'I11';
WHILE EXISTS (SELECT 1 FROM #tbl_Br)BEGIN
    SELECT TOP 1 @_BranchCode=BranchCode FROM #tbl_Br ORDER BY BranchCode;
    DROP TABLE IF EXISTS #tbl;
    ;WITH cte AS (SELECT EOMONTH(@_StartDocDate) AS DocDate
                  UNION ALL
                  SELECT EOMONTH(DATEADD(MONTH, 1, DocDate))
                  FROM cte
                  WHERE EOMONTH(DATEADD(MONTH, 1, DocDate))<=EOMONTH(@_EndDocDate))
    SELECT DocDate, 0 AS _Check INTO #tbl FROM cte
    OPTION(MAXRECURSION 0);
    WHILE EXISTS (SELECT 1 FROM #tbl WHERE _Check=0)BEGIN
        SELECT TOP 1 @_DocDate=DocDate FROM #tbl WHERE _Check=0 ORDER BY DocDate;
        UPDATE #tbl SET _Check=1 WHERE DocDate=@_DocDate
        EXEC dbo.usp_B30FinPlanDetail_CalculateAndSavePlannedCOGS @_BranchCode=@_BranchCode, @_DocDate=@_DocDate, @_Year=@_Year, @_nUserId=1213, @_SelectExec=0;
        SELECT @_BranchCode+' --- '+FORMAT(@_DocDate, 'dd-MM-yyyy')+' ---  Done: usp_B30FinPlanDetail_CalculateAndSavePlannedCOGS!!!'
    END;
    UPDATE #tbl SET _Check=0


	--chỉ chạy giá vốn cho mã sản phẩm cũ (đã có định mức)
	DELETE #tbl WHERE _Check=0

    --DECLARE @_SOMONTH DATE
    --DECLARE @_EOMONTH DATE
    --WHILE EXISTS (SELECT 1 FROM #tbl WHERE _Check=0)BEGIN
    --    SELECT TOP 1 @_DocDate=DocDate FROM #tbl WHERE _Check=0 ORDER BY DocDate;
    --    SELECT @_SOMONTH=DATEFROMPARTS(YEAR(@_DocDate), MONTH(@_DocDate), '01')
    --    SELECT @_EOMONTH=EOMONTH(@_SOMONTH)
    --    UPDATE #tbl SET _Check=1 WHERE DocDate=@_DocDate
    --    DELETE FROM #tbl WHERE DocDate=@_DocDate;
    --    EXEC dbo.usp_Kct_VariableCostAnalysis @_BranchCode=@_BranchCode, @_DocDate1=@_SOMONTH, @_DocDate2=@_EOMONTH, @_Year=@_Year, @_nUserId=1213, @_Import_Product_New=1
    --    SELECT @_BranchCode+'---'+FORMAT(@_DocDate, 'dd-MM-yyyy')+'--- Done: usp_Kct_VariableCostAnalysis!!!'
    --END;
    SELECT @_BranchCode+' Done!!!'
    DELETE FROM #tbl_Br WHERE BranchCode=@_BranchCode;
END;