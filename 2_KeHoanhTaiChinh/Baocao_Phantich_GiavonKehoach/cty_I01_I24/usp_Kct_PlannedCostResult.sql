USE B10THACOIDACC;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- ====================================
-- Author: TINNT
-- Create date: 2026-08-12
-- Des: Báo cáo phân tích Giá vốn kế hoạch
-- ====================================
CREATE OR ALTER PROC dbo.usp_Kct_PlannedCostResult
    @_DocDate1 DATE = '20260101',
    @_DocDate2 DATE = '20260131',
    @_ForeignCurrencyOnly TINYINT = 0,
    @_nUserId AS INT = 0,
    @_LangId SMALLINT = 0,
    @_BranchCode VARCHAR(3) = 'I09',
    @_BizDocId VARCHAR(16) = ''
AS
BEGIN
    SET NOCOUNT ON;
    -- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);
    DECLARE @_KeyCd NVARCHAR(MAX) = N'',
            @_Key1 NVARCHAR(MAX) = N'',
            @_Key2 NVARCHAR(MAX);
    DECLARE @_MoneyType AS dbo.MoneyType = 0,
            @_QuantityType dbo.QuantityType = 0,
            @_TINYINTType TINYINT = 0,
            @_INTType INT = 0,
            @_CodeType VARCHAR(24) = '',
            @_SMALLDATETIMEType SMALLDATETIME = NULL,
            @_NameType NVARCHAR(256) = N'',
            @_UnitType NVARCHAR(8) = N'',
            @_BizDocIdType VARCHAR(16) = N'',
            @_DataCode VARCHAR(8) = '', --varchar	8
            @_DocDate DATE
    SET @_DocDate = DATEADD(DAY, 1 - DAY(@_DocDate2), @_DocDate2);
    DECLARE @_SOMONTH DATE = DATEFROMPARTS(YEAR(@_DocDate), MONTH(@_DocDate), '01');
    DECLARE @_EOMONTH DATE = EOMONTH(@_SOMONTH);
    DROP TABLE IF EXISTS #FinPlan;
    SELECT TOP (0)
           DocDate,
           DocDate00,
           DocNo,
           CAST(NULL AS INT) AS Year,
           CAST(NULL AS INT) AS _Month,
           CustomerId,
           ItemId,
           @_CodeType AS ItemCode,
           @_NameType AS ItemName,
           CAST(NULL AS TINYINT) AS ItemType,
           @_MoneyType AS OriginalUnitCost,
           @_MoneyType AS Amount,
           @_QuantityType AS Quantity,
           @_MoneyType AS OriginalAmount,
           BranchCode,
           @_CodeType AS MESGroupCode, --
           @_CodeType AS Type,
           @_TINYINTType AS M_DocDate,
           @_INTType AS Y_DocDate,
           @_CodeType AS Thang,
           @_BizDocIdType AS BizDocId
    INTO #FinPlan
    FROM dbo.vB30FinPlanDetail_GetData;
    EXEC dbo.usp_FinPlanDetail_GetData @_DocDate1 = @_SOMONTH,
                                       @_DocDate2 = @_EOMONTH,
                                       @_UsingDateKey = 1,
                                       @_CtTmp = '#FinPlan',
                                       @_DateCol = 'sc.DocDate00',
                                       @_BranchCode = @_BranchCode,
                                       @_PrintExec = 1, --, @_BizDocId = @_BizDocId
                                       @_LangId = @_LangId;
    DROP TABLE IF EXISTS #K_PlannedCostResult;
    SELECT TOP 0
           *,
           @_MoneyType AS Amount,
           @_CodeType AS ItemCode,
           @_NameType AS ItemName,
           @_CodeType AS ProductClassCode,
           @_NameType AS ProductClassName,
           @_CodeType AS CostFactorCode,
           @_NameType AS CostFactorName,
           @_CodeType AS ClassCode2,
           @_MoneyType AS OriginalUnitCost, --Doanh thu kế hoạch
           @_MoneyType AS Quantity2,
           @_MoneyType AS Amount2,
           @_MoneyType AS GrossProfit,
           @_QuantityType AS GrossProfitMargin,
           CAST('' AS NVARCHAR(4000)) AS _FormatStyleKey,
           0 AS _Status
    INTO #K_PlannedCostResult
    FROM vB30PlannedCostResult_GetData;
    DECLARE @_Key_ZDetail NVARCHAR(MAX)
        = N'   DocDate BETWEEN ''' + FORMAT(DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), 1), 'yyyyMMdd')
          + N''' AND ''' + FORMAT(@_DocDate2, 'yyyyMMdd') + N'''';
    EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1,
                                               @_DocDate2 = @_DocDate2,
                                               @_Key = @_Key_ZDetail,
                                               @_CtTmp = '#K_PlannedCostResult',
                                               @_BranchCode = @_BranchCode,
                                               @_BizDocName = 'vB30PlannedCostResult_GetData',
                                               @_PrintExec = 1;
    UPDATE #K_PlannedCostResult
    SET _Status = 1
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_PlannedCostResult',
                                             @_List_Cats = 'Item'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_PlannedCostResult',
                                             @_List_Cats = 'ProductClass'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_PlannedCostResult',
                                             @_List_Cats = 'CostFactor',
                                             @_SetString_Other = ',kq.ClassCode2 = CostFactor.ClassCode2';
    ;WITH cte
    AS (SELECT Id,
               CostFactorCode,
               ROW_NUMBER() OVER (PARTITION BY ItemId ORDER BY CostFactorCode) AS _RN
        FROM #K_PlannedCostResult)
    --UPDATE k
    --SET k.OriginalUnitCost = f.OriginalUnitCost
    --  , k.Quantity2 = f.Quantity

    INSERT INTO #K_PlannedCostResult
    (
        Id,
        ProductId,
        ItemId,
        DocDate,
        BranchCode,
        IsActive,
        ProductClassId,
        ItemCode,
        ItemName,
        ProductClassCode,
        ProductClassName,
        ClassCode2,
        OriginalUnitCost,
        Amount2,
        Quantity2,
        _FormatStyleKey,
        _Status
    )
    SELECT k.Id,
           k.ProductId,
           k.ItemId,
           k.DocDate,
           k.BranchCode,
           k.IsActive,
           k.ProductClassId,
           k.ItemCode,
           k.ItemName,
           k.ProductClassCode,
           k.ProductClassName,
           k.ClassCode2,
           f.OriginalUnitCost,
           0,
           f.Quantity AS Quantity2,
           'Subtotal0',
           0
    FROM #K_PlannedCostResult AS k
        INNER JOIN
        (
            SELECT ItemId,
                   SUM(Quantity) AS Quantity,
                   MAX(OriginalUnitCost) AS OriginalUnitCost
            FROM #FinPlan
            GROUP BY ItemId
        ) AS f
            ON k.ItemId = f.ItemId
    WHERE Id IN
          (
              SELECT Id FROM cte WHERE _RN = 1
          )

    UPDATE k
    SET k.VariableAmount = a.VariableAmount,
        k.FixedAmount = a.FixedAmount,
        k.Coeff = a.Coeff
    FROM #K_PlannedCostResult AS k
        INNER JOIN
        (
            SELECT SUM(VariableAmount) AS VariableAmount,
                   SUM(FixedAmount) AS FixedAmount,
                   SUM(Coeff) AS Coeff,
                   ItemId
            FROM #K_PlannedCostResult
            GROUP BY ItemId
        ) AS a
            ON k.ItemId = a.ItemId
    WHERE _Status = 0

    UPDATE #K_PlannedCostResult
    SET Amount2 = OriginalUnitCost * Quantity2,
        Amount = VariableAmount + FixedAmount

    UPDATE #K_PlannedCostResult
    SET GrossProfit = Amount2 - Amount
    WHERE _Status = 0

    UPDATE #K_PlannedCostResult
    SET GrossProfitMargin = IIF(Amount2 <> 0, GrossProfit / Amount2, 0)
    WHERE _Status = 0

    SELECT *
    FROM #K_PlannedCostResult
    ORDER BY ItemCode,
             _Status ASC,
             DocDate,
             ClassCode2,
             CostFactorCode ASC

    SELECT SUM(Amount),
           SUM(Amount2),
           ProductClassCode
    FROM #K_PlannedCostResult
    GROUP BY ProductClassCode



    --SELECT * FROM #FinPlan
    DROP TABLE #K_PlannedCostResult,
               #FinPlan
END;
GO
SET DATEFORMAT DMY;
--EXEC usp_Kct_PlannedCostResult @_DocDate1 = '20260301',
--                               @_DocDate2 = '20260301',
--                               @_BranchCode = 'I09';

EXEC usp_Kct_PlannedCostResult @_DocDate1 = '01/03/2026 00:00:00.000',
                               @_DocDate2 = '31/03/2026 00:00:00.000',
                               @_nUserId = 1213,
                               @_LangId = 0,
                               @_BranchCode = 'I09'