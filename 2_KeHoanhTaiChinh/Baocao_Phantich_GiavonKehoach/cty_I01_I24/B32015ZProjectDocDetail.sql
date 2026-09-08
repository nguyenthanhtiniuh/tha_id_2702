USE B10THACOIDACC
GO


CREATE OR ALTER PROC usp_Account_632carryforward_data
    @_DocDate AS DATE = '20260801'
  , @_Year AS VARCHAR(4) = '2026'
  , @_ItemId AS VARCHAR(512) = ''
  , @_nUserId AS INT = 0
  , @_LangId TINYINT = 0
  , @_BranchCode AS VARCHAR(3) = 'I24'
  , @_BizDocId AS VARCHAR(16) = ''
  , @_CtTmp1 NVARCHAR(24) = ''
  , @_CtTmp2 NVARCHAR(24) = ''
AS
BEGIN

    SET NOCOUNT ON;
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);
    DECLARE @_Key_ZDetail NVARCHAR(MAX) = N''
          , @_DataCode    NVARCHAR(8)   = ''
    DECLARE @_Key          NVARCHAR(MAX)    = N''
          , @_MoneyType    AS dbo.MoneyType = 0
          , @_QuantityType dbo.QuantityType = 0
          , @_TINYINTType  TINYINT          = 0
          , @_INTType      INT              = 0
          , @_CodeType     VARCHAR(24)      = ''
          , @_BizDocIdType VARCHAR(16)      = ''
          , @_NameType     NVARCHAR(256)    = N''

    DECLARE @_PercentType       AS NUMERIC(15, 5) = 0
          , @_SMALLDATETIMEType SMALLDATETIME     = NULL
          , @_UnitType          NVARCHAR(8)       = N''
          , @_nl                CHAR(1)           = CHAR(13)
          , @_strExec           NVARCHAR(MAX)     = ''

    SELECT TOP 1
           @_DataCode = DataCode
    FROM dbo.B00Branch AS br
    WHERE BranchCode = @_BranchCode

    IF @_Year = ''
        SELECT @_Year = YEAR(@_DocDate);
    SELECT @_ItemId = ISNULL(@_ItemId, '');
    IF RTRIM(@_ItemId) <> ''
        SET @_Key = @_Key + N' AND sc.ItemId IN (' + REPLACE(@_ItemId, ',', ''',''') + N')';
    IF RTRIM(@_Year) <> ''
        SET @_Key = @_Key + N' AND sc.Year IN (' + REPLACE(@_Year, ',', ''',''') + N')';
    IF LEFT(@_Key, 5) = N' AND '
        SET @_Key = SUBSTRING(@_Key, 6, LEN(@_Key) - 5);


    SET @_DocDate = DATEADD(MONTH, -1, @_DocDate);

    DECLARE @_SOMONTH DATE = DATEFROMPARTS(YEAR(@_DocDate), MONTH(@_DocDate), '01');
    DECLARE @_EOMONTH DATE = EOMONTH(@_SOMONTH);

    --DROP TABLE IF EXISTS #ZProjectDocDetail
    --SELECT TOP (0)
    --       BranchCode
    --     , DocDate
    --     , CostFactorId
    --     , Account632
    --     , @_MoneyType              AS Amount
    --     , CAST('' AS VARCHAR(24))  AS Type
    --     , CAST('' AS VARCHAR(24))  AS Thang
    --     , CAST('' AS NVARCHAR(24)) AS Col_DocDate
    --     , CAST('' AS NVARCHAR(24)) AS M_DocDate
    --     , CAST('' AS NVARCHAR(24)) AS Y_DocDate
    --INTO #ZProjectDocDetail
    --FROM dbo.vB30ZProjectDocDetail_GetData

    DROP TABLE IF EXISTS #ZProjectDocDetail

    SELECT TOP 0
           zpdd.BizDocId_C2
         , zpdd.Amount
         , zpdd.Account632
         , zpdd.DocDate
         , zpdd.ExpenseAccount
         , zpdd.AllocationType
         , zpdd.CostFactorId
         , CostFactor.Code AS CostFactorCode
         , CostFactor.Name AS CostFactorName
         , CostFactor.ClassCode2
         , so.ProductGroupId
         , @_CodeType      AS ProductGroupCode
         , @_NameType      AS ProductGroupName
         , ProductGroup.ProductClassId
         , @_CodeType      AS ProductClassCode
         , @_NameType      AS ProductClassName
    INTO #ZProjectDocDetail
    FROM B32015ZProjectDocDetail     AS zpdd
        LEFT JOIN B20CostFactor      AS CostFactor
            ON zpdd.CostFactorId = CostFactor.Id
        LEFT JOIN dbo.B32015BizDocSO AS so
            ON zpdd.BizDocId_C2 = so.BizDocId
        LEFT JOIN B20ProductGroup    AS ProductGroup
            ON ProductGroup.Id = so.ProductGroupId
    --WHERE MONTH(zpdd.DocDate) = 7
    --ORDER BY DocDate ASC

    SET @_Key_ZDetail
        = N'   DocDate BETWEEN ''' + FORMAT(@_SOMONTH, 'yyyyMMdd') + N''' AND ''' + FORMAT(@_EOMONTH, 'yyyyMMdd')
          + N''''

    IF @_BranchCode IN ( 'I01', 'I24' )
        EXEC dbo.usp_B30ZQTCostFactorStage_GetData @_DocDate1 = @_SOMONTH
                                                 , @_DocDate2 = @_EOMONTH
                                                 , @_Key = @_Key_ZDetail
                                                 , @_CtTmp = '#ZProjectDocDetail'
                                                 , @_BranchCode = @_BranchCode
                                                 , @_BizDocName = 'vB30ZProjectDocDetail_GetData'
                                                 , @_PrintExec = 0

    SELECT @_strExec
        = 'UPDATE #ZProjectDocDetail
    SET ProductGroupId = so.ProductGroupId
    FROM #ZProjectDocDetail        AS dt
        INNER JOIN dbo.B3' + @_DataCode + 'BizDocSO AS so
            ON dt.BizDocId_C2 = so.BizDocId'

    EXEC (@_strExec)


    EXECUTE dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#ZProjectDocDetail'
                                              , @_List_Cats = 'ProductGroup'
                                              , @_SetString_Other = ',kq.ProductClassId=ProductGroup.ProductClassId'
                                              , @_WhereString = ' WHERE ISNULL(kq.ProductGroupId,0) <> 0 '
                                              , @_PrintExec = 0

    EXECUTE dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#ZProjectDocDetail'
                                              , @_List_Cats = 'ProductClass'

    EXECUTE dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#ZProjectDocDetail'
                                              , @_List_Cats = 'CostFactor'
                                              , @_SetString_Other = ',kq.ClassCode2 =  CostFactor.ClassCode2'

    --SELECT *
    --FROM #ZProjectDocDetail

    --SELECT zpdd.BizDocId_C2
    --     , zpdd.Amount
    --     , zpdd.Account632
    --     , zpdd.DocDate
    --     , zpdd.ExpenseAccount
    --     , zpdd.AllocationType
    --     , zpdd.CostFactorId
    --     , CostFactor.Code AS CostFactorCode
    --     , CostFactor.Name AS CostFactorName
    --     , CostFactor.ClassCode2
    --     , so.ProductGroupId
    --     , ProductGroup.ProductClassId
    --INTO #ZProjectDocDetail
    --FROM B32015ZProjectDocDetail     AS zpdd
    --    LEFT JOIN B20CostFactor      AS CostFactor
    --        ON zpdd.CostFactorId = CostFactor.Id
    --    LEFT JOIN dbo.B32015BizDocSO AS so
    --        ON zpdd.BizDocId_C2 = so.BizDocId
    --    LEFT JOIN B20ProductGroup    AS ProductGroup
    --        ON ProductGroup.Id = so.ProductGroupId
    --WHERE MONTH(zpdd.DocDate) = 7
    --ORDER BY DocDate ASC

    DROP TABLE IF EXISTS #ZProjectDocDetail1
    SELECT ProductClassId
         , Account632
         , ClassCode2
         , CostFactorId
         , CostFactorCode
         , CostFactorName
         , SUM(Amount) AS Amount
    INTO #ZProjectDocDetail1
    FROM #ZProjectDocDetail
    GROUP BY ProductClassId
           , Account632
           , ClassCode2
           , CostFactorId
           , CostFactorCode
           , CostFactorName;


    --SELECT ProductClassId
    --     , ClassCode2
    --     , SUM(Amount) AS Amount
    --FROM #ZProjectDocDetail
    --WHERE ClassCode2 = 'BP'
    --GROUP BY ProductClassId
    --       , ClassCode2



    -------
    ;
    WITH cte
    AS (SELECT ProductClassId
             , ClassCode2
             , SUM(Amount) AS Amount
        FROM #ZProjectDocDetail
        WHERE ClassCode2 = 'BP'
        GROUP BY ProductClassId
               , ClassCode2)
    SELECT dt1.*
         , dt1.Amount / dt.Amount AS TyTrongYtcp
    FROM #ZProjectDocDetail1 AS dt1
        LEFT JOIN cte        AS dt
            ON dt1.ProductClassId = dt.ProductClassId
               AND dt1.ClassCode2 = dt.ClassCode2
    WHERE dt1.ClassCode2 = 'BP'
    ORDER BY dt1.ClassCode2
           , CostFactorCode




END

GO


SET DATEFORMAT DMY
EXEC usp_Account_632carryforward_data