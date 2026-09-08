SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	
/*B2: LẤY DỮ LIỆU ĐỊNH MỨC THÁNG GẦN NHẤT  
GettheLatestMonthlyNormData*/
-- =============================================
ALTER PROCEDURE dbo.usp_B30FinPlanDetail_GettheLatestMonthlyNormData
    @_DocDate AS DATE = '20260301'
  , @_Year AS VARCHAR(4) = '2026'
  , @_ItemId AS VARCHAR(512) = ''
  , @_nUserId AS INT = 0
  , @_LangId TINYINT = 0
  , @_BranchCode AS VARCHAR(3) = 'I09'
  , @_BizDocId AS VARCHAR(16) = 'I090000017FP'
  , @_DataXML XML = NULL
  , @_CtTmp1 NVARCHAR(24) = ''
  , @_CtTmp2 NVARCHAR(24) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);

    IF CAST(@_DataXML AS NVARCHAR(MAX)) = ''
        RETURN;

    DECLARE @_strExec NVARCHAR(MAX);
    DECLARE @_Key NVARCHAR(MAX) = N'';

    DECLARE @_MoneyType    AS dbo.MoneyType = 0
          , @_QuantityType dbo.QuantityType = 0
          , @_TINYINTType  TINYINT          = 0
          , @_INTType      INT              = 0
          , @_CodeType     VARCHAR(24)      = ''
          , @_BizDocIdType VARCHAR(16)      = ''
          , @_NameType     NVARCHAR(256)    = N''
          , @_DataCode_Tmp VARCHAR(8)       = '';

    SELECT TOP (1)
           @_DataCode_Tmp = DataCode
    FROM dbo.B00Branch
    WHERE BranchCode = @_BranchCode;

    DROP TABLE IF EXISTS #K_SoTmp;
    CREATE TABLE #K_SoTmp
    (
        ItemId INT
      , Quantity NUMERIC(18, 2)
      , BranchCode VARCHAR(3)
      , ProductId INT
      , DocDate DATETIME
      , DocDate00 DATE
    );

    IF @_DataXML IS NOT NULL
    BEGIN
        DECLARE @_docHandle INT;
        EXEC sys.sp_xml_preparedocument @_docHandle OUTPUT, @_DataXML;

        INSERT INTO #K_SoTmp
        (
            ItemId
          , Quantity
          , BranchCode
        )
        SELECT ItemId
             , Quantity
             , BranchCode
        FROM
            OPENXML(@_docHandle, '/NewDataSet/PlannedOutputDetermination', 1)
            WITH
            (
                ItemId INT
              , Quantity NUMERIC(18, 2)
              , BranchCode VARCHAR(3)
            );

        EXEC sys.sp_xml_removedocument @_docHandle;

    END;

    IF @_DataXML IS NULL
    BEGIN

        DROP TABLE IF EXISTS #FinPlan;
        SELECT TOP (0)
               DocDate
             , DocDate00
             , ItemId
             , @_QuantityType AS Quantity
             , BranchCode
        INTO #FinPlan_Out
        FROM dbo.vB30FinPlanDetail_GetData;

        EXEC usp_B30FinPlanDetail_PlannedOutputDetermination @_DocDate = @_DocDate
                                                           , @_Year = @_Year
                                                           , @_nUserId = @_nUserId
                                                           , @_LangId = @_LangId
                                                           , @_BranchCode = @_BranchCode
                                                           , @_CtTmp1 = '#FinPlan_Out'
        --, @_ItemId = @_ItemId

        INSERT INTO #K_SoTmp
        (
            ItemId
          , Quantity
          , BranchCode
          , ProductId
          , DocDate
          , DocDate00
        )
        SELECT fpo.ItemId
             , SUM(fpo.Quantity) AS Quantity
             , fpo.BranchCode
             , inf.ProductId
             , fpo.DocDate
             , fpo.DocDate00
        FROM #FinPlan_Out          AS fpo
            INNER JOIN B20ItemInfo AS inf
                ON fpo.ItemId = inf.ItemId
        WHERE fpo.Quantity <> 0
        GROUP BY fpo.ItemId
               , fpo.BranchCode
               , inf.ProductId
               , fpo.DocDate
               , fpo.DocDate00

    --select * from #K_SoTmp where itemid = 1834676 return 

    END;

    IF RTRIM(@_ItemId) <> ''
        SET @_Key = @_Key + N' AND sc.ItemId IN (' + REPLACE(@_ItemId, ',', ''',''') + N')';
    IF RTRIM(@_Year) <> ''
        SET @_Key = @_Key + N' AND sc.Year IN (' + REPLACE(@_Year, ',', ''',''') + N')';

    IF LEFT(@_Key, 5) = N' AND '
        SET @_Key = SUBSTRING(@_Key, 6, LEN(@_Key) - 5);

    SET DATEFORMAT DMY;
    --
    DECLARE @_LastMONTHDocDate DATE = DATEADD(MONTH, -1, @_DocDate);
    DECLARE @_SOLastMONTH DATE = DATEFROMPARTS(YEAR(@_LastMONTHDocDate), MONTH(@_LastMONTHDocDate), '01');
    DECLARE @_EOLastMONTH DATE = EOMONTH(@_SOLastMONTH);
    DROP TABLE IF EXISTS #ZCoeffDetail0;

    ;WITH cte
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
              AND
              (
                  EffectiveDate >= '20260101'
                  AND EffectiveDate <= EOMONTH(@_DocDate)
              )
              AND ZCoeff.ProductId IN
                  (
                      SELECT ProductId FROM #K_SoTmp
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
    --LEFT JOIN #K_SoTmp                      AS kst
    --    ON ItemInfo.ItemId = kst.ItemId
    WHERE ZCoeff.Id IN
          (
              --2026-08-11 Lấy định mức gần nhất
              SELECT Id FROM cte_Lasteest WHERE _RN = 1
          )
          AND CostFactor.ClassCode2 = 'BP';

    DROP TABLE IF EXISTS #ZCoeffDetail
    SELECT kst.BranchCode
         , ZCoeffDetail0.EffectiveDate
         , ZCoeffDetail0.ProductId
         , ZCoeffDetail0.CostFactorId
         , ZCoeffDetail0.StageId
         , ISNULL(ZCoeffDetail0.Coeff, 0)                                        AS Coeff
         , kst.ItemId
         , kst.Quantity
         , kst.DocDate
         , kst.DocDate00
         , CAST(ISNULL(ZCoeffDetail0.Coeff, 0) * kst.Quantity AS NUMERIC(18, 2)) AS VariableAmount
    INTO #ZCoeffDetail
    FROM #K_SoTmp                AS kst
        LEFT JOIN #ZCoeffDetail0 AS ZCoeffDetail0
            ON ZCoeffDetail0.ItemId = kst.ItemId

    --SELECT *
    --FROM #K_SoTmp
    --WHERE ItemId = 1834676


    --SELECT *
    --FROM #ZCoeffDetail
    --WHERE ItemId = 1834676
    --WHERE ItemId = 100529138


    DROP TABLE IF EXISTS #Detail_AmountCost_DP;
    CREATE TABLE #Detail_AmountCost_DP
    (
        ItemId INT
      , ItemCode VARCHAR(24)
      , ItemName NVARCHAR(256)
      , CostFactorId INT
      , CostFactorCode VARCHAR(24)
      , CostFactorName NVARCHAR(256)
      , FixedAmount DECIMAL(38, 2)
      , ProductId INT
      , ProductCode VARCHAR(24)
      , ProductName NVARCHAR(256)
      , DocDate DATE
    );

    SELECT @_strExec
        = N'
	INSERT INTO #Detail_AmountCost_DP(ItemId,CostFactorId,FixedAmount,ProductId,DocDate)
    SELECT ItemInfo.ItemId
          ,ZDetail.CostFactorId 
          ,SUM(ZDetail.IndirectAmount + ZDetail.DirectAmount) AS FixedAmount
          ,Cdz.ProductId     ,cdz.DocDate
    FROM dbo.B3' + @_DataCode_Tmp + N'ZDetail (NOLOCK) AS ZDetail
         INNER JOIN dbo.B3' + @_DataCode_Tmp
          + N'CdZ (NOLOCK) AS Cdz ON Cdz.DocDate = ZDetail.DocDate
                                                     AND Cdz.ProductId = ZDetail.ProductId
                                                     AND Cdz.StageId = ZDetail.StageId
         INNER JOIN dbo.B20ItemInfo (NOLOCK) AS ItemInfo ON Cdz.ProductId = ItemInfo.ProductId
         INNER JOIN dbo.B20CostFactor (NOLOCK) AS CostFactor ON ZDetail.CostFactorId = CostFactor.Id
    WHERE ItemInfo.ItemId IN
          (
              SELECT kst.ItemId FROM #K_SoTmp AS kst WHERE Quantity <> 0
          )
          AND Cdz.BranchCode = ''' + @_BranchCode + N'''
          AND Cdz.DocDate
          BETWEEN ''' + CAST(@_SOLastMONTH AS VARCHAR(11)) + N''' AND  ''' + CAST(@_EOLastMONTH AS VARCHAR(11))
          + N'''
          AND ClassCode2 = ''DP''
    GROUP BY ItemInfo.ItemId
            ,ZDetail.CostFactorId
            ,Cdz.ProductId
			,Cdz.DocDate
	';
    EXEC (@_strExec);

    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#Detail_AmountCost_DP'
                                           , @_List_Cats = 'Item';
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#Detail_AmountCost_DP'
                                           , @_List_Cats = 'CostFactor';
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#Detail_AmountCost_DP'
                                           , @_List_Cats = 'Product';

    SELECT ItemId
         , @_CodeType          AS ItemCode
         , @_NameType          AS ItemName
         , CostFactorId
         , @_CodeType          AS CostFactorCode
         , @_NameType          AS CostFactorName
         , Quantity
         , SUM(Coeff)          AS Coeff
         , SUM(VariableAmount) AS VariableAmount
         , ProductId
         , @_CodeType          AS ProductCode
         , @_NameType          AS ProductName
         , MAX(DocDate)        AS DocDate
         , MAX(DocDate00)      AS DocDate00
    INTO #Detail_AmountCost_BP
    FROM #ZCoeffDetail
    GROUP BY ItemId
           , CostFactorId
           , ProductId
           , Quantity;

    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#Detail_AmountCost_BP'
                                           , @_List_Cats = 'CostFactor';

    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#Detail_AmountCost_BP'
                                           , @_List_Cats = 'Item';

    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#Detail_AmountCost_BP'
                                           , @_List_Cats = 'Product';


    DECLARE @_FieldInsert VARCHAR(MAX) = ''
          , @_FieldSelect VARCHAR(MAX) = '';

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
                          WHERE Object_Id = OBJECT_ID('Tempdb..' + '#Detail_AmountCost_BP')
                      )
        ) AS tb1;

        SET @_FieldInsert = STUFF(@_FieldInsert, 1, 1, '');

        SET @_FieldSelect = @_FieldInsert;

        SET @_strExec
            = N'INSERT INTO ' + @_CtTmp1 + N'(' + @_FieldInsert + N')' + CHAR(13) + N'SELECT ' + @_FieldSelect
              + CHAR(13) + N'FROM #Detail_AmountCost_BP ' + CHAR(13) + N'ORDER BY ItemCode ASC';



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
                          WHERE Object_Id = OBJECT_ID('Tempdb..' + '#Detail_AmountCost_DP')
                      )
        ) AS tb1;

        SET @_FieldInsert = STUFF(@_FieldInsert, 1, 1, '');

        SET @_FieldSelect = @_FieldInsert;

        SET @_strExec
            = N'INSERT INTO ' + @_CtTmp2 + N'(' + @_FieldInsert + N')' + CHAR(13) + N'SELECT ' + @_FieldSelect
              + CHAR(13) + N'FROM #Detail_AmountCost_DP ' + CHAR(13) + N'ORDER BY ItemCode ASC';

        EXEC sp_executesql @_strExec;
        RETURN;
    END;

    SELECT *
    FROM #Detail_AmountCost_BP
    --WHERE ItemId = 1834676
    ORDER BY ItemCode
           , CostFactorCode;

    SELECT *
    FROM #Detail_AmountCost_DP AS dacd
    --WHERE ItemId = 1834676
    ORDER BY dacd.ItemCode
           , dacd.CostFactorCode;

    DROP TABLE IF EXISTS #K_SoTmp;
    DROP TABLE IF EXISTS #ZCoeffDetail;
    DROP TABLE IF EXISTS #Detail_AmountCost_BP;
    DROP TABLE IF EXISTS #Detail_AmountCost_DP;
END;
GO
SET DATEFORMAT DMY
EXEC usp_B30FinPlanDetail_GettheLatestMonthlyNormData @_DocDate = '20260301'
                                                    , @_BranchCode = 'I09'
                                                    , @_ItemId = '1834676'