SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Kế hoạch doanh thu - lợi nhuận sản phẩm (I.b)
*/
ALTER   PROCEDURE [dbo].[usp_REP_ConsolidatedRevenueandProfitPlan_HN_Summary_Ib]
    @_DocDate1 DATE = '20260101'
  , @_DocDate2 DATE = '20260131'
  , @_DocDatePlan2 DATE = '20261031'
  , @_Account NVARCHAR(2000) = '511,515,521,632,635,641,642,711,811,821'
  , @_ExcludeCrspAccount VARCHAR(254) = '911'
  , @_BranchCode NVARCHAR(24) = ''
  , @_nUserId INT = 0
  , @_LangId INT = 0
  , @_CurrencyCode0 CHAR(3) = 'VND'
  , @_LAYOUT_XML NVARCHAR(MAX) = '' OUTPUT
  , @_IsRound INT = 0
  , @_BranchReportId INT = NULL
  , @_RepId0 VARCHAR(16) = 'T000000015'
  , @_RepId1 VARCHAR(16) = 'T000000001'
  , @_RepId2 VARCHAR(16) = 'T000000007'
  , @_DefinitionTableName NVARCHAR(32) = N'B10BusinessPlanHNDetail'
  , @_StrTime NVARCHAR(128) = NULL OUTPUT
  , @_ShowFinPlan INT = 0
  , @_MESGroupCode_List VARCHAR(24) = N''
  , @_IsGetPlan INT = 0
  , @_IsGet_DataSMT INT = 0
  , @_BizDocId VARCHAR(16) = ''
  , @_BranchCode1 NVARCHAR(128) = '' -- Nhóm đơn vị cơ sở hợp nhất quản trị
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @_Time1       DATETIME      = GETDATE()
          , @_Time2       DATETIME
          , @_DataCode    NVARCHAR(4)   = N''
          , @_nl          CHAR(1)       = CHAR(13)
          , @_LAYOUT_XML1 NVARCHAR(MAX) = N''
    DECLARE @_Num_Round INT          = IIF(@_IsRound = 1, 1000000, 1)
          , @_KeyHeader VARCHAR(MAX) = N' Stt = ''' + @_RepId0 + N''' '

    DECLARE @_Key NVARCHAR(MAX) = N''

    DECLARE @_MoneyType    AS dbo.MoneyType = 0
          , @_QuantityType dbo.QuantityType = 0
          , @_TINYINTType  TINYINT          = 0
          , @_INTType      INT              = 0
          , @_CodeType     VARCHAR(24)      = ''
          , @_BizDocIdType VARCHAR(16)      = ''
          , @_NameType     NVARCHAR(256)    = N''
          , @_UnitType     NVARCHAR(8)      = N''

    DECLARE @_BranchList TABLE
    (
        BranchCode1 VARCHAR(24)
      , BranchName1 NVARCHAR(256)
      , BranchCode VARCHAR(3)
      , BranchName NVARCHAR(256)
      , DataCode_Branch VARCHAR(8)
      , _Scan INT
            DEFAULT 0
    )

    IF @_BranchCode = 'I00'
       AND @_BranchCode1 = ''
    BEGIN
        ;
        WITH cte
        AS (SELECT DISTINCT
                   c.BranchCode1
            FROM B10THACOID.dbo.B00BrConsolidation AS c
            WHERE c.ParentId = -1)
        SELECT @_BranchCode1 = STRING_AGG(BranchCode1, ',')
        FROM cte
    END;

    IF @_BranchCode = 'I00'
       AND @_BranchCode1 <> ''
    BEGIN
        INSERT INTO @_BranchList
        (
            BranchCode1
          , BranchName1
          , BranchCode
          , BranchName
          , DataCode_Branch
        )
        SELECT DISTINCT
               BranchCode1
             , BranchName1
             , BranchCode
             , BranchName
             , DataCode
        FROM dbo.ufn_B00BrConsolidation_GetChildTable(@_BranchCode1, '')
    END
    ELSE
    BEGIN
        INSERT INTO @_BranchList
        (
            BranchCode1
          , BranchName1
          , BranchCode
          , BranchName
          , DataCode_Branch
        )
        SELECT BranchCode1
             , BranchName1
             , BranchCode
             , BranchName
             , DataCode
        FROM dbo.ufn_B00BrConsolidation_GetChildTable('', @_BranchCode)
    END

    DECLARE @_Ma_DvcsFilter NVARCHAR(24) = N''

    SELECT TOP (1)
           @_DataCode = bb.DataCode
    FROM B10THACOID.dbo.B00Branch AS bb
    WHERE bb.BranchCode = @_BranchCode
    ORDER BY bb.BranchCode ASC

    BEGIN
        DROP TABLE IF EXISTS #tblTmp;
        SELECT TOP (0)
               *
        INTO #tblTmp
        FROM dbo.B10BusinessPlanHNDetail;
        EXECUTE dbo.usp_sys_Append @_DefinitionTableName
                                 , '#tblTmp'
                                 , @_Where_TableSource = @_KeyHeader;
    END


    BEGIN
        SELECT @_KeyHeader = N' Stt = ''' + @_RepId1 + N''' ';
        DROP TABLE IF EXISTS #tblTmp1
        SELECT TOP (0)
               CAST(NULL AS INT)        AS Id
             , IsPrint
             , BuiltinOrder
             , Stt
             , ExpenditureType
             , VarKey
             , VarValue
             , CAST('' AS VARCHAR(MAX)) AS VarValueDetail
             , CAST('' AS VARCHAR(256)) AS ValueCol
             , VarKey_Exclude
             , VarValue_Exclude
             , ItemLevel
             , Description
             , ItemNo
             , Formula
             , _FormatStyleKey
             , _LinkCommand
             , CAST('' AS VARCHAR(256)) AS _FormatStyleArgs
        INTO #tblTmp1
        FROM dbo.B10BusinessPlanHNDetail

        EXECUTE dbo.usp_sys_Append @_TableSource = @_DefinitionTableName
                                 , @_TableDestination = '#tblTmp1'
                                 , @_Where_TableSource = @_KeyHeader
                                 , @_Print_Exec =1 

								 


        UPDATE #tblTmp1
        SET ValueCol = cl.ValueCol
        FROM #tblTmp1                              AS TMP
            LEFT JOIN B10THACOID_Data.dbo.B20Class AS cl
                ON cl.ParentCode = 'ExpenditureType'
                   AND TMP.ExpenditureType = cl.Code;

        ;WITH cte
        AS (SELECT STRING_AGG(sub.ExpenseCatgId, ',') AS ExpenseCatgId_Lst
                 , sub.ParentId
            FROM dbo.B10BusinessPlanHNDetailSub AS sub
            GROUP BY sub.ParentId)
        UPDATE #tblTmp1
        SET VarValueDetail = c.ExpenseCatgId_Lst
        FROM #tblTmp1      AS tt
            INNER JOIN cte AS c
                ON tt.Id = c.ParentId;

        ;WITH cte
        AS (SELECT dbo.ufn_Get_List_CatgDetail_KHTC(ca.value, 'B20ExpenseCatg', 'Id') AS List_CatgDetail
                 , tmp.Id
            FROM #tblTmp1                                   AS tmp
                CROSS APPLY
            (SELECT value FROM STRING_SPLIT(VarValue, ',')) AS ca
            WHERE tmp.VarValue IS NOT NULL
                  AND tmp.ExpenditureType LIKE 'CP%')
            , cte1
        AS (SELECT STRING_AGG(cte.List_CatgDetail, ',') AS List_CatgDetail
                 , cte.Id
            FROM cte
            WHERE cte.List_CatgDetail <> ''
            GROUP BY cte.Id)
        UPDATE tmp2
        SET tmp2.VarValueDetail = IIF(c1.List_CatgDetail <> '', c1.List_CatgDetail, tmp2.VarValue)
        FROM #tblTmp1      AS tmp2
            LEFT JOIN cte1 AS c1
                ON tmp2.Id = c1.Id
        WHERE ISNULL(tmp2.VarValueDetail, '') = ''
              AND ISNULL(tmp2.VarValue, '') <> ''



    END

    BEGIN
        SELECT @_KeyHeader = N' Stt = ''' + @_RepId2 + N''' ';
        SELECT TOP (0)
               CAST(NULL AS INT)        AS Id
             , IsPrint
             , BuiltinOrder
             , Stt
             , ExpenditureType
             , VarKey
             , VarValue
             , CAST('' AS VARCHAR(MAX)) AS VarValueDetail
             , CAST('' AS VARCHAR(256)) AS ValueCol
             , VarKey_Exclude
             , VarValue_Exclude
             , ItemLevel
             , Description
             , ItemNo
             , Formula
             , _FormatStyleKey
             , _LinkCommand
             , CAST('' AS VARCHAR(256)) AS _FormatStyleArgs
        INTO #tblTmp2
        FROM dbo.B10BusinessPlanHNDetail

        EXECUTE dbo.usp_sys_Append @_TableSource = @_DefinitionTableName
                                 , @_TableDestination = '#tblTmp2'
                                 , @_Where_TableSource = @_KeyHeader
                                 , @_Print_Exec = 0;

        UPDATE #tblTmp2
        SET ValueCol = cl.ValueCol
        FROM #tblTmp2                              AS TMP
            LEFT JOIN B10THACOID_Data.dbo.B20Class AS cl
                ON cl.ParentCode = 'ExpenditureType'
                   AND TMP.ExpenditureType = cl.Code;

        ;
        WITH cte
        AS (SELECT STRING_AGG(sub.ExpenseCatgId, ',') AS ExpenseCatgId_Lst
                 , sub.ParentId
            FROM dbo.B10BusinessPlanHNDetailSub AS sub
            GROUP BY sub.ParentId)
        UPDATE #tblTmp2
        SET VarValueDetail = c.ExpenseCatgId_Lst
        FROM #tblTmp2      AS tt
            INNER JOIN cte AS c
                ON tt.Id = c.ParentId;

        ;WITH cte
        AS (SELECT dbo.ufn_Get_List_CatgDetail_KHTC(ca.value, 'B20ExpenseCatg', 'Id') AS List_CatgDetail
                 , tmp.Id
            FROM #tblTmp2                                   AS tmp
                CROSS APPLY
            (SELECT value FROM STRING_SPLIT(VarValue, ',')) AS ca
            WHERE tmp.VarValue IS NOT NULL
                  AND tmp.ExpenditureType LIKE 'CP%')
            , cte1
        AS (SELECT STRING_AGG(cte.List_CatgDetail, ',') AS List_CatgDetail
                 , cte.Id
            FROM cte
            WHERE cte.List_CatgDetail <> ''
            GROUP BY cte.Id)
        UPDATE tmp2
        SET tmp2.VarValueDetail = IIF(c1.List_CatgDetail <> '', c1.List_CatgDetail, tmp2.VarValue)
        FROM #tblTmp2      AS tmp2
            LEFT JOIN cte1 AS c1
                ON tmp2.Id = c1.Id
        WHERE ISNULL(tmp2.VarValueDetail, '') = ''
              AND ISNULL(tmp2.VarValue, '') <> ''

    END


    DROP TABLE IF EXISTS #ColList
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
    FROM dbo.B00ColList
    INSERT INTO #ColList
    EXEC dbo.usp_GenerateReportHeader_ActualPlan_Final @_DocDate1 = @_DocDate1
                                                     , @_DocDate2 = @_DocDate2
                                                     , @_DocDatePlan2 = @_DocDatePlan2
                                                     , @_LAYOUT_XML = @_LAYOUT_XML1 OUTPUT
                                                     , @_IsGetPlan = @_IsGetPlan



    DECLARE @_Key_Acc NVARCHAR(MAX)
        = N'((Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + N'%''))'
    IF @_ExcludeCrspAccount <> ''
        SET @_Key_Acc += N' AND ((CrspAccount NOT LIKE '''
                         + REPLACE(@_ExcludeCrspAccount, ',', '%'') OR (CrspAccount NOT LIKE ''') + N'%''))'

    IF LTRIM(RTRIM(@_MESGroupCode_List)) <> N''
        SET @_Key_Acc += N' AND CustomerId0 IN (SELECT Id FROM dbo.B20Customer WHERE MESGroupCode  IN ('''
                         + REPLACE(REPLACE(@_MESGroupCode_List, N' ', N''), N',', N''',''') + N'''))'

    DROP TABLE IF EXISTS #CtTmpGeneralLedger
    SELECT TOP (0)
           CAST(-1 AS INT)           AS Id
         , BranchCode
         , DocDate
         , DocCode
         , DocNo
         , CAST('' AS NVARCHAR(24))  AS Col_DocDate
         , CAST('' AS NVARCHAR(24))  AS M_DocDate
         , CAST('' AS NVARCHAR(24))  AS Y_DocDate
         , CustomerId0
         , Amount2
         , OriginalAmount2
         , Stt
         , RowId
         , Account
         , Account                   AS AccountCal
         , Account                   AS AccountCal1
         , CrspAccount
         , DebitAccount
         , CreditAccount
         , Amount
         , OriginalAmount
         , ItemId
         , CAST(NULL AS INT)         AS ProductId
         , CAST(NULL AS INT)         AS ProfitCenterId
         , CAST('' AS NVARCHAR(128)) AS _FormatStyleKey
         , DebitAmount
         , OriginalDebitAmount
         , CreditAmount
         , Quantity
         , CurrencyCode
         , CAST('' AS VARCHAR(24))   AS MESGroupCode
         , ExpenseCatgId
         , Description
         , CAST('' AS VARCHAR(24))   AS Type
         , Amount                    AS No_Co
         , Amount                    AS Co_No
         , CAST('' AS VARCHAR(24))   AS Thang

/*
B20ProductLine --Dòng sp
B20ProductGroup --Nhóm sp
B20ProductClass-- Nhóm sp HN2
B20ProductLevel -- Nhóm sp HN1
*/
		 , CAST(NULL AS INT)         AS ProductLevelId
    INTO #CtTmpGeneralLedger
    FROM dbo.B00CtTmp (NOLOCK)

    EXEC dbo.usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                        , @_DocDate2 = @_DocDate2
                                        , @_Key1 = @_Key_Acc
                                        , @_Key2 = ''
                                        , @_CtTmp = N'#CtTmpGeneralLedger'
                                        , @_nUserId = @_nUserId
                                        , @_LangId = @_LangId
                                        , @_BranchCode = @_BranchCode
                                        , @_CurrencyCode0 = @_CurrencyCode0
                                        , @_BranchReportId = @_BranchReportId

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

    IF @_IsGet_DataSMT = 1
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


    UPDATE #CtTmpGeneralLedger
    SET Type = 'ACTUAL'
      , No_Co = DebitAmount - CreditAmount
      , Co_No = CreditAmount - DebitAmount
      , AccountCal = LEFT(Account, 3)
      , AccountCal1 = LEFT(Account, 4)

    UPDATE #CtTmpGeneralLedger
    SET Col_DocDate = DocDate
      , M_DocDate = MONTH(DocDate)
      , Y_DocDate = YEAR(DocDate)

    UPDATE #CtTmpGeneralLedger
    SET Thang = cl.ColName
    FROM #CtTmpGeneralLedger AS ge
        INNER JOIN #ColList  AS cl
            ON ge.M_DocDate = cl.Tt
               AND ge.Y_DocDate = cl.Y_DocDate
               AND cl.Type = '0'

    -- ========================================================    
    -- 4. THU THẬP DỮ LIỆU KẾ HOẠCH (#FinPlan)
    -- ========================================================
    BEGIN
        /*Lấy dữ liệu 511 Kế hoạch */
        DROP TABLE IF EXISTS #FinPlan
        SELECT TOP (0)
               DocDate
             , DocDate               AS DocDate00
             , DocNo
             , CAST(NULL AS INT)     AS _Year
             , CAST(NULL AS INT)     AS _Month
             , CustomerId
             , ItemId
             , ProfitCenterId
             , CAST(NULL AS TINYINT) AS ItemType
             , CAST(NULL AS INT)     AS ProductId
             , @_MoneyType           AS OriginalUnitCost
             , @_MoneyType           AS Amount
             , @_QuantityType        AS Quantity
             , @_MoneyType           AS OriginalAmount
             , BranchCode
             , @_CodeType            AS MESGroupCode --
             , @_CodeType            AS Type
             , @_TINYINTType         AS M_DocDate
             , @_INTType             AS Y_DocDate
             , @_CodeType            AS Thang
             , @_BizDocIdType        AS BizDocId
        INTO #FinPlan
        FROM dbo.vB30FinPlanDetail_GetData

        IF @_IsGetPlan = 1
            EXEC dbo.usp_FinPlanDetail_GetData @_CtTmp = '#FinPlan'
                                             , @_BranchCode = @_BranchCode
                                             , @_PrintExec = 0
                                             , @_BizDocId = @_BizDocId

        UPDATE fi
        SET fi.Type = 'PLAN'
          , fi.M_DocDate = MONTH(fi.DocDate00)
          , fi.Y_DocDate = YEAR(fi.DocDate00)
        FROM #FinPlan AS fi

        UPDATE FI
        SET FI.Thang = cl.ColName
        FROM #FinPlan           AS FI
            INNER JOIN #ColList AS cl
                ON FI.M_DocDate = cl.Tt
                   AND cl.Type = '1'

        DELETE #FinPlan
        WHERE (DocDate00 < @_DocDate1)

        INSERT INTO #CtTmpGeneralLedger
        (
            CustomerId0
          , ItemId
          , Thang
          , Co_No
          , Quantity
          , Account
          , AccountCal
          , BranchCode
          , Type
        )
        SELECT CustomerId
             , ItemId
             , Thang
             , Amount
             , Quantity
             , '511'
             , '511'
             , BranchCode
             , Type
        FROM #FinPlan
        WHERE Thang <> ''

    END

    UPDATE #CtTmpGeneralLedger
    SET Amount2 = Amount2 / @_Num_Round
      , OriginalAmount2 = OriginalAmount2 / @_Num_Round
      , OriginalAmount = OriginalAmount / @_Num_Round
      , DebitAmount = DebitAmount / @_Num_Round
      , OriginalDebitAmount = OriginalDebitAmount / @_Num_Round
      , CreditAmount = CreditAmount / @_Num_Round

    UPDATE c
    SET c.MESGroupCode = cus.MESGroupCode
    FROM #CtTmpGeneralLedger       AS c
        INNER JOIN dbo.B20Customer AS cus (NOLOCK)
            ON c.CustomerId0 = cus.Id

    DECLARE @_Key_Detail NVARCHAR(MAX)
    /*641,642 Kế hoạch*/
    BEGIN
        --641
        DROP TABLE IF EXISTS #PlannedSellExpensesResult
        SELECT TOP 0
               Account
             , Account       AS AccountCal
             , DocDate
             , ExpenseCatgId
             , Amount
             , @_CodeType    AS Type
             , @_TINYINTType AS M_DocDate
             , @_INTType     AS Y_DocDate
             , @_CodeType    AS Thang
             , BranchCode
        INTO #PlannedSellExpensesResult
        FROM B30PlannedSellExpensesResult

        SET @_Key_Detail
            = N'   DocDate BETWEEN ''' + FORMAT(@_DocDate2, 'yyyyMMdd') + N''' AND '''
              + FORMAT(@_DocDatePlan2, 'yyyyMMdd') + N''''

        EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                                 , @_DocDate2 = @_DocDate2
                                                 , @_Key = @_Key_Detail
                                                 , @_CtTmp = '#PlannedSellExpensesResult'
                                                 , @_BranchCode = @_BranchCode
                                                 , @_BizDocName = 'vB30PlannedSellExpensesResult_Getdata'
                                                 , @_PrintExec = 0
                                                 , @_BranchReportId = @_BranchReportId




        --642
        DROP TABLE IF EXISTS #PlannedAdExpensesResult
        SELECT TOP 0
               Account
             , Account       AS AccountCal
             , DocDate
             , ExpenseCatgId
             , Amount
             , @_CodeType    AS Type
             , @_TINYINTType AS M_DocDate
             , @_INTType     AS Y_DocDate
             , @_CodeType    AS Thang
             , BranchCode
        INTO #PlannedAdExpensesResult
        FROM B30PlannedAdExpensesResult

        EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                                 , @_DocDate2 = @_DocDate2
                                                 , @_Key = @_Key_Detail
                                                 , @_CtTmp = '#PlannedAdExpensesResult'
                                                 , @_BranchCode = @_BranchCode
                                                 , @_BizDocName = 'vB30PlannedAdExpensesResult_Getdata'
                                                 , @_PrintExec = 0
                                                 , @_BranchReportId = @_BranchReportId
        UPDATE fi
        SET fi.Type = 'PLAN'
          , fi.M_DocDate = MONTH(fi.DocDate)
          , fi.Y_DocDate = YEAR(fi.DocDate)
          , AccountCal = LEFT(Account, 3)
        FROM #PlannedSellExpensesResult AS fi

        UPDATE FI
        SET FI.Thang = cl.ColName
        FROM #PlannedSellExpensesResult AS FI
            INNER JOIN #ColList         AS cl
                ON FI.M_DocDate = cl.Tt
                   AND cl.Type = '1'

        UPDATE fi
        SET fi.Type = 'PLAN'
          , fi.M_DocDate = MONTH(fi.DocDate)
          , fi.Y_DocDate = YEAR(fi.DocDate)
          , AccountCal = LEFT(Account, 3)
        FROM #PlannedAdExpensesResult AS fi

        UPDATE FI
        SET FI.Thang = cl.ColName
        FROM #PlannedAdExpensesResult AS FI
            INNER JOIN #ColList       AS cl
                ON FI.M_DocDate = cl.Tt
                   AND cl.Type = '1'
    END

    /*635  Kế hoạch*/
    BEGIN
        DROP TABLE IF EXISTS #PlannedFinExpensesResult
        SELECT TOP 0
               Account
             , Account       AS AccountCal
             , DocDate
             , ExpenseCatgId
             , Amount
             , @_CodeType    AS Type
             , @_TINYINTType AS M_DocDate
             , @_INTType     AS Y_DocDate
             , @_CodeType    AS Thang
             , BranchCode
        INTO #PlannedFinExpensesResult
        FROM B30PlannedFinExpensesResult

        EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                                 , @_DocDate2 = @_DocDate2
                                                 , @_Key = @_Key_Detail
                                                 , @_CtTmp = '#PlannedFinExpensesResult'
                                                 , @_BranchCode = @_BranchCode
                                                 , @_BizDocName = 'vB30PlannedFinExpensesResult_Getdata'
                                                 , @_PrintExec = 0

        UPDATE fi
        SET fi.Type = 'PLAN'
          , fi.M_DocDate = MONTH(fi.DocDate)
          , fi.Y_DocDate = YEAR(fi.DocDate)
          , AccountCal = LEFT(Account, 3)
        FROM #PlannedFinExpensesResult AS fi

        UPDATE FI
        SET FI.Thang = cl.ColName
        FROM #PlannedFinExpensesResult AS FI
            INNER JOIN #ColList        AS cl
                ON FI.M_DocDate = cl.Tt
                   AND cl.Type = '1'

    END

    DECLARE @_ColName_Total NVARCHAR(128) =
            (
                SELECT TOP (1) ColName FROM #ColList WHERE Tt = 0 ORDER BY Tt ASC
            )
          , @_AlterCols     NVARCHAR(MAX) = N''

    SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,3) DEFAULT 0', ',')
    FROM #ColList

    DROP TABLE IF EXISTS #T_lst_Tmp
    SELECT value
    INTO #T_lst_Tmp
    FROM STRING_SPLIT('#tblTmp,#tblTmp1,#tblTmp2', ',')


    DECLARE @_SqlAlter NVARCHAR(MAX) = ''
    SELECT @_SqlAlter = @_SqlAlter + N'ALTER TABLE ' + value + ' ADD ' + @_AlterCols + N'  ' + @_nl
    FROM #T_lst_Tmp
    EXEC sys.sp_executesql @_SqlAlter

    DELETE #T_lst_Tmp
    WHERE value = '#tblTmp'

	UPDATE #CtTmpGeneralLedger SET ProductLevelId = item.ProductLevelId
	FROM #CtTmpGeneralLedger gl INNER JOIN dbo.B20Item item ON gl.ItemId = item.Id

    DROP TABLE IF EXISTS #kq_DoanhThu_511
    SELECT TOP (0)
           BranchCode
         , MESGroupCode
         , ProductLevelId
         , AccountCal
    INTO #kq_DoanhThu_511
    FROM #CtTmpGeneralLedger

    DECLARE @query     NVARCHAR(MAX) = N'SELECT * FROM #CtTmpGeneralLedger '
          , @_jsonData NVARCHAR(MAX) =
            (
                SELECT * FROM #ColList AS cl FOR JSON AUTO
            )
    DECLARE @query_tmp NVARCHAR(MAX) = @query + N' WHERE Account LIKE ''511%'' AND CrspAccount NOT LIKE ''911%'' '
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,ProductLevelId,AccountCal'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'Co_No'
                                , @bang = '#kq_DoanhThu_511'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

								 

    DROP TABLE IF EXISTS #kq_DoanhThu_Route;
    SELECT TOP (0)
           RouteCode
    INTO #kq_DoanhThu_Route
    FROM #FinActual;

    DECLARE @_BrowField NVARCHAR(MAX) = N''
          , @_query     NVARCHAR(MAX) = N''
          , @_bang      VARCHAR(256)
          , @_agg_col   VARCHAR(256)
          , @_on_rows   VARCHAR(256);
    SELECT @_query = N'SELECT * FROM #FinActual   ';
    SELECT @_bang    = '#kq_DoanhThu_Route'
         , @_agg_col = 'ISNULL(Amount,0)'
         , @_on_rows = 'RouteCode';

    DECLARE @_query_ColList NVARCHAR(MAX) = N' SELECT  ColName FROM #ColList  ';
    DECLARE @_on_cols_ColList NVARCHAR(MAX) = N'ColName';


    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = @_query_ColList
                                , @on_cols_ColList = @_on_cols_ColList
                                , @_ColName_Total = @_ColName_Total
                                , @query = @_query
                                , @on_rows = @_on_rows
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = @_agg_col
                                , @bang = @_bang
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    DECLARE @_SetColumns NVARCHAR(MAX) = ''

    SELECT @_SetColumns
        = STRING_AGG(CONCAT(QUOTENAME(ColName), ' = ISNULL(b.', QUOTENAME(ColName), ', 0)') + @_nl, ', ')
    FROM #ColList;

    DECLARE @_SqlInsertAgg NVARCHAR(MAX)
        = N'UPDATE a
			SET ' + @_SetColumns
          + N'
			FROM #tblTmp a INNER JOIN #kq_DoanhThu_Route b ON a.VarValue = b.RouteCode and a.VarKey = ''RouteCode'' ;				 				'; -- 
    EXEC sys.sp_executesql @_SqlInsertAgg;

    --20260918 Đổ dữ liệu cho bảng #kq_DoanhThu_511 => thì tổng hợp lại theo các mã danh mục => không sử dụng mã đơn vị nữa
    UPDATE #CtTmpGeneralLedger
    SET BranchCode = ''

    DROP TABLE IF EXISTS #kq_DTTC_515
    SELECT TOP (0)
           BranchCode
         , AccountCal1
         , Account
    INTO #kq_DTTC_515
    FROM #CtTmpGeneralLedger
    SELECT @query_tmp = @query + N' WHERE Account LIKE ''515%'' AND CrspAccount NOT LIKE ''911%'' '
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'AccountCal1,Account'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'Co_No'
                                , @bang = '#kq_DTTC_515'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0



    DROP TABLE IF EXISTS #kq_GiaVon_632
    SELECT TOP (0)
           BranchCode
         , AccountCal
    INTO #kq_GiaVon_632
    FROM #CtTmpGeneralLedger
    SELECT @query_tmp = @query + N' WHERE Account LIKE ''632%'' AND CrspAccount NOT LIKE ''911%'' '
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,AccountCal'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'No_Co'
                                , @bang = '#kq_GiaVon_632'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    DROP TABLE IF EXISTS #kq_CPLaiVay_6351
    SELECT TOP (0)
           BranchCode
         , AccountCal
         , Account
    INTO #kq_CPLaiVay_6351
    FROM #CtTmpGeneralLedger

    SELECT @query_tmp
        = +N'
	SELECT 	BranchCode,Account	,AccountCal,DocDate	,ExpenseCatgId	,No_Co	,Type	,M_DocDate	,Y_DocDate	,Thang FROM #CtTmpGeneralLedger 
	WHERE Account LIKE ''6351%'' AND CrspAccount NOT LIKE ''911%''
	UNION ALL 
	SELECT 
	BranchCode,Account	,AccountCal,DocDate	,ExpenseCatgId	,Amount	,Type	,M_DocDate	,Y_DocDate	,Thang
	FROM #PlannedFinExpensesResult '

    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,AccountCal,Account'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'No_Co'
                                , @bang = '#kq_CPLaiVay_6351'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    --(Lỗ) Chênh lệch tỷ giá
    DROP TABLE IF EXISTS #kq_CPLoCLTG_6352
    SELECT TOP (0)
           BranchCode
         , AccountCal
         , Account
    INTO #kq_CPLoCLTG_6352
    FROM #CtTmpGeneralLedger
    SELECT @query_tmp = @query + N' WHERE Account LIKE ''6352%'' AND CrspAccount NOT LIKE ''911%'' '
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,AccountCal,Account'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'No_Co'
                                , @bang = '#kq_CPLoCLTG_6352'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    DROP TABLE IF EXISTS #kq_CPTCK_6358
    SELECT TOP (0)
           BranchCode
         , AccountCal
         , Account
    INTO #kq_CPTCK_6358
    FROM #CtTmpGeneralLedger
    SELECT @query_tmp = @query + N' WHERE Account LIKE ''6358%'' AND CrspAccount NOT LIKE ''911%'' '
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,AccountCal,Account'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'No_Co'
                                , @bang = '#kq_CPTCK_6358'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    DROP TABLE IF EXISTS #kq_CPBanHang_641
    SELECT TOP (0)
           BranchCode
         , ExpenseCatgId
         , AccountCal
    INTO #kq_CPBanHang_641
    FROM #CtTmpGeneralLedger

    SELECT @query_tmp
        = +N'
	SELECT 	BranchCode,Account	,AccountCal,DocDate	,ExpenseCatgId	,No_Co	,Type	,M_DocDate	,Y_DocDate	,Thang FROM #CtTmpGeneralLedger 
	WHERE Account LIKE ''641%'' AND CrspAccount NOT LIKE ''911%'' 
	UNION ALL 
	SELECT 
	BranchCode,Account	,AccountCal,DocDate	,ExpenseCatgId	,Amount	,Type	,M_DocDate	,Y_DocDate	,Thang
	FROM #PlannedSellExpensesResult '

    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'ExpenseCatgId,AccountCal'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'No_Co'
                                , @bang = '#kq_CPBanHang_641'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    DROP TABLE IF EXISTS #kq_CPQuanLy_642
    SELECT TOP (0)
           BranchCode
         , ExpenseCatgId
         , AccountCal
    INTO #kq_CPQuanLy_642
    FROM #CtTmpGeneralLedger


    SELECT @query_tmp
        = +N'
	SELECT 	BranchCode,Account	,AccountCal,DocDate	,ExpenseCatgId	,No_Co	,Type	,M_DocDate	,Y_DocDate	,Thang FROM #CtTmpGeneralLedger 
	WHERE Account LIKE ''642%'' AND CrspAccount NOT LIKE ''911%'' 
	UNION ALL 
	SELECT 
	BranchCode,Account	,AccountCal,DocDate	,ExpenseCatgId	,Amount	,Type	,M_DocDate	,Y_DocDate	,Thang
	FROM #PlannedAdExpensesResult '


    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,ExpenseCatgId,AccountCal'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'No_Co'
                                , @bang = '#kq_CPQuanLy_642'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    DROP TABLE IF EXISTS #kq_ThuNhapKhac_711
    SELECT TOP (0)
           BranchCode
         , AccountCal
    INTO #kq_ThuNhapKhac_711
    FROM #CtTmpGeneralLedger
    SELECT @query_tmp = @query + N' WHERE Account LIKE ''711%'' AND CrspAccount NOT LIKE ''911%'' '
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,AccountCal'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'Co_No'
                                , @bang = '#kq_ThuNhapKhac_711'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    DROP TABLE IF EXISTS #kq_ChiPhiKhac_811
    SELECT TOP (0)
           BranchCode
         , AccountCal
    INTO #kq_ChiPhiKhac_811
    FROM #CtTmpGeneralLedger
    SELECT @query_tmp = @query + N' WHERE Account LIKE ''811%'' AND CrspAccount NOT LIKE ''911%'' '
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,AccountCal'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'No_Co'
                                , @bang = '#kq_ChiPhiKhac_811'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0

    DROP TABLE IF EXISTS #kq_ChiPhithueTNDN_821
    SELECT TOP (0)
           BranchCode
         , AccountCal
    INTO #kq_ChiPhithueTNDN_821
    FROM #CtTmpGeneralLedger
    SELECT @query_tmp = @query + N' WHERE Account LIKE ''821%'' AND CrspAccount NOT LIKE ''911%'''
    EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                , @on_cols_ColList = 'ColName'
                                , @_ColName_Total = @_ColName_Total
                                , @query = @query_tmp
                                , @on_rows = 'BranchCode,AccountCal'
                                , @on_cols = 'Thang'
                                , @agg_func = 'SUM'
                                , @agg_col = 'No_Co'
                                , @bang = '#kq_ChiPhithueTNDN_821'
                                , @_jsonData = @_jsonData
                                , @_DocDate2 = @_DocDate2
                                , @_PrintExec = 0



    DECLARE @_StringSet NVARCHAR(MAX) = N''
    SELECT @_StringSet = STRING_AGG(@_nl + QUOTENAME(ColName) + ' = ISNULL(b.' + QUOTENAME(ColName) + ', 0)', ', ')
    FROM #ColList

    DECLARE @_FinalSumColumns NVARCHAR(MAX)
    SELECT @_FinalSumColumns
        = STRING_AGG(CONCAT('SUM(ad.', QUOTENAME(ColName), ') AS ', QUOTENAME(ColName)) + @_nl, ', ')
    FROM #ColList

    DECLARE @_SqlUpdate NVARCHAR(MAX) = ''

    SELECT @_SqlUpdate
        = @_SqlUpdate + N'	UPDATE a SET '  + @_StringSet + @_nl + N' FROM ' + value + ' a  CROSS APPLY 
				(SELECT ' + @_FinalSumColumns
          + N' FROM   #kq_DTTC_515 ad 
					WHERE  PATINDEX(CONCAT(''%'',TRIM(STR(ad.AccountCal1)),''%'') ,  CONCAT(''%'',TRIM( (a.VarValue)),''%'')  ) <> 0 )  b 
						WHERE a.ExpenditureType LIKE ''DTTC''  AND a.VarKey = ''Account'' AND a.ValueCol =''515'' '
          + @_nl
    FROM #T_lst_Tmp
    EXEC sys.sp_executesql @_SqlUpdate

    SELECT @_SqlUpdate = ''
    SELECT @_SqlUpdate
        = @_SqlUpdate + N'UPDATE a SET ' + @_StringSet + N' FROM ' + value
          + ' a INNER JOIN #kq_GiaVon_632   b ON  ExpenditureType = ''GV''  
				AND a.VarKey = ''Account'' AND a.ValueCol=b.AccountCal AND ItemLevel=9 ' + @_nl
    FROM #T_lst_Tmp
    EXEC sys.sp_executesql @_SqlUpdate

    SELECT @_SqlUpdate = ''
    SELECT @_SqlUpdate
        = @_SqlUpdate + N'UPDATE a SET ' + @_StringSet + N' FROM ' + value
          + ' a INNER JOIN #kq_CPLaiVay_6351 b ON  ExpenditureType = ''CPTC'' 
				AND a.VarKey = ''Account'' AND a.VarValue = b.Account AND ItemLevel=9' + @_nl
    FROM #T_lst_Tmp
    EXEC sys.sp_executesql @_SqlUpdate

    BEGIN
        SELECT @_SqlUpdate = ''
        SELECT @_SqlUpdate
            = @_SqlUpdate + N'	UPDATE a SET '  + @_StringSet + @_nl + N' FROM ' + value
              + ' a  CROSS APPLY 
			(SELECT '        + @_FinalSumColumns
              + N' FROM   #kq_CPBanHang_641 ad 
				WHERE  PATINDEX(CONCAT(''%'',TRIM(STR(ad.ExpenseCatgId)),''%'') ,  CONCAT(''%'',TRIM( (a.VarValueDetail)),''%'')  ) <> 0 )  b 
					WHERE a.ExpenditureType LIKE ''CPBH''  AND a.VarKey = ''ExpenseCatgId'' AND a.ValueCol =''641''; '
              + @_nl
        FROM #T_lst_Tmp
        EXEC sys.sp_executesql @_SqlUpdate

        SELECT @_SqlUpdate = ''
        SELECT @_SqlUpdate
            = @_SqlUpdate + N'	UPDATE a SET '  + @_StringSet + @_nl + N' FROM ' + value
              + ' a  CROSS APPLY 
			(SELECT '        + @_FinalSumColumns
              + N' FROM   #kq_CPQuanLy_642 ad 
				WHERE ad.ExpenseCatgId IS NOT NULL AND PATINDEX(CONCAT(''%'',TRIM(STR(ad.ExpenseCatgId)),''%'') , CONCAT(''%'',TRIM( (a.VarValueDetail)),''%'' ) ) <> 0 )  b 
					WHERE  a.ExpenditureType LIKE ''CPQL''  AND a.VarKey = ''ExpenseCatgId'' AND a.ValueCol =''642'' AND ItemLevel=9 '
              + @_nl
        FROM #T_lst_Tmp
        EXEC sys.sp_executesql @_SqlUpdate

        SELECT @_SqlUpdate = ''
        SELECT @_SqlUpdate
            = @_SqlUpdate + N'	UPDATE a SET '  + @_StringSet + @_nl + N' FROM ' + value
              + ' a  CROSS APPLY 
			(SELECT '        + @_FinalSumColumns
              + N' FROM   #kq_CPLoCLTG_6352 ad 
				WHERE   PATINDEX(CONCAT(''%'',TRIM(STR(a.VarValue)),''%'') ,  CONCAT(''%'',TRIM( (ad.Account)),''%'')  ) <> 0 )  b 
					WHERE  a.ExpenditureType LIKE ''CPCLTG''    AND a.ValueCol =''6352'' AND ItemLevel=9 ' + @_nl
        FROM #T_lst_Tmp
        EXEC sys.sp_executesql @_SqlUpdate

        SELECT @_SqlUpdate = ''
        SELECT @_SqlUpdate
            = @_SqlUpdate + N'	UPDATE a SET '  + @_StringSet + @_nl + N' FROM ' + value
              + ' a  CROSS APPLY 
			(SELECT '        + @_FinalSumColumns
              + N' FROM   #kq_CPTCK_6358 ad 
				WHERE   PATINDEX(CONCAT(''%'',TRIM(STR(a.VarValue)),''%'') ,  CONCAT(''%'',TRIM( (ad.Account)),''%'')  ) <> 0 )  b 
					WHERE  a.ExpenditureType LIKE ''CPTCK''    AND a.ValueCol =''6358'' AND ItemLevel=9 ' + @_nl
        FROM #T_lst_Tmp
        EXEC sys.sp_executesql @_SqlUpdate

    END

    SELECT @_SqlUpdate = ''
    SELECT @_SqlUpdate
        = @_SqlUpdate + N' UPDATE a SET ' + @_StringSet + N' FROM ' + value
          + ' a INNER JOIN #kq_ThuNhapKhac_711 b ON  ExpenditureType = ''TNK''  AND a.VarKey = ''Account'' 
				AND a.ValueCol=b.AccountCal AND ItemLevel=9 ' + @_nl
    FROM #T_lst_Tmp
    EXEC sys.sp_executesql @_SqlUpdate

    SELECT @_SqlUpdate = ''
    SELECT @_SqlUpdate
        = @_SqlUpdate + N'UPDATE a SET ' + @_StringSet + N' FROM ' + value
          + ' a INNER JOIN #kq_ChiPhiKhac_811  b ON  ExpenditureType = ''CPK''  AND a.VarKey = ''Account'' 
				AND a.ValueCol=b.AccountCal AND ItemLevel=9 ' + @_nl
    FROM #T_lst_Tmp
    EXEC sys.sp_executesql @_SqlUpdate

    SELECT @_SqlUpdate = ''
    SELECT @_SqlUpdate
        = @_SqlUpdate + N'UPDATE a SET ' + @_StringSet + N' FROM ' + value
          + ' a INNER JOIN #kq_ChiPhithueTNDN_821 b ON  ExpenditureType = ''CPTTNDN''  
				AND a.VarKey = ''Account'' AND a.ValueCol=b.AccountCal AND ItemLevel=9 ' + @_nl
    FROM #T_lst_Tmp
    EXEC sys.sp_executesql @_SqlUpdate

    BEGIN
        SELECT @_SetColumns = N''
        SELECT @_SetColumns
            = STRING_AGG(CONCAT(QUOTENAME(ColName), ' = ISNULL(FinalAgg.', QUOTENAME(ColName), ', 0)') + @_nl, ', ')
        FROM #ColList
        SELECT @_FinalSumColumns
            = STRING_AGG(CONCAT('SUM(ad.', QUOTENAME(ColName), ') AS ', QUOTENAME(ColName)) + @_nl, ', ')
        FROM #ColList

        DECLARE @_SqlPreAgg NVARCHAR(MAX) = ''
        SELECT @_SqlPreAgg
            = @_SqlPreAgg + N'  UPDATE TMP SET ' + @_SetColumns + N' FROM ' + value + '  TMP  CROSS APPLY (SELECT '
              + @_FinalSumColumns
              + N' FROM STRING_SPLIT(TMP.VarValue, '','') s
			  INNER JOIN #kq_DoanhThu_511 ad ON ad.ProductLevelId = TRIM(s.value) ) FinalAgg WHERE TMP.VarKey = ''ProductLevelId''   AND ExpenditureType = ''DT''    '
              + @_nl
        FROM #T_lst_Tmp
        EXEC sys.sp_executesql @_SqlPreAgg 

        --Bổ sung thêm đoạn cập nhật cho Lưới 1 => chỉ Lấy theo mã đơn vị
        SELECT @_SqlPreAgg = ''
        SELECT @_SqlPreAgg
            = @_SqlPreAgg + N'  UPDATE TMP SET ' + @_SetColumns + N' FROM   #tblTmp TMP  CROSS APPLY (SELECT '
              + @_FinalSumColumns
              + N' FROM STRING_SPLIT(TMP.VarValue, '','') s
			  INNER JOIN #kq_DoanhThu_511 ad ON ad.BranchCode = TRIM(s.value) ) FinalAgg WHERE TMP.VarKey = ''BranchCode''      '
              + @_nl
        EXEC sys.sp_executesql @_SqlPreAgg


    END

    --bắt đầu lấy dữ liệu Giá vốn phân rã theo sản lượng bán hàng
    BEGIN
        DECLARE @_StrExec     NVARCHAR(MAX) = N''
              , @_Key_ZDetail NVARCHAR(MAX) = N''

        DROP TABLE IF EXISTS #ZDetail
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
             , CAST(NULL AS INT ) AS  ProductLevelId
        INTO #ZDetail
        FROM dbo.B30ZQTCostFactorStage

        SET @_Key_ZDetail
            = N'   DocDate BETWEEN ''' + FORMAT(@_DocDate1, 'yyyyMMdd') + N''' AND ''' + FORMAT(@_DocDate2, 'yyyyMMdd')
              + N''''
        EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                                 , @_DocDate2 = @_DocDate2
                                                 , @_Key = @_Key_ZDetail
                                                 , @_CtTmp = '#ZDetail'
                                                 , @_BranchCode = @_BranchCode
                                                 , @_BizDocName = 'vB30ZQTCostFactorStage_GetData'
                                                 , @_PrintExec = 0
                                                 , @_BranchReportId = @_BranchReportId

		

        UPDATE #ZDetail
        SET Type = 'ACTUAL'
          , Col_DocDate = DocDate
          , M_DocDate = MONTH(DocDate)
          , Y_DocDate = YEAR(DocDate)
          , Amount = ZAmount + ZAmount2

        UPDATE #ZDetail
        SET Thang = cl.ColName
        FROM #ZDetail           AS ge
            INNER JOIN #ColList AS cl
                ON ge.M_DocDate = cl.Tt
                   AND ge.Y_DocDate = cl.Y_DocDate
                   AND cl.Type = '0'
    END



    BEGIN
        -- 2026-08-25 ZProjectDoc	(Số thực hiện) Dữ liệu kết chuyển 632
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



            IF EXISTS (SELECT * FROM @_BranchList)
                EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                                         , @_DocDate2 = @_DocDate2
                                                         , @_Key = @_Key_ZDetail
                                                         , @_CtTmp = '#ZProjectDocDetail'
                                                         , @_BranchCode = @_BranchCode
                                                         , @_BizDocName = 'vB30ZProjectDocDetail_GetData'
                                                         , @_PrintExec = 0
                                                         , @_BranchReportId = @_BranchReportId

            UPDATE #ZProjectDocDetail
            SET Type = 'ACTUAL'
              , Col_DocDate = DocDate
              , M_DocDate = MONTH(DocDate)
              , Y_DocDate = YEAR(DocDate)

            UPDATE #ZProjectDocDetail
            SET Thang = cl.ColName
            FROM #ZProjectDocDetail AS ge
                INNER JOIN #ColList AS cl
                    ON ge.M_DocDate = cl.Tt
                       AND ge.Y_DocDate = cl.Y_DocDate
                       AND cl.Type = '0'
        END
    END

    BEGIN
        DROP TABLE IF EXISTS #PlannedCostResult
        SELECT BranchCode
             , ProductId
             , ItemId
             , DocDate
             , CostFactorId
             , VariableAmount
             , FixedAmount
             , @_MoneyType              AS Amount
             , CAST('' AS VARCHAR(24))  AS Type
             , CAST('' AS VARCHAR(24))  AS Thang
             , CAST('' AS NVARCHAR(24)) AS Col_DocDate
             , CAST('' AS NVARCHAR(24)) AS M_DocDate
             , CAST('' AS NVARCHAR(24)) AS Y_DocDate
        INTO #PlannedCostResult
        FROM dbo.vB30PlannedCostResult_GetData

        SET @_Key_ZDetail
            = N'   DocDate BETWEEN ''' + FORMAT(DATEFROMPARTS(YEAR(@_DocDate2), MONTH(@_DocDate2), 1), 'yyyyMMdd')
              + N''' AND ''' + FORMAT(@_DocDatePlan2, 'yyyyMMdd') + N''''
        IF @_IsGetPlan = 1
            IF @_BranchCode IN ( 'I01', 'I24' )
                EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_Key = @_Key_ZDetail
                                                         , @_CtTmp = '#PlannedCostResult'
                                                         , @_BranchCode = @_BranchCode
                                                         , @_BizDocName = 'vB30PlannedCostResult_GetData_ByProductClass'
                                                         --,@_Extension_View = 'PlannedCostResult_GetData'
                                                         , @_PrintExec = 1
            ELSE
                EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_Key = @_Key_ZDetail
                                                         , @_CtTmp = '#PlannedCostResult'
                                                         , @_BranchCode = @_BranchCode
                                                         , @_BizDocName = 'vB30PlannedCostResult_GetData'
                                                         --,@_Extension_View = 'PlannedCostResult_GetData'
                                                         , @_PrintExec = 1

        UPDATE #PlannedCostResult
        SET Amount = ISNULL(VariableAmount, 0) + ISNULL(FixedAmount, 0)

        UPDATE #PlannedCostResult
        SET Type = 'PLAN'
          , Col_DocDate = DocDate
          , M_DocDate = MONTH(DocDate)
          , Y_DocDate = YEAR(DocDate)

        UPDATE #PlannedCostResult
        SET Thang = cl.ColName
        FROM #PlannedCostResult AS ge
            INNER JOIN #ColList AS cl
                ON ge.M_DocDate = cl.Tt
                   AND ge.Y_DocDate = cl.Y_DocDate
                   AND cl.Type = '1'

        --20260907 Bổ sung thêm dữ liệu số Kế hoạch từ bảng #PlannedCostResult cho đơn vị I24				 
        IF @_BranchCode IN ( 'I01', 'I24' )
            INSERT INTO #ZProjectDocDetail
            (
                BranchCode
              , DocDate
              , CostFactorId
              , Amount
              , Type
              , Thang
              , Col_DocDate
              , M_DocDate
              , Y_DocDate
            )
            SELECT BranchCode
                 , DocDate
                 , CostFactorId
                 , Amount
                 , Type
                 , Thang
                 , Col_DocDate
                 , M_DocDate
                 , Y_DocDate
            FROM #PlannedCostResult
        ELSE
            INSERT INTO #ZDetail
            (
                BranchCode
              , DocDate
              , CostFactorId
              , Amount
              , Type
              , Thang
              , Col_DocDate
              , M_DocDate
              , Y_DocDate
            )
            SELECT BranchCode
                 , DocDate
                 , CostFactorId
                 , Amount
                 , Type
                 , Thang
                 , Col_DocDate
                 , M_DocDate
                 , Y_DocDate
            FROM #PlannedCostResult

    END

	UPDATE #ZDetail
		SET ProductLevelId = i.ProductLevelId
		FROM #ZDetail              AS z
			INNER JOIN B20ItemInfo AS inf (NOLOCK)
				ON z.ProductId = inf.ProductId
			INNER JOIN B20Item     AS i (NOLOCK)
				ON inf.ItemId = i.Id

    DROP TABLE IF EXISTS #Kq_ZDetail
    SELECT TOP (0)
           CostFactorId,
           ProductLevelId
    INTO #Kq_ZDetail
    FROM #ZDetail

    IF @_BranchCode IN ( 'I01', 'I24' )
    BEGIN
        SELECT @query_tmp
            = N'	SELECT Thang, CostFactorId, Amount FROM #ZProjectDocDetail '
              + ' union all SELECT  Thang, CostFactorId, Amount FROM #ZDetail'
        EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                    , @on_cols_ColList = 'ColName'
                                    , @_ColName_Total = @_ColName_Total
                                    , @query = @query_tmp
                                    , @on_rows = 'CostFactorId'
                                    , @on_cols = 'Thang'
                                    , @agg_func = 'SUM'
                                    , @agg_col = 'Amount'
                                    , @bang = '#Kq_ZDetail'
                                    , @_jsonData = @_jsonData
                                    , @_DocDate2 = @_DocDate2
                                    , @_PrintExec = 0
    END
    ELSE
    BEGIN

        SELECT @query_tmp = N' SELECT * FROM #ZDetail '
        EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                    , @on_cols_ColList = 'ColName'
                                    , @_ColName_Total = @_ColName_Total
                                    , @query = @query_tmp
                                    , @on_rows = 'ProductLevelId'
                                    , @on_cols = 'Thang'
                                    , @agg_func = 'SUM'
                                    , @agg_col = 'Amount'
                                    , @bang = '#Kq_ZDetail'
                                    , @_jsonData = @_jsonData
                                    , @_DocDate2 = @_DocDate2
                                    , @_PrintExec = 0
    END

    SELECT @_SqlUpdate = ''
    SELECT @_SqlUpdate
        = @_SqlUpdate + N' UPDATE a ' + @_nl + N' SET ' + @_StringSet + N' FROM ' + value
          + ' a INNER JOIN #Kq_ZDetail b ON a.VarValue = b.ProductLevelId and ExpenditureType = ''GV''  AND a.VarKey = ''ProductLevelId'' '
    FROM #T_lst_Tmp
    EXEC sys.sp_executesql @_SqlUpdate

    DECLARE @_CalSum VARCHAR(MAX) = ''
    SELECT @_CalSum = STRING_AGG(ColName, ',')
    FROM #ColList

    BEGIN
        --bắt đầu xử lý lấy dữ liệu số khấu hao
        SELECT TOP (0)
               *
             , CAST('' AS VARCHAR(24)) AS Type
        INTO #T_SoTmp9
        FROM dbo.vB30AssetDoc WITH (NOLOCK)

        EXECUTE dbo.usp_B30AssetDoc_GetData @_Date1 = @_DocDate1
                                          , @_Date2 = @_DocDate2
                                          , @_Key1 = @_Key
                                          , @_CtTmp = N'#T_SoTmp9'
                                          , @_nUserId = @_nUserId
                                          , @_LangId = @_LangId
                                          , @_BranchCode = @_BranchCode
                                          , @_BranchReportId = @_BranchReportId



        UPDATE #T_SoTmp9
        SET Type = IIF(Trans = 1, 1, 2)
        ALTER TABLE #T_SoTmp9
        ADD ClassCode1 VARCHAR(24)
                DEFAULT ''
          , M_DocDate INT
          , Y_DocDate INT
          , Thang VARCHAR(24)

        DELETE #T_SoTmp9
        WHERE AssetTransType <> 'KHAUHAO'


        UPDATE #T_SoTmp9
        SET M_DocDate = MONTH(DocDate)
          , Y_DocDate = YEAR(DocDate)
        UPDATE #T_SoTmp9
        SET Thang = cl.ColName
        FROM #T_SoTmp9          AS ge
            INNER JOIN #ColList AS cl
                ON ge.M_DocDate = cl.Tt
                   AND ge.Y_DocDate = cl.Y_DocDate
                   AND cl.Type = '0'

        SELECT b.AssetId
             , Y_DocDate
             , M_DocDate
             , ClassCode1
             , b.ParentId
             , b.Thang
             , b.BranchCode
             , IIF(b.Type = 2, SUM(b.OriginalCost), 0) AS DecreaseOriginalCost
             , IIF(b.Type = 1, SUM(b.OriginalCost), 0) AS IncreaseOriginalCost
             , IIF(b.Type = 2, SUM(b.Depreciation), 0) AS DecreaseDepreciation
             , IIF(b.Type = 1, SUM(b.Depreciation), 0) AS IncreaseDepreciation
             , MAX(b.DocDate)                          AS DocDate
        INTO #BcTmp
        FROM #T_SoTmp9 AS b
        GROUP BY b.AssetId
               , b.Type
               , b.ParentId
               , b.Thang
               , Y_DocDate
               , M_DocDate
               , ClassCode1
               , BranchCode

        DROP TABLE IF EXISTS #Kq_BcTmp
        SELECT TOP (0)
               ClassCode1
        INTO #Kq_BcTmp
        FROM #T_SoTmp9

        BEGIN
            DROP TABLE IF EXISTS #PlannedDeprExpenseResult
            SELECT TOP 0
                   Account
                 , Account       AS AccountCal
                 , DocDate
                 , AssetId
                 , Amount
                 , @_CodeType    AS Type
                 , @_TINYINTType AS M_DocDate
                 , @_INTType     AS Y_DocDate
                 , @_CodeType    AS Thang
                 , BranchCode
                 , @_CodeType    AS ClassCode1
            INTO #PlannedDeprExpenseResult
            FROM B30PlannedDeprExpenseResult

            EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_DocDate1
                                                     , @_DocDate2 = @_DocDate2
                                                     , @_Key = @_Key_Detail
                                                     , @_CtTmp = '#PlannedDeprExpenseResult'
                                                     , @_BranchCode = @_BranchCode
                                                     , @_BizDocName = 'vB30PlannedDeprExpenseResult_Getdata'
                                                     , @_PrintExec = 0

            UPDATE fi
            SET fi.Type = 'PLAN'
              , fi.M_DocDate = MONTH(fi.DocDate)
              , fi.Y_DocDate = YEAR(fi.DocDate)
              , AccountCal = LEFT(Account, 3)
            FROM #PlannedDeprExpenseResult AS fi

            UPDATE FI
            SET FI.Thang = cl.ColName
            FROM #PlannedDeprExpenseResult AS FI
                INNER JOIN #ColList        AS cl
                    ON FI.M_DocDate = cl.Tt
                       AND cl.Type = '1'

            SELECT @_StrExec = ''
            SELECT @_StrExec
                = @_StrExec
                  + N' UPDATE bc SET  ClassCode1 =  dm.ClassCode1   FROM #PlannedDeprExpenseResult bc  INNER JOIN B2'
                  + DataCode_Branch + N'Asset dm ON bc.AssetId = dm.Id WHERE bc.BranchCode = ''' + BranchCode + ''' '
                  + @_nl
            FROM @_BranchList
            EXECUTE sys.sp_executesql @_StrExec

            SELECT @_StrExec = ''
            SELECT @_StrExec
                = @_StrExec + N' UPDATE bc SET  ClassCode1 =  dm.ClassCode1   FROM #BcTmp bc  INNER JOIN B2'
                  + DataCode_Branch + N'Asset dm ON bc.AssetId = dm.Id WHERE bc.BranchCode = ''' + BranchCode + ''' '
                  + @_nl
            FROM @_BranchList
            EXECUTE sys.sp_executesql @_StrExec


        END

        SELECT @query_tmp
            = N' 
		SELECT IncreaseDepreciation,Thang,ClassCode1 FROM #BcTmp
		UNION ALL
		SELECT Amount as IncreaseDepreciation,Thang,ClassCode1 FROM #PlannedDeprExpenseResult'

        EXEC dbo.usp_pivot_KHTC_Final @query_ColList = ' SELECT  ColName FROM #ColList  '
                                    , @on_cols_ColList = 'ColName'
                                    , @_ColName_Total = @_ColName_Total
                                    , @query = @query_tmp
                                    , @on_rows = 'ClassCode1'
                                    , @on_cols = 'Thang'
                                    , @agg_func = 'SUM'
                                    , @agg_col = 'IncreaseDepreciation'
                                    , @bang = '#Kq_BcTmp'
                                    , @_jsonData = @_jsonData
                                    , @_DocDate2 = @_DocDate2
                                    , @_PrintExec = 0
        SELECT @_SqlUpdate = ''
        SELECT @_SqlUpdate
            = @_SqlUpdate + N'UPDATE a SET ' + @_StringSet + N' FROM ' + value
              + ' a INNER JOIN #Kq_BcTmp b  ON (b.ClassCode1 <> '''') and  ExpenditureType = ''IncreaseDepreciation''
			AND ItemLevel=9   AND (PATINDEX(CONCAT(''%'',TRIM(STR(b.ClassCode1)),''%'') , CONCAT(''%'',TRIM( (a.VarValue)),''%'' ) ) <> 0 )'
        FROM #T_lst_Tmp
        EXEC sys.sp_executesql @_SqlUpdate
    END


    EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp'
                               , @_FieldList = @_CalSum
                               , @_FieldKey = 'ItemNo'
                               , @_FieldCal = 'Formula'
                               , @_FieldBac = 'ItemLevel'
                               , @_FieldIn_Ck = 'IsPrint'
                               , @_ResetFormula = 1

    EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp1'
                               , @_FieldList = @_CalSum
                               , @_FieldKey = 'ItemNo'
                               , @_FieldCal = 'Formula'
                               , @_FieldBac = 'ItemLevel'
                               , @_FieldIn_Ck = 'IsPrint'
                               , @_ResetFormula = 1

    EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp2'
                               , @_FieldList = @_CalSum
                               , @_FieldKey = 'ItemNo'
                               , @_FieldCal = 'Formula'
                               , @_FieldBac = 'ItemLevel'
                               , @_FieldIn_Ck = 'IsPrint'
                               , @_ResetFormula = 1

 
    SELECT *
         , ItemNo  AS _FormulaKey
         , Formula AS _Formula
    FROM #tblTmp1 AS tt
    WHERE tt.IsPrint = 1
    ORDER BY tt.BuiltinOrder ASC

    --SELECT *
    --     , ItemNo  AS _FormulaKey
    --     , Formula AS _Formula
    --FROM #tblTmp2 AS tt
    --WHERE tt.IsPrint = 1
    --ORDER BY tt.BuiltinOrder ASC


    DECLARE @_LAYOUT_XML2 NVARCHAR(MAX) = REPLACE(@_LAYOUT_XML1, 'Report_0', 'Report_1');
    

    SET @_LAYOUT_XML
        = N'<panelReporter>' + @_nl + N'   <Controls> ' + @_nl + N' '
          + CONCAT(@_LAYOUT_XML1, @_nl, @_LAYOUT_XML2, @_nl) + @_nl + N'   </Controls> ' + @_nl
          + N'</panelReporter>' + @_nl;


    SET @_Time2 = GETDATE()
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, @_Time2))) --
    DROP TABLE IF EXISTS #BcTmp
                       , #ColList
                       , #CtTmpGeneralLedger
                       , #Kq_BcTmp
                       , #kq_ChiPhiKhac_811
                       , #kq_ChiPhithueTNDN_821
                       , #kq_CPBanHang_641
                       , #kq_CPLaiVay_6351
                       , #kq_CPLoCLTG_6352
                       , #kq_CPQuanLy_642
                       , #kq_DoanhThu_511
                       , #kq_DTTC_515
                       , #kq_GiaVon_632
                       , #kq_ThuNhapKhac_711
                       , #Kq_ZDetail
                       , #tblTmp1
                       , #T_SoTmp9
                       , #ZDetail
END
GO



SET DATEFORMAT DMY
EXEC usp_REP_ConsolidatedRevenueandProfitPlan_HN_Summary_Ib @_DocDate1 = '01/01/2026 00:00:00.000'
                                                          , @_DocDate2 = '31/08/2026 00:00:00.000'
                                                          , @_DocDatePlan2 = '31/08/2026 00:00:00.000'
                                                          , @_Account = '511,515,641,642,635,711,811,911'
                                                          , @_ExcludeCrspAccount = '821,911'
                                                          , @_BranchCode = 'I09'
                                                          , @_nUserId = 1213
                                                          , @_LangId = 0
                                                          , @_CurrencyCode0 = 'VND'
                                                          , @_IsRound = 0
                                                          , @_RepId1 = 'T000000001'
                                                          , @_RepId2 = 'T000000007'
                                                          , @_StrTime = '00:00:04'
                                                          , @_IsGetPlan = 0
                                                          , @_IsGet_DataSMT = 0