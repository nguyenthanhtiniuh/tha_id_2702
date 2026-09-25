SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Coder: DucCM    
-- Manager: ThangNH
CREATE OR ALTER   PROCEDURE [dbo].[usp_Tth_ToolInstrumentAllocationCalc] 
    @_DocDate1          DATE            = N'Jan 01 2001'    
   ,@_DocDate2          DATE            = N'Dec 31 2019'    
   ,@_AssetId           VARCHAR(512)    = N''    
   ,@_lookupModeAsset   TINYINT         = 0    
   ,@_DeptId            VARCHAR(512)    = N''    
   ,@_AssetAccount      VARCHAR(24)     = N''    
   ,@_DeprDebitAccount  VARCHAR(24)     = N''    
   ,@_DeprCreditAccount VARCHAR(24)     = N''   OUTPUT 
   ,@_nUserId           INT             = 0    
   ,@_LangId            INT             = 1    
   ,@_CurrencyCode0     CHAR(3)         = 'VND'    
   ,@_BranchCode        VARCHAR(3)      = N'A01'    
   ,@_DataCode          VARCHAR(8)      = ''    
   ,@_IsHide            INT             = 0    
   ,@_LAYOUT_XML        NVARCHAR(MAX)   = N'' OUTPUT    
   ,@_CheckBC           TINYINT         = 0    
   ,@_DeprMethod        INT             = NULL    
   ,@_GroupByExprs      NVARCHAR(128)   = ''    
   ,@_TableTemp         NVARCHAR(128)   = ''    
   ,@_BranchReportId    INT             = NULL           
AS    
BEGIN    
    SET NOCOUNT ON;    
	DECLARE @_strExec           NVARCHAR(MAX) = N''
		, @_Declare           NVARCHAR(MAX) = N''
		, @_StrTmp            NVARCHAR(MAX) = N''
		, @_nl                CHAR(1)       = CHAR(10)
		, @_BranchCode_Filter VARCHAR(3)    = N''
		, @_DataCode_Filter   VARCHAR(4)    = N''

    IF @_DataCode = ''    
    BEGIN    
        SELECT TOP 1 @_DataCode = DataCode    
        FROM dbo.B00Branch    
        WHERE BranchCode = @_BranchCode    
    END    
  
    IF @_nUserId = -1 OR @_nUserId IS NULL    
        SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);    
  
    IF ISNULL(@_BranchCode, '') = ''    
        SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode);    
  
    DECLARE @_Key1 NVARCHAR(MAX) = N''    
  
    IF @_AssetAccount <> ''    
        SET @_Key1 = @_Key1 + N' AND AssetAccount LIKE ''' + @_AssetAccount + N'%'''    
  
    IF @_DeprDebitAccount <> ''    
        SET @_Key1 = @_Key1 + N' AND DeprDebitAccount LIKE ''' + @_DeprDebitAccount + N'%'''    
  
    IF @_DeprCreditAccount <> ''    
        SET @_Key1 = @_Key1 + N' AND DeprCreditAccount LIKE ''' + @_DeprCreditAccount + N'%'''    
  
    DROP TABLE IF EXISTS #_AssetFilter;    
    CREATE TABLE #_AssetFilter (Id INT);    
  
    IF @_AssetId <> N''    
    BEGIN    
        EXECUTE dbo.usp_sys_GenKey    
             @_Code      = @_AssetId    
            ,@_ColGen    = 'AssetId'    
            ,@_ColName   = 'Id'    
            ,@_TableName = 'B20Asset'    
            ,@_BranchCode = @_BranchCode    
            ,@_AndOrKey  = 'AND'    
            ,@_Key       = @_Key1 OUTPUT    
  
        INSERT INTO #_AssetFilter    
        SELECT * FROM STRING_SPLIT(@_AssetId, ',')    
    END    
  
    IF @_DeptId <> N''    
    BEGIN    
        EXECUTE dbo.usp_sys_GenKey    
             @_Code      = @_DeptId    
            ,@_ColGen    = 'DeptId'    
            ,@_ColName   = 'Id'    
            ,@_TableName = 'B20Dept'    
            ,@_AndOrKey  = 'AND'    
            ,@_Key       = @_Key1 OUTPUT    
    END    
  
    IF @_Key1 <> ''    
        SET @_Key1 = STUFF(@_Key1, 1, 5, '')    
  
    IF OBJECT_ID('TempDb..#CtTmp', 'U') IS NOT NULL    
        DROP TABLE #CtTmp    
  
    SELECT TOP 0 *, CAST(1 AS SMALLINT) AS _Head, CAST('' AS VARCHAR(24)) AS _AssetCode    
    INTO #CtTmp    
    FROM vB30AssetDoc    
     
    EXECUTE dbo.usp_sys_DefaultTable N'#CtTmp'    
	  
	--Lấy tất cả dữ liệu Khấu hao CCDC tới ngày DocDate2
    EXECUTE dbo.usp_B30AssetDoc_GetData    
             @_Date1          = ''    
            ,@_Date2          = @_DocDate2    
            ,@_AssetType      = 1    
            ,@_Key1           = @_Key1    
            ,@_CtTmp          = N'#CtTmp'    
            ,@_nUserId        = @_nUserId    
            ,@_LangId         = @_LangId    
            ,@_BranchCode     = @_BranchCode    
            ,@_BranchReportId = @_BranchReportId  
			,@_PRINT_Exec = 0	
 
	DECLARE @_DataCodeList TABLE
	(
		DataCode VARCHAR(8)
	  , BranchCode VARCHAR(3)
	  , Tinh NVARCHAR(1)
			DEFAULT ''
	)
	DECLARE @_BranchCode0 VARCHAR(3) = ''


	IF ISNULL(@_BranchReportId, 0) <> 0
	BEGIN
		DROP TABLE IF EXISTS #BranchCode0
		SELECT a.BranchCode0
		INTO #BranchCode0
		FROM dbo.B20BranchReportDetail     AS a
			INNER JOIN dbo.B20BranchReport AS b
				ON a.BranchReportId = b.Id
		WHERE b.Id = @_BranchReportId

		WHILE EXISTS (SELECT * FROM #BranchCode0)
		BEGIN
			SELECT TOP 1
				   @_BranchCode0 = BranchCode0
			FROM #BranchCode0
			DELETE #BranchCode0
			WHERE BranchCode0 = @_BranchCode0

			INSERT INTO @_DataCodeList
			(
				BranchCode
			  , DataCode
			)
			SELECT BranchCode
				 , DataCode
			FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode0)
			WHERE BranchCode NOT IN
				  (
					  SELECT BranchCode FROM @_DataCodeList
				  )
		END

		DROP TABLE IF EXISTS #BranchCode0
	END
	ELSE
	BEGIN
		INSERT INTO @_DataCodeList
		(
			BranchCode
		  , DataCode
		)
		SELECT BranchCode
			 , DataCode
		FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode)
	END



    SELECT @_StrTmp = STRING_AGG(CAST(
        N'UPDATE #CtTmp' + @_nl +
        N'SET _AssetCode = b.Code' + @_nl +
        N'FROM #CtTmp a' + @_nl +
        N'JOIN dbo.B2' + DataCode + N'Asset b ON a.AssetId = b.Id' + @_nl +
        N'WHERE a._AssetCode = '''' OR a._AssetCode IS NULL AND b.BranchCode = '''+BranchCode+''' ' AS NVARCHAR(MAX)), N';')
    FROM @_DataCodeList

    EXECUTE sys.sp_executesql @_StrTmp
  
    UPDATE #CtTmp    
    SET _Head = IIF(DocGroup = '2', -1, 1)    
  
    SELECT tb.AssetId    
          ,CAST(NULL AS INT)           AS Id    
          ,CAST(NULL AS INT)           AS ParentId    
          ,CAST(NULL AS BIT)           AS IsGroup    
          ,CAST(NULL AS VARCHAR(24))   AS AssetCode    
          ,CAST(NULL AS VARCHAR(24))   AS AssetCodeB7    
          ,CAST(NULL AS NVARCHAR(192)) AS AssetName    
          ,CAST(NULL AS NVARCHAR(8))   AS Unit    
          ,SUM(tb.IncQuantity - tb.DeQuantity) AS Quantity    
          ,MIN(tb.DocDate)             AS DocDate    
          ,SUM(CASE WHEN DocGroup <> '2' AND AssetTransType <> 'KHAUHAO' THEN  tb.UsefulMonth  
                    WHEN DocGroup =  '2' AND AssetTransType <> 'KHAUHAO' THEN -1 * tb.UsefulMonth  
               END) AS UsefulMonth    
          ,MAX(DeptId)					AS DeptId    
		  ,CAST('' AS NVARCHAR(156))	AS DeptCode   
          ,SUM(tb.OriginalCost * tb._Head) AS OriginalCost    
		  --ĐẦU KỲ
          ,SUM(CASE WHEN tb.DocDate < @_DocDate1  
                    THEN IIF(tb.AssetTransType = 'GIAMTAISAN', 0, tb.OriginalCost * tb._Head)  
                    ELSE CAST(0 AS NUMERIC(18,2)) END) AS OpenOriginalCost  --Giá trị Đầu kỳ  
          ,SUM(CASE WHEN tb.DocDate < @_DocDate1  
                    THEN IIF(tb.AssetTransType = 'GIAMTAISAN', 0, tb.Depreciation * tb._Head)  
                    ELSE CAST(0 AS NUMERIC(18,2)) END) AS OpenDepreciation  --Giá trị phân bổ đầu kỳ
          ,CAST(0 AS NUMERIC(18,2))   AS OpenBookValue						--Giá trị còn lại đầu kỳ

          ,SUM(CASE WHEN tb.DocDate BETWEEN @_DocDate1 AND @_DocDate2  
                    THEN IIF(tb.AssetTransType = 'GIAMTAISAN', 0, tb.OriginalCost * tb._Head)  
                    ELSE CAST(0 AS NUMERIC(18,2)) END) AS ThisPeriodOriginalCost    

			--PHÂN BỔ
          ,SUM(CASE WHEN tb.DocDate BETWEEN @_DocDate1 AND @_DocDate2  
                    THEN IIF(tb.AssetTransType <> 'GIAMTAISAN', tb.Depreciation * tb._Head, tb.NetBookValue)  
                    ELSE CAST(0 AS NUMERIC(18,2)) END) AS ThisPeriodDepreciation    --Giá trị phân bổ trong kỳ

          ,SUM(IIF(DocDate BETWEEN @_DocDate1 AND @_DocDate2, IncOriginalCost,  0)) AS ThisPeriodIncOriginalCost    --GIÁ TRỊ NGUYÊN GIÁ tăng trong kỳ
          ,SUM(IIF(DocDate BETWEEN @_DocDate1 AND @_DocDate2, DeOriginalCost,   0)) AS ThisPeriodDeOriginalCost		--GIÁ TRỊ NGUYÊN GIÁ giảm trong kỳ   
          
		  --CUỐI KỲ
		  --CCDC tại thời điểm DocDate2
		  ,SUM(tb.OriginalCost * tb._Head) AS CloseOriginalCost    --Giá trị cuối kỳ
          ,SUM(IIF(tb.AssetTransType = 'GIAMTAISAN', tb.NetBookValue, tb.Depreciation * tb._Head)) AS CloseDepreciation    --Giá trị phân bổ lũy kế cuối kỳ
          ,CAST(0 AS NUMERIC(18,2))   AS CloseBookValue --Giá trị cuối kỳ

          ,CAST('' AS NVARCHAR(MAX))  AS _GroupOrder    
          ,CAST('' AS VARCHAR(24))    AS _FormatStyleKey    
		  --Cột danh mục
          ,MAX(RouteCode)             AS RouteCode    
          ,MAX(DeprDebitAccount)      AS DeprDebitAccount    
          ,MAX(DeprCreditAccount)     AS DeprCreditAccount    
          ,MAX(AssetAccount)          AS AssetAccount    
          ,MAX(ExpenseCatgId)         AS ExpenseCatgId    
          ,CAST('' AS NVARCHAR(156))  AS ExpenseCatgCode    
          ,MAX(ProfitCenterId)        AS ProfitCenterId    
          ,CAST('' AS NVARCHAR(156))  AS ProfitCenterCode               
          ,MAX(StageId)               AS StageId    
          ,CAST('' AS VARCHAR(24))    AS StageCode    
          ,MAX(FirstDeprDate)         AS FirstDeprDate    
          ,MAX(TerritoryId)           AS TerritoryId    
          ,CAST('' AS NVARCHAR(24))   AS TerritoryCode    
          ,CAST('' AS NVARCHAR(256))  AS TerritoryName    
          ,MAX(DeprMethod)            AS DeprMethod    
          ,CAST(NULL AS TINYINT)      AS DeprCapacity    
          ,CAST(0 AS NUMERIC(18,2))   AS QuantityCapacityNet    
          ,CAST(0 AS NUMERIC(18,2))   AS QuantityCapacityDe    
          ,CAST(0 AS NUMERIC(18,2))   AS QuantityCapacityRe    
          ,MAX(BizDocId_C2)           AS BizDocId_C2    
          ,CAST('' AS NVARCHAR(64))   AS DocNo_C2    
          ,MAX(ProductId)             AS ProductId    
          ,CAST('' AS NVARCHAR(24))   AS ProductCode    
          ,CAST('' AS NVARCHAR(256))  AS ProductName    
          ,CAST('' AS NVARCHAR(MAX))  AS ProductCodeList   
          ,CAST(0 AS NUMERIC(18,2))   AS QuantityCapacityThisPeriod    
          ,MAX(tb.BranchCode)         AS BranchCode    
		  --CỘT DỰNG CÂY
          ,CAST(0 AS INT)             AS Id_Tree    
          ,CAST(0 AS INT)             AS ParentId_Tree    
    INTO #BcTemp
    FROM #CtTmp tb    
    WHERE tb.AssetTransType <> 'GIAMTAISAN'    
    GROUP BY tb.AssetId   
 
/*
OpenOriginalCost	Giá trị đầu kỳ
OpenDepreciation	Giá trị phân bổ
OpenBookValue	Giá trị còn lại
ThisPeriodIncOriginalCost	Tăng
ThisPeriodDeOriginalCost	Giảm
ThisPeriodDepreciation	Giá trị phân bổ trong kỳ
CloseOriginalCost	Giá trị cuối kỳ
CloseDepreciation	Giá trị phân bổ
CloseBookValue	Giá trị còn lại
*/	
 
	--Lấy dữ liệu giảm CCDC: dữ liệu thanh lý CCDC
    UPDATE #BcTemp    
    SET ThisPeriodDeOriginalCost = tb.ThisPeriodDepreciation    
    FROM #BcTemp bct    
        INNER JOIN (    
            SELECT tb.AssetId    
                  ,SUM(CASE WHEN tb.AssetTransType = 'GIAMTAISAN' THEN tb.NetBookValue ELSE 0 END) AS ThisPeriodDepreciation    
            FROM #CtTmp tb    
            GROUP BY tb.AssetId    
        ) tb ON bct.AssetId = tb.AssetId  
 
	DECLARE @_ListCol_Update NVARCHAR(MAX) = 'ExpenseCatgId,DeptId,StageId,ProfitCenterId,DeprDebitAccount,DeprCreditAccount'
 
	;WITH cte AS (SELECT DISTINCT value FROM STRING_SPLIT(@_ListCol_Update,','))
		SELECT @_StrTmp = STRING_AGG(';WITH cte AS (SELECT AssetId, '+c.value+', DocDate FROM #CtTmp WHERE AssetTransType <> ''GIAMTAISAN'')  
			UPDATE #BcTemp SET '+c.value+' = a.'+c.value+'  FROM #BcTemp bct OUTER APPLY (SELECT TOP 1 * FROM cte WHERE bct.AssetId = cte.AssetId ORDER BY cte.DocDate DESC) a ',' ; ')		
		FROM cte c
	EXECUTE sys.sp_executesql @_StrTmp
 
    SELECT @_StrTmp = STRING_AGG(CAST(
        N'DELETE a FROM #BcTemp a' + @_nl +
        N'WHERE EXISTS (' + @_nl +
        N'    SELECT * FROM dbo.vB3' + DataCode + N'AssetDoc_Resign' + @_nl +
        N'    WHERE IsActive = 1 AND BranchCode = ''' + BranchCode + N'''' + @_nl +
        N'      AND DocDate < @_DocDate1 AND AssetId = a.AssetId)'
    AS NVARCHAR(MAX)), N';')
    FROM @_DataCodeList

    SET @_Declare = N'@_DocDate1 DATE'
    EXECUTE sys.sp_executesql @_StrTmp, @_Declare, @_DocDate1
	    
		--2026-10-08 TINNT 
    UPDATE #BcTemp SET CloseOriginalCost = OpenOriginalCost +ThisPeriodIncOriginalCost,
						CloseDepreciation = OpenDepreciation + ThisPeriodDeOriginalCost + ThisPeriodDepreciation
 
	 

	WHILE EXISTS (SELECT * FROM @_DataCodeList WHERE Tinh ='')
	BEGIN 

	SELECT TOP (1) @_DataCode_Filter = DataCode, @_BranchCode_Filter = BranchCode FROM @_DataCodeList WHERE Tinh = '' ORDER BY BranchCode ASC 

	UPDATE @_DataCodeList SET Tinh ='x' WHERE BranchCode = @_BranchCode_Filter

	SELECT @_StrTmp = ''
    SELECT @_StrTmp = STRING_AGG(CAST(N'
        UPDATE #BcTemp
        SET  Id           = dm.Id
            ,ParentId     = dm.ParentId
            ,IsGroup      = dm.IsGroup
            ,AssetCode    = dm.Code
            ,AssetCodeB7  = dm.AssetCodeB7
            ,AssetName    = dm.Name
            ,Unit         = dm.Unit
            ,DeprCapacity = dm.DeprCapacity
        FROM #BcTemp tb
        INNER JOIN dbo.B2' + @_DataCode_Filter + N'Asset dm WITH (NOLOCK)
            ON tb.AssetId = dm.Id    
		WHERE  tb.BranchCode = '''+@_BranchCode_Filter+'''
				AND AssetCode IS NULL
			
        UPDATE BcTmp
        SET DocNo_C2 = bizdocso.DocNo
        FROM #BcTemp BcTmp
        INNER JOIN dbo.B3' + @_DataCode_Filter + N'BizDocSO bizdocso WITH (NOLOCK)
            ON BcTmp.BizDocId_C2 = bizdocso.BizDocId
			WHERE  BcTmp.BranchCode = '''+@_BranchCode_Filter+'''

        UPDATE #BcTemp
        SET CloseOriginalCost = 0
           ,CloseDepreciation = 0
        FROM #BcTemp tb
        INNER JOIN dbo.vB3' + @_DataCode_Filter + N'AssetDoc ctts WITH (NOLOCK)
            ON tb.AssetId           = ctts.AssetId
            AND ctts.AssetType      = 1
            AND ctts.AssetTransType = ''GIAMTAISAN''
            AND ctts.DocDate       <= @_DocDate2
            AND ctts.IsActive       = 1  
		WHERE  tb.BranchCode = '''+@_BranchCode_Filter+'''
			'AS NVARCHAR(MAX)), N';')

			PRINT @_StrTmp

		EXECUTE sys.sp_executesql @_StrTmp, N'@_DocDate2 DATE', @_DocDate2

	END 
	 
 
	UPDATE #BcTemp    
    SET OpenBookValue  = OpenOriginalCost  - OpenDepreciation    
       ,CloseBookValue = CloseOriginalCost - CloseDepreciation 

    IF @_DeprMethod IS NOT NULL    
        DELETE #BcTemp WHERE DeprMethod <> @_DeprMethod    
    
    -- Lấy dữ liệu danh sách sản phẩm  
    SELECT TOP 0 AssetId, ProductId, CAST(0 AS INT) AS Type, Quantity    
    INTO #ProductionCapacity    
    FROM dbo.B30AssetDoc WITH (NOLOCK)    
    
    EXECUTE dbo.usp_B30AssetProduct_GetData_v2    
             @_Date1          = ''    
            ,@_Date2          = @_DocDate2    
            ,@_Key1           = N'AssetId IN (SELECT AssetId FROM #BcTemp)'    
            ,@_CtTmp          = N'#ProductionCapacity'    
            ,@_nUserId        = @_nUserId    
            ,@_LangId         = @_LangId    
            ,@_BranchCode     = @_BranchCode    
            ,@_BranchReportId = @_BranchReportId  
    
    ;WITH cte AS (SELECT AssetId, SUM(Quantity) AS Quantity FROM #ProductionCapacity GROUP BY AssetId)  
    UPDATE bt SET bt.QuantityCapacityNet = ac.Quantity  
    FROM #BcTemp AS bt LEFT JOIN cte ac ON bt.AssetId = ac.AssetId  
  
    ;WITH cte AS (  
        SELECT pc.AssetId, pro.Code AS ProductCode  
        FROM #ProductionCapacity pc LEFT JOIN dbo.B20Product pro ON pc.ProductId = pro.Id  
    ), cte_string AS (  
        SELECT STRING_AGG(ProductCode, ' ' + CHAR(13) + CHAR(10) + '') AS ProductCodeList, AssetId  
        FROM cte GROUP BY AssetId  
    )  
    UPDATE #BcTemp  
    SET ProductCodeList = ISNULL(cte_string.ProductCodeList, '')  
    FROM #BcTemp bct LEFT JOIN cte_string ON bct.AssetId = cte_string.AssetId  
  
    -- Lấy dữ liệu danh sách sản phẩm đã khấu hao theo sản lượng  
    DROP TABLE IF EXISTS #AssetProductActual    
    SELECT TOP 0 AssetId, ProductId, Quantity, DocDate    
    INTO #AssetProductActual    
    FROM dbo.B30AssetProductActual WITH (NOLOCK)    
    
    EXECUTE dbo.usp_B30AssetProductActual_GetData_v2    
             @_Date1          = ''    
            ,@_Date2          = @_DocDate2    
            ,@_Key1           = N'AssetId IN (SELECT AssetId FROM #BcTemp)'    
            ,@_CtTmp          = N'#AssetProductActual'    
            ,@_nUserId        = @_nUserId    
            ,@_LangId         = @_LangId    
            ,@_BranchCode     = @_BranchCode    
            ,@_PRINT_Exec     = 0    
            ,@_BranchReportId = @_BranchReportId  
    
    UPDATE bt    
    SET bt.QuantityCapacityDe          = ISNULL(ac.QuantityDe,          0)    
       ,bt.QuantityCapacityRe          = ISNULL(bt.QuantityCapacityNet, 0) - ISNULL(ac.QuantityDe, 0)    
       ,bt.QuantityCapacityThisPeriod  = ISNULL(acThisPeriod.QuantityThisPeriod, 0)    
    FROM #BcTemp AS bt    
        INNER JOIN (SELECT AssetId, SUM(Quantity) AS QuantityDe FROM #AssetProductActual WHERE DocDate <= @_DocDate2 GROUP BY AssetId) ac  
            ON bt.AssetId = ac.AssetId    
        INNER JOIN (SELECT AssetId, SUM(Quantity) AS QuantityThisPeriod FROM #AssetProductActual WHERE DocDate BETWEEN @_DocDate1 AND @_DocDate2 GROUP BY AssetId) acThisPeriod  
            ON bt.AssetId = acThisPeriod.AssetId    
    
    UPDATE bt SET bt.ProductCode = pro.Code, bt.ProductName = pro.Name    
    FROM #BcTemp bt INNER JOIN dbo.B20Product pro WITH (NOLOCK) ON bt.ProductId = pro.Id    
    

	UPDATE #BcTemp
	SET ExpenseCatgCode = ISNULL(expe.Code, '')
	  , ProfitCenterCode = ISNULL(pro.Code, '')
	  , DeptCode = ISNULL(dept.Code, '')
	  , StageCode = ISNULL(Stage.Code, '')
	  , TerritoryCode = ISNULL(Territory.Code, '')
	  , TerritoryName = ISNULL(Territory.Name, '')
	FROM #BcTemp                            ct
		LEFT JOIN dbo.B20ExpenseCatg  expe (NOLOCK)
			ON expe.Id = ct.ExpenseCatgId
		LEFT JOIN dbo.B20ProfitCenter pro (NOLOCK)
			ON pro.Id = ct.ProfitCenterId
		LEFT JOIN dbo.B20Dept         dept (NOLOCK)
			ON dept.Id = ct.DeptId
		LEFT JOIN dbo.B20ZStage       Stage (NOLOCK)
			ON Stage.Id = ct.StageId
		LEFT JOIN dbo.B20Territory    Territory (NOLOCK)
			ON Territory.Id = ct.TerritoryId;
    
    IF @_CheckBC = 1    
    BEGIN    
        DELETE FROM #BcTemp    
        WHERE CloseBookValue  = 0    
          AND OpenBookValue   = 0    
          AND OriginalCost    = 0    
          AND (IsGroup = 0)    
          AND (ThisPeriodIncOriginalCost = 0 AND ThisPeriodDeOriginalCost = 0)  
    END    
    
    IF @_IsHide <> 0    
    BEGIN    
        DELETE #BcTemp    
        WHERE (AssetId IS NOT NULL AND (ABS(OpenBookValue) + ABS(ThisPeriodDepreciation) + ABS(ThisPeriodIncOriginalCost) = 0))  
          AND IsGroup = 0    
          AND (ThisPeriodIncOriginalCost = 0 AND ThisPeriodDeOriginalCost = 0)  
    END    
    
    IF ISNULL(@_TableTemp, '') <> ''    
    BEGIN    
        EXEC dbo.usp_sys_Append    
             @_TableSource           = '#BcTemp'    
            ,@_TableDestination      = @_TableTemp    
            ,@_InsertIntersectColumn = 1    
        RETURN    
    END    
    
    DECLARE @_tblName     NVARCHAR(64)  = N'#BcTemp'    
           ,@_tblDmName   NVARCHAR(64)    
           ,@_colCode     NVARCHAR(128)    
           ,@_colDmCode   NVARCHAR(128)    
           ,@_colListIns  NVARCHAR(128)    
           ,@_colListSel  NVARCHAR(128)    
           ,@_colName     NVARCHAR(128) = N'AssetName'    
           ,@_colDmName   NVARCHAR(128)    
           ,@_colTreeNode NVARCHAR(128) = N'_GroupOrder'    
           ,@_colId       NVARCHAR(64)  = N'Id_Tree'    
           ,@_colParentId NVARCHAR(64)  = N'ParentId_Tree'    
           ,@_IsDetail    TINYINT       = 1    
    
    IF ISNULL(@_GroupByExprs, '') <> ''    
    BEGIN    
        SELECT TOP 1    
               @_tblDmName  = TableName    
              ,@_colCode    = ValueCol    
              ,@_colDmName  = NameCol    
              ,@_colDmCode  = CodeCol    
              ,@_colListIns = N'FirstDeprDate, IsGroup,AssetCode'    
              ,@_colListSel = N'NULL, 1,Code'    
              ,@_tblDmName = TableName
        FROM dbo.B20Class    
        WHERE ParentCode = 'REP02_GroupByTs1' AND Code = @_GroupByExprs  
  
        SELECT @_tblDmName = IIF (@_GroupByExprs = 'AssetId', N'vB20Asset_ToolInstrument'    ,@_tblDmName)
    
        EXEC dbo.usp_sys_CreateTreeNodeKey    
             @_tblName      = @_tblName    
            ,@_tblDmName    = @_tblDmName    
            ,@_colCode      = @_colCode    
            ,@_colDmCode    = @_colDmCode    
            ,@_colListIns   = @_colListIns    
            ,@_colListSel   = @_colListSel    
            ,@_colName      = @_colName    
            ,@_colDmName    = @_colDmName    
            ,@_colTreeNode  = @_colTreeNode    
            ,@_colId        = @_colId    
            ,@_colParentId  = @_colParentId    
            ,@_LangId       = @_LangId    
            ,@_BranchCode   = @_BranchCode    
			,@_PRINT_Exec = 0
       
    END    
 
    SELECT * FROM #BcTemp ORDER BY _GroupOrder,BranchCode, AssetCode  ASC    
    
	DROP TABLE IF EXISTS #BcTemp
					   , #AssetProductActual
					   , #BranchCode0
					   , #CtTmp
					   , #ProductionCapacity
					   , #AssetFilter;
END
GO
GO


 