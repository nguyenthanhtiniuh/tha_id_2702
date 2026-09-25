 
 
-- ============================================         
-- Description: Bảng tổng hợp tài sản         
-- Trung đang sửa đổi         
-- 23/09/2011 : DqThắng Sửa giảm TSCĐ         
-- 20260921       
-- TINNT => hàm viết riêng để kế thừa dữ liệu các đơn vị A46,A70,A74,B13,B27,B73        
-- => dùng để Tổng hợp dữ liệu lên báo cáo thuyết minh Hợp nhất        
-- ============================================         
CREATE   PROCEDURE dbo.usp_Tth_AssetSummaryTable_inherit 
    @_DocDate1 SMALLDATETIME = '01/01/13' 
  , @_DocDate2 SMALLDATETIME = '03/31/13' 
  , @_AssetCode NVARCHAR(16) = N'' 
  , @_DeptCode NVARCHAR(16) = N'' 
  , @_ProductCostId NVARCHAR(24) = N'' 
  , @_ExpenseCatgCode NVARCHAR(16) = N'' 
  , @_AssetFuncCode NVARCHAR(16) = N'' 
  , @_DeprDebitAccount NVARCHAR(16) = N'' 
  , @_DeprCreditAccount NVARCHAR(16) = N'' 
  , @_AssetAccount NVARCHAR(16) = N'' 
  , @_ReportType CHAR(1) = N'1' 
  , @_ShownIncreaseDeprColumn TINYINT = 0 -- 18/06/2013 ThắngĐQ: Khấu hao trích trong kỳ (do phân bổ)         
  , @_GroupByExprs NVARCHAR(128) = '' 
  , @_nUserId AS INT = 0 
  , @_LangId INT = 0 
  , @_Note NVARCHAR(256) = '' OUTPUT 
  , @_BranchCode NCHAR(3) = N'A03' 
  , @_CurrencyCode0 NVARCHAR(3) = N'VND' 
  , @_BranchCode1 NVARCHAR(512) = '' 
  , @_Not_BranchCode1 NVARCHAR(512) = '' 
  , @_Not_BranchCode1Detail NVARCHAR(512) = '' 
  , @_IsGroupStageCode INT = 0 
     
AS 
BEGIN 
    SET NOCOUNT ON 
    DECLARE @_Key     NVARCHAR(2000) 
          , @_Key2    NVARCHAR(2000) 
          , @_StrTmp  NVARCHAR(3000) 
          , @_GroupBy NVARCHAR(128) 
 
    SET @_IsGroupStageCode = 0 
 
    SET @_Key = N'' 
    SET @_Key2 = N'' 
 
    IF @_AssetCode <> N'' 
       AND ISNULL(dbo.ufn_sys_IsGroup(@_AssetCode, N'B20Asset'), 0) <> 1 
    BEGIN 
        SET @_Key = @_Key + N' AND AssetCode LIKE N''' + RTRIM(@_AssetCode) + N'%''' 
    END 
 
    IF @_AssetCode <> N'' 
       AND ISNULL(dbo.ufn_sys_IsGroup(@_AssetCode, N'B20Asset'), 0) = 1 
    BEGIN 
        SET @_Key 
            = @_Key + N' AND (AssetCode IN (SELECT Ma FROM [dbo].[ufn_sys_GetDmDetail] (N''' + @_AssetCode 
              + N''', N''B20Asset'')))' 
    END 
 
    IF @_AssetAccount <> N'' 
        SET @_Key = @_Key + N' AND AssetAccount LIKE N''' + @_AssetAccount + N'%''' 
 
    SET @_Key = LTRIM(@_Key) 
    IF LEFT(@_Key, 3) = N'AND' 
        SET @_Key = SUBSTRING(@_Key, 4, LEN(@_Key) - 3) 
 
    SET @_Key2 = @_Key + CASE 
                             WHEN @_Key = '' THEN 
                                 '' 
                             ELSE 
                                 ' AND ' 
                         END + ' AssetTransType <> ''KHKHNAM'' ' 
 
    -- Đầu kỳ         
    IF OBJECT_ID('TempDb..#T_CdTmp') IS NOT NULL 
        DROP TABLE #T_CdTmp 
    SELECT TOP 0 
           CAST(0 AS INT)              AS Id 
         , IsGroup 
         , ParentId 
         , CAST('' AS NCHAR(3))        AS BranchCode 
         , Code 
         , CAST('' AS NVARCHAR(16))    AS IncrNo 
         , Name 
         , Unit 
         , CardNo 
         , MadeIn 
         , MadeYear 
         , Capacity 
         , UsefulYear 
         , AssetAccount 
         , FirstUsedDate 
         , FirstDeprDate 
         , CAST(NULL AS SMALLDATETIME) AS LastDeprDate 
         , CAST(0 AS NUMERIC(18, 2))   AS OriginalCost 
         , CAST(0 AS NUMERIC(18, 2))   AS Depreciation 
         , CAST(0 AS NUMERIC(18, 2))   AS NetBookValue 
         , CAST(0 AS NUMERIC(18, 2))   AS AmountForDepr 
         , CAST(0 AS NUMERIC(15))      AS Quantity 
         , CAST('' AS NCHAR(16))       AS EquityCode 
         , CAST('' AS NCHAR(24))       AS ProductCostId 
         , CAST('' AS NCHAR(16))       AS ExpenseCatgCode 
         , CAST('' AS NCHAR(16))       AS DeptCode 
         , CAST('' AS NCHAR(16))       AS DeprDebitAccount 
         , CAST('' AS NCHAR(16))       AS DeprCreditAccount 
         , CAST('' AS NCHAR(16))       AS ProfitCenterCode 
         , CAST('' AS NCHAR(16))       AS StageCode 
   , CAST('' AS NCHAR(16))       AS BranchCode2 
         , CAST('' AS NCHAR(16))       AS TransportType 
    INTO #T_CdTmp 
    FROM B20Asset 
 
    EXECUTE dbo.usp_B30AssetDoc_OpenAssetList @_DocDate0 = @_DocDate1 
                                            , @_Key = @_Key 
                                            , @_CtTmp = N'#T_CdTmp' 
                                            , @_nUserId = @_nUserId 
                                            , @_LangId = @_LangId 
                                            , @_BranchCode = @_BranchCode 
                                            , @_BranchCode1 = @_BranchCode1 
                                            , @_Not_BranchCode1 = @_Not_BranchCode1 
                                            , @_Not_BranchCode1Detail = @_Not_BranchCode1Detail 
 
 
 
    -- Cuối kỳ         
    IF OBJECT_ID('TempDb..#T_CdTmp2') IS NOT NULL 
        DROP TABLE #T_CdTmp2 
    SELECT TOP 0 
           CAST(0 AS INT)              AS Id 
         , IsGroup 
         , ParentId 
         , CAST('' AS NCHAR(3))        AS BranchCode 
         , Code 
         , CAST('' AS NVARCHAR(16))    AS IncrNo 
         , Name 
         , Unit 
         , CardNo 
         , MadeIn 
         , MadeYear 
         , Capacity 
         , UsefulYear 
         , AssetAccount 
         , FirstUsedDate 
         , FirstDeprDate 
         , CAST(NULL AS SMALLDATETIME) AS LastDeprDate 
         , CAST(0 AS NUMERIC(18, 2))   AS OriginalCost 
         , CAST(0 AS NUMERIC(18, 2))   AS Depreciation 
         , CAST(0 AS NUMERIC(18, 2))   AS NetBookValue 
         , CAST(0 AS NUMERIC(18, 2))   AS AmountForDepr 
         , CAST(0 AS NUMERIC(15))      AS Quantity 
         , CAST('' AS NCHAR(16))       AS EquityCode 
         , CAST('' AS NCHAR(24))       AS ProductCostId 
         , CAST('' AS NCHAR(16))       AS ExpenseCatgCode 
         , CAST('' AS NCHAR(16))       AS DeptCode 
         , CAST('' AS NCHAR(16))       AS DeprDebitAccount 
         , CAST('' AS NCHAR(16))       AS DeprCreditAccount 
         , CAST('' AS NCHAR(16))       AS ProfitCenterCode 
         , CAST('' AS NCHAR(16))       AS StageCode 
         , CAST('' AS NCHAR(16))       AS BranchCode2 
         , CAST('' AS NCHAR(16))       AS TransportType 
    INTO #T_CdTmp2 
    FROM B20Asset 
 
    EXECUTE dbo.usp_B30AssetDoc_CloseAssetList @_DocDate2 = @_DocDate2 
                                             , @_Key = @_Key 
                                             , @_CtTmp = N'#T_CdTmp2' 
                                             , @_nUserId = @_nUserId 
                                             , @_LangId = @_LangId 
                                             , @_BranchCode = @_BranchCode 
                                             , @_BranchCode1 = @_BranchCode1 
                                             , @_Not_BranchCode1 = @_Not_BranchCode1 
                                             , @_Not_BranchCode1Detail = @_Not_BranchCode1Detail 
 
    SELECT TOP 0 
           * 
    INTO #T_SoTmp9 
    FROM dbo.vB30AssetDoc 
 
    EXECUTE dbo.usp_B30AssetDoc_GetData @_Date1 = @_DocDate1 
                                      , @_Date2 = @_DocDate2 
                                      , @_Key1 = @_Key2 
                                      , @_CtTmp = N'#T_SoTmp9' 
                                      , @_nUserId = @_nUserId 
                                      , @_LangId = @_LangId 
                                      , @_BranchCode = @_BranchCode 
                                      , @_BranchCode1 = @_BranchCode1 
                                      , @_Not_BranchCode1 = @_Not_BranchCode1 
                                      , @_Not_BranchCode1Detail = @_Not_BranchCode1Detail 
 
    UPDATE #T_SoTmp9 
    SET AssetTransType = 'KHAUHAO' 
    WHERE isKH = 1 
          AND AssetTransType = '' 
 
    -- Lấy số phát sinh khấu hao         
    IF OBJECT_ID('TempDb..#T_KhTs') IS NOT NULL 
        DROP TABLE #T_KhTs 
    SELECT dmts.Id 
         , tb.AssetCode 
         , tb.EquityCode 
         , dmts.Name                AS AssetName 
         , dmts.AssetAccount 
         , MAX(tb.ProductCostId)    AS ProductCostId 
         , MAX(tb.DeptCode)         AS DeptCode 
         , MAX(tb.StageCode)        AS StageCode 
         , MAX(tb.ProfitCenterCode) AS ProfitCenterCode 
         , MAX(tb.BranchCode2)      AS BranchCode2 
         , SUM(   CASE 
                      WHEN tb.AssetTransType = 'KHAUHAO' 
                           OR 
                           ( 
                               tb.AssetTransType = '' 
                               AND AssetTransCode <> '' 
                           ) THEN 
                          CASE 
                              WHEN tb.Trans >= 0 THEN 
                                  tb.Depreciation 
                              ELSE 
                                  -tb.Depreciation 
                          END 
                      ELSE 
                          0 
                  END 
              )                     AS Depreciation_Tk 
         , SUM(tb.Depreciation)     AS Depreciation 
         , SUM(   CASE 
                      WHEN tb.AssetTransType = 'KHAUHAO' THEN 
                          tb.Depreciation 
                      ELSE 
                          0 
                  END 
              )                     AS IncreaseDeprAmount 
    INTO #T_KhTs 
    FROM #T_SoTmp9              AS tb 
        INNER JOIN dbo.B20Asset AS dmts 
            ON dmts.Code = tb.AssetCode 
    WHERE ( 
              tb.AssetTransType = 'KHAUHAO' 
              OR 
              ( 
                  tb.AssetTransType = '' 
                  AND tb.AssetTransCode <> '' 
                  AND tb.AssetTransType <> 'GIAMTAISAN' 
              ) 
          ) 
          AND tb.Depreciation <> 0 
    GROUP BY dmts.Id 
           , tb.AssetCode 
           , tb.EquityCode 
           , dmts.Name 
           , dmts.AssetAccount --, tb.DeptCode,Tb.StageCode,tb.ProductCostId,tb.ProfitCenterCode         
 
    IF ISNULL(@_IsGroupStageCode, 0) = 0 
    BEGIN 
        UPDATE #T_CdTmp 
        SET StageCode = '' 
        UPDATE #T_CdTmp2 
        SET StageCode = '' 
        UPDATE #T_SoTmp9 
        SET StageCode = '' 
        UPDATE #T_KhTs 
        SET StageCode = '' 
    END 
 
 
 
    IF OBJECT_ID('TempDb..#BcTmp1') IS NOT NULL 
        DROP TABLE #BcTmp1 
    SELECT tb.Id 
         , AssetCode 
         , tb.EquityCode 
         , AssetName 
         , AssetAccount 
         , MAX(tb.ProductCostId)     AS ProductCostId 
         , MAX(tb.DeptCode)          AS DeptCode 
         , MAX(tb.StageCode)         AS StageCode 
         , MAX(tb.ProfitCenterCode)  AS ProfitCenterCode 
         , MAX(tb.BranchCode2)       AS BranchCode2 
         , MAX(tb.Quantity)          AS Quantity 
         , SUM(tb.OriginalCost1)     AS OriginalCost1 
         , SUM(tb.Depreciation1)     AS Depreciation1 
         , SUM(tb.NetBookValue1)     AS NetBookValue1 
         , CAST(0 AS NUMERIC(18, 2)) AS Depreciation_Tk 
         , CAST(0 AS NUMERIC(18, 2)) AS Depreciation 
         , CAST(0 AS NUMERIC(18, 2)) AS IncreaseDeprAmount 
         , SUM(tb.OriginalCost2)     AS OriginalCost2 
         , SUM(tb.Depreciation2)     AS Depreciation2 
         , SUM(tb.NetBookValue2)     AS NetBookValue2 
         , MIN(tb.zType)             AS zType 
    INTO #BcTmp1 
    FROM 
    ( 
        SELECT Id 
             , Code                      AS AssetCode 
             , Name                      AS AssetName 
             , EquityCode 
             , AssetAccount 
             , ProductCostId 
             , DeptCode 
             , StageCode 
             , ProfitCenterCode 
             , BranchCode2 
             , Quantity 
             , OriginalCost              AS OriginalCost1 
             , Depreciation              AS Depreciation1 
             , NetBookValue              AS NetBookValue1 
             , CAST(0 AS NUMERIC(18, 2)) AS OriginalCost2 
             , CAST(0 AS NUMERIC(18, 2)) AS Depreciation2 
             , CAST(0 AS NUMERIC(18, 2)) AS NetBookValue2 
             , 1                         AS zType 
        FROM #T_CdTmp 
        UNION ALL 
        SELECT Id 
             , Code                      AS AssetCode 
             , Name                      AS AssetName 
             , EquityCode 
             , AssetAccount 
             , ProductCostId 
             , DeptCode 
             , StageCode 
             , ProfitCenterCode 
             , BranchCode2 
             , Quantity 
             , CAST(0 AS NUMERIC(18, 2)) AS OriginalCost1 
             , CAST(0 AS NUMERIC(18, 2)) AS Depreciation1 
             , CAST(0 AS NUMERIC(18, 2)) AS NetBookValue1 
             , OriginalCost              AS OriginalCost2 
             , Depreciation              AS Depreciation2 
             , NetBookValue              AS NetBookValue2 
             , 0                         AS zType 
        FROM #T_CdTmp2 
    ) AS tb 
    GROUP BY tb.Id 
           , tb.AssetCode 
           , tb.EquityCode 
           , tb.AssetName 
           , tb.AssetAccount 
 
    EXECUTE dbo.usp_sys_DefaultTable N'#BcTmp1' 
 
    INSERT INTO #BcTmp1 
    ( 
        Id 
      , AssetCode 
      , EquityCode 
      , AssetName 
      , AssetAccount 
      , ProductCostId 
      , DeptCode 
      , StageCode 
      , ProfitCenterCode 
      , BranchCode2 
    ) 
    SELECT Id 
         , AssetCode 
         , EquityCode 
         , AssetName 
         , AssetAccount 
         , ProductCostId 
         , DeptCode 
         , StageCode 
         , ProfitCenterCode 
         , BranchCode2 
    FROM #T_KhTs 
    EXCEPT 
    SELECT Id 
         , AssetCode 
         , EquityCode 
         , AssetName 
         , AssetAccount 
         , ProductCostId 
         , DeptCode 
         , StageCode 
         , ProfitCenterCode 
         , BranchCode2 
    FROM #BcTmp1 
 
    UPDATE #BcTmp1 
    SET Depreciation_Tk = tb.Depreciation_Tk 
      , Depreciation = tb.Depreciation 
      , IncreaseDeprAmount = tb.IncreaseDeprAmount 
    FROM #BcTmp1           AS bc 
        INNER JOIN #T_KhTs AS tb 
            ON bc.AssetCode = tb.AssetCode 
               AND bc.DeptCode = tb.DeptCode 
               AND bc.ProductCostId = tb.ProductCostId 
               AND tb.EquityCode = bc.EquityCode 
               AND bc.ProfitCenterCode = tb.ProfitCenterCode 
               AND bc.BranchCode2 = tb.BranchCode2 
 
    IF OBJECT_ID('TempDb..#T_KhTs') IS NOT NULL 
        DROP TABLE #T_KhTs 
    IF OBJECT_ID('TempDb..#T_CdTmp') IS NOT NULL 
        DROP TABLE #T_CdTmp 
    IF OBJECT_ID('TempDb..#T_CdTmp2') IS NOT NULL 
        DROP TABLE #T_CdTmp2 
 
    IF @_DeptCode <> N'' 
        IF NOT EXISTS 
        ( 
            SELECT Code 
            FROM dbo.B20Dept 
            WHERE Code = RTRIM(@_DeptCode) 
        ) 
            DELETE FROM #BcTmp1 
            WHERE DeptCode NOT LIKE @_DeptCode + '%' 
        ELSE IF dbo.ufn_sys_IsGroup(@_DeptCode, 'B20Dept') <> 1 
            DELETE FROM #BcTmp1 
            WHERE NOT DeptCode = @_DeptCode 
        ELSE 
            DELETE FROM #BcTmp1 
            FROM #BcTmp1 
            WHERE (DeptCode IN 
                   ( 
                       SELECT Ma FROM dbo.ufn_sys_GetDmDetail(@_DeptCode, N'B20Dept') 
                   ) 
                  ) 
 
    IF @_AssetFuncCode <> '' 
        DELETE FROM #BcTmp1 
        FROM #BcTmp1                     AS tb 
            LEFT OUTER JOIN dbo.B20Asset AS dm 
                ON tb.AssetCode = dm.Code 
        WHERE NOT dm.AssetFuncCode = @_AssetFuncCode 
 
 
    -- Xử lý nhóm         
    IF CHARINDEX(N'DeptCode', N',' + @_GroupByExprs) = 0 
    BEGIN 
        UPDATE #BcTmp1 
        SET DeptCode = tb.DeptCode 
        FROM #BcTmp1 AS bc 
            OUTER APPLY 
        ( 
            SELECT TOP 1 
                   tb.DeptCode 
            FROM #BcTmp1 AS tb 
            WHERE bc.Id = tb.Id 
  ORDER BY tb.zType 
        )            AS tb 
    END 
 
    -- Xử lý nhóm         
    IF CHARINDEX(N'EquityCode', N',' + @_GroupByExprs) = 0 
    BEGIN 
        UPDATE #BcTmp1 
        SET EquityCode = '' 
    END 
 
    IF OBJECT_ID('TempDb..#BcTmp') IS NOT NULL 
        DROP TABLE #BcTmp 
    SELECT bc.Id 
         , AssetCode 
         , bc.EquityCode 
         , AssetName 
         , AssetAccount 
         , MAX(bc.ProductCostId)                         AS ProductCostId 
         , MAX(bc.DeptCode)                              AS DeptCode 
         , MAX(bc.StageCode)                             AS StageCode 
         , MAX(bc.ProfitCenterCode)                      AS ProfitCenterCode 
         , MAX(bc.BranchCode2)                           AS BranchCode2 
         , MAX(bc.Quantity)                              AS Quantity 
         , SUM(bc.OriginalCost1)                         AS OriginalCost1 
         , SUM(bc.Depreciation1)                         AS Depreciation1 
         , SUM(bc.NetBookValue1)                         AS NetBookValue1 
         , SUM(bc.Depreciation_Tk)                       AS Depreciation_Tk 
         , SUM(bc.Depreciation)                          AS Depreciation 
         , SUM(bc.IncreaseDeprAmount)                    AS IncreaseDeprAmount 
         , SUM(bc.OriginalCost2)                         AS OriginalCost2 
         , SUM(bc.Depreciation2)                         AS Depreciation2 
         , SUM(bc.NetBookValue2)                         AS NetBookValue2 
         , CAST(0 AS TINYINT)                            AS Level 
         , CAST('' AS CHAR(1))                           AS Bold 
         , CAST(0 AS TINYINT)                            AS IsGroup 
         , CAST(0 AS INT)                                AS ParentId 
         , CAST('' AS NVARCHAR(24))                      AS ProductCode 
         , CAST('' AS NVARCHAR(256))                     AS ProductName 
         , CAST('' AS SMALLDATETIME)                     AS FirstDeprDate 
         , CAST('' AS NVARCHAR(24))                      AS Unit 
         , CAST('' AS NVARCHAR(3))                       AS BranchCode 
         , CAST('' AS NVARCHAR(64))                      AS _FormatStyleKey 
         , CAST('' AS NVARCHAR(64))                      AS _ParentIdList 
         , CAST('' AS VARCHAR(64))                       AS _GroupOrder 
         , CAST('' AS VARCHAR(16))                       AS ExpenseCatgCode 
         , CAST('' AS NVARCHAR(200))                     AS ChassisNumber 
         , CAST('' AS NVARCHAR(200))                     AS NumberPlate 
         , CAST('' AS NVARCHAR(500))                     AS Comment 
         , CAST('' AS VARCHAR(16))                       AS AssetFuncCode 
         , CAST('' AS NVARCHAR(128))                     AS AssetFuncName 
         , CAST('' AS VARCHAR(16))                       AS ParentCode 
         , CAST('' AS VARCHAR(16))                       AS AssetTransCode 
         , CAST(SUM(bc.OriginalCost1) AS NUMERIC(18, 2)) AS IncreaseOriginalCost 
         , CAST(SUM(bc.OriginalCost1) AS NUMERIC(18, 2)) AS DecreaseOriginalCost 
         , CAST(SUM(bc.Depreciation1) AS NUMERIC(18, 2)) AS IncreaseDepreciation 
         , CAST(SUM(bc.Depreciation1) AS NUMERIC(18, 2)) AS DecreaseDepreciation 
    INTO #BcTmp 
    FROM #BcTmp1 AS bc 
    GROUP BY bc.Id 
           , bc.AssetCode 
           , bc.EquityCode 
           , bc.AssetName 
           , bc.AssetAccount 
           , bc.DeptCode 
           , bc.StageCode 
 
    UPDATE #BcTmp 
    SET IsGroup = dm.IsGroup 
      , ParentId = dm.ParentId 
      , Unit = dm.Unit 
      , FirstDeprDate = dm.FirstDeprDate 
      , ChassisNumber = dm.ChassisNumber 
      , NumberPlate = dm.NumberPlate 
      , Comment = dm.Comment 
    FROM #BcTmp             AS bc 
        INNER JOIN b20Asset AS dm 
            ON bc.AssetCode = dm.Code 
 
    IF OBJECT_ID('TempDb..#BcTmp1') IS NOT NULL 
        DROP TABLE #BcTmp1 
 
    -- them doan nay de xoa cac tai san da het khau hao          
 
    DELETE FROM #BcTmp 
    WHERE Depreciation = 0 
          AND OriginalCost2 = 0 
          AND NetBookValue2 = 0 
          AND OriginalCost1 = 0 
          AND NetBookValue2 = 0 
    -- Tạo cây         
    IF OBJECT_ID(N'tempdb..#Tree') IS NOT NULL 
        DROP TABLE #Tree 
    SELECT TOP 0 
           CAST(_GroupOrder AS NVARCHAR(24)) AS _GroupOrder 
         , CAST(N'' AS NVARCHAR(254))        AS AssetName 
    INTO #Tree 
    FROM dbo.vB20Asset 
 
    IF @_GroupByExprs = N'DeptCode' 
    BEGIN 
        UPDATE #BcTmp 
        SET _GroupOrder = RTRIM(DeptCode) 
 
        INSERT INTO #Tree 
        SELECT Code 
             , Code + ' - ' + Name 
        FROM vB20Dept 
    END 
    ELSE IF @_GroupByExprs = N'AssetAccount' 
    BEGIN 
        UPDATE #BcTmp 
        SET _GroupOrder = Dm.ParentIdList + CASE 
                                                WHEN ISNULL(Dm.ParentIdList, '') = '' THEN 
                                                    '' 
                                                ELSE 
                                                    ',' 
                                            END + RTRIM(Dm.GroupOrder) 
        FROM #BcTmp 
            LEFT OUTER JOIN vB20ChartOfAccount0_TreeView AS Dm 
                ON #BcTmp.AssetAccount = Dm.Code 
 
        --CUONGNC: 24/07/2014 Them ngon ngu         
        INSERT INTO #Tree 
        SELECT _GroupOrder 
             , CASE 
                   WHEN @_LangId = 1 THEN 
                       Name_English 
                   WHEN @_LangId = 2 THEN 
                       Name_French 
                   WHEN @_LangId = 3 THEN 
                       Name_Japanese 
                   WHEN @_LangId = 4 THEN 
                       Name_Chinese 
                   WHEN @_LangId = 5 THEN 
                       Name_Custom 
                   ELSE 
                       Name 
               END 
        FROM vB20ChartOfAccount0 
    END 
    ELSE IF @_GroupByExprs = N'EquityCode' 
    BEGIN 
        UPDATE #BcTmp 
        SET _GroupOrder = EquityCode 
 
        INSERT INTO #Tree 
        SELECT Code 
             , Code + ' - ' + Name 
        FROM B20Equity 
    END 
    ELSE 
    BEGIN 
        UPDATE #BcTmp 
        SET Id = Dm.Id 
          , _GroupOrder = Dm.ParentIdList 
        FROM #BcTmp 
            LEFT OUTER JOIN vB20Asset_TreeView AS Dm 
                ON #BcTmp.AssetCode = Dm.Code 
 
        INSERT INTO #Tree 
        SELECT _GroupOrder 
             , Code + ' - ' + Name 
        FROM dbo.vB20Asset 
        WHERE IsGroup = 1 
        ORDER BY Code 
    END 
 
    ALTER TABLE #BcTmp 
    ADD AssetCode_B63 NVARCHAR(16) 
      , DocDate DATETIME 
      , UsefulMonth INT 
      , DeprDebitAccount NVARCHAR(16) 
      , DeprCreditAccount NVARCHAR(16) 
            DEFAULT 0 NOT NULL 
 
    UPDATE #BcTmp 
    SET AssetCode_B63 = Asset.AssetCodeB63 
      , BranchCode = Asset.BranchCode 
      , AssetFuncCode = Asset.AssetFuncCode 
    FROM #BcTmp             AS T 
        INNER JOIN B20Asset AS Asset 
            ON T.AssetCode = Asset.Code 
 
    UPDATE #BcTmp 
    SET ProductCode = P.Code 
      , ProductName = P.Name 
    FROM #BcTmp               AS T1 
        INNER JOIN B20Product AS P 
            ON T1.ProductCostId = P.RowId 
 
    -- thêm các cột sản lượng công suất         
    ALTER TABLE #BcTmp 
    ADD UsefulMonthbd NUMERIC(18, 0) 
      , QuantityCapacity NUMERIC(18, 2) 
      , QuantityCap_Cost NUMERIC(18, 4) 
      , SlKhThang NUMERIC(18, 4) 
            DEFAULT 0 
      , SlLuyKe NUMERIC(18, 4) 
            DEFAULT 0 
      , SlConLai NUMERIC(18, 4) 
 
    --quanhp: tính thời gian khấu hao         
    UPDATE #BcTmp 
    SET UsefulMonth = T2.UsefulMonth 
      , UsefulMonthbd = T2.UsefulMonth 
    FROM #BcTmp AS T 
        INNER JOIN 
        ( 
            SELECT Code 
                 , (UsefulYear * 12) + UsefulMonth AS UsefulMonth 
            FROM B20Asset 
        )       AS T2 
        ON T.AssetCode = T2.Code 
 
 
    IF OBJECT_ID('TempDb..#Tgbs') IS NOT NULL 
        DROP TABLE #Tgbs 
 
    SELECT AssetCode 
         , IncrNo 
         , SUM(Trans * UsefulMonth)                                              AS UsefulMonth 
         , ROW_NUMBER() OVER (PARTITION BY AssetCode ORDER BY AssetCode, IncrNo) AS _Stt 
    INTO #Tgbs 
    FROM dbo.vB30AssetDoc 
    WHERE AssetCode IN 
          ( 
              SELECT AssetCode FROM #BcTmp 
          ) 
          AND IsActive = 1 
          AND DocDate <= @_DocDate2 
          AND AssetTransType NOT IN ( 'KHAUHAO' ) --AND IncrNo='001'         
    GROUP BY AssetCode 
           , IncrNo 
 
    UPDATE #BcTmp 
    SET UsefulMonth = T1.UsefulMonthbd + ISNULL(t2.UsefulMonth, 0) 
    FROM #BcTmp          AS T1 
        INNER JOIN #Tgbs AS t2 
            ON T1.AssetCode = t2.AssetCode 
               AND t2._Stt = 1 
 
    IF OBJECT_ID('TempDb..#Tgbs') IS NOT NULL 
        DROP TABLE #Tgbs 
 
    UPDATE #BcTmp 
    SET QuantityCapacity = ISNULL(ct.QuantityCapacity, 0) 
    FROM #BcTmp                                AS t1 
        LEFT OUTER JOIN dbo.vB30AssetDoc_Trans AS ct 
            ON t1.AssetCode = ct.AssetCode 
 
    UPDATE #BcTmp 
    SET QuantityCap_Cost = OriginalCost2 / QuantityCapacity 
    WHERE QuantityCapacity <> 0 
 
    UPDATE #BcTmp 
    SET SlKhThang = ISNULL(Depreciation, 0) / ISNULL(QuantityCap_Cost, 0) 
    WHERE QuantityCap_Cost <> 0 
 
    UPDATE #BcTmp 
    SET SlLuyKe = Depreciation2 / ISNULL(QuantityCap_Cost, 0) 
    WHERE QuantityCap_Cost <> 0 
 
    UPDATE #BcTmp 
    SET SlConLai = ISNULL(QuantityCapacity, 0) - ISNULL(SlLuyKe, 0) 
 
    UPDATE #BcTmp 
    SET DocDate = T2.DocDate 
      , DeprDebitAccount = T2.DebitAccount 
      , DeprCreditAccount = T2.CreditAccount 
      , StageCode = T2.StageCode 
      , DeptCode = T2.DeptCode 
    FROM #BcTmp AS T 
        INNER JOIN 
        ( 
            SELECT AssetCode 
                 , MIN(Docdate)           AS DocDate 
                 , MAX(DeprDebitAccount)  AS DebitAccount 
                 , MAX(DeprCreditAccount) AS CreditAccount 
                 , MAX(StageCode)         AS StageCode 
                 , MAX(DeptCode)          AS DeptCode 
            FROM B30AssetDoc 
            WHERE IsActive = 1 
                  AND DocGroup = 1 
                  AND AssetTransType <> 'KHAUHAO' 
                  AND AssetCode IN 
                      ( 
                          SELECT AssetCode FROM #BcTmp 
                      ) 
            GROUP BY AssetCode 
        )       AS T2 
            ON T.AssetCode = T2.AssetCode 
 
    --quanhp: 						         
    UPDATE #BcTmp 
    SET DeprDebitAccount = ISNULL(T2.DeprDebitAccount, '') 
      , DeprCreditAccount = ISNULL(T2.DeprCreditAccount, '') 
    FROM #BcTmp AS T 
        OUTER APPLY 
    ( 
        SELECT TOP 1 
               AssetCode 
             , DeprDebitAccount 
             , DeprCreditAccount 
        FROM B30AssetDoc WITH (NOLOCK) 
        WHERE IsActive = 1 
              AND AssetTransType = 'KHAUHAO' 
              AND AssetCode = T.AssetCode 
              AND DocDate <= @_DocDate2 
              AND DeprDebitAccount <> '' 
        ORDER BY DocDate DESC 
    )           AS T2 
 
    --quanhp: lay ma khoan muc phi moi nhat           
    IF OBJECT_ID('TempDb..#laysl') IS NOT NULL 
        DROP TABLE #laysl 
    SELECT BranchCode 
         , AssetCode 
         , MAX(DocDate)          AS DocDate 
         , MAX(ExpenseCatgCode)  AS ExpenseCatgCode 
         , MIN(DocDateIncr)      AS DocDateIncr 
         , MAX(ProfitCenterCode) AS ProfitCenterCode 
         , MAX(DeptCode)         AS DeptCode 
         , MAX(UsefulMonth)      AS UseFulMonth -- duyenttm         
    INTO #laysl 
    FROM B30AssetDoc 
    WHERE AssetCode IN 
          ( 
              SELECT DISTINCT AssetCode FROM #BcTmp 
          ) 
          AND DocDate <= @_DocDate2 
          AND AssetTransType <> N'KHAUHAO' 
          AND DocGroup IN ( 1, 3 ) 
          AND DeprAllocationRate = 0 
          AND IsActive = 1 
    GROUP BY BranchCode 
           , AssetCode 
    ORDER BY BranchCode 
           , AssetCode 
 
    UPDATE #laysl 
    SET ExpenseCatgCode = t2.ExpenseCatgCode 
      , ProfitCenterCode = t2.ProfitCenterCode 
      , DeptCode = t2.DeptCode 
    FROM #laysl                AS t1 
        INNER JOIN B30AssetDoc AS t2 
            ON t1.BranchCode = t2.BranchCode 
               AND t1.AssetCode = t2.AssetCode 
               AND t1.DocDate = t2.DocDate 
               AND t2.AssetTransType <> 'KHAUHAO' 
               AND t2.DocGroup IN ( 1, 3 ) 
               AND t2.AssetTransCode <> '' 
               AND t2.IsActive = 1 
 
    UPDATE #BcTmp 
    SET ExpenseCatgCode = t2.ExpenseCatgCode 
      , ProfitCenterCode = t2.ProfitCenterCode 
      , DeptCode = t2.DeptCode 
    FROM #BcTmp           AS t1 
        INNER JOIN #laysl AS t2 
            ON t1.AssetCode = t2.AssetCode 
 
    DROP TABLE #laysl 
 
    --quanhp: lay thong tin khau hao gan nhat           
    IF OBJECT_ID('TempDb..#laysl_khauhao') IS NOT NULL 
        DROP TABLE #laysl_khauhao 
    SELECT BranchCode 
         , AssetCode 
         , MAX(DocDate)          AS DocDate 
         , MAX(ExpenseCatgCode)  AS ExpenseCatgCode 
         , MIN(DocDateIncr)      AS DocDateIncr 
         , MAX(ProfitCenterCode) AS ProfitCenterCode 
         , MAX(DeptCode)         AS DeptCode 
         , MAX(StageCode)        AS StageCode -- duyenttm         
    INTO #laysl_khauhao 
    FROM B30AssetDoc WITH (NOLOCK) 
    WHERE AssetCode IN 
          ( 
              SELECT DISTINCT AssetCode FROM #BcTmp 
          ) 
          AND DocDate <= @_DocDate2 
          AND AssetTransType = N'KHAUHAO' 
          AND IsActive = 1 
    GROUP BY BranchCode 
           , AssetCode 
    ORDER BY BranchCode 
           , AssetCode 
 
    UPDATE #laysl_khauhao 
    SET StageCode = t2.StageCode 
      , DeptCode = t2.DeptCode --,ProfitCenterCode=t2.ProfitCenterCode,DeptCode=t2.DeptCode         
    FROM #laysl_khauhao        AS t1 
        INNER JOIN B30AssetDoc AS t2 WITH (NOLOCK) 
            ON t1.BranchCode = t2.BranchCode 
               AND t1.AssetCode = t2.AssetCode 
               AND t1.DocDate = t2.DocDate 
               AND t2.AssetTransType = 'KHAUHAO' 
               AND t2.IsActive = 1 
 
    UPDATE #BcTmp 
    SET StageCode = t2.StageCode 
      , DeptCode = t2.DeptCode 
    FROM #BcTmp                   AS t1 
        INNER JOIN #laysl_khauhao AS t2 
            ON t1.AssetCode = t2.AssetCode 
 
    DROP TABLE #laysl_khauhao 
 
    IF OBJECT_ID('TempDb..#layslngaytang') IS NOT NULL 
        DROP TABLE #layslngaytang 
    SELECT BranchCode 
         , AssetCode 
         , MIN(DocDate)        AS DocDate 
         , MIN(DocDateIncr)    AS DocDateIncr 
         , MIN(AssetTransCode) AS AssetTransCode 
    INTO #layslngaytang 
    FROM b30assetdoc 
    WHERE AssetTransType = '' 
          AND DocGroup = 1 
          AND IncrNo <> '' 
          AND AssetTransCode <> '' 
          AND AssetCode IN 
              ( 
                  SELECT DISTINCT AssetCode FROM #BcTmp 
              ) 
          AND IsActive = 1 
    GROUP BY BranchCode 
           , AssetCode 
    ORDER BY BranchCode 
           , AssetCode 
 
    UPDATE #BcTmp 
    SET Docdate = t2.DocDateIncr 
      , FirstDeprDate = t2.DocDate 
      , AssetTransCode = t2.AssetTransCode 
    FROM #BcTmp                   AS t1 
        INNER JOIN #layslngaytang AS t2 
            ON t1.AssetCode = t2.AssetCode 
               AND t1.BranchCode = t2.BranchCode 
 
    DROP TABLE #layslngaytang 
 
    SELECT @_Note = '' 
    IF EXISTS 
    ( 
        SELECT * 
        FROM #BcTmp 
        WHERE Depreciation < 0 
              OR NetBookValue2 < 0 
    ) 
    BEGIN 
        SET @_Note = N'Tồn tại tài sản có giá trị khấu hao < 0 hoặc giá trị còn lại cuối kỳ <0' 
    END 
 
    UPDATE #BcTmp 
    SET _FormatStyleKey = 'RedColor' 
    WHERE Depreciation < 0 
          OR NetBookValue2 < 0 
 
 
    UPDATE #BcTmp 
    SET AssetFuncName = dm.Name 
    FROM #BcTmp                 AS kq 
        INNER JOIN B20AssetFunc AS dm 
            ON kq.AssetFuncCode = dm.Code 
 
    UPDATE #BcTmp 
    SET ParentCode = ag.Code 
    FROM #BcTmp             AS bc 
        INNER JOIN b20asset AS ag 
            ON ag.IsGroup = 1 
               AND bc.ParentId = ag.Id 
 
    ALTER TABLE #T_SoTmp9 ADD Type NVARCHAR(24) 
 
    UPDATE #T_SoTmp9 
    SET Type = IIF(Trans = '1', '1', '2'); 
    WITH CTE 
    AS (SELECT b.AssetCode 
             , IIF(b.Type = 2, SUM(b.OriginalCost), 0) AS DecreaseOriginalCost 
             , IIF(b.Type = 1, SUM(b.OriginalCost), 0) AS IncreaseOriginalCost 
             , IIF(b.Type = 2, SUM(b.Depreciation), 0) AS DecreaseDepreciation 
             , IIF(b.Type = 1, SUM(b.Depreciation), 0) AS IncreaseDepreciation 
        FROM #T_SoTmp9 AS b 
        GROUP BY b.AssetCode 
               , b.Type) 
    UPDATE #BcTmp 
    SET DecreaseOriginalCost = b.DecreaseOriginalCost 
      , IncreaseOriginalCost = b.IncreaseOriginalCost 
      , DecreaseDepreciation = b.DecreaseDepreciation 
      , IncreaseDepreciation = b.IncreaseDepreciation 
    FROM #BcTmp AS a 
        LEFT OUTER JOIN 
        ( 
            SELECT CTE.AssetCode 
                 , SUM(CTE.DecreaseOriginalCost) AS DecreaseOriginalCost 
                 , SUM(CTE.IncreaseOriginalCost) AS IncreaseOriginalCost 
                 , SUM(CTE.DecreaseDepreciation) AS DecreaseDepreciation 
                 , SUM(CTE.IncreaseDepreciation) AS IncreaseDepreciation 
            FROM CTE 
            GROUP BY CTE.AssetCode 
        )       AS b 
            ON a.AssetCode = b.AssetCode 
 
    SELECT bc.* 
         , ROW_NUMBER() OVER (ORDER BY bc._GroupOrder, bc.AssetCode) AS Order1 
         , @_DocDate1                                                AS DocDate1 
         , @_DocDate2                                                AS DocDate2 
         , 'B7'                                                      AS DataSourceVer 
         , -1                                                        AS CreatedBy 
         , GETUTCDATE()                                              AS CreatedAt 
         , -1                                                        AS ModifiedBy 
         , GETUTCDATE()                                              AS ModifiedAt 
    FROM #BcTmp AS bc 
    --WHERE NetBookValue2<>0       
    ORDER BY bc._GroupOrder 
           , bc.AssetCode 
 
    IF OBJECT_ID('TempDb..#BcTmp') IS NOT NULL 
        DROP TABLE #BcTmp 
    IF OBJECT_ID('TempDb..#Tree') IS NOT NULL 
        DROP TABLE #Tree 
 
 
END  