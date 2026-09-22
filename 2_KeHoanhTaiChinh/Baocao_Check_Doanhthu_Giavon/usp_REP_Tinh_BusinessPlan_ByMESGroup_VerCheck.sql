SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--22-06-2026
--ver check

ALTER PROCEDURE dbo.usp_REP_Tinh_BusinessPlan_ByMESGroup_VerCheck
    @_DocDate1 DATE = '20260101'
  , @_DocDate2 DATE = '20260131'
  , @_DocDatePlan2 DATE = ''
  , @_ProductId VARCHAR(24) = ''
  , @_BranchCode NVARCHAR(24) = 'I09'
  , @_Account NVARCHAR(2000) = '511,521,632'
  , @_ExcludeCrspAccount VARCHAR(254) = '911'
  , @_nUserId INT = 0
  , @_LangId INT = 0
  , @_CurrencyCode0 CHAR(3) = 'VND'
  , @_LAYOUT_XML NVARCHAR(MAX) = '' OUTPUT
  , @_IsRound INT = 0
  , @_DefinitionTableName NVARCHAR(32) = N'B10BusinessPlanDetail'
  , @_tblTmp NVARCHAR(32) = ''
  , @_RepId1 VARCHAR(16) = 'I000000007'
  , @_BranchReportId INT = NULL
  , @_StrTime NVARCHAR(128) = NULL OUTPUT
  , @_IsGetPlan INT = 0
  , @_Message NVARCHAR(MAX) = '' OUTPUT
  , @_M_BranchFollowRevenueByBizdoc NVARCHAR(128) = 'I24'
  , @_Is_Diff_Branch INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    -- ======================================================== -- 1. KHỞI TẠO BIẾN VÀ BẢNG TẠM CƠ SỞ -- ========================================================
    DECLARE @_Time1 AS DATETIME = GETDATE()
          , @_Time2 AS DATETIME;
    SELECT @_DocDatePlan2 = IIF(@_DocDatePlan2 = '', @_DocDate2, @_DocDatePlan2);
    DECLARE @_Num_Round AS INT = CASE
                                     WHEN @_IsRound = 1 THEN
                                         1000000
                                     ELSE
                                         1
                                 END;
    DECLARE @_nl   AS CHAR(1)      = CHAR(13)
          , @_Key2 AS VARCHAR(MAX) = '';
    DECLARE @DebugStepTime AS DATETIME      = GETDATE()
          , @_Step         AS NVARCHAR(2000)
          , @_DebugMsg     AS NVARCHAR(256) = N'';
    DECLARE @_MoneyType   AS dbo.MoneyType = 0
          , @_TINYINTType AS TINYINT       = 0
          , @_INTType     AS INT           = 0
          , @_CodeType    AS VARCHAR(24)   = ''
          , @_BizDocId    AS VARCHAR(16)   = ''
          , @_NameType    AS NVARCHAR(256) = N'';
    DECLARE @_Key AS VARCHAR(MAX) = 'Stt = ''' + @_RepId1 + ''' ';
    DECLARE @_Key_Acc AS VARCHAR(MAX) = '';
    IF @_Account <> ''
        SET @_Key_Acc = N'((Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + '%''))';
    IF @_ExcludeCrspAccount <> ''
        SET @_Key_Acc += ' AND ((CrspAccount NOT LIKE ''' + REPLACE(@_ExcludeCrspAccount, ',', '%''') + '%''))';
    SELECT @_Step = N' Start: Khởi tạo dữ liệu cơ bản & GenKey xong.';
    EXECUTE dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                     , @_DebugStepTime = @DebugStepTime OUTPUT;
    DROP TABLE IF EXISTS #ColList;
    SELECT TOP (0)
           Tt
         , M_DocDate1
         , M_DocDate2
         , Y_DocDate
         , ColName
         , UserData0
         , Row_0_VN
         , Row_0_EN
         , UserData1
         , Row_1_VN
         , Row_1_EN
         , _TextAlign
         , _Width
         , _Format
         , _ForeColor
         , _BackColor
         , Type
         , BuiltinOrder1
    INTO #ColList
    FROM dbo.B00ColList;
    INSERT INTO #ColList
    EXECUTE dbo.usp_GenerateReportHeader_ActualPlan_Final @_DocDate1 = @_DocDate1
                                                        , @_DocDate2 = @_DocDate2
                                                        , @_DocDatePlan2 = @_DocDatePlan2
                                                        , @_LAYOUT_XML = @_LAYOUT_XML OUTPUT;
    -- VũLA sửa riêng cho THACO -- Xử lý dữ liệu đơn vị cơ sở và năm làm việc
    DECLARE @_BranchList TABLE
    (
        BranchCode VARCHAR(3)
      , DataCode_Branch VARCHAR(8)
      , _Scan INT
            DEFAULT 0
    );
    IF ISNULL(@_BranchReportId, 0) <> 0
    BEGIN
        DROP TABLE IF EXISTS #BranchCode0;
        SELECT a.BranchCode0
        INTO #BranchCode0
        FROM dbo.B20BranchReportDetail     AS a
            INNER JOIN dbo.B20BranchReport AS b
                ON a.BranchReportId = b.Id
        WHERE b.Id = @_BranchReportId;
        DECLARE @_BranchCode0 AS VARCHAR(3) = '';
        WHILE EXISTS (SELECT * FROM #BranchCode0)
        BEGIN
            SELECT TOP 1
                   @_BranchCode0 = BranchCode0
            FROM #BranchCode0;
            DELETE #BranchCode0
            WHERE BranchCode0 = @_BranchCode0;
            INSERT INTO @_BranchList
            (
                BranchCode
              , DataCode_Branch
            )
            SELECT BranchCode
                 , DataCode
            FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode0);
        END;
        DROP TABLE IF EXISTS #BranchCode0;
    END;
    ELSE
    BEGIN
        INSERT INTO @_BranchList
        (
            BranchCode
          , DataCode_Branch
        )
        SELECT BranchCode
             , DataCode
        FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode);
    END;



    DROP TABLE IF EXISTS #CtTmpGeneralLedger;
    SELECT TOP (0)
           CAST(-1 AS INT)           AS Id
         , BranchCode
         , DocDate
         , DocCode
         , CAST('' AS NVARCHAR(24))  AS Col_DocDate
         , CAST('' AS NVARCHAR(24))  AS M_DocDate
         , CAST('' AS NVARCHAR(24))  AS Y_DocDate
         , CAST('' AS NVARCHAR(24))  AS MesGroupCode
         , CustomerId0
         , CustomerId
         , Amount2
         , OriginalAmount2
         , Stt
         , RowId
         , DebitAccount
         , CreditAccount
         , Account
         , CrspAccount
         , Amount
         , OriginalAmount
         , OriginalAmount            AS Co_No
         , OriginalAmount            AS No_Co
         , CAST(NULL AS INT)         AS DocGroup
         , ItemId
         , CAST(NULL AS VARCHAR(24)) AS ItemCode
         , CAST(NULL AS INT)         AS ProductId
         , CAST('' AS NVARCHAR(128)) AS _FormatStyleKey
         , DebitAmount
         , OriginalDebitAmount
         , CreditAmount
         , Quantity
         , CurrencyCode
         , CAST(NULL AS INT)         AS ProductLevelId
         , CAST(NULL AS INT)         AS ProductClassId
         , CAST(NULL AS INT)         AS ProductGroupId
         , CAST(NULL AS INT)         AS ProductLineId
         , @_CodeType                AS Thang
         , @_BizDocId                AS BizDocId_C2
    INTO #CtTmpGeneralLedger
    FROM dbo.B00CtTmp WITH (NOLOCK);


    EXECUTE dbo.usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                           , @_DocDate2 = @_DocDate2
                                           , @_Key1 = @_Key_Acc
                                           , @_Key2 = ''
                                           , @_CtTmp = N'#CtTmpGeneralLedger'
                                           , @_nUserId = @_nUserId
                                           , @_LangId = @_LangId
                                           , @_BranchReportId = @_BranchReportId
                                           , @_BranchCode = @_BranchCode
                                           , @_CurrencyCode0 = @_CurrencyCode0
                                           , @_PrintExec = 0


    UPDATE #CtTmpGeneralLedger
    SET ProductLineId = NULL
      , ProductGroupId = NULL
      , ProductClassId = NULL
      , ProductLevelId = NULL;
    SELECT @_Step = N' Bước 1: Lấy xong dữ liệu Số phát sinh sổ cái (#CtTmpGeneralLedger).';
    EXECUTE dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                     , @_DebugStepTime = @DebugStepTime OUTPUT;
    DROP TABLE IF EXISTS #V_CtTmp0;
    SELECT TOP 0
           Stt
         , RowId
         , ItemId
         , BranchCode
    INTO #V_CtTmp0
    FROM dbo.B00CtTmp;
    DECLARE @_Key1 NVARCHAR(MAX) = N'';
    SELECT @_Key1
        = N'EXISTS (SELECT * FROM #CtTmpGeneralLedger AS kct WHERE kct.Stt = sc.Stt AND kct.RowId = sc.RowId AND ISNULL(kct.ItemId,0) = 0 )';

    IF EXISTS
    (
        SELECT *
        FROM #CtTmpGeneralLedger AS kct
        WHERE ISNULL(kct.ItemId, 0) = 0
    )
    BEGIN
        EXECUTE dbo.usp_B30StockLedger_GetData @_Date1 = @_DocDate1
                                             , @_Date2 = @_DocDate2
                                             , @_Key1 = @_Key1
                                             , @_CtTmp = N'#V_CtTmp0'
                                             , @_nUserId = @_nUserId
                                             , @_LangId = @_LangId
                                             , @_BranchCode = @_BranchCode
                                             , @_BranchReportId = @_BranchReportId
                                             , @_PrintExec = 0



        UPDATE kct
        SET kct.ItemId = vct.ItemId
        FROM #CtTmpGeneralLedger AS kct
            INNER JOIN #V_CtTmp0 AS vct
                ON kct.BranchCode = vct.BranchCode
                   AND vct.Stt = kct.Stt
                   AND vct.RowId = kct.RowId
        WHERE ISNULL(kct.ItemId, 0) = 0;
    END;


    DELETE #CtTmpGeneralLedger
    WHERE Amount = 0;
    UPDATE #CtTmpGeneralLedger
    SET Amount = IIF(DocGroup = 1, -Amount, Amount)
      , OriginalAmount = IIF(DocGroup = 1, -OriginalAmount, OriginalAmount)
      , Quantity = IIF(DocGroup = 1, -Quantity, Quantity);

    UPDATE #CtTmpGeneralLedger
    SET Co_No = CreditAmount - DebitAmount
      , No_Co = DebitAmount - CreditAmount;

    DELETE #CtTmpGeneralLedger
    WHERE CrspAccount LIKE '911%';

    --SELECT Account,CrspAccount,SUM(DebitAmount),SUM(CreditAmount) FROM #CtTmpGeneralLedger WHERE Account LIKE '511%' GROUP BY Account,CrspAccount RETURN 

    DROP TABLE IF EXISTS #FinPlan;
    SELECT TOP (0)
           DocDate
         , CAST(NULL AS INT)         AS _Year
         , CAST(NULL AS INT)         AS _Month
         , CAST('' AS NVARCHAR(24))  AS Col_DocDate
         , CustomerId
         , ProfitCenterId
         , ItemId
         , CAST(NULL AS TINYINT)     AS ItemType
         , CAST(NULL AS INT)         AS ProductId
         , CAST(0 AS NUMERIC(18, 0)) AS OriginalUnitCost
         , CAST(0 AS NUMERIC(18, 0)) AS Amount
         , CAST(0 AS NUMERIC(18, 0)) AS OriginalAmount
         , BranchCode
         , CAST(NULL AS INT)         AS ProductLevelId
         , CAST(NULL AS INT)         AS ProductClassId
         , CAST(NULL AS INT)         AS ProductGroupId
         , CAST(NULL AS INT)         AS ProductLineId
         , CAST('' AS VARCHAR(24))   AS MESGroupCode
    INTO #FinPlan
    FROM dbo.B00CtTmp;
    EXECUTE dbo.usp_sys_DefaultTable @_Table = '#FinPlan';
    --IF @_IsGetPlan = 1
    --    EXECUTE dbo.usp_FinPlanDetail_GetData @_CtTmp = '#FinPlan'
    --                                         ,@_BranchCode = @_BranchCode
    --                                         ,@_PrintExec = 0;
    UPDATE #FinPlan
    SET ProductLineId = NULL
      , ProductGroupId = NULL
      , ProductClassId = NULL
      , ProductLevelId = NULL;
    UPDATE #CtTmpGeneralLedger
    SET M_DocDate = MONTH(DocDate)
      , Y_DocDate = YEAR(DocDate);
    UPDATE GE
    SET GE.Thang = cl.ColName
    FROM #CtTmpGeneralLedger AS GE
        INNER JOIN #ColList  AS cl
            ON GE.M_DocDate = cl.Tt
               AND GE.Y_DocDate = cl.Y_DocDate
               AND cl.Type = '0';
    UPDATE ctgl
    SET ctgl.MesGroupCode = cus.MesGroupCode
    FROM #CtTmpGeneralLedger       AS ctgl
        INNER JOIN dbo.B20Customer AS cus (NOLOCK)
            ON ctgl.CustomerId0 = cus.Id;
    DECLARE @_BranchCode_Filter VARCHAR(4) = '';
    DECLARE @_DataCode_Filter VARCHAR(4) = '';
    DECLARE @_StrExec NVARCHAR(MAX) = N'';
    -- ========================================================    
    -- 4.1 Bổ sung thêm đoạn update riêng cho các đơn vị theo dõi doanh thu theo Hợp đồng (I24)
    -- ========================================================	
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#CtTmpGeneralLedger'
                                           , @_List_Cats = 'Item'
                                           , @_SetString_Other = ',kq.ProductLevelId = Item.ProductLevelId';
    DECLARE @_Declare NVARCHAR(MAX) = N'@_DocDate1 DATE,@_DocDate2 DATE';
    WHILE EXISTS (SELECT TOP 1 * FROM @_BranchList WHERE _Scan = 0)
    BEGIN
        SELECT TOP 1
               @_BranchCode_Filter = BranchCode
             , @_DataCode_Filter   = DataCode_Branch
        FROM @_BranchList
        WHERE _Scan = 0
        ORDER BY BranchCode;
        UPDATE @_BranchList
        SET _Scan = 1
        WHERE BranchCode = @_BranchCode_Filter;
        IF CHARINDEX(CONCAT(',', @_BranchCode_Filter, ','), CONCAT(',', @_M_BranchFollowRevenueByBizdoc, ',')) >= 1
           AND ISNULL(@_BranchCode_Filter, '') <> ''
        BEGIN
            SELECT @_StrExec
                = N'UPDATE kq
SET kq.ProductGroupId = biz.ProductGroupId
FROM #CtTmpGeneralLedger kq INNER JOIN dbo.B3' + @_DataCode_Filter
                  + N'BizDocSO AS biz ON kq.BizDocId_C2 = biz.BizDocId';
            EXEC (@_StrExec);
        END;
        BEGIN
            SELECT @_StrExec
                = N'IF EXISTS
        (
            SELECT *
            FROM dbo.B3' + @_DataCode_Filter
                  + N'AccDocSales1
            WHERE ProductGroupId IS NOT NULL
                  AND DocDate
                  BETWEEN @_DocDate1 AND @_DocDate2
        )
            UPDATE kq
            SET kq.ProductGroupId = IIF(ISNULL(kq.ProductGroupId, 0) = 0, DocSales1.ProductGroupId, kq.ProductGroupId)
            FROM #CtTmpGeneralLedger AS kq
                 INNER JOIN dbo.B3' + @_DataCode_Filter
                  + N'AccDocSales1 AS DocSales1 ON kq.Stt = DocSales1.Stt
                                                                   AND kq.RowId = DocSales1.RowId
                                                                   AND DocSales1.DocDate
                                                                   BETWEEN @_DocDate1 AND @_DocDate2
                                                                   AND DocSales1.ProductGroupId IS NOT NULL
            WHERE ISNULL(kq.ProductGroupId, 0) = 0';
            SET @_Declare = N'@_DocDate1 DATE,@_DocDate2 DATE';
            EXECUTE sys.sp_executesql @_StrExec, @_Declare, @_DocDate1, @_DocDate2;
            SELECT @_StrExec
                = N'
      IF EXISTS
        (
            SELECT *
            FROM dbo.B3' + @_DataCode_Filter
                  + N'AccDocJournalEntry
            WHERE ProductGroupId IS NOT NULL
                  AND DocDate
                  BETWEEN @_DocDate1 AND @_DocDate2
        )
            UPDATE kq
            SET kq.ProductGroupId = IIF(ISNULL(kq.ProductGroupId, 0) = 0, DocSales1.ProductGroupId, kq.ProductGroupId)
            FROM #CtTmpGeneralLedger AS kq
                 INNER JOIN dbo.B3' + @_DataCode_Filter
                  + N'AccDocJournalEntry AS DocSales1 ON kq.Stt = DocSales1.Stt
                                                                         AND DocSales1.ProductGroupId IS NOT NULL
                                                                         AND kq.RowId = DocSales1.RowId
            WHERE ISNULL(kq.ProductGroupId, 0) = 0  ';
            EXECUTE sys.sp_executesql @_StrExec, @_Declare, @_DocDate1, @_DocDate2;
            UPDATE kq
            SET kq.ProductLevelId = ProductClass.ProductLevelId
            FROM #CtTmpGeneralLedger           AS kq
                INNER JOIN dbo.B20ProductGroup AS ProductGroup WITH (NOLOCK)
                    ON kq.ProductGroupId = ProductGroup.Id
                INNER JOIN dbo.B20ProductClass AS ProductClass WITH (NOLOCK)
                    ON ProductGroup.ProductClassId = ProductClass.Id
            WHERE ISNULL(kq.ProductLevelId, 0) = 0;
        END;
    END;

    SELECT @_Step = N' Bước 4. Xong Update các trường Code,Name theo danh mục cho bảng #CtTmpGeneralLedger';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @DebugStepTime OUTPUT;
    DROP TABLE IF EXISTS #tblTmp1Grid2;
    CREATE TABLE #tblTmp1Grid2
    (
        Id INT
            DEFAULT 0
      , Key_Where VARCHAR(4000)
            DEFAULT ''
      , VarValue VARCHAR(64)
            DEFAULT ''
      , VarKey VARCHAR(24)
            DEFAULT ''
      , BuiltinOrder INT
      , IsPrint INT
    );
    EXECUTE dbo.usp_sys_CreateTable @_Table = '#tblTmp1Grid2'
                                  , @_BaseTable = @_DefinitionTableName;
    SELECT @_Key = 'Stt = ''' + @_RepId1 + ''' ';
    EXECUTE dbo.usp_sys_Append @_TableSource = @_DefinitionTableName
                             , @_TableDestination = '#tblTmp1Grid2 '
                             , @_Where_TableSource = @_Key; -- Thêm các cột động vào khung báo cáo
    DECLARE @_AlterCols AS NVARCHAR(MAX) = N'';
    DECLARE @_AlterColsOriginal AS NVARCHAR(MAX) = N'';
    SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL', ', ')
    FROM #ColList;
    DECLARE @_SqlAlterHeaders AS NVARCHAR(MAX) = N'ALTER TABLE #tblTmp1Grid2 ADD ' + @_AlterCols + N';';
    EXECUTE sys.sp_executesql @_SqlAlterHeaders;
    UPDATE #CtTmpGeneralLedger
    SET CustomerId = CustomerId0;
    UPDATE #CtTmpGeneralLedger
    SET Col_DocDate = FORMAT(DocDate, 'yyyyMM')
      , M_DocDate = MONTH(DocDate)
      , Y_DocDate = YEAR(DocDate)
      , Amount2 = ISNULL(Amount2, 0)
      , OriginalAmount2 = ISNULL(OriginalAmount2, 0);
    UPDATE #CtTmpGeneralLedger
    SET Amount2 = ISNULL(Amount, 0)
      , OriginalAmount2 = ISNULL(OriginalAmount, 0);
    SET @_LAYOUT_XML
        = N'<panelReporter>' + @_nl + N'   <Controls> ' + @_nl + N' ' + CONCAT(@_LAYOUT_XML, @_nl, '') + @_nl
          + N'   </Controls> ' + @_nl + N'</panelReporter>' + @_nl;
    DROP TABLE IF EXISTS #kq_MesGroup;
    SELECT TOP (0)
           BranchCode
    INTO #kq_MesGroup
    FROM #CtTmpGeneralLedger;
    DECLARE @query AS NVARCHAR(MAX) = N'SELECT * FROM #CtTmpGeneralLedger where isnull(MesGroupCode,'''') <>'''' ';
    DECLARE @_jsonData AS NVARCHAR(MAX) =
            (
                SELECT * FROM #ColList AS cl FOR JSON AUTO
            );
    DECLARE @_ColName_Total AS NVARCHAR(128) =
            (
                SELECT TOP (1) ColName FROM #ColList WHERE Tt = 0 ORDER BY Tt ASC
            );
    DECLARE @query_tmp NVARCHAR(MAX) = @query + N' AND Account LIKE ''511%'' AND CrspAccount NOT LIKE ''911%'' ';
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'Co_No'
                                , @bang = '#kq_MesGroup'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0;


    DROP TABLE IF EXISTS #kq_ProductLevel;
    SELECT TOP (0)
           BranchCode
    INTO #kq_ProductLevel
    FROM #CtTmpGeneralLedger;
    SELECT @query_tmp
        = @query + N'  AND ISNULL(ProductLevelId,0) <>0 AND Account LIKE ''511%'' AND CrspAccount NOT LIKE ''911%''  ';
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'Co_No'
                                , @bang = '#kq_ProductLevel'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0;


    DECLARE @_SqlSetStr AS NVARCHAR(MAX);
    SELECT @_SqlSetStr = STRING_AGG(QUOTENAME(ColName) + ' = ISNULL(b.' + QUOTENAME(ColName) + ', 0)', ', ')
    FROM #ColList;
    DROP TABLE IF EXISTS #tblTmp1Grid2_Result;
    SELECT TOP 0
           G2.*
         , S.BranchCode
         , @_NameType AS BranchInfo
         , @_NameType AS OtherKey2
    INTO #tblTmp1Grid2_Result
    FROM #tblTmp1Grid2           AS G2
        OUTER APPLY @_BranchList AS S;
    UPDATE @_BranchList
    SET _Scan = 0;
    WHILE EXISTS (SELECT * FROM @_BranchList WHERE _Scan = 0)
    BEGIN
        SELECT TOP 1
               @_BranchCode_Filter = BranchCode
        FROM @_BranchList
        WHERE _Scan = 0;
        INSERT INTO #tblTmp1Grid2_Result
        SELECT *
             , @_BranchCode_Filter
             , @_NameType
             , @_NameType
        FROM #tblTmp1Grid2;
        UPDATE @_BranchList
        SET _Scan = 1
        WHERE BranchCode = @_BranchCode_Filter;
    END;
    UPDATE #tblTmp1Grid2_Result
    SET BranchInfo = CONCAT(re.BranchCode, ' - ', br.BranchName)
    FROM #tblTmp1Grid2_Result    AS re
        INNER JOIN dbo.B00Branch AS br
            ON re.BranchCode = br.BranchCode;
    BEGIN
        DECLARE @_Key_ZDetail NVARCHAR(MAX) = N'';
        DROP TABLE IF EXISTS #ZDetail;
        SELECT TOP (0)
               BranchCode
             , DocDate
             , ProductId
             , CostFactorId
             , ExpenseAccount
             , ZAmount
             , ZAmount2
             , @_MoneyType              AS Amount
             , CAST('' AS VARCHAR(24))  AS Type
             , CAST('' AS VARCHAR(24))  AS Thang
             , CAST('' AS NVARCHAR(24)) AS Col_DocDate
             , CAST('' AS NVARCHAR(24)) AS M_DocDate
             , CAST('' AS NVARCHAR(24)) AS Y_DocDate
        INTO #ZDetail
        FROM dbo.B30ZQTCostFactorStage;
        SET @_Key_ZDetail
            = N'   DocDate BETWEEN ''' + FORMAT(@_DocDate1, 'yyyyMMdd') + N''' AND ''' + FORMAT(@_DocDate2, 'yyyyMMdd')
              + N'''';
        EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                                 , @_DocDate2 = @_DocDate2
                                                 , @_Key = @_Key_ZDetail
                                                 , @_CtTmp = '#ZDetail'
                                                 , @_BranchCode = @_BranchCode
                                                 , @_BizDocName = 'vB30ZQTCostFactorStage_GetData'
                                                 , @_PrintExec = 0
                                                 , @_BranchReportId = @_BranchReportId;

        --TTiền phân rã = ZAmount + ZAmount2;
        UPDATE #ZDetail
        SET Amount = ZAmount + ZAmount2;

        IF EXISTS (SELECT * FROM @_BranchList WHERE BranchCode IN ( 'I01', 'I24' ))
        BEGIN

            DROP TABLE IF EXISTS #ZProjectDocDetail
            SELECT TOP (0)
                   BranchCode
                 , DocDate
                 , CostFactorId
                 , Account632
                 , @_MoneyType              AS Amount
                 , CAST('' AS VARCHAR(24))  AS Type
                 , CAST('' AS VARCHAR(24))  AS Thang
                 , CAST('' AS NVARCHAR(24)) AS Col_DocDate
                 , CAST('' AS NVARCHAR(24)) AS M_DocDate
                 , CAST('' AS NVARCHAR(24)) AS Y_DocDate
            INTO #ZProjectDocDetail
            FROM dbo.vB30ZProjectDocDetail_GetData

            SET @_Key_ZDetail
                = N'   DocDate BETWEEN ''' + FORMAT(@_DocDate1, 'yyyyMMdd') + N''' AND '''
                  + FORMAT(@_DocDate2, 'yyyyMMdd') + N''''

            EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                                     , @_DocDate2 = @_DocDate2
                                                     , @_Key = @_Key_ZDetail
                                                     , @_CtTmp = '#ZProjectDocDetail'
                                                     , @_BranchCode = @_BranchCode
                                                     , @_BizDocName = 'vB30ZProjectDocDetail_GetData'
                                                     , @_PrintExec = 0
                                                     , @_BranchReportId = @_BranchReportId
            --20260908=> bổ sung thêm dữ liệu (Số thực hiện) Dữ liệu kết chuyển 632 => dùng cho các đơn vị Xây dựng
            EXEC dbo.usp_sys_Append @_TableSource = '#ZProjectDocDetail' -- nvarchar(128)
                                  , @_TableDestination = '#ZDetail'      -- nvarchar(128)

        END

        UPDATE #ZDetail
        SET Type = 'ACTUAL'
          , Col_DocDate = DocDate
          , M_DocDate = MONTH(DocDate)
          , Y_DocDate = YEAR(DocDate)

        UPDATE #ZDetail
        SET Thang = cl.ColName
        FROM #ZDetail           AS ge
            INNER JOIN #ColList AS cl
                ON ge.M_DocDate = cl.Tt
                   AND ge.Y_DocDate = cl.Y_DocDate
                   AND cl.Type = '0';

         

        DROP TABLE IF EXISTS #Kq_ZDetail;
        SELECT TOP (0)
               BranchCode
        INTO #Kq_ZDetail
        FROM #ZDetail;
        SELECT @query_tmp = N' SELECT * FROM #ZDetail';
        EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                    , @on_cols_ColList = 'ColName'
                                    , @_ColName_Total = @_ColName_Total
                                    , @query = @query_tmp
                                    , @on_rows = 'BranchCode'
                                    , @on_cols = 'Thang'
                                    , @agg_func = 'SUM'
                                    , @agg_col = 'Amount'
                                    , @bang = '#Kq_ZDetail'
                                    , @_jsonData = @_jsonData
                                    , @_DocDate2 = @_DocDate2
                                    , @_PrintExec = 0

      

        BEGIN
            DROP TABLE IF EXISTS #kq_GV;
            SELECT TOP (0)
                   BranchCode
            INTO #kq_GV
            FROM #CtTmpGeneralLedger;
            SELECT @query_tmp
                = '  SELECT * FROM #CtTmpGeneralLedger WHERE     Account LIKE ''632%'' AND CrspAccount NOT LIKE ''911%''   '
            EXECUTE dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                           , @on_cols_ColList = 'ColName'
                                           , @_ColName_Total = @_ColName_Total
                                           , @query = @query_tmp
                                           , @on_rows = 'BranchCode'
                                           , @on_cols = 'Thang'
                                           , @agg_func = 'SUM'
                                           , @agg_col = 'No_Co'
                                           , @bang = '#kq_GV'
                                           , @_jsonData = @_jsonData
                                           , @_DocDate2 = @_DocDate2
                                           , @_PrintExec = 0;
        END;
        BEGIN
            DECLARE @_SqlUpdateAgg AS NVARCHAR(MAX)
                = N' UPDATE a SET ' + @_SqlSetStr
                  + N' FROM #tblTmp1Grid2_Result a INNER JOIN #kq_MesGroup b ON a.BranchCode = b.BranchCode     WHERE VarKey=''MESGroupCode'' AND ExpenditureType=''DT'' ';
            EXECUTE sys.sp_executesql @_SqlUpdateAgg;
            SELECT @_SqlUpdateAgg
                = N' UPDATE a SET ' + @_SqlSetStr
                  + N' FROM #tblTmp1Grid2_Result a INNER JOIN #kq_ProductLevel b ON a.BranchCode = b.BranchCode     WHERE VarKey=''ProductLevelId''  AND ExpenditureType=''DT'' ';
            EXECUTE sys.sp_executesql @_SqlUpdateAgg;
            --gv phan ra
            SELECT @_SqlUpdateAgg
                = N' UPDATE a SET ' + @_SqlSetStr
                  + N' FROM #tblTmp1Grid2_Result a INNER JOIN #Kq_ZDetail b ON a.BranchCode = b.BranchCode     WHERE  ExpenditureType=''GVPR'' ';
            EXECUTE sys.sp_executesql @_SqlUpdateAgg;
            --gv P-L
            SELECT @_SqlUpdateAgg
                = N' UPDATE a SET ' + @_SqlSetStr
                  + N' FROM #tblTmp1Grid2_Result a INNER JOIN #kq_GV b ON a.BranchCode = b.BranchCode    WHERE  ExpenditureType=''GV'' ';
            EXECUTE sys.sp_executesql @_SqlUpdateAgg;





            DECLARE @_SqlSelectStr NVARCHAR(MAX) = N'';
            SELECT @_SqlSelectStr
                = STRING_AGG(
                                '   ISNULL(tb1.' + QUOTENAME(ColName) + ', 0) - ISNULL(tb2.' + QUOTENAME(ColName)
                                + ', 0)  as ' + QUOTENAME(ColName)
                              , ', '
                            )
            FROM #ColList;
            DECLARE @_SqlSetStrSummary NVARCHAR(MAX);
            SELECT @_SqlSetStrSummary
                = STRING_AGG(QUOTENAME('' + ColName) + ' =   ISNULL(Summa.' + QUOTENAME(ColName) + ', 0)   ', ', ')
            FROM #ColList;
            SELECT @_SqlUpdateAgg
                = N' ;WITH CTE_MESGroup AS (SELECT * FROM #tblTmp1Grid2_Result WHERE   VarKey=''MESGroupCode''  )
				, CTE_ProductLevel AS (SELECT * FROM #tblTmp1Grid2_Result WHERE   VarKey=''ProductLevelId''  )
				, CTE_Summary AS  (SELECT  tb1.BranchCode,' + @_SqlSelectStr
                  + N' FROM CTE_MESGroup tb1 INNER JOIN CTE_ProductLevel  tb2
				ON tb1.BranchCode  =  tb2.BranchCode  )
				UPDATE re SET ' + @_SqlSetStrSummary
                  + N'
					FROM #tblTmp1Grid2_Result re INNER JOIN CTE_Summary Summa on re.BranchCode = Summa.BranchCode WHERE     ExpenditureType=''CLDT'' ';
            EXEC (@_SqlUpdateAgg);
            SELECT @_SqlUpdateAgg
                = N'UPDATE #tblTmp1Grid2_Result SET _FormatStyleKey = ''RedColor'' WHERE ISNULL(' + @_ColName_Total
                  + N',0) <> 0 AND ISNULL(VarKey,'''') = '''' ';
            EXEC (@_SqlUpdateAgg);
            SELECT @_SqlUpdateAgg
                = N' ;WITH GV AS (SELECT * FROM #tblTmp1Grid2_Result WHERE  ExpenditureType=''GV'' )
				, GVPR AS (SELECT * FROM #tblTmp1Grid2_Result WHERE   ExpenditureType=''GVPR''  )
				, CTE_Summary AS  (SELECT  tb1.BranchCode,' + @_SqlSelectStr
                  + N' FROM GV tb1 INNER JOIN GVPR  tb2 
				ON tb1.BranchCode  =  tb2.BranchCode  )
				UPDATE re SET ' + @_SqlSetStrSummary
                  + N'
					FROM #tblTmp1Grid2_Result re INNER JOIN CTE_Summary Summa on re.BranchCode = Summa.BranchCode WHERE   ExpenditureType=''CLGV'' ';
            EXEC (@_SqlUpdateAgg);
            SELECT @_SqlUpdateAgg
                = N'UPDATE #tblTmp1Grid2_Result SET _FormatStyleKey = ''RedColor'' WHERE ISNULL(' + @_ColName_Total
                  + N',0) <> 0 AND ISNULL(VarKey,'''') = '''' ';
            EXEC (@_SqlUpdateAgg);


            --LN BCTC
            SELECT @_SqlUpdateAgg
                = N' ;WITH CTE_MESGroup AS (SELECT    * FROM #tblTmp1Grid2_Result WHERE ExpenditureType=''DT'' AND   VarKey=''MESGroupCode''  )
				, GV AS (SELECT    * FROM #tblTmp1Grid2_Result WHERE   ExpenditureType=''GV''  )
				, CTE_Summary AS  (SELECT  tb1.BranchCode,' + @_SqlSelectStr
                  + N' FROM CTE_MESGroup tb1 INNER JOIN GV  tb2
				ON tb1.BranchCode  =  tb2.BranchCode  )
				UPDATE re SET ' + @_SqlSetStrSummary
                  + N'
					FROM #tblTmp1Grid2_Result re INNER JOIN CTE_Summary Summa on re.BranchCode = Summa.BranchCode WHERE     ExpenditureType=''LNPL'' ';
            EXEC (@_SqlUpdateAgg);
            PRINT @_SqlUpdateAgg;

            --LN BCTC
            SELECT @_SqlUpdateAgg
                = N' ;WITH CTE_MESGroup AS (SELECT   * FROM #tblTmp1Grid2_Result WHERE  ExpenditureType=''DT'' AND   VarKey=''MESGroupCode''  )
				, GV AS (SELECT   * FROM #tblTmp1Grid2_Result WHERE   ExpenditureType=''GVPR''  )
				, CTE_Summary AS  (SELECT  tb1.BranchCode,' + @_SqlSelectStr
                  + N' FROM CTE_MESGroup tb1 INNER JOIN GV  tb2
				ON tb1.BranchCode  =  tb2.BranchCode  )
				UPDATE re SET ' + @_SqlSetStrSummary
                  + N'
					FROM #tblTmp1Grid2_Result re INNER JOIN CTE_Summary Summa on re.BranchCode = Summa.BranchCode WHERE     ExpenditureType=''LNKHTC'' ';
            EXEC (@_SqlUpdateAgg);

            --CL LN
            SELECT @_SqlUpdateAgg
                = N' ;WITH CTE_MESGroup AS (SELECT   * FROM #tblTmp1Grid2_Result WHERE  ExpenditureType=''LNPL''    )
				, GV AS (SELECT   * FROM #tblTmp1Grid2_Result WHERE   ExpenditureType=''LNKHTC''  )
				, CTE_Summary AS  (SELECT  tb1.BranchCode,' + @_SqlSelectStr
                  + N' FROM CTE_MESGroup tb1 INNER JOIN GV  tb2
				ON tb1.BranchCode  =  tb2.BranchCode  )
				UPDATE re SET ' + @_SqlSetStrSummary
                  + N'
					FROM #tblTmp1Grid2_Result re INNER JOIN CTE_Summary Summa on re.BranchCode = Summa.BranchCode WHERE     ExpenditureType=''CLLN'' ';
            EXEC (@_SqlUpdateAgg);

        END;
    END;
    DECLARE @_BranchLst_Err NVARCHAR(MAX);
    ;WITH cte
    AS (SELECT DISTINCT
               BranchInfo
        FROM #tblTmp1Grid2_Result
        WHERE _FormatStyleKey = 'RedColor')
    SELECT @_BranchLst_Err = STRING_AGG(cte.BranchInfo, NCHAR(13) + NCHAR(10))
    FROM cte;
    IF EXISTS
    (
        SELECT 1
        FROM #tblTmp1Grid2_Result
        WHERE _FormatStyleKey = 'RedColor'
              AND ISNULL(VarKey, '') = ''
    )
    BEGIN
        SELECT @_Message = N'Các đơn vị cần lưu ý xem lại !' + NCHAR(13) + NCHAR(10) + @_BranchLst_Err;
    END;
    UPDATE #tblTmp1Grid2_Result
    SET OtherKey2 = CONCAT('BranchCode = ', '''', BranchCode, '''');
    IF @_Is_Diff_Branch = 1
    BEGIN
        ;WITH cte
         AS (SELECT DISTINCT
                    BranchCode
             FROM #tblTmp1Grid2_Result
             WHERE ISNULL(VarKey, '') = ''
                   AND K_Total_2026 <> 0)
        DELETE #tblTmp1Grid2_Result
        WHERE BranchCode NOT IN
              (
                  SELECT BranchCode FROM cte
              );
    END;
    DECLARE @_CalSum VARCHAR(MAX) = '';
    SELECT @_CalSum = STRING_AGG(ColName, ',')
    FROM #ColList;

    --EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp1Grid2_Result'
    --                              ,@_FieldList = @_CalSum
    --                              ,@_FieldKey = 'ItemNo'
    --                              ,@_FieldCal = 'Formula'
    --                              ,@_FieldBac = 'ItemLevel'
    --                              ,@_FieldIn_Ck = 'IsPrint'
    --                              ,@_ResetFormula = NULL 

    SELECT *
    FROM #tblTmp1Grid2_Result
    WHERE IsPrint = 1
    ORDER BY BranchCode
           , BuiltinOrder;
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, GETDATE())));
    SET @_DebugMsg
        = N'--- TỔNG THỜI GIAN CHẠY SP: ' + CAST(DATEDIFF(ms, @_Time1, GETDATE()) AS VARCHAR) + N' ms ~ '
          + CAST(DATEDIFF(ss, @_Time1, GETDATE()) AS VARCHAR) + N' ss ---';
    DROP TABLE IF EXISTS #ColList
                       , #BranchCode0
                       , #CtTmp
                       , #tblTmp1
                       , #tblTmp1Grid2
                       , #AggregatedData
                       , #AggGrid2;
END;
GO



SET DATEFORMAT DMY
EXEC usp_REP_Tinh_BusinessPlan_ByMESGroup_VerCheck @_DocDate1 = '01/01/2026 00:00:00.000'
                                                 , @_DocDate2 = '31/07/2026 00:00:00.000'
                                                 , @_BranchCode = 'I01'
                                                 , @_nUserId = 1213
                                                 , @_LangId = 0
                                                 , @_CurrencyCode0 = 'VND'
                                                 , @_IsRound = 0
                                                 , @_RepId1 = 'I000000007'
                                                 , @_StrTime = '00:00:00'
                                                 , @_IsGetPlan = 0
                                                 , @_Message = ''
                                                 , @_Is_Diff_Branch = 0