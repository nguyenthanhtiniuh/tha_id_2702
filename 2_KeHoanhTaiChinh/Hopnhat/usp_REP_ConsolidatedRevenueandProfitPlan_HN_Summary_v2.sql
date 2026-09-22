SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
author: TINNT
creted_at: 15-05-2026
Kế hoạch doanh thu - lợi nhuận sản phẩm hợp nhất (I.c i.d I.e)	
*/
ALTER PROCEDURE dbo.usp_REP_ConsolidatedRevenueandProfitPlan_HN_Summary_v2
    @_DocDate1 DATE = '20260101'
  , @_DocDate2 DATE = '20260131'
  , @_Account NVARCHAR(2000) = '511,515,641,642,635,711,811,911'
  , @_ExcludeCrspAccount VARCHAR(254) = '821,911'
  , @_NotMESGroupCodeList VARCHAR(254) = ''
  , @_BranchCode NVARCHAR(24) = ''
  , @_nUserId INT = 0
  , @_LangId INT = 0
  , @_CurrencyCode0 CHAR(3) = 'VND'
  , @_LAYOUT_XML NVARCHAR(MAX) = '' OUTPUT
  , @_IsRound INT = 0
  , @_BranchReportId INT = NULL
  , @_RepId1 VARCHAR(16) = 'T000000015'
  , @_RepId2 VARCHAR(16) = 'T000000013'
  , @_RepId3 VARCHAR(16) = 'T000000017'
  , @_DefinitionTableName NVARCHAR(32) = N'B10BusinessPlanHNDetail'
  , @_StrTime NVARCHAR(128) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- ========================================================
    -- 1. KHỞI TẠO BIẾN VÀ BẢNG TẠM CƠ SỞ
    -- ========================================================
    DECLARE @_Time1       DATETIME      = GETDATE()
          , @_Time2       DATETIME
          , @_LAYOUT_XML1 NVARCHAR(MAX) = N''
          , @_nl          CHAR(1)       = CHAR(13);
    DECLARE @DebugStartTime DATETIME = GETDATE()
          , @DebugStepTime  DATETIME = GETDATE()
          , @DebugMsg       NVARCHAR(2000)
          , @_Step          NVARCHAR(2000);
    DECLARE @_MoneyType    AS dbo.MoneyType = 0
          , @_QuantityType dbo.QuantityType = 0
          , @_TINYINTType  TINYINT          = 0
          , @_INTType      INT              = 0
    SELECT @_Step = N'BẮT ĐẦU CHẠY SP...';
    SET @DebugMsg = N'[' + CONVERT(VARCHAR, GETDATE(), 114) + N'] ' + @_Step;
    RAISERROR(@DebugMsg, 10, 1) WITH NOWAIT;
    DECLARE @_Num_Round INT = CASE
                                  WHEN @_IsRound = 1 THEN
                                      1000000
                                  ELSE
                                      1
                              END;
    -- Tạo cấu trúc cột cho báo cáo
    DROP TABLE IF EXISTS #ColList;
    CREATE TABLE #ColList
    (
        Tt INT
      , M_DocDate1 INT
      , M_DocDate2 INT
      , Y_DocDate INT
      , ColName NVARCHAR(128)
      , UserData0 NVARCHAR(128)
      , Row_0_VN NVARCHAR(256)
      , Row_0_EN NVARCHAR(256)
      , UserData1 NVARCHAR(128)
      , Row_1_VN NVARCHAR(256)
      , Row_1_EN NVARCHAR(256)
      , _TextAlign NVARCHAR(24)
      , _Width NVARCHAR(24)
      , _Format NVARCHAR(24)
      , _ForeColor NVARCHAR(24)
      , _BackColor NVARCHAR(24)
      , Type INT
    );
    INSERT INTO #ColList
    EXEC dbo.usp_GenerateReportHeader_ActualPlan_CDT @_DocDate1 = @_DocDate1
                                                   , @_DocDate2 = @_DocDate2
                                                   , @_LAYOUT_XML = @_LAYOUT_XML1 OUTPUT;
    DECLARE @_KeyHeader VARCHAR(MAX) = N' Stt = ''' + @_RepId1 + N''' ';
    DROP TABLE IF EXISTS #tblTmp;
    SELECT TOP (0)
           *
    INTO #tblTmp
    FROM dbo.B10BusinessPlanHNDetail;
    EXECUTE dbo.usp_sys_Append @_DefinitionTableName
                             , '#tblTmp'
                             , @_Where_TableSource = @_KeyHeader;
    --EXECUTE dbo.usp_sys_Append @_TableSource='B10BusinessPlanHNDetail',@_TableDestination= '#tblTmp', @_Where_TableSource = @_KeyHeader;
    SELECT @_KeyHeader = N' Stt = ''' + @_RepId2 + N''' ';
    SELECT TOP (0)
           *
         , CAST('' AS NVARCHAR(72))  AS ValueCol
         , CAST('' AS NVARCHAR(MAX)) AS VarValueDetail
    INTO #tblTmp2
    FROM dbo.B10BusinessPlanHNDetail;
    EXECUTE dbo.usp_sys_Append @_DefinitionTableName
                             , '#tblTmp2'
                             , @_Where_TableSource = @_KeyHeader;

    --Dùng hàm ufn_Get_List_CatgDetail để lấy giá trị các mã con
    ;
    WITH cte
    AS (SELECT dbo.ufn_Get_List_CatgDetail(ca.value, 'vb20ExpenseCatg', 'Id') AS List_CatgDetail
             , tmp.Id
        FROM #tblTmp2                                   AS tmp
            CROSS APPLY
        (SELECT value FROM STRING_SPLIT(VarValue, ',')) AS ca
        WHERE tmp.VarValue IS NOT NULL
              AND tmp.ExpenditureType LIKE 'CP%')
       , cte1
    AS (SELECT STRING_AGG(cte.List_CatgDetail, ',') AS List_CatgDetail
             , Id
        FROM cte
        WHERE cte.List_CatgDetail <> ''
        GROUP BY Id)
    UPDATE #tblTmp2
    SET VarValueDetail = c1.List_CatgDetail
    FROM #tblTmp2       AS tmp2
        INNER JOIN cte1 AS c1
            ON tmp2.Id = c1.Id;
    --Lấy giá trị ValueCol làm Loại tk
    UPDATE #tblTmp2
    SET ValueCol = cl.ValueCol
    FROM #tblTmp2                              AS TMP
        LEFT JOIN B10THACOID_Data.dbo.B20Class AS cl
            ON cl.ParentCode = 'ExpenditureType'
               AND TMP.ExpenditureType = cl.Code;
    SELECT @_KeyHeader = N' Stt = ''' + @_RepId3 + N''' ';
    SELECT TOP (0)
           *
         , CAST('' AS NVARCHAR(72)) AS ValueCol
    INTO #tblTmp3
    FROM dbo.B10BusinessPlanHNDetail;
    EXECUTE dbo.usp_sys_Append @_DefinitionTableName
                             , '#tblTmp3'
                             , @_Where_TableSource = @_KeyHeader;
    DECLARE @_AlterCols NVARCHAR(MAX) = N'';
    SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,2) DEFAULT 0', ',')
    FROM #ColList;
    DECLARE @_SqlAlter NVARCHAR(MAX) = N'ALTER TABLE #tblTmp ADD ' + @_AlterCols + N';';
    EXEC sys.sp_executesql @_SqlAlter;
    SELECT @_SqlAlter = N'ALTER TABLE #tblTmp2 ADD ' + @_AlterCols + N';';
    EXEC sys.sp_executesql @_SqlAlter;
    SELECT @_SqlAlter = N'ALTER TABLE #tblTmp3 ADD ' + @_AlterCols + N';';
    EXEC sys.sp_executesql @_SqlAlter;
    --Lấy giá trị ValueCol làm Loại tk
    UPDATE #tblTmp2
    SET ValueCol = cl.ValueCol
    FROM #tblTmp2                              AS TMP
        LEFT JOIN B10THACOID_Data.dbo.B20Class AS cl WITH (NOLOCK)
            ON cl.ParentCode = 'ExpenditureType'
               AND TMP.ExpenditureType = cl.Code;
    UPDATE #tblTmp3
    SET ValueCol = cl.ValueCol
    FROM #tblTmp3                              AS TMP
        LEFT JOIN B10THACOID_Data.dbo.B20Class AS cl WITH (NOLOCK)
            ON cl.ParentCode = 'ExpenditureType'
               AND TMP.ExpenditureType = cl.Code;
    DECLARE @_Key_Acc NVARCHAR(MAX)
        = N'((Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + N'%''))';
    IF ISNULL(@_ExcludeCrspAccount, '') <> ''
        SET @_Key_Acc
            = @_Key_Acc + N' AND ((CrspAccount NOT LIKE '''
              + REPLACE(@_ExcludeCrspAccount, ',', '%'') OR (CrspAccount NOT LIKE ''') + N'%''))';;
    IF LTRIM(RTRIM(@_NotMESGroupCodeList)) <> N''
    BEGIN
        SET @_Key_Acc
            = @_Key_Acc + N' AND CustomerId0 IN (SELECT Id FROM dbo.B20Customer WHERE MESGroupCode NOT IN ('''
              + REPLACE(REPLACE(@_NotMESGroupCodeList, N' ', N''), N',', N''',''') + N'''))';
    END;
    --- DEBUG LOG ---
    SELECT @_Step = N' Bước 1: Khởi tạo dữ liệu cơ bản & GenKey xong.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @DebugStepTime OUTPUT;
    -- ========================================================
    -- 2. THU THẬP DỮ LIỆU HẠCH TOÁN THỰC TẾ (#CtTmpGeneralLedger)
    -- ========================================================
    DROP TABLE IF EXISTS #CtTmpGeneralLedger;
    SELECT TOP (0)
           CAST(-1 AS INT)           AS Id
         , BranchCode
         , DocDate
         , DocCode
         , CustomerId0
         , CustomerId
         --,Amount2
         --,OriginalAmount2
         , Stt
         , RowId
         , Account
         , CrspAccount
         , DebitAccount
         , CreditAccount
         , @_MoneyType               AS No_Co
         , @_MoneyType               AS Co_No
         , @_MoneyType               AS OriginalAmount
         , ItemId
         , CAST('' AS NVARCHAR(128)) AS _FormatStyleKey
         , @_MoneyType               AS DebitAmount
         , @_MoneyType               AS OriginalDebitAmount
         , @_MoneyType               AS CreditAmount
         , @_QuantityType            AS Quantity
         , CurrencyCode
         , CAST('' AS VARCHAR(24))   AS MESGroupCode
         --19-04-2026 TINNT bổ sung thêm trường Khoản mục phí -> dùng để lấy tiêu chí group lên báo cáo dữ liệu theo khoản mục phí
         , ExpenseCatgId
         , Description
         --
         , CAST('' AS NVARCHAR(24))  AS Thang
         , CAST('' AS NVARCHAR(24))  AS Type
         , @_TINYINTType             AS M_DocDate
         , @_INTType                 AS Y_DocDate
    INTO #CtTmpGeneralLedger
    FROM dbo.B00CtTmp;
    EXEC dbo.usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                        , @_DocDate2 = @_DocDate2
                                        , @_Key1 = @_Key_Acc
                                        , @_Key2 = ''
                                        , @_CtTmp = N'#CtTmpGeneralLedger'
                                        , @_nUserId = @_nUserId
                                        , @_LangId = @_LangId
                                        , @_BranchReportId = @_BranchReportId
                                        , @_BranchCode = @_BranchCode
                                        , @_CurrencyCode0 = @_CurrencyCode0;
    UPDATE c
    SET c.MESGroupCode = cus.MESGroupCode
    FROM #CtTmpGeneralLedger       AS c
        INNER JOIN dbo.B20Customer AS cus WITH (NOLOCK)
            ON c.CustomerId0 = cus.Id;
    UPDATE #CtTmpGeneralLedger
    SET Type = 'ACTUAL'
      , M_DocDate = MONTH(ge.DocDate)
      , Y_DocDate = YEAR(ge.DocDate)
      , No_Co = ge.DebitAmount - ge.CreditAmount
      , Co_No = ge.CreditAmount - ge.DebitAmount
    FROM #CtTmpGeneralLedger AS ge;
    UPDATE #CtTmpGeneralLedger
    SET Thang = cl.ColName
    FROM #CtTmpGeneralLedger AS ge
        INNER JOIN #ColList  AS cl
            ON ge.M_DocDate = cl.Tt
               AND cl.Type = '0';
    -- ========================================================
    -- THU THẬP DỮ LIỆU KẾ HOẠCH (#FinActual)
    -- các đơn vị ngoại lệ SMT
    -- ========================================================						
    DROP TABLE IF EXISTS #FinActual;
    SELECT TOP (0)
           DocDate
         , CAST(NULL AS INT)        AS _Year
         , CAST(NULL AS INT)        AS _Month
         , CustomerId
         , ItemId
         , ProfitCenterId
         , CAST(NULL AS TINYINT)    AS ItemType
         , CAST(NULL AS INT)        AS ProductId
         , @_MoneyType              AS OriginalUnitCost
         , @_MoneyType              AS Amount
         , @_MoneyType              AS OriginalAmount
         , CAST('' AS NVARCHAR(24)) AS MESGroupCode
         , CAST('' AS NVARCHAR(24)) AS RouteCode
         , IsActive
         , CurrencyCode --
         , CAST('' AS NVARCHAR(24)) AS Thang
         , CAST('' AS NVARCHAR(24)) AS Type
         , @_TINYINTType            AS M_DocDate
         , @_INTType                AS Y_DocDate
    INTO #FinActual
    FROM dbo.B00CtTmp;
    EXECUTE dbo.usp_sys_DefaultTable @_Table = '#FinActual'; --
    EXEC dbo.usp_FinActualDetail_GetData @_CtTmp = '#FinActual'
                                       , @_PrintExec = 0;
    UPDATE FI
    SET FI.Type = 'ACTUAL'
      , FI.M_DocDate = MONTH(FI.DocDate)
      , FI.Y_DocDate = YEAR(FI.DocDate)
    FROM #FinActual AS FI;
    UPDATE FI
    SET FI.Thang = cl.ColName
    FROM #FinActual         AS FI
        INNER JOIN #ColList AS cl
            ON FI.M_DocDate = cl.Tt
               AND cl.Type = '0';
    -- ========================================================
    -- THU THẬP DỮ LIỆU KẾ HOẠCH (#FinPlan)
    -- ========================================================
    DROP TABLE IF EXISTS #FinPlan;
    SELECT TOP (0)
           DocDate
         , CAST(NULL AS INT)        AS _Year
         , CAST(NULL AS INT)        AS _Month
         , CustomerId
         , ItemId
         , ProfitCenterId
         , CAST(NULL AS TINYINT)    AS ItemType
         , CAST(NULL AS INT)        AS ProductId
         , @_MoneyType              AS OriginalUnitCost
         , @_MoneyType              AS Amount
         , @_MoneyType              AS OriginalAmount
         , BranchCode
         , CAST('' AS NVARCHAR(24)) AS MESGroupCode --
         , CAST('' AS NVARCHAR(24)) AS Thang
         , CAST('' AS NVARCHAR(24)) AS Type
         , @_TINYINTType            AS M_DocDate
         , @_INTType                AS Y_DocDate
    INTO #FinPlan
    FROM dbo.B00CtTmp;
    EXEC dbo.usp_FinPlanDetail_GetData @_CtTmp = '#FinPlan'
                                     , @_BranchCode = @_BranchCode
                                     , @_PrintExec = 0;
    UPDATE fi
    SET fi.Type = 'PLAN'
      , fi.M_DocDate = MONTH(fi.DocDate)
      , fi.Y_DocDate = YEAR(fi.DocDate)
    FROM #FinPlan AS fi;
    UPDATE FI
    SET FI.Thang = cl.ColName
    FROM #FinPlan           AS FI
        INNER JOIN #ColList AS cl
            ON FI.M_DocDate = cl.Tt
               AND cl.Type = '1';
    DELETE #FinPlan
    WHERE (DocDate < @_DocDate1);
    INSERT INTO #CtTmpGeneralLedger
    (
        CustomerId
      , MESGroupCode
      , Thang
      , Co_No
      , Account
      , BranchCode
      , Type
    )
    SELECT CustomerId
         , MESGroupCode
         , Thang
         , Amount
         , '511'
         , BranchCode
         , Type
    FROM #FinPlan
    WHERE Thang <> '';
    SELECT @_Step = N' Bước 2: Lấy xong dữ liệu sổ cái, số hoạch doanh thu, số thực hiện các đơn vị ngoại lệ.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @DebugStepTime OUTPUT;
    IF @_Num_Round <> 1
    BEGIN
        UPDATE #CtTmpGeneralLedger
        SET DebitAmount = DebitAmount / @_Num_Round
          , CreditAmount = CreditAmount / @_Num_Round;
        UPDATE #FinActual
        SET Amount = Amount / @_Num_Round;
        UPDATE #FinPlan
        SET Amount = Amount / @_Num_Round;
    END;
    /*2026-05-15 thêm đk lọc cho bang #kq_DoanhThu tk doanh thu  */
    DECLARE @_Account_DT NVARCHAR(MAX) = N'511';
    DECLARE @_CrspAccount_DT NVARCHAR(2000) = N'521,3332,333301,33381';
    DECLARE @_Key_DoanhThu VARCHAR(MAX)
        = N'(Account LIKE N''' + REPLACE(@_Account_DT, N',', N'%'' OR Account LIKE N''') + N'%'')';
    IF @_CrspAccount_DT <> ''
        SET @_Key_DoanhThu += N'OR (' + N'  (CrspAccount LIKE '''
                              + REPLACE(@_CrspAccount_DT, ',', '%'') OR (CrspAccount LIKE ''') + N'%'')' + N')';
    DECLARE @_ColName_Total NVARCHAR(128) = N''
          , @_SetColumns    NVARCHAR(MAX) = N'';
    SELECT @_SetColumns
        = STRING_AGG(CONCAT(QUOTENAME(ColName), ' = ISNULL(b.', QUOTENAME(ColName), ', 0)') + @_nl, ', ')
    FROM #ColList;
    SELECT TOP (1)
           @_ColName_Total = ColName
    FROM #ColList
    WHERE Tt = 0
    ORDER BY Tt ASC;
    DROP TABLE IF EXISTS #kq_DoanhThu;
    SELECT TOP (0)
           BranchCode
    INTO #kq_DoanhThu
    FROM #CtTmpGeneralLedger;
    DECLARE @_BrowField NVARCHAR(MAX) = N''
          , @_query     NVARCHAR(MAX) = N''
          , @_bang      VARCHAR(256)
          , @_agg_col   VARCHAR(256)
          , @_on_rows   VARCHAR(256);
    DECLARE @_query_ColList NVARCHAR(MAX) = N' SELECT  ColName FROM #ColList  ';
    DECLARE @_on_cols_ColList NVARCHAR(MAX) = N'ColName';
    SELECT @_query = N'SELECT * FROM #CtTmpGeneralLedger WHERE  ' + @_Key_DoanhThu + N'  ';
    SELECT @_bang    = '#kq_DoanhThu'
         , @_agg_col = 'ISNULL(Co_No,0)'
         , @_on_rows = 'BranchCode';
    EXEC dbo.usp_pivot_KHTC @query_ColList = @_query_ColList
                          , @on_cols_ColList = @_on_cols_ColList
                          , @_ColName_Total = @_ColName_Total
                          , @query = @_query
                          , @on_rows = @_on_rows
                          , @on_cols = 'Thang'
                          , @agg_func = 'SUM'
                          , @agg_col = @_agg_col
                          , @bang = @_bang
                          , @brow_str = @_BrowField
                          , @_PrintExec = 0;
    DECLARE @_SqlInsertAgg NVARCHAR(MAX)
        = N'UPDATE a 
			SET ' + @_SetColumns
          + N'
			FROM #tblTmp a INNER JOIN #kq_DoanhThu b ON a.VarValue = b.BranchCode and a.VarKey = ''BranchCode'' ;        		';
    EXEC sys.sp_executesql @_SqlInsertAgg;
    DROP TABLE IF EXISTS #kq_DoanhThu_Route;
    SELECT TOP (0)
           RouteCode
    INTO #kq_DoanhThu_Route
    FROM #FinActual;
    SELECT @_query = N'SELECT * FROM #FinActual   ';
    SELECT @_bang    = '#kq_DoanhThu_Route'
         , @_agg_col = 'ISNULL(Amount,0)'
         , @_on_rows = 'RouteCode';
    EXEC dbo.usp_pivot_KHTC @query_ColList = @_query_ColList
                          , @on_cols_ColList = @_on_cols_ColList
                          , @_ColName_Total = @_ColName_Total
                          , @query = @_query
                          , @on_rows = @_on_rows
                          , @on_cols = 'Thang'
                          , @agg_func = 'SUM'
                          , @agg_col = @_agg_col
                          , @bang = @_bang
                          , @brow_str = @_BrowField
                          , @_PrintExec = 0;
    SELECT @_SqlInsertAgg
        = N'UPDATE a
			SET ' + @_SetColumns
          + N'
			FROM #tblTmp a INNER JOIN #kq_DoanhThu_Route b ON a.VarValue = b.RouteCode and a.VarKey = ''RouteCode'' ;				 				'; -- 
    EXEC sys.sp_executesql @_SqlInsertAgg;
    SELECT @_Step
        = N' Bước 3: Cập nhật xong Lưới 1(#tblTmp) Số thực hiện, Số Kế hoạch doanh thu, Số thực hiện các đơn vị ngoại lệ.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @DebugStepTime OUTPUT;
    -- ========================================================    
    --BẮT ĐẦU XỬ LÝ LẤY DỮ LIỆU Z CHI PHÍ   
    -- ========================================================
    BEGIN
        DECLARE @_StrExec     NVARCHAR(MAX) = N''
              , @_Key_ZDetail NVARCHAR(MAX) = N'';
        DROP TABLE IF EXISTS #ZDetail;
        SELECT TOP (0)
               BranchCode
             , DocDate
             , ProductId
             , StageId
             , CostFactorId
             , ExpenseAccount
             , ItemId
             , DirectQuantity
             , IndirectQuantity
             , DirectAmount
             , InDirectAmount
             , DirectAmount             AS Amount
             , CAST('' AS NVARCHAR(24)) AS Thang
             , CAST('' AS NVARCHAR(24)) AS Type
             , @_TINYINTType            AS M_DocDate
             , @_INTType                AS Y_DocDate
        INTO #ZDetail
        FROM dbo.B30ZDetail;
        EXEC dbo.usp_sys_DefaultTable N'#ZDetail';
        SET @_Key_ZDetail
            = N'   DocDate BETWEEN ''' + FORMAT(@_DocDate1, 'yyyyMMdd') + N''' AND ''' + FORMAT(@_DocDate2, 'yyyyMMdd')
              + N'''';
        SET @_Key_ZDetail += N' AND CrspAccount NOT LIKE ''155%''';
        SET @_StrExec
            = N' INSERT #ZDetail(BranchCode,DocDate,ProductId,StageId,CostFactorId,ExpenseAccount,ItemId,' + @_nl
              + N'					DirectQuantity,IndirectQuantity,DirectAmount,InDirectAmount,Amount)'   + @_nl
              + N' SELECT BranchCode,DocDate,ProductId,StageId,CostFactorId,ExpenseAccount,ItemId,  ' + @_nl
              + N'					DirectQuantity,IndirectQuantity,DirectAmount,InDirectAmount,ISNULL(DirectAmount,0)+ISNULL(InDirectAmount,0)'
              + @_nl + N' FROM B32012ZDetail ' + @_nl + N' WHERE ' + @_Key_ZDetail;
        EXEC sys.sp_executesql @_StrExec
    END;
    UPDATE ge
    SET ge.Type = 'ACTUAL'
      , ge.M_DocDate = MONTH(ge.DocDate)
      , ge.Y_DocDate = YEAR(ge.DocDate)
    FROM #ZDetail AS ge;
    UPDATE ge
    SET ge.Thang = cl.ColName
    FROM #ZDetail           AS ge
        INNER JOIN #ColList AS cl
            ON ge.M_DocDate = cl.Tt
               AND cl.Type = '0';
    DROP TABLE IF EXISTS #kq_ZDetail;
    SELECT TOP (0)
           CostFactorId
    INTO #kq_ZDetail
    FROM #ZDetail;
    SELECT @_query = N'SELECT * FROM #ZDetail   ';
    SELECT @_bang    = '#kq_ZDetail'
         , @_agg_col = 'ISNULL(Amount,0)'
         , @_on_rows = 'CostFactorId';
    EXEC dbo.usp_pivot_KHTC @query_ColList = @_query_ColList
                          , @on_cols_ColList = @_on_cols_ColList
                          , @_ColName_Total = @_ColName_Total
                          , @query = @_query
                          , @on_rows = @_on_rows
                          , @on_cols = 'Thang'
                          , @agg_func = 'SUM'
                          , @agg_col = @_agg_col
                          , @bang = @_bang
                          , @brow_str = @_BrowField
                          , @_PrintExec = 0;
    SELECT @_Step = N' Bước 4: Lấy xong dữ liệu ZDetail.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @DebugStepTime OUTPUT;
    SELECT @_SqlInsertAgg
        = N'          				 
		UPDATE a
        SET  ' + @_SetColumns
          + N'
        FROM #tblTmp2 a
        INNER JOIN #kq_ZDetail   b ON a.VarValue = b.CostFactorId AND  (ExpenditureType = ''CostFactor'' AND a.VarKey = ''CostFactorId'') ;'
    EXEC sys.sp_executesql @_SqlInsertAgg;
    SELECT @_Step = N' Bước 5: Cập nhật xong Lưới 2(#tblTmp2) Dữ liệu Giá vốn phân rã theo Yếu tố chi phí.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @DebugStepTime OUTPUT;
    DECLARE @_CalSum VARCHAR(MAX) =
            (
                SELECT STRING_AGG(ColName, ',')FROM #ColList
            );
    EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp'
                               , @_FieldList = @_CalSum
                               , @_FieldKey = 'ItemNo'
                               , @_FieldCal = 'Formula'
                               , @_FieldBac = 'ItemLevel'
                               , @_FieldIn_Ck = 'IsPrint'
                               , @_ResetFormula = 1; --
    EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp2'
                               , @_FieldList = @_CalSum
                               , @_FieldKey = 'ItemNo'
                               , @_FieldCal = 'Formula'
                               , @_FieldBac = 'ItemLevel'
                               , @_FieldIn_Ck = 'IsPrint'
                               , @_ResetFormula = 1; --
    EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp3'
                               , @_FieldList = @_CalSum
                               , @_FieldKey = 'ItemNo'
                               , @_FieldCal = 'Formula'
                               , @_FieldBac = 'ItemLevel'
                               , @_FieldIn_Ck = 'IsPrint'
                               , @_ResetFormula = 1; --
    SELECT *
    FROM #tblTmp
    ORDER BY BuiltinOrder ASC;
    SELECT *
    FROM #tblTmp2
    WHERE IsPrint = 1
    ORDER BY BuiltinOrder ASC; --
    SELECT *
    FROM #tblTmp3
    ORDER BY BuiltinOrder ASC; --
    DECLARE @_LAYOUT_XML2 NVARCHAR(MAX) = REPLACE(@_LAYOUT_XML1, 'Report_0', 'Report_1');
    DECLARE @_LAYOUT_XML3 NVARCHAR(MAX) = REPLACE(@_LAYOUT_XML1, 'Report_0', 'Report_2');
    SET @_LAYOUT_XML
        = N'<panelReporter>' + @_nl + N'   <Controls> ' + @_nl + N' '
          + CONCAT(@_LAYOUT_XML1, @_nl, @_LAYOUT_XML2, @_nl, @_LAYOUT_XML3) + @_nl + N'   </Controls> ' + @_nl
          + N'</panelReporter>' + @_nl;
    SET @_Time2 = GETDATE();
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, @_Time2)));
    -- --- DEBUG LOG ---
    SET @DebugMsg
        = N'[' + CONVERT(VARCHAR, GETDATE(), 114) + N'] Bước 13: Clean & Select Output. Thời gian: '
          + CAST(DATEDIFF(ms, @DebugStepTime, GETDATE()) AS NVARCHAR) + N' ms';
    RAISERROR(@DebugMsg, 10, 1) WITH NOWAIT;
    SET @DebugMsg
        = N'--- TỔNG THỜI GIAN CHẠY SP: ' + CAST(DATEDIFF(ss, @DebugStartTime, GETDATE()) AS VARCHAR) + N' s ---';
    RAISERROR(@DebugMsg, 10, 1) WITH NOWAIT;
    DROP TABLE IF EXISTS #tblTmp
                       , #tblTmp2
                       , #tblTmp3
                       , #ColList;
END;
GO


SET DATEFORMAT DMY
EXEC usp_REP_ConsolidatedRevenueandProfitPlan_HN_Summary_v2 @_DocDate1 = '01/01/2026 00:00:00.000'
                                                          , @_DocDate2 = '31/01/2026 00:00:00.000'
                                                          , @_Account = '511'
                                                          , @_ExcludeCrspAccount = '911'
                                                          , @_BranchCode = 'I00'
                                                          , @_nUserId = 1213
                                                          , @_LangId = 0
                                                          , @_CurrencyCode0 = 'VND'
                                                          , @_IsRound = 0
                                                          , @_RepId1 = 'T000000015'
                                                          , @_RepId2 = 'T000000013'
                                                          , @_RepId3 = 'T000000017'
                                                          , @_StrTime = '00:00:04'