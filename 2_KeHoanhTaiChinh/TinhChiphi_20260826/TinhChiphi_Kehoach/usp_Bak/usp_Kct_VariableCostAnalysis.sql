SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================
-- Author: TINNT
-- Create date: 2026-08-12
-- Des: Báo cáo phân tích T? tr?ng Bi?n phí
-- ====================================

CREATE OR ALTER PROC dbo.usp_Kct_VariableCostAnalysis @_Year AS VARCHAR(4) ='2026', @_DocDate1 DATE='20260101', @_DocDate2 DATE='20260131', @_ForeignCurrencyOnly TINYINT=0, @_nUserId AS INT=0, @_LangId SMALLINT=0, @_BranchCode VARCHAR(3) ='I09', @_BizDocId VARCHAR(16) ='', @_ItemId NVARCHAR(4000) =''
AS BEGIN
    SET NOCOUNT ON;
    -- T? ??ng l?y thông tin theo AppName khi th?c hi?n trong ch??ng trình, không theo tham s? truy?n vào
    SET @_nUserId=dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);
    DECLARE @_KeyCd NVARCHAR(MAX) =N'', @_Key1 NVARCHAR(MAX) =N'', @_Key2 NVARCHAR(MAX);
    DECLARE @_MoneyType AS dbo.MoneyType=0, @_QuantityType dbo.QuantityType=0, @_TINYINTType TINYINT=0, @_INTType INT=0, @_CodeType VARCHAR(24) ='', @_SMALLDATETIMEType SMALLDATETIME=NULL, @_NameType NVARCHAR(256) =N'', @_UnitType NVARCHAR(8) =N'', @_BizDocIdType VARCHAR(16) =N'', @_DataCode VARCHAR(8) ='', @_DocDate DATE
    SET @_DocDate=DATEADD(DAY, 1-DAY(@_DocDate2), @_DocDate2);
    DECLARE @_SOMONTH DATE=DATEFROMPARTS(YEAR(@_DocDate), MONTH(@_DocDate), '01');
    DECLARE @_EOMONTH DATE=EOMONTH(@_SOMONTH);
    DROP TABLE IF EXISTS #FinPlan_0814
    SELECT TOP(0)DocDate, DocDate00, DocNo, CAST(NULL AS INT) AS Year, CAST(NULL AS INT) AS _Month, CustomerId, ItemId, @_CodeType AS ItemCode, @_NameType AS ItemName, CAST(NULL AS TINYINT) AS ItemType, @_MoneyType AS OriginalUnitCost, @_MoneyType AS Amount, @_QuantityType AS Quantity, @_MoneyType AS OriginalAmount, BranchCode, @_CodeType AS MESGroupCode, --
        @_CodeType AS Type, @_TINYINTType AS M_DocDate, @_INTType AS Y_DocDate, @_CodeType AS Thang, @_BizDocIdType AS BizDocId, IsActive, Id
    INTO #FinPlan_0814
    FROM dbo.vB30FinPlanDetail_GetData;
    IF @_ItemId<>N''
        EXECUTE dbo.usp_sys_GenKey @_Code=@_ItemId, @_ColGen='ItemId', @_ColName='Id', @_TableName='B20Item', @_AndOrKey='   ', @_Key=@_Key1 OUTPUT
    EXEC dbo.usp_FinPlanDetail_GetData @_DocDate1=@_SOMONTH, @_DocDate2=@_EOMONTH, @_UsingDateKey=1, @_Key=@_Key1, @_CtTmp='#FinPlan_0814', @_DateCol='sc.DocDate00', @_BranchCode=@_BranchCode, --, @_PrintExec = 1 --, @_BizDocId = @_BizDocId
        @_LangId=@_LangId;
    DROP TABLE IF EXISTS #K_PlannedCostResult;
    SELECT TOP 0 *, @_MoneyType AS Amount, @_CodeType AS ItemCode, @_NameType AS ItemName, @_CodeType AS ProductClassCode, @_NameType AS ProductClassName, @_CodeType AS CostFactorCode, @_NameType AS CostFactorName, @_CodeType AS ClassCode2, @_MoneyType AS OriginalUnitCost, --Doanh thu k? ho?ch
        @_MoneyType AS Quantity2, @_MoneyType AS Amount2, @_MoneyType AS GrossProfit, @_QuantityType AS GrossProfitMargin, CAST('' AS NVARCHAR(4000)) AS _FormatStyleKey, 0 AS _Status, 0 AS _RN
    INTO #K_PlannedCostResult
    FROM vB30PlannedCostResult_GetData;
    DECLARE @_Key_ZDetail NVARCHAR(MAX) =N'   DocDate BETWEEN '''+FORMAT(DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), 1), 'yyyyMMdd')+N''' AND '''+FORMAT(@_DocDate2, 'yyyyMMdd')+N'''';
    IF @_ItemId<>N''
        EXECUTE dbo.usp_sys_GenKey @_Code=@_ItemId, @_ColGen='ItemId', @_ColName='Id', @_TableName='B20Item', @_AndOrKey=' AND ', @_Key=@_Key_ZDetail OUTPUT
    EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1=@_DocDate1, @_DocDate2=@_DocDate2, @_Key=@_Key_ZDetail, @_CtTmp='#K_PlannedCostResult', @_BranchCode=@_BranchCode, @_BizDocName='vB30PlannedCostResult_GetData', @_PrintExec=0
    UPDATE #K_PlannedCostResult SET _Status=1
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp='#K_PlannedCostResult', @_List_Cats='Item'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp='#K_PlannedCostResult', @_List_Cats='ProductClass'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp='#K_PlannedCostResult', @_List_Cats='CostFactor', @_SetString_Other=',kq.ClassCode2 = CostFactor.ClassCode2';
    ;
    WITH cte AS (SELECT Id, CostFactorId, ItemId, ROW_NUMBER() OVER (PARTITION BY ItemId ORDER BY CostFactorCode) AS _RN
                 FROM #K_PlannedCostResult)
    UPDATE #K_PlannedCostResult
    SET _RN=c._RN
    FROM #K_PlannedCostResult AS k
         INNER JOIN cte AS c ON k.ItemId=c.ItemId AND k.CostFactorId=c.CostFactorId
    UPDATE #K_PlannedCostResult
    SET Quantity2=ISNULL(f.Quantity, k.Quantity), OriginalUnitCost=f.OriginalUnitCost
    FROM #K_PlannedCostResult AS k
         INNER JOIN(SELECT f.ItemId, SUM(Quantity) AS Quantity, MAX(OriginalUnitCost) AS OriginalUnitCost
                    FROM #FinPlan_0814 AS f
                    GROUP BY ItemId) AS f ON k.ItemId=f.ItemId
    WHERE _RN=1 OR _RN=0
    UPDATE k
    SET k.VariableAmount=a.VariableAmount, k.FixedAmount=a.FixedAmount, k.Coeff=a.Coeff
    FROM #K_PlannedCostResult AS k
         INNER JOIN(SELECT SUM(VariableAmount) AS VariableAmount, SUM(FixedAmount) AS FixedAmount, SUM(Coeff) AS Coeff, ItemId
                    FROM #K_PlannedCostResult
                    GROUP BY ItemId) AS a ON k.ItemId=a.ItemId
    WHERE _Status=0
    UPDATE #K_PlannedCostResult
    SET Amount2=OriginalUnitCost * Quantity2, Amount=VariableAmount+FixedAmount

    --B?ng phân tích theo y?u t? chi phí
    BEGIN
        DROP TABLE IF EXISTS #K_PlannedCostResult_By_CostFactor
        SELECT ItemId, ItemCode, ItemName, BranchCode, SUM(VariableAmount) AS VariableAmount, SUM(FixedAmount) AS FixedAmount, MAX(Quantity) AS Quantity, SUM(Coeff) AS Coeff, SUM(Amount) AS Amount, ProductClassId, ProductClassCode, ProductClassName, CostFactorId, CostFactorCode, CostFactorName, OriginalUnitCost, ClassCode2, MAX(Quantity2) AS Quantity2, SUM(Amount2) AS Amount2, SUM(GrossProfit) AS GrossProfit, SUM(GrossProfitMargin) AS GrossProfitMargin
        INTO #K_PlannedCostResult_By_CostFactor
        FROM #K_PlannedCostResult
        GROUP BY ItemId, ItemCode, ItemName, BranchCode, ProductClassId, ProductClassCode, ProductClassName, CostFactorId, CostFactorCode, CostFactorName, OriginalUnitCost, ClassCode2
        SELECT * FROM #K_PlannedCostResult_By_CostFactor
        BEGIN
            DROP TABLE IF EXISTS #temptable_BP
            DROP TABLE IF EXISTS #TblProductClass_0814
            SELECT TOP 0 Year, _Month, (Quantity) AS Quantity, (Amount) AS Amount, @_INTType AS ProductClassId, @_CodeType AS ProductClassCode, @_NameType AS ProductClassName, @_INTType AS ProductId
            INTO #TblProductClass_0814
            FROM #FinPlan_0814
            DECLARE @_Doc1 DATE='20260101', @_DocDate_Filter DATE
            DECLARE @_Doc2 DATE=DATEADD(DAY, -1, DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), '01'));
            ;WITH cte AS (SELECT EOMONTH(@_Doc1) AS DocDate
                          UNION ALL
                          SELECT EOMONTH(DATEADD(MONTH, 1, DocDate))
                          FROM cte
                          WHERE EOMONTH(DATEADD(MONTH, 1, DocDate))<=EOMONTH(@_Doc2))
            SELECT DocDate INTO #tbl_Date FROM cte
            OPTION(MAXRECURSION 0);   
            WHILE EXISTS (SELECT * FROM #tbl_Date)BEGIN
                SELECT TOP 1 @_DocDate_Filter=DocDate FROM #tbl_Date ORDER BY DocDate
                DELETE #tbl_Date WHERE DocDate=@_DocDate_Filter

                --SELECT @_DocDate_Filter
                SELECT @_Year=YEAR(@_DocDate_Filter)
                EXEC usp_B30FinPlanDetail_PlannedOutputDetermination @_DocDate=@_DocDate_Filter, @_Year=@_Year, @_nUserId=@_nUserId, @_LangId=@_LangId, @_BranchCode=@_BranchCode, @_CtTmp2='#TblProductClass_0814'
                DELETE #TblProductClass_0814
                WHERE ProductClassId NOT IN(SELECT ProductClassId FROM #K_PlannedCostResult)

				--2026-08-15 00:10:30.460 xong b??c l?y t?ng l??ng doanh thu k? ho?ch quá kh?
				-- x? lý l?y ??nh m?c theo các y?u t? chi phí quá kh?
				-- tính: S? giá v?n quá kh? theo nhóm s?n ph?m = s?n l??ng * ??nh m?c 
				--
            END
            SELECT * FROM #TblProductClass_0814
            RETURN
        END
    END
    DROP TABLE IF EXISTS #K_PlannedCostResult, #FinPlan_0814, #K_PlannedCostResult_By_CostFactor
--, #K_PlannedCostResult_By_Item
END;
GO
SET DATEFORMAT DMY
--EXEC usp_Kct_PlannedCostResult @_DocDate1 = '01/03/2026 00:00:00.000'
--                             , @_DocDate2 = '31/03/2026 00:00:00.000'
--                             , @_nUserId = 1213
--                             , @_LangId = 0
--                             , @_BranchCode = 'I09'
EXEC usp_Kct_VariableCostAnalysis @_DocDate1='01/04/2026 00:00:00.000', @_DocDate2='30/04/2026 00:00:00.000', @_nUserId=1213, @_LangId=0, @_BranchCode='I09', @_ItemId='1422799'