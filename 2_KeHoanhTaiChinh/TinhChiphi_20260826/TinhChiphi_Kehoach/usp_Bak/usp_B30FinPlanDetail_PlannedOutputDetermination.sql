SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	
/*
B1: XÁC ĐỊNH SẢN LƯỢNG KẾ HOẠCH (THÁNG 7) 
PlannedOutputDetermination 
*/
-- =============================================

ALTER PROCEDURE dbo.usp_B30FinPlanDetail_PlannedOutputDetermination
    @_DocDate AS DATE = '20260301'
  , @_Year AS VARCHAR(4) = '2026'
  , @_ItemId AS VARCHAR(512) = ''
  , @_nUserId AS INT = 0
  , @_LangId TINYINT = 0
  , @_BranchCode AS VARCHAR(3) = ''
  , @_BizDocId AS VARCHAR(16) = ''
  , @_CtTmp1 NVARCHAR(24) = ''
  , @_CtTmp2 NVARCHAR(24) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);
    DECLARE @_Key          NVARCHAR(MAX)    = N''
          , @_MoneyType    AS dbo.MoneyType = 0
          , @_QuantityType dbo.QuantityType = 0
          , @_TINYINTType  TINYINT          = 0
          , @_INTType      INT              = 0
          , @_CodeType     VARCHAR(24)      = ''
          , @_BizDocIdType VARCHAR(16)      = ''
          , @_NameType     NVARCHAR(256)    = N'';

    IF @_Year = ''
        SELECT @_Year = YEAR(@_DocDate);
    SELECT @_ItemId = ISNULL(@_ItemId, '');
    IF RTRIM(@_ItemId) <> ''
        SET @_Key = @_Key + N' AND sc.ItemId IN (' + REPLACE(@_ItemId, ',', ''',''') + N')';
    IF RTRIM(@_Year) <> ''
        SET @_Key = @_Key + N' AND sc.Year IN (' + REPLACE(@_Year, ',', ''',''') + N')';
    IF LEFT(@_Key, 5) = N' AND '
        SET @_Key = SUBSTRING(@_Key, 6, LEN(@_Key) - 5);

    SET @_DocDate = DATEADD(DAY, 1 - DAY(@_DocDate), @_DocDate);

    DECLARE @_SOMONTH DATE = DATEFROMPARTS(YEAR(@_DocDate), MONTH(@_DocDate), '01');

    DECLARE @_EOMONTH DATE = EOMONTH(@_SOMONTH);

    DROP TABLE IF EXISTS #FinPlan;
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
         , CAST(NULL AS INT)     AS ProductId
         , @_CodeType            AS ProductCode
         , @_NameType            AS ProductName
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
                                                 /*
                                                       ProductLine --Dòng sp
                                                       ProductGroup --Nhóm sp
                                                       ProductClass-- Nhóm sp HN2
                                                       ProductLevel -- Nhóm sp HN1
                                                       */
         , CAST(NULL AS INT)     AS ProductLineId
         , @_CodeType            AS ProductLineCode
         , @_NameType            AS ProductLineName
         , CAST(NULL AS INT)     AS ProductGroupId
         , @_CodeType            AS ProductGroupCode
         , @_NameType            AS ProductGroupName
         , CAST(NULL AS INT)     AS ProductClassId
         , @_CodeType            AS ProductClassCode
         , @_NameType            AS ProductClassName
         , CAST(NULL AS INT)     AS ProductLevelId
         , @_CodeType            AS ProductLevelCode
         , @_NameType            AS ProductLevelName
    INTO #FinPlan
    FROM dbo.vB30FinPlanDetail_GetData;
    EXEC dbo.usp_FinPlanDetail_GetData @_DocDate1 = @_SOMONTH
                                     , @_DocDate2 = @_EOMONTH
                                     , @_UsingDateKey = 1
                                     , @_Key = @_Key
                                     , @_CtTmp = '#FinPlan'
                                     , @_DateCol = 'sc.DocDate00'
                                     , @_BranchCode = @_BranchCode
                                     , @_PrintExec = 1
                                     , @_BizDocId = @_BizDocId
                                     , @_LangId = @_LangId;

    --SELECT * FROM #FinPlan RETURN 

    UPDATE fp
    SET fp.ProductId = iteminfo.ProductId
    FROM #FinPlan                  AS fp
        INNER JOIN dbo.B20ItemInfo AS iteminfo (NOLOCK)
            ON fp.ItemId = iteminfo.ItemId;

    UPDATE fp
    SET fp.ProductCode = Product.Code
      , fp.ProductName = Product.Name
    FROM #FinPlan                 AS fp
        INNER JOIN dbo.B20Product AS Product (NOLOCK)
            ON Product.Id = fp.ProductId;
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#FinPlan'
                                           , @_List_Cats = 'Item'
                                           , @_SetString_Other = '
,kq.ItemType=Item.ItemType
,kq.ProductLineId=Item.ProductLineId
,kq.ProductGroupId=Item.ProductGroupId
,kq.ProductClassId=Item.ProductClassId
,kq.ProductLevelId=Item.ProductLevelId';

    EXECUTE dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#FinPlan'
                                              , @_List_Cats = 'ProductLine';
    EXECUTE dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#FinPlan'
                                              , @_List_Cats = 'ProductGroup';
    EXECUTE dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#FinPlan'
                                              , @_List_Cats = 'ProductClass';
    EXECUTE dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#FinPlan'
                                              , @_List_Cats = 'ProductLevel';
    DELETE #FinPlan
    WHERE ItemType <> 1;

    DELETE #FinPlan
    WHERE Quantity = 0;


    DECLARE @_FieldInsert VARCHAR(MAX)  = ''
          , @_FieldSelect VARCHAR(MAX)  = ''
          , @_strExec     NVARCHAR(MAX) = N'';
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
        SET @_strExec
            = N'INSERT INTO ' + @_CtTmp1 + N'(' + @_FieldInsert + N')' + CHAR(13) + N'SELECT ' + @_FieldSelect
              + CHAR(13) + N'FROM #FinPlan' + CHAR(13) + N'ORDER BY ItemCode ASC';
        EXEC sp_executesql @_strExec;
        RETURN;
    END;

    SELECT *
    FROM #FinPlan
    ORDER BY ItemCode ASC;


    DROP TABLE IF EXISTS #TblProductClass;
    SELECT Year
         , _Month
         , SUM(Quantity)   AS Quantity
         , SUM(Amount)     AS Amount
         , ProductClassId
         , ProductClassCode
         , ProductClassName
    INTO #TblProductClass
    FROM #FinPlan
    GROUP BY Year
           , _Month
           , ProductClassId
           , ProductClassCode
           , ProductClassName;

    IF ISNULL(@_CtTmp2, '') <> ''
    BEGIN
        SELECT @_FieldInsert = @_FieldInsert + ',' + RTRIM(Name)
        FROM
        (
            SELECT Name
            FROM tempdb.sys.Columns WITH (NOLOCK)
            WHERE OBJECT_ID = OBJECT_ID('Tempdb..' + @_CtTmp2)
                  AND name IN
                      (
                          SELECT Name
                          FROM tempdb.sys.Columns WITH (NOLOCK)
                          WHERE OBJECT_ID = OBJECT_ID('Tempdb..' + '#TblProductClass')
                      )
        ) AS tb1;

        SET @_FieldInsert = STUFF(@_FieldInsert, 1, 1, '');
        SET @_FieldSelect = @_FieldInsert;
        SET @_strExec
            = N'INSERT INTO ' + @_CtTmp2 + N'(' + @_FieldInsert + N')' + CHAR(13) + N'SELECT ' + @_FieldSelect
              + CHAR(13) + N'FROM #TblProductClass' + CHAR(13) + N' ';
        EXEC sp_executesql @_strExec;
        RETURN;

    END;

    /*Lấy Tổng doanh thu kế hoạch tháng tính kế hoạch Theo Mã Nhóm sản phẩm Hợp nhất cấp 2 */
    SELECT *
    FROM #TblProductClass;
    DROP TABLE IF EXISTS #FinPlan
                       , #TblProductClass;
END;
GO


SET DATEFORMAT DMY
EXEC usp_B30FinPlanDetail_PlannedOutputDetermination @_DocDate = '01/03/2026 00:00:00.000'
                                                   , @_Year = '2026'
                                                   , @_ItemId = NULL
                                                   , @_BranchCode = 'I09'