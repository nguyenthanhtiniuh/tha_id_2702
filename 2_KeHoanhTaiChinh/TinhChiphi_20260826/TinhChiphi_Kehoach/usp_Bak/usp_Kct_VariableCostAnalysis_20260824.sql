SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================
-- Author: TINNT
-- Create date: 2026-08-24
-- Des: Báo cáo phân tích Tỷ trọng Biến phí 
-- ====================================

CREATE OR ALTER PROC dbo.usp_Kct_VariableCostAnalysis_20260824
    @_Year AS VARCHAR(4) = '2026'
  , @_DocDate1 DATE = '20260101'
  , @_DocDate2 DATE = '20260131'
  , @_ForeignCurrencyOnly TINYINT = 0
  , @_nUserId AS INT = 0
  , @_LangId SMALLINT = 0
  , @_BranchCode VARCHAR(3) = 'I09'
  , @_BizDocId VARCHAR(16) = ''
  , @_ItemId NVARCHAR(4000) = ''
  , @_CtTmp1 NVARCHAR(24) = ''
  , @_CtTmp2 NVARCHAR(24) = ''
--, @_SelectExec INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    -- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);
    DECLARE @_Key1 NVARCHAR(MAX) = N''

    DECLARE @_MoneyType    AS dbo.MoneyType = 0
          , @_QuantityType dbo.QuantityType = 0
          , @_TINYINTType  TINYINT          = 0
          , @_INTType      INT              = 0
          , @_CodeType     VARCHAR(24)      = ''
          --, @_SMALLDATETIMEType SMALLDATETIME    = NULL
          , @_NameType     NVARCHAR(256)    = N''
          --, @_UnitType     NVARCHAR(8)      = N''
          , @_BizDocIdType VARCHAR(16)      = N''
          --, @_DataCode          VARCHAR(8)       = ''
          , @_DocDate      DATE
    SET @_DocDate = DATEADD(DAY, 1 - DAY(@_DocDate2), @_DocDate2);
    DECLARE @_SOMONTH DATE = DATEFROMPARTS(YEAR(@_DocDate), MONTH(@_DocDate), '01');
    DECLARE @_EOMONTH DATE = EOMONTH(@_SOMONTH);

    DROP TABLE IF EXISTS #FinPlan_0814
    SELECT TOP (0)
           DocDate
         , DocDate00
         , DocNo
         , CAST(NULL AS INT)     AS Year
         , CAST(NULL AS INT)     AS _Month
         , CustomerId
         , ItemId
         , @_CodeType            AS ItemCode
         , @_NameType            AS ItemName
         , CAST(NULL AS TINYINT) AS ItemType
         , @_MoneyType           AS OriginalUnitCost
         , @_QuantityType        AS Quantity
         , @_MoneyType           AS Amount
         , @_MoneyType           AS OriginalAmount
         , BranchCode
         , @_CodeType            AS MESGroupCode --
         , @_CodeType            AS Type
         , @_TINYINTType         AS M_DocDate
         , @_INTType             AS Y_DocDate
         , @_CodeType            AS Thang
         , @_BizDocIdType        AS BizDocId
         , IsActive
         , Id
         , ProductClassId
         , ProductGroupId
         , ProductLevelId
         , ProductLineId
    INTO #FinPlan_0814
    FROM dbo.vB30FinPlanDetail_GetData;
    IF @_ItemId <> N''
        EXECUTE dbo.usp_sys_GenKey @_Code = @_ItemId
                                 , @_ColGen = 'ItemId'
                                 , @_ColName = 'Id'
                                 , @_TableName = 'B20Item'
                                 , @_AndOrKey = '   '
                                 , @_Key = @_Key1 OUTPUT
    --Lấy dữ liệu kế hoạch
    EXEC dbo.usp_FinPlanDetail_GetData @_DocDate1 = @_SOMONTH
                                     , @_DocDate2 = @_EOMONTH
                                     , @_UsingDateKey = 1
                                     , @_Key = @_Key1
                                     , @_CtTmp = '#FinPlan_0814'
                                     , @_DateCol = 'sc.DocDate00'
                                     , @_BranchCode = @_BranchCode --, @_PrintExec = 1 --, @_BizDocId = @_BizDocId
                                     , @_LangId = @_LangId;

    --SELECT SUM(Amount) FROM #FinPlan_0814 RETURN 

    DROP TABLE IF EXISTS #K_PlannedCostResult_Present
    SELECT TOP (0)
           *
         , @_MoneyType                AS Amount
         , @_CodeType                 AS ItemCode
         , @_NameType                 AS ItemName
         , @_CodeType                 AS ProductClassCode
         , @_NameType                 AS ProductClassName
         , @_CodeType                 AS CostFactorCode
         , @_NameType                 AS CostFactorName
         , @_CodeType                 AS ClassCode2
         , @_MoneyType                AS OriginalUnitCost --Doanh thu kế hoạch
         , @_MoneyType                AS Quantity2
         , @_MoneyType                AS Amount2
         , @_MoneyType                AS GrossProfit
         , @_QuantityType             AS GrossProfitMargin
         , CAST('' AS NVARCHAR(4000)) AS _FormatStyleKey
         , 0                          AS _Status
         , 0                          AS _RN
    INTO #K_PlannedCostResult_Present
    FROM vB30PlannedCostResult_GetData;

    DECLARE @_Key_ZDetail NVARCHAR(MAX) = ''

    SELECT @_Key_ZDetail
        = @_Key_ZDetail + N'    DocDate BETWEEN '''
          + FORMAT(DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), 1), 'yyyyMMdd') + N''' AND '''
          + FORMAT(@_DocDate2, 'yyyyMMdd') + N'''';

    IF @_ItemId <> N''
        EXECUTE dbo.usp_sys_GenKey @_Code = @_ItemId
                                 , @_ColGen = 'ItemId'
                                 , @_ColName = 'Id'
                                 , @_TableName = 'B20Item'
                                 , @_AndOrKey = ' AND '
                                 , @_Key = @_Key_ZDetail OUTPUT

    --Lấy lại Dữ liệu giá vốn Kế hoạch trong tháng 
    EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                             , @_DocDate2 = @_DocDate2
                                             , @_Key = @_Key_ZDetail
                                             , @_CtTmp = '#K_PlannedCostResult_Present'
                                             , @_BranchCode = @_BranchCode
                                             , @_BizDocName = 'vB30PlannedCostResult_GetData'
                                             , @_PrintExec = 0
    --chỉ lấy dữ liệu Biến phí
    DELETE #K_PlannedCostResult_Present
    WHERE ClassCode2 = 'DP'

    UPDATE #K_PlannedCostResult_Present
    SET _Status = 1

    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_PlannedCostResult_Present'
                                           , @_List_Cats = 'Item'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_PlannedCostResult_Present'
                                           , @_List_Cats = 'ProductClass'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#K_PlannedCostResult_Present'
                                           , @_List_Cats = 'CostFactor'
                                           , @_SetString_Other = ',kq.ClassCode2 = CostFactor.ClassCode2';
    ;
    WITH cte
    AS (SELECT Id
             , CostFactorId
             , ItemId
             , ROW_NUMBER() OVER (PARTITION BY ItemId ORDER BY CostFactorCode) AS _RN
        FROM #K_PlannedCostResult_Present)
    UPDATE #K_PlannedCostResult_Present
    SET _RN = c._RN
    FROM #K_PlannedCostResult_Present AS k
        INNER JOIN cte                AS c
            ON k.ItemId = c.ItemId
               AND k.CostFactorId = c.CostFactorId

    UPDATE #K_PlannedCostResult_Present
    SET Quantity2 = ISNULL(ISNULL(f.Quantity, 0), k.Quantity)
      , OriginalUnitCost = f.OriginalUnitCost
    FROM #K_PlannedCostResult_Present AS k
        LEFT JOIN
        (
            SELECT f.ItemId
                 , SUM(Quantity)         AS Quantity
                 , MAX(OriginalUnitCost) AS OriginalUnitCost
            FROM #FinPlan_0814 AS f
            GROUP BY ItemId
        )                             AS f
            ON k.ItemId = f.ItemId
    WHERE _RN = 1
          OR _RN = 0

    UPDATE k
    SET k.VariableAmount = a.VariableAmount
      , k.FixedAmount = a.FixedAmount
      , k.Coeff = a.Coeff
    FROM #K_PlannedCostResult_Present AS k
        INNER JOIN
        (
            SELECT SUM(VariableAmount) AS VariableAmount
                 , SUM(FixedAmount)    AS FixedAmount
                 , SUM(Coeff)          AS Coeff
                 , ItemId
            FROM #K_PlannedCostResult_Present
            GROUP BY ItemId
        )                             AS a
            ON k.ItemId = a.ItemId
    WHERE k._Status = 0;

    ; UPDATE #K_PlannedCostResult_Present
      SET Amount2 = OriginalUnitCost * Quantity2
        , Amount = VariableAmount
    --2026-08-17 phát hiện sai số

    BEGIN

        BEGIN

            --@_Doc1 ngày bắt đầu nhận dữ liệu kế hoạch
            DECLARE @_Doc1           DATE = ''
                  , @_DocDate_Filter DATE

            DECLARE @_Doc2 DATE = DATEADD(DAY, -1, DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), '01'));

            SELECT @_Doc1 = DATEADD(MONTH, -1, @_Doc2);
            WITH cte
            AS (SELECT EOMONTH(@_Doc1) AS DocDate
                UNION ALL
                SELECT EOMONTH(DATEADD(MONTH, 1, DocDate))
                FROM cte
                WHERE EOMONTH(DATEADD(MONTH, 1, DocDate)) <= EOMONTH(@_Doc2))
            SELECT DocDate
                 , 0 AS _Check
            INTO #tbl_Date
            FROM cte
            OPTION (MAXRECURSION 0);

            --2026-08-15 Lấy được tổng Sản lượng doanh thu Kế hoạch 2 tháng trước
            DECLARE @_DocDateSO_Filter DATE
            DECLARE @_DocDateEO_Filter DATE

            UPDATE #tbl_Date
            SET _Check = 0

            DECLARE @_ProductClassId NVARCHAR(4000) = ''

            --Lấy các mã Nhóm sản phẩm HN cấp 2 trong bảng tính
            SELECT @_ProductClassId = STRING_AGG(ProductClassId, ',')
            FROM
            (SELECT DISTINCT ProductClassId FROM #K_PlannedCostResult_Present) AS a

            --11:21 Bắt đầu lấy dữ liệu kết quả tính Kế hoạch giá vốn 2 tháng trước
            WHILE EXISTS (SELECT * FROM #tbl_Date WHERE _Check = 0)
            BEGIN

                SELECT TOP 1
                       @_DocDate_Filter = DocDate
                FROM #tbl_Date
                WHERE _Check = 0
                ORDER BY DocDate

                SELECT @_DocDateSO_Filter = DATEFROMPARTS(YEAR(@_DocDate_Filter), MONTH(@_DocDate_Filter), '01')

                SELECT @_DocDateEO_Filter = EOMONTH(@_DocDate_Filter)

                UPDATE #tbl_Date
                SET _Check = 1
                WHERE DocDate = @_DocDate_Filter

                --SELECT @_DocDate_Filter
                DROP TABLE IF EXISTS #K_PlannedCostResult_LastMonth;
                SELECT TOP 0
                       *
                     , @_MoneyType                AS Amount
                     , @_CodeType                 AS ItemCode
                     , @_NameType                 AS ItemName
                     , @_CodeType                 AS ProductClassCode
                     , @_NameType                 AS ProductClassName
                     , @_CodeType                 AS CostFactorCode
                     , @_NameType                 AS CostFactorName
                     , @_CodeType                 AS ClassCode2
                     , @_MoneyType                AS OriginalUnitCost --Doanh thu kế hoạch
                     , @_MoneyType                AS Quantity2
                     , @_MoneyType                AS Amount2
                     , @_MoneyType                AS GrossProfit
                     , @_QuantityType             AS GrossProfitMargin
                     , CAST('' AS NVARCHAR(4000)) AS _FormatStyleKey
                     , 0                          AS _Status
                     , 0                          AS _RN
                INTO #K_PlannedCostResult_LastMonth
                FROM vB30PlannedCostResult_GetData;

                --Lấy dữ liệu kế hoạch giá vốn các tháng trước
                EXEC usp_Kct_PlannedCostResult @_DocDate1 = @_DocDateSO_Filter
                                             , @_DocDate2 = @_DocDateEO_Filter
                                             , @_nUserId = @_nUserId
                                             , @_LangId = @_LangId
                                             , @_BranchCode = @_BranchCode
                                             , @_CtTmp1 = '#K_PlannedCostResult_LastMonth'

                DELETE #K_PlannedCostResult_LastMonth
                WHERE ProductClassId NOT IN
                      (
                          SELECT ProductClassId FROM #K_PlannedCostResult_Present
                      )

                DELETE #K_PlannedCostResult_LastMonth
                WHERE Quantity = 0

                DELETE #K_PlannedCostResult_LastMonth
                WHERE DocDate >= DATEFROMPARTS(YEAR(@_DocDate2), MONTH(@_DocDate2), '1')

            END

            UPDATE p
            SET ProductId = pro.ProductId
            FROM #K_PlannedCostResult_Present AS p
                INNER JOIN B20ItemInfo        AS pro (READUNCOMMITTED)
                    ON p.ItemId = pro.ItemId

            UPDATE p
            SET ProductId = pro.ProductId
            FROM #K_PlannedCostResult_LastMonth AS p
                INNER JOIN B20ItemInfo          AS pro (READUNCOMMITTED)
                    ON p.ItemId = pro.ItemId;

            --Lấy dữ liệu Giá trị định mức
            ;
            WITH cte
            AS (SELECT
                    --ZCoeff
                    ZCoeff.BranchCode
                  , ZCoeff.EffectiveDate
                  , ZCoeff.ProductId
                  , ZCoeff.Id
                  , ZCoeff.IsActive
                FROM dbo.B20ZCoeff (NOLOCK)            AS ZCoeff
                    LEFT JOIN dbo.B20ItemInfo (NOLOCK) AS ItemInfo
                        ON ZCoeff.ProductId = ItemInfo.ProductId
                WHERE ZCoeff.IsActive = 1
                      AND (EffectiveDate <= EOMONTH(@_DocDate))
                      AND ZCoeff.ProductId IN
                          (
                              SELECT ProductId FROM #K_PlannedCostResult_Present
                          ))
               , cte_Lasteest
            AS (SELECT ZCoeff.BranchCode
                     , ZCoeff.EffectiveDate
                     , ZCoeff.ProductId
                     , ZCoeff.Id
                     , ZCoeff.IsActive
                     , ROW_NUMBER() OVER (PARTITION BY ProductId ORDER BY EffectiveDate DESC) AS _RN
                FROM cte AS ZCoeff)
            SELECT
                --ZCoeff
                ZCoeff.BranchCode
              , ZCoeff.EffectiveDate
              , ZCoeff.ProductId
              , ZCoeffDetail.CostFactorId
              , ZCoeffDetail.StageId
              , ZCoeffDetail.Coeff
              , ItemInfo.ItemId
            INTO #ZCoeffDetail0
            FROM dbo.B20ZCoeff (NOLOCK)                 AS ZCoeff
                INNER JOIN dbo.B20ZCoeffDetail (NOLOCK) AS ZCoeffDetail
                    ON ZCoeff.Id = ZCoeffDetail.ParentId
                LEFT JOIN dbo.B20ItemInfo (NOLOCK)      AS ItemInfo
                    ON ZCoeff.ProductId = ItemInfo.ProductId
                LEFT JOIN dbo.B20CostFactor (NOLOCK)    AS CostFactor
                    ON ZCoeffDetail.CostFactorId = CostFactor.Id
            WHERE ZCoeff.Id IN
                  (
                      --2026-08-11 Lấy định mức gần nhất
                      SELECT Id FROM cte_Lasteest WHERE _RN = 1
                  )
                  AND CostFactor.ClassCode2 = 'BP';

            -- Lấy xong dữ liệu biến phí quá khứ
            DROP TABLE IF EXISTS #tbl_TyTrongBienPhi;
            WITH cte_LastMonth
            AS (SELECT ProductClassCode
                     , ProductClassId
                     , ProductClassName
                     , CostFactorCode
                     , CostFactorName
                     , CostFactorId
                     , SUM(VariableAmount) AS VariableAmount
                --chỉ lấy các mã  đã tính biến phí của tháng quá khứ
                FROM #K_PlannedCostResult_LastMonth
                WHERE ProductId IN
                      (
                          SELECT ProductId FROM #ZCoeffDetail0
                      )
                GROUP BY ProductClassCode
                       , ProductClassId
                       , ProductClassName
                       , CostFactorCode
                       , CostFactorName
                       , CostFactorId)
               , cte_ThisMonth
            AS (SELECT ProductClassCode
                     , ProductClassId
                     , SUM(Amount2) AS Amount2
                FROM #K_PlannedCostResult_Present
                GROUP BY ProductClassCode
                       , ProductClassId)
            SELECT c_lastmonth.ProductClassCode
                 , c_lastmonth.ProductClassId
                 , ProductClassName
                 , c_lastmonth.CostFactorCode
                 , CostFactorName
                 , c_lastmonth.CostFactorId
                 , c_lastmonth.VariableAmount
                 , t_month.Amount2
                 , c_lastmonth.VariableAmount / Amount2 AS TyTrongBienPhi
                 , ROW_NUMBER() OVER (PARTITION BY c_lastmonth.ProductClassCode
                                      ORDER BY c_lastmonth.CostFactorCode
                                     )                  AS _RN
            INTO #tbl_TyTrongBienPhi
            FROM cte_LastMonth           AS c_lastmonth
                INNER JOIN cte_ThisMonth AS t_month
                    ON t_month.ProductClassId = c_lastmonth.ProductClassId

            DROP TABLE IF EXISTS #tbl_GiaVonKeHoach_SanPhanMoi;
            ;WITH cte
            AS (SELECT pre.BranchCode
                     , pre.ItemId
                     , pre.ItemCode
                     , pre.ItemName
                     , pre.Amount2
                     , pre.Quantity2
                     , pre.OriginalUnitCost
                     , pre.ProductClassId
                FROM #K_PlannedCostResult_Present AS pre
                WHERE
                    --chỉ lấy 1 dòng đại diện
                    (OriginalUnitCost <> 0)
                    AND
                    --2026-08-17 chỉ lấy các mã chưa có khai báo định mức tính P-L để tính toán 
                    pre.ProductId NOT IN
                    (
                        SELECT ProductId FROM #ZCoeffDetail0
                    ))
                , cte_TyTrongBienPhi
            AS (SELECT *
                FROM #tbl_TyTrongBienPhi AS t
                WHERE t.ProductClassId IN
                      (
                          SELECT cte.ProductClassId FROM cte
                      ))
            SELECT pre.BranchCode
                 , pre.ItemId
                 , pre.ItemCode
                 , pre.ItemName
                 , pre.Amount2
                 , pre.Quantity2
                 , pre.OriginalUnitCost
                 , t.ProductClassCode
                 , t.ProductClassName
                 , pre.ProductClassId
                 , t.CostFactorCode
                 , t.CostFactorName
                 , t.CostFactorId
                 , t.TyTrongBienPhi
                 , t.TyTrongBienPhi * pre.Amount2                          AS VariableAmount --2026-08-17 lấy thêm trường giá trị biến phí để kế thừa qua hàm post                                                                        
                 , t.TyTrongBienPhi * pre.Amount2                          AS Amount
                 , DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), '1') AS DocDate
            INTO #tbl_GiaVonKeHoach_SanPhanMoi
            FROM cte                          AS pre
                INNER JOIN cte_TyTrongBienPhi AS t
                    ON t.ProductClassId = pre.ProductClassId

            UPDATE #tbl_GiaVonKeHoach_SanPhanMoi
            SET VariableAmount = t_spm.Amount2 * t.TyTrongBienPhi
              , Amount = t_spm.Amount2 * t.TyTrongBienPhi
            FROM #tbl_GiaVonKeHoach_SanPhanMoi AS t_spm
                INNER JOIN #tbl_TyTrongBienPhi AS t
                    ON t_spm.ProductClassId = t.ProductClassId
                       AND t_spm.CostFactorId = t.CostFactorId

            -----------
            ;
            WITH cte
            AS (SELECT ItemId
                     , CostFactorCode
                     , ROW_NUMBER() OVER (PARTITION BY ItemId ORDER BY CostFactorCode) AS _RN
                FROM #tbl_GiaVonKeHoach_SanPhanMoi)
            UPDATE #tbl_GiaVonKeHoach_SanPhanMoi
            SET Quantity2 = 0
              , OriginalUnitCost = 0
              , Amount2 = 0
            FROM #tbl_GiaVonKeHoach_SanPhanMoi AS t
                INNER JOIN cte                 AS c
                    ON t.ItemId = c.ItemId
                       AND t.CostFactorCode = c.CostFactorCode
            WHERE c._RN <> 1

            DECLARE @_FieldInsert VARCHAR(MAX)  = ''
                  , @_FieldSelect VARCHAR(MAX)  = ''
                  , @_strExec     NVARCHAR(MAX) = ''

            IF ISNULL(@_CtTmp1, '') <> ''
            BEGIN
                SELECT @_FieldInsert = @_FieldInsert + ',' + RTRIM(Name)
                FROM
                (
                    SELECT DISTINCT
                           Name
                    FROM tempdb.sys.Columns WITH (NOLOCK)
                    WHERE Object_Id = OBJECT_ID('Tempdb..' + @_CtTmp1)
                          AND Name IN
                              (
                                  SELECT DISTINCT
                                         Name
                                  FROM tempdb.sys.Columns WITH (NOLOCK)
                                  WHERE Object_Id = OBJECT_ID('Tempdb..' + '#tbl_TyTrongBienPhi')
                              )
                ) AS tb1;
                SET @_FieldInsert = STUFF(@_FieldInsert, 1, 1, '');
                SET @_FieldSelect = @_FieldInsert;
                SET @_strExec
                    = N'INSERT INTO ' + @_CtTmp1 + N'(' + @_FieldInsert + N')' + CHAR(13) + N'SELECT ' + @_FieldSelect
                      + CHAR(13) + N'FROM #tbl_TyTrongBienPhi ' + CHAR(13) + N' ';

                EXEC sp_executesql @_strExec;
                RETURN;
            END;
            IF ISNULL(@_CtTmp2, '') <> ''
            BEGIN
                SELECT @_FieldInsert = @_FieldInsert + ',' + RTRIM(Name)
                FROM
                (
                    SELECT DISTINCT
                           Name
                    FROM tempdb.sys.Columns WITH (NOLOCK)
                    WHERE Object_Id = OBJECT_ID('Tempdb..' + @_CtTmp2)
                          AND Name IN
                              (
                                  SELECT DISTINCT
                                         Name
                                  FROM tempdb.sys.Columns WITH (NOLOCK)
                                  WHERE Object_Id = OBJECT_ID('Tempdb..' + '#tbl_GiaVonKeHoach_SanPhanMoi')
                              )
                ) AS tb1;
                SET @_FieldInsert = STUFF(@_FieldInsert, 1, 1, '');
                SET @_FieldSelect = @_FieldInsert;
                SET @_strExec
                    = N'INSERT INTO ' + @_CtTmp2 + N'(' + @_FieldInsert + N')' + CHAR(13) + N'SELECT ' + @_FieldSelect
                      + CHAR(13) + N'FROM #tbl_GiaVonKeHoach_SanPhanMoi ' + CHAR(13) + N'ORDER BY CostFactorCode ASC';
                EXEC sp_executesql @_strExec;
                RETURN;
            END;

            UPDATE #tbl_TyTrongBienPhi
            SET Amount2 = 0
            WHERE _RN <> 1

            BEGIN
                --TBL1
                SELECT *
                FROM #tbl_TyTrongBienPhi;
                --TBL2
                SELECT *
                FROM #tbl_GiaVonKeHoach_SanPhanMoi
                ORDER BY CostFactorCode ASC;
            END
        END
    END
    DROP TABLE IF EXISTS #K_PlannedCostResult_0815
                       , #FinPlan_0814
                       , #K_PlannedCostResult_By_CostFactor
                       , #tbl_GiaVonKeHoach_SanPhanMoi

END;
GO


SET DATEFORMAT DMY
EXEC dbo.usp_Kct_VariableCostAnalysis_20260824 @_DocDate1 = '01/03/2026 00:00:00.000'
                                             , @_DocDate2 = '31/03/2026 00:00:00.000'
                                             , @_nUserId = 1213
                                             , @_LangId = 0
                                             , @_BranchCode = 'I09'