USE B10THACOIDACC
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================
-- Description	: BÁO CÁO LỢI NHUẬN THEO HỢP ĐỒNG DỰ ÁN
-- ===========================================================
ALTER PROCEDURE dbo.usp_ProfitProjectContract
    @_DocDate1 DATE = '20240101'
  , @_DocDate2 DATE = '20240101'
  , @_BizDocId_C2 NVARCHAR(24) = ''
  , @_Account511 NVARCHAR(2000) = '511'
  , @_Account632 NVARCHAR(2000) = '632'
  , @_NotAccountList NVARCHAR(2000) = '911'
  , @_CurrencyCode0 NVARCHAR(24) = 'VND'
  , @_LangId INT = 0
  , @_nUserId INT = 0
  , @_BranchCode VARCHAR(3) = N'A01'
  , @_CtTmp1 NVARCHAR(256) = ''
  , @_CtTmp2 NVARCHAR(256) = ''
AS
BEGIN
    SET NOCOUNT ON;
    -- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
    SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)

    DECLARE @_Key1     NVARCHAR(MAX) = '0=0'
          , @_DataCode VARCHAR(4)    = ''
          , @_Declare  NVARCHAR(MAX) = ''
          , @_StrExec  NVARCHAR(MAX) = ''
          , @_SumCol   NVARCHAR(MAX) = ''
          , @_nl       CHAR(1)       = CHAR(10)

    DECLARE @_MoneyType         AS dbo.MoneyType    = 0
          , @_QuantityType      AS dbo.QuantityType = 0
          , @_PercentType       AS NUMERIC(15, 5)   = 0
          , @_TINYINTType       TINYINT             = 0
          , @_INTType           INT                 = 0
          , @_CodeType          VARCHAR(24)         = ''
          , @_NameType          NVARCHAR(256)       = N''
          , @_SMALLDATETIMEType SMALLDATETIME       = NULL
          , @_UnitType          NVARCHAR(8)         = N''
          , @_BizDocIdType      VARCHAR(16)         = N''


    SELECT TOP (1)
           @_DataCode = DataCode
    FROM B10THACOID.dbo.B00Branch
    WHERE BranchCode = @_BranchCode

    --SET @_DocDate1=DATEFROMPARTS(YEAR(@_DocDate1), MONTH(@_DocDate1), 1)
    --SET @_DocDate2=EOMONTH(@_DocDate2)

    SET @_Key1 = 'IsActive =1 AND BranchCode=' + QUOTENAME(@_BranchCode, CHAR(39))
    SET @_Key1 += ' AND DocDate BETWEEN ''' + FORMAT(@_DocDate1, 'yyyyMMdd') + ''' AND '''
                  + FORMAT(@_DocDate2, 'yyyyMMdd') + ''''

    --SET @_Key1 = ' ISNULL(BizDocId_C2,'''') <>'''' '

    SET @_Key1 = ''

    IF @_Account511 <> ''
       OR @_Account632 <> ''
    BEGIN
        SET @_Key1 += ' AND ('

        IF @_Account511 <> ''
        BEGIN
            SET @_Key1 += '(Account LIKE ''' + REPLACE(@_Account511, ',', '%'' OR Account LIKE ''') + '%'')'
        END

        IF @_Account632 <> ''
        BEGIN
            SET @_Key1 += CASE
                              WHEN @_Account511 <> '' THEN
                                  ' OR '
                              ELSE
                                  ''
                          END + '(Account LIKE ''' + REPLACE(@_Account632, ',', '%'' OR Account LIKE ''') + '%'')'
        END

        SET @_Key1 += ')'

        IF @_NotAccountList <> ''
        BEGIN
            SET @_Key1 += ' AND NOT (CrspAccount LIKE '''
                          + REPLACE(@_NotAccountList, ',', '%'' OR CrspAccount LIKE ''') + '%'')'
        END
    END

    IF @_BizDocId_C2 <> ''
    BEGIN
        SET @_Key1 += ' AND BizDocId_C2= ' + QUOTENAME(@_BizDocId_C2, CHAR(39))

    END

    IF LEFT(@_Key1, 5) = N' AND '
        SET @_Key1 = SUBSTRING(@_Key1, 6, LEN(@_Key1) - 5)

    DROP TABLE IF EXISTS #CtTmp
    SELECT BizDocId_C2
         , Account
         , CrspAccount
         , Amount
         , DocGroup
         , DocCode
         , DebitAccount
         , CreditAccount
         , DebitAmount
         , CreditAmount
    INTO #CtTmp
    FROM dbo.B00CtTmp

    EXEC usp_sys_DefaultTable '#CtTmp'

    EXECUTE usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                       , @_DocDate2 = @_DocDate2
                                       , @_Key1 = @_Key1
                                       , @_Key2 = ''
                                       , @_CtTmp = N'#CtTmp'
                                       , @_nUserId = @_nUserId
                                       , @_LangId = @_LangId
                                       , @_BranchCode = @_BranchCode
                                       , @_CurrencyCode0 = @_CurrencyCode0
                                       , @_GroupByCols = 'BizDocId_C2, Account, CrspAccount'
                                       , @_PrintExec = 1

    UPDATE #CtTmp
    SET Amount =
        -- CASE
        -- 				 WHEN DocGroup = 2 THEN
        -- 					 Amount
        -- 				 ELSE
        -- 					 -Amount
        -- 			 END 
        CreditAmount - DebitAmount
    WHERE EXISTS
    (
        SELECT 1
        FROM STRING_SPLIT(@_Account511, ',')
        WHERE #CtTmp.Account LIKE LTRIM(RTRIM(value)) + '%'
    )

    --TINNT them đk 632 thì lấy ps nợ - ps có
    UPDATE #CtTmp
    SET Amount = DebitAmount - CreditAmount
    WHERE EXISTS
    (
        SELECT 1
        FROM STRING_SPLIT(@_Account632, ',')
        WHERE #CtTmp.Account LIKE LTRIM(RTRIM(value)) + '%'
    )

    DROP TABLE IF EXISTS #Result
    SELECT BizDocId_C2
         , DocNo                     AS DocNo_C2
         , Description
         , ProfitCenterId
         , ProfitCenterCode
         , ProfitCenterName
         , TerritoryId
         , TerritoryCode
         , TerritoryName
         , Amount2
         , Amount
         , CAST(0 AS NUMERIC(18, 5)) AS GrossProfit
         , CAST(NULL AS INT)         AS ProductGroupId
         , @_CodeType                AS ProductGroupCode
         , @_NameType                AS ProductGroupName
         , CAST(NULL AS INT)         AS ProductClassId
         , @_CodeType                AS ProductClassCode
         , @_NameType                AS ProductClassName --Tỷ suất lợi nhuận gộp
         , @_PercentType             AS GrossProfitRatio
    INTO #Result
    FROM dbo.B00CtTmp

    EXEC usp_sys_DefaultTable '#Result'

    INSERT INTO #Result
    (
        BizDocId_C2
      , Amount2
      , Amount
    )
    SELECT BizDocId_C2
         , SUM(   CASE
                      WHEN Is511 = 1 THEN
                          Amount
                      ELSE
                          0
                  END
              ) AS Amount2
         , SUM(   CASE
                      WHEN Is632 = 1 THEN
                          Amount
                      ELSE
                          0
                  END
              ) AS Amount
    FROM
    (
        SELECT BizDocId_C2
             , Amount
             , CASE
                   WHEN EXISTS
                        (
                            SELECT 1
                            FROM STRING_SPLIT(@_Account511, ',')
                            WHERE #CtTmp.Account LIKE LTRIM(RTRIM(value)) + '%'
                        ) THEN
                       1
                   ELSE
                       0
               END AS Is511
             , CASE
                   WHEN EXISTS
                        (
                            SELECT 1
                            FROM STRING_SPLIT(@_Account632, ',')
                            WHERE #CtTmp.Account LIKE LTRIM(RTRIM(value)) + '%'
                        ) THEN
                       1
                   ELSE
                       0
               END AS Is632
        FROM #CtTmp
    ) AS a
    GROUP BY BizDocId_C2

    UPDATE #Result
    SET GrossProfit = Amount2 - Amount

    UPDATE #Result
    SET GrossProfitRatio = IIF(Amount2 = 0, 0, GrossProfit / Amount2)

    SET @_StrExec
        = N'	UPDATE a ' + @_nl
          + '	
				SET DocNo_C2 = b.DocNo
					,a.TerritoryId=b.TerritoryId
					,a.ProfitCenterId=b.ProfitCenterId
					,a.Description = b.Description
					,a.ProductGroupId = b.ProductGroupId' + @_nl + 'FROM #Result a LEFT JOIN B3' + @_DataCode
          + 'BizDocSO b ON a.BizDocId_C2 = b.BizDocId'
    EXEC (@_StrExec)

    UPDATE #Result
    SET Description = N'Chưa xác định Hợp đồng bán'
    FROM #Result
    WHERE ISNULL(Description, '') = ''

    /*
    ProductGroupId
    ProductClassId
    */

    UPDATE a
    SET ProfitCenterCode = profit.Code
      , ProfitCenterName = profit.Name
      , a.TerritoryCode = territory.Code
      , a.TerritoryName = territory.Name
      , a.ProductGroupCode = ProductGroup.Code
      , a.ProductGroupName = ProductGroup.Name
      , a.ProductClassId = ProductGroup.ProductClassId
      , a.ProductClassCode = ProductClass.Code
      , a.ProductClassName = ProductClass.Name
    FROM #Result                  AS a
        LEFT JOIN B20ProfitCenter AS profit (NOLOCK)
            ON a.ProfitCenterId = profit.Id
        LEFT JOIN B20Territory    AS territory (NOLOCK)
            ON a.TerritoryId = territory.Id
        LEFT JOIN B20ProductGroup AS ProductGroup (NOLOCK)
            ON a.ProductGroupId = ProductGroup.Id
        LEFT JOIN B20ProductClass AS ProductClass (NOLOCK)
            ON ProductGroup.ProductClassId = ProductClass.Id



    BEGIN
        --bảng phân tích Tỷ trọng giá vốn thực hiện theo Nhóm sản phẩm HN cấp 2
        DROP TABLE IF EXISTS #Result1
        SELECT ProductClassId
             , ProductClassCode
             , ProductClassName
             , SUM(Amount2)                                              AS Amount2
             , SUM(Amount)                                               AS Amount
             , SUM(GrossProfit)                                          AS GrossProfit

             --Tỷ suất lợi nhuận gộp
             , IIF(SUM(Amount2) = 0, 0, SUM(GrossProfit) / SUM(Amount2)) AS GrossProfitRatio
             --Tỷ trọng Giá vốn thực hiện QK
             , IIF(SUM(Amount) = 0, 0, SUM(Amount) / SUM(Amount2))       AS ActualCOGSRatio
             --Giá vốn kế hoạch
             , @_MoneyType                                               AS PlannedCOGS
             --Tỷ trọng chi phí Kế hoạch	
             --Lợi nhuận gộp Kế hoạch	
             --Tỷ suất lợi nhuận gộp
             , ProductGroupId
             , ProductGroupCode
             , ProductGroupName
        INTO #Result1
        FROM #Result
        WHERE ProductClassId IS NOT NULL
        GROUP BY ProductClassId
               , ProductClassCode
               , ProductClassName
               , ProductGroupId
               , ProductGroupCode
               , ProductGroupName
    END


    DECLARE @_FieldInsert VARCHAR(MAX) = ''
          , @_FieldSelect VARCHAR(MAX) = ''
    IF ISNULL(@_CtTmp1, '') <> ''
    BEGIN
        SELECT @_FieldInsert = @_FieldInsert + ',' + RTRIM(Name)
        FROM
        (
            SELECT Name
            FROM tempdb.sys.Columns WITH (NOLOCK)
            WHERE Object_Id = OBJECT_ID('Tempdb..' + @_CtTmp1)
        ) AS tb1;
        SET @_FieldInsert = STUFF(@_FieldInsert, 1, 1, '');
        SET @_FieldSelect = @_FieldInsert;
        SET @_StrExec
            = N'INSERT INTO ' + @_CtTmp1 + N'(' + @_FieldInsert + N')' + CHAR(13) + N'SELECT ' + @_FieldSelect
              + CHAR(13) + N'FROM #Result' + CHAR(13) + N'ORDER BY DocNo_C2 ASC';
        EXEC sp_executesql @_StrExec;
        RETURN;
    END;

    IF ISNULL(@_CtTmp2, '') <> ''
    BEGIN
        SELECT @_FieldInsert = @_FieldInsert + ',' + RTRIM(Name)
        FROM
        (
            SELECT Name
            FROM tempdb.sys.Columns WITH (NOLOCK)
            WHERE Object_Id = OBJECT_ID('Tempdb..' + @_CtTmp2)
        ) AS tb1;
        SET @_FieldInsert = STUFF(@_FieldInsert, 1, 1, '');
        SET @_FieldSelect = @_FieldInsert;
        SET @_StrExec
            = N'INSERT INTO ' + @_CtTmp2 + N'(' + @_FieldInsert + N')' + CHAR(13) + N'SELECT ' + @_FieldSelect
              + CHAR(13) + N'FROM #Result1' + CHAR(13) + N'ORDER BY ProductClassCode ASC, ProductGroupCode ASC';
        EXEC sp_executesql @_StrExec;
        RETURN;
    END;

    SELECT *
    FROM #Result
    ORDER BY DocNo_C2 ASC

    --bảng phân tích tỷ trọng
    SELECT *
    FROM #Result1
    ORDER BY ProductClassCode ASC
           , ProductGroupCode ASC

    DROP TABLE IF EXISTS #CtTmp
                       , #Result
                       , #Result1
END
GO


SET DATEFORMAT DMY
EXEC usp_ProfitProjectContract @_DocDate1 = '01/07/2026 00:00:00.000'
                             , @_DocDate2 = '31/07/2026 00:00:00.000'
                             , @_Account511 = '511'
                             , @_Account632 = '632'
                             , @_NotAccountList = '911'
                             , @_CurrencyCode0 = 'VND'
                             , @_LangId = 0
                             , @_nUserId = 1213
                             , @_BranchCode = 'I24'

