USE [B10THACOIDACC]
GO
/****** Object:  StoredProcedure [dbo].[usp_Tth_AssetSummaryTableByTime]    Script Date: 2026-10-05 3:44:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Coder: DucCM
-- Manager: ThangNH
-- ============================================
-- Description: B?ng t?ng h?p tài s?n (giá tr? kh?u hao theo tháng)
-- ============================================
CREATE OR ALTER    PROCEDURE [dbo].[usp_Tth_AssetSummaryTableByTime] 
	@_DocDate1 DATE = '01/01/19',
	@_DocDate2 DATE = '12/31/19',
	@_AssetId VARCHAR(512) = N'',
	@_DeptId VARCHAR(512) = N'',
	@_TerritoryId VARCHAR(512) = N'',
	@_ProductId VARCHAR(24) = N'',
	@_ExpenseCatgId VARCHAR(512) = N'',
	@_AssetFuncId VARCHAR(24) = N'',
	@_DeprDebitAccount VARCHAR(24) = N'',
	@_DeprCreditAccount VARCHAR(24) = N'',
	@_AssetAccount VARCHAR(24) = N'',
	@_ReportType CHAR(1) = N'1',
	@_ShownIncreaseDeprColumn TINYINT = 0, -- Kh?u hao trích trong k? (do phân b?)
	@_FiscalYear INT	= 0,
	@_GroupByExprs NVARCHAR(128) = '',
	@_ByTimeType NVARCHAR(128) = '', -- 0-Nhóm theo tháng, 1-Nhóm theo quý, 2-Nhóm theo n?m
	@_nUserId INT = 0,
	@_LangId INT = 0, 
	@_BranchCode VARCHAR(3)	= N'A01', 
	@_CurrencyCode0 CHAR(3)	= N'VND',
	@_LAYOUT_XML NVARCHAR(MAX) = '' OUTPUT,
	@_ClassCode1            VARCHAR(24)     = NULL,
	@_tblOutput NVARCHAR(128) = '',
	@_jsonData     NVARCHAR(MAX) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON
 
	-- T? ??ng l?y thông tin theo AppName khi th?c hi?n trong ch??ng trình, không theo tham s? truy?n vào
	IF ISNULL(@_nUserId,-1)=-1
		SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);

	IF ISNULL(@_BranchCode, '') =''
	SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)

	DECLARE @_BranchList TABLE (BranchCode VARCHAR(8), DataCode_Branch VARCHAR(8), Tinh CHAR(1) DEFAULT '' NOT NULL);

	INSERT INTO @_BranchList (BranchCode, DataCode_Branch)
	SELECT BranchCode, DataCode
	FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode)


	DECLARE @_Key NVARCHAR(MAX) = N''
		   ,@_Key2 NVARCHAR(MAX) = N''
		   ,@_StrTmp NVARCHAR(MAX)
		   ,@_Month INT = 0
		   ,@_BranchCode_Tmp VARCHAR(3) = ''
		   ,@_DataCode_Tmp VARCHAR(4) = ''

	SELECT TOP 1 @_DataCode_Tmp = DataCode  
    FROM B00Branch  
    WHERE BranchCode = @_BranchCode 
	
	DROP TABLE IF EXISTS #_AssetFilter;
	CREATE TABLE #_AssetFilter (Id INT);
	
	IF @_AssetId <> N''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_AssetId, @_ColGen = 'AssetId', 
			@_ColName = 'Id', @_TableName = 'B20Asset', @_BranchCode =@_BranchCode,
			@_AndOrKey = 'AND', @_Key = @_Key OUTPUT

	IF @_DeptId <> N'' 
		EXECUTE dbo.usp_sys_GenKey @_Code = @_DeptId, @_ColGen = 'DeptId', 
			@_ColName = 'Id', @_TableName = 'B20Dept', 
			@_AndOrKey = 'AND', @_Key = @_Key OUTPUT
			
	IF @_TerritoryId <> N'' 
		EXECUTE dbo.usp_sys_GenKey @_Code = @_TerritoryId, @_ColGen = 'TerritoryId', 
			@_ColName = 'Id', @_TableName = 'B20Territory', 
			@_AndOrKey = 'AND', @_Key = @_Key OUTPUT

	IF @_AssetFuncId <> ''
		SET @_Key = @_Key + ' AND (AssetFuncId IN (' + @_AssetFuncId  + '))' 

	IF @_AssetAccount <> N''
		SET @_Key = @_Key + N' AND AssetAccount LIKE ''' + @_AssetAccount + '%'''

	IF LTRIM(RTRIM(@_ClassCode1)) <> N''  
    BEGIN  
        SET @_Key = @_Key + N' AND AssetId IN (  
            SELECT Id FROM dbo.B2' + @_DataCode_Tmp + N'Asset WITH (NOLOCK)  
            WHERE ClassCode1 IN (''' + REPLACE(REPLACE(LTRIM(RTRIM(@_ClassCode1)), N' ', N''), N',', N''',''') + N'''))';  
  
        SET @_Key2 = @_Key2 + N' AND AssetId IN (  
            SELECT Id FROM dbo.B2' + @_DataCode_Tmp + N'Asset WITH (NOLOCK)  
            WHERE ClassCode1 IN (''' + REPLACE(REPLACE(LTRIM(RTRIM(@_ClassCode1)), N' ', N''), N',', N''',''') + N'''))';  
    END  

	SET @_Key = LTRIM(@_Key)
	IF LEFT(@_Key, 3) = N'AND'
		SET @_Key = SUBSTRING(@_Key, 4, LEN(@_Key) - 3)


	SET @_Key2 = @_Key + CASE WHEN @_Key = '' THEN '' ELSE ' AND ' END + ' AssetTransType <> ''KHKHNAM'' '
	
	-- ??u k?
	DROP TABLE IF EXISTS #T_CdTmp
	SELECT TOP 0 CAST(0 AS Int) AS Id, IsGroup, ParentId, 
		CAST('' AS VARCHAR(8)) AS BranchCode, Code, Name, Unit, CardNo, 
		MadeIn, MadeYear, Capacity, UsefulYear, AssetAccount, FirstUsedDate, 
		FirstDeprDate, CAST(NULL AS date) AS LastDeprDate,
		CAST(0 AS NUMERIC(18, 2)) AS OriginalCost,
		CAST(0 AS NUMERIC(18, 2)) AS Depreciation,
		CAST(0 AS NUMERIC(18, 2)) AS NetBookValue,
		CAST(0 AS NUMERIC(18, 2)) AS AmountForDepr,
		CAST(0 AS NUMERIC(15)) AS Quantity,
		CAST('' AS VARCHAR(24)) AS EquityId,
		CAST('' AS VARCHAR(24)) AS ProductId, 
		CAST(NULL AS INT) AS ExpenseCatgId,
		CAST(NULL AS INT) AS DeptId,
		CAST('' AS VARCHAR(24)) AS DeprDebitAccount,
		CAST('' AS VARCHAR(24)) AS DeprCreditAccount,
		CAST( NULL AS INT) AS StageId,
		CAST( NULL AS INT) AS TerritoryId,
		CAST( NULL AS INT) AS ProfitCenterId,CAST('' AS VARCHAR(24))  AS BizDocId_C2
	INTO #T_CdTmp
	FROM dbo.B20Asset WITH (NOLOCK)
	
	EXECUTE dbo.usp_B30AssetDoc_OpenAssetList
		@_DocDate0 = @_DocDate1,
		@_Key = @_Key,
		@_CtTmp = N'#T_CdTmp',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,   
        @_ExcludedDecreasingAsset   = 1  ,
        @_ExcludedDecreasingAssetDate = NULL  ,
		@_DeleteAssetResign = 1, -- Xóa ?i tài s?n thanh lý
		@_DeleteAssetResignDate = @_DocDate1 -- Ch? xóa TS có ngày < ngày truy?n vào
	
	SELECT @_StrTmp = '
	;WITH OpenDel AS
	(
		SELECT AssetId
			FROM vB3'+@_DataCode_Tmp+'AssetDoc_Resign
			WHERE AssetId IN (SELECT AssetId FROM #T_CdTmp) AND DocDate <   ''' + CONVERT(VARCHAR(11), @_DocDate1) + N'''
				AND BranchCode = ''' + CONVERT(VARCHAR(3), @_BranchCode) + N''' AND IsActive = 1 
	)	
	DELETE FROM #T_CdTmp WHERE Id IN (SELECT AssetId FROM OpenDel)'
	EXEC (@_StrTmp)

	-- Cu?i k?
	DROP TABLE IF EXISTS #T_CdTmp2
	SELECT TOP 0 CAST(0 AS Int) AS Id, IsGroup, ParentId, 
		CAST('' AS VARCHAR(8)) AS BranchCode, Code, Name, Unit, CardNo, 
		MadeIn, MadeYear, Capacity,  UsefulYear, AssetAccount, FirstUsedDate, 
		FirstDeprDate, CAST(NULL AS date) AS LastDeprDate,
		CAST(0 AS NUMERIC(18, 2)) AS OriginalCost,
		CAST(0 AS NUMERIC(18, 2)) AS Depreciation,
		CAST(0 AS NUMERIC(18, 2)) AS NetBookValue,
		CAST(0 AS NUMERIC(18, 2)) AS AmountForDepr,
		CAST(0 AS NUMERIC(15)) AS Quantity,
		CAST('' AS VARCHAR(24)) AS EquityId,
		CAST('' AS VARCHAR(24)) AS ProductId, 
		CAST(NULL AS INT) AS ExpenseCatgId,
		CAST(NULL AS INT) AS DeptId,
		CAST('' AS VARCHAR(24)) AS DeprDebitAccount,
		CAST('' AS VARCHAR(24)) AS DeprCreditAccount,
		CAST( NULL AS INT) AS StageId,
		CAST( NULL AS INT) AS TerritoryId,
		CAST( NULL AS INT) AS ProfitCenterId
	INTO #T_CdTmp2
	FROM dbo.B20Asset WITH (NOLOCK)
	
	EXECUTE dbo.usp_B30AssetDoc_CloseAssetList
		@_DocDate2 = @_DocDate2,
		@_Key = @_Key,
		@_CtTmp = N'#T_CdTmp2',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
        @_ExcludedDecreasingAsset   = 1  
        ,@_ExcludedDecreasingAssetDate = NULL,
		@_DeleteAssetResign = 1, -- Xóa ?i tài s?n thanh lý
		@_DeleteAssetResignDate = @_DocDate1 -- Ch? xóa TS có ngày < ngày truy?n vào

	SELECT @_StrTmp = ';WITH CloseDel AS
	(
		SELECT AssetId 
		FROM vB3'+@_DataCode_Tmp+'AssetDoc_Resign
		WHERE AssetId IN (SELECT AssetId FROM #T_CdTmp2) AND DocDate <  ''' + CONVERT(VARCHAR(11), @_DocDate1) + N'''
			AND BranchCode =  ''' + CONVERT(VARCHAR(3), @_BranchCode) + N''' AND IsActive = 1 
	)	
	DELETE FROM #T_CdTmp2 WHERE Id IN (SELECT AssetId FROM CloseDel)'
	EXEC (@_StrTmp)

    UPDATE @_BranchList SET Tinh = ''  
  
    WHILE EXISTS (SELECT * FROM @_BranchList WHERE Tinh = '')  
    BEGIN  
        SELECT TOP 1  
             @_BranchCode_Tmp = BranchCode  
            ,@_DataCode_Tmp   = DataCode_Branch  
        FROM @_BranchList  
        WHERE Tinh = ''  
  
        SET @_StrTmp = N'  
        ;WITH CloseDel AS  
        (  
            SELECT AssetId  
            FROM dbo.vB3' + @_DataCode_Tmp + N'AssetDoc_Resign  
            WHERE AssetId IN (SELECT Id FROM #T_CdTmp2)  
              AND DocDate < @_DocDate1  
              AND IsActive = 1  
        )  
        DELETE FROM #T_CdTmp2 WHERE Id IN (SELECT AssetId FROM CloseDel)'  
  
        EXECUTE sys.sp_executesql @_StrTmp, N'@_DocDate1 DATE', @_DocDate1  
  
        UPDATE @_BranchList SET Tinh = 'x' WHERE BranchCode = @_BranchCode_Tmp  
    END  
	
	SELECT TOP 0 * 
	INTO #T_SoTmp9 
	FROM dbo.vB30AssetDoc WITH (NOLOCK)

	EXECUTE dbo.usp_B30AssetDoc_GetData
		@_Date1 = @_DocDate1,
		@_Date2 = @_DocDate2,
		@_Key1 = @_Key2,
		@_CtTmp = N'#T_SoTmp9',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode

	ALTER TABLE #T_SoTmp9 ADD _AssetCode VARCHAR(32), _AssetName NVARCHAR(192), _AssetAccount VARCHAR(24)

	SELECT @_StrTmp = STRING_AGG('
		UPDATE #T_SoTmp9
		SET _AssetCode = ts.Code, _AssetName = ts.Name, _AssetAccount = ts.AssetAccount
		FROM #T_SoTmp9 AS tb
			INNER JOIN B2' + DataCode_Branch + N'Asset AS ts ON ts.Id = tb.AssetId', ';')
	FROM @_BranchList
	GROUP BY DataCode_Branch	
	EXECUTE sys.sp_executesql @_StrTmp;

	-- L?y s? phát sinh kh?u hao
	DROP TABLE IF EXISTS #T_KhTsByMonth
	SELECT tb.AssetId AS Id, tb.AssetId, tb.EquityId, _AssetName AS Name, _AssetAccount AS AssetAccount, tb.DeptId,tb.TerritoryId,tb.ProfitCenterId,tb.StageId, tb.DocDate,
		SUM(CASE WHEN tb.AssetTransType = 'KHAUHAO' OR (tb.AssetTransType = '' AND tb.AssetTransId IS NOT NULL) 
			THEN CASE WHEN tb.Trans >=0 THEN tb.Depreciation ELSE -tb.Depreciation END ELSE 0 END) AS Depreciation_Tk,	
		SUM(tb.Depreciation) AS Depreciation,	
		SUM(CASE WHEN tb.AssetTransType = 'KHAUHAO' THEN tb.Depreciation ELSE 0 END) AS IncreaseDeprAmount,
		CAST('' AS NVARCHAR(24)) AS _GroupBy, CAST('' AS NVARCHAR(24)) AS _GroupByName
	INTO #T_KhTsByMonth
	FROM #T_SoTmp9 tb
	WHERE tb.AssetTransType = 'KHAUHAO' OR (tb.AssetTransType = '' AND tb.AssetTransId IS NOT NULL AND tb.AssetTransType <> 'GIAMTAISAN')
		AND tb.Depreciation <> 0
	GROUP BY tb.AssetId, tb.EquityId, _AssetName, _AssetAccount, tb.DeptId, tb.TerritoryId,tb.ProfitCenterId,tb.StageId,tb.DocDate
	

	--SELECT * FROM #T_SoTmp9 RETURN 

	DROP TABLE IF EXISTS #T_KhTs
	SELECT tb.AssetId AS Id, tb.AssetId, tb.EquityId, _AssetName AS AssetName, _AssetAccount AS AssetAccount, tb.DeptId,tb.TerritoryId,tb.ProfitCenterId,tb.StageId,
		SUM(CASE WHEN tb.AssetTransType = 'KHAUHAO' OR (tb.AssetTransType = '' AND tb.AssetTransId IS NOT NULL) 
			THEN CASE WHEN tb.Trans >=0 THEN tb.Depreciation ELSE -tb.Depreciation END ELSE 0 END) AS Depreciation_Tk,	
		SUM(tb.Depreciation) AS Depreciation,	
		SUM(CASE WHEN tb.AssetTransType = 'KHAUHAO' THEN tb.Depreciation ELSE 0 END) AS IncreaseDeprAmount
	INTO #T_KhTs
	FROM #T_SoTmp9 tb
	WHERE tb.AssetTransType = 'KHAUHAO' OR (tb.AssetTransType = '' AND tb.AssetTransId IS NOT NULL AND tb.AssetTransType <> 'GIAMTAISAN')
		AND tb.Depreciation <> 0
	GROUP BY tb.AssetId, tb.EquityId, _AssetName, _AssetAccount, tb.DeptId,tb.TerritoryId,tb.ProfitCenterId,tb.StageId

	DROP TABLE IF EXISTS #T_NgTs
	SELECT tb.AssetId AS Id, tb.AssetId, tb.EquityId, _AssetName AS AssetName, _AssetAccount AS AssetAccount, tb.DeptId,tb.TerritoryId,tb.ProfitCenterId,tb.StageId,
		SUM(CASE WHEN tb.DocGroup = 1 THEN tb.OriginalCost ELSE 0 END) AS IncreaseOriginalCost,
		SUM(CASE WHEN tb.DocGroup = 2 THEN tb.OriginalCost ELSE 0 END) AS DecreaseOriginalCost
	INTO #T_NgTs
	FROM #T_SoTmp9 tb
	WHERE tb.AssetTransType <> 'KHAUHAO' AND tb.OriginalCost <> 0
	GROUP BY tb.AssetId, tb.EquityId, _AssetName, _AssetAccount, tb.DeptId,tb.TerritoryId,tb.ProfitCenterId,tb.StageId
	
	DROP TABLE IF EXISTS #BcTmp1
	SELECT tb.Id, tb.AssetId, tb.EquityId, AssetName, AssetAccount, 
		tb.DeptId,tb.TerritoryId,tb.ProfitCenterId,tb.StageId,
		MAX(tb.Quantity2) AS Quantity,
		SUM(tb.OriginalCost1) AS OriginalCost1,
		SUM(tb.Depreciation1) AS Depreciation1,
		SUM(tb.NetBookValue1) AS NetBookValue1,
		CAST(0 AS NUMERIC(18, 2)) AS Depreciation_Tk,
		CAST(0 AS NUMERIC(18, 2)) AS Depreciation,
		CAST(0 AS NUMERIC(18, 2)) AS IncreaseDeprAmount,	
		CAST(0 AS NUMERIC(18, 2)) AS IncreaseOriginalCost,	
		CAST(0 AS NUMERIC(18, 2)) AS DecreaseOriginalCost,	
		SUM(tb.OriginalCost2) AS OriginalCost2,
		SUM(tb.Depreciation2) AS Depreciation2,
		SUM(tb.NetBookValue2) AS NetBookValue2,
		MIN(tb.zType) AS zType,IDENTITY (INT ) AS _Id
	INTO #BcTmp1	
	FROM	
	(
		SELECT Id, Id AS AssetId, Name AS AssetName, 
			EquityId, AssetAccount,
			DeptId, TerritoryId, ProfitCenterId, StageId,
			Quantity AS Quantity1,  
			OriginalCost AS OriginalCost1,
			Depreciation AS Depreciation1,
			NetBookValue AS NetBookValue1,
			CAST(0 AS Numeric(18, 2)) AS Quantity2, 
			CAST(0 AS Numeric(18, 2)) AS OriginalCost2,
			CAST(0 AS Numeric(18, 2)) AS Depreciation2,
			CAST(0 AS Numeric(18, 2)) AS NetBookValue2,
			1 AS zType
		FROM #T_CdTmp
		UNION ALL
			SELECT Id, Id AS AssetId, Name AS AssetName, 
			EquityId, AssetAccount, 
			DeptId, TerritoryId, ProfitCenterId, StageId,
			CAST(0 AS Numeric(18, 2)) AS Quantity1, 
			CAST(0 AS Numeric(18, 2)) AS OriginalCost1,
			CAST(0 AS Numeric(18, 2)) AS Depreciation1,
			CAST(0 AS Numeric(18, 2)) AS NetBookValue1,
			Quantity AS Quantity2,  
			OriginalCost AS OriginalCost2,
			Depreciation AS Depreciation2,
			NetBookValue AS NetBookValue2,
			0 AS zType
		FROM #T_CdTmp2
	) tb	
	GROUP BY tb.Id, tb.AssetId, tb.EquityId, tb.AssetName, tb.AssetAccount, tb.DeptId,tb.TerritoryId,tb.ProfitCenterId,tb.StageId

	EXECUTE dbo.usp_sys_DefaultTable N'#BcTmp1'

    ;WITH cte AS (SELECT tct.Id,tct.ProfitCenterId FROM #T_CdTmp2 tct) 
	UPDATE #BcTmp1
	SET ProfitCenterId = t.ProfitCenterId
	FROM #BcTmp1 bct INNER JOIN #T_CdTmp2 t ON bct.AssetId = t.Id
 
	--INSERT INTO #BcTmp1 (Id, AssetId, EquityId, AssetName, AssetAccount,DeptId, TerritoryId, ProfitCenterId, StageId)
	--SELECT Id, AssetId, EquityId, AssetName, AssetAccount, DeptId, TerritoryId, ProfitCenterId, StageId
	--FROM #T_KhTs
	--EXCEPT
	--SELECT Id, AssetId, EquityId, AssetName, AssetAccount, DeptId, TerritoryId, ProfitCenterId, StageId
	--FROM #BcTmp1

	INSERT INTO #BcTmp1 ( Id, AssetId, EquityId, AssetName, AssetAccount   )
	SELECT  Id, AssetId, EquityId, ISNULL(AssetName, ''), ISNULL(AssetAccount, '')   
	FROM    #T_KhTs
	EXCEPT
	SELECT  Id, AssetId, EquityId, ISNULL(AssetName, ''), ISNULL(AssetAccount, '')  
	FROM    #BcTmp1
 
	;WITH cte
	AS (SELECT bc.AssetId
			 , tb.Depreciation_Tk
			 , tb.Depreciation
			 , bc.IncreaseDeprAmount
			 , bc._Id
			 , ROW_NUMBER() OVER (PARTITION BY bc.AssetId ORDER BY bc.Id) AS _RN
		FROM #BcTmp1           AS bc
			INNER JOIN #T_KhTs AS tb
				ON bc.AssetId = tb.AssetId)
	UPDATE bc
	SET bc.Depreciation_Tk = tb.Depreciation_Tk
	  , bc.Depreciation = tb.Depreciation
	  , bc.IncreaseDeprAmount = tb.IncreaseDeprAmount
	FROM #BcTmp1           AS bc
		INNER JOIN cte AS tb
			ON bc.AssetId = tb.AssetId
			   --AND bc.DeptId = tb.DeptId 
			   --AND bc.TerritoryId = tb.TerritoryId 
			   --AND bc.StageId = tb.StageId 
			   --AND bc.ProfitCenterId = tb.ProfitCenterId 
			   --AND bc.EquityId = tb.EquityId
			   AND bc._Id =tb._Id			   
			   AND tb._RN = 1 	 

	;WITH cte
	AS (SELECT bc.AssetId
			 , tb.IncreaseOriginalCost
			 , tb.DecreaseOriginalCost
			 , bc._Id
			 , ROW_NUMBER() OVER (PARTITION BY bc.AssetId ORDER BY bc.Id) AS _RN
		FROM #BcTmp1           AS bc
			INNER JOIN #T_NgTs AS tb
				ON bc.AssetId = tb.AssetId)
	UPDATE bc
	SET bc.IncreaseOriginalCost = tb.IncreaseOriginalCost
	  , bc.DecreaseOriginalCost = tb.DecreaseOriginalCost
	FROM #BcTmp1       AS bc
		INNER JOIN cte AS tb
			ON bc.AssetId = tb.AssetId
			   --AND bc.DeptId = tb.DeptId 
			   --AND bc.TerritoryId = tb.TerritoryId 
			   --AND bc.StageId = tb.StageId 
			   --AND bc.ProfitCenterId = tb.ProfitCenterId 
			   --AND tb.EquityId = bc.EquityId
			   AND bc._Id = tb._Id
			   AND tb._RN = 1;

	 

	DROP TABLE IF EXISTS #T_KhTs
	DROP TABLE IF EXISTS #T_CdTmp
	DROP TABLE IF EXISTS #T_CdTmp2
	
	-- X? lý nhóm
	IF CHARINDEX(N'DeptId', N',' + @_GroupByExprs) = 0
	BEGIN
		UPDATE #BcTmp1 SET DeptId = tb.DeptId
		FROM #BcTmp1 bc
			OUTER APPLY
			(	SELECT TOP 1 tb.DeptId
				FROM #BcTmp1 tb
				WHERE bc.Id = tb.Id
				ORDER BY tb.zType
			) tb	

		UPDATE #T_KhTsByMonth SET DeptId = tb.DeptId
		FROM #T_KhTsByMonth bc
			OUTER APPLY
			(	SELECT TOP 1 tb.DeptId
				FROM #BcTmp1 tb
				WHERE bc.AssetId = tb.AssetId
				ORDER BY tb.zType
			) tb	
	END
	
	-- X? lý nhóm
	IF CHARINDEX(N'EquityId', N',' + @_GroupByExprs) = 0
	BEGIN
		UPDATE #BcTmp1 SET EquityId = ''
		UPDATE #T_KhTsByMonth SET EquityId = ''
	END

	DROP TABLE IF EXISTS #BcTmp
	SELECT bc.Id, bc.AssetId, CAST('' AS VARCHAR(24)) AS AssetCode,CAST('' AS VARCHAR(24)) AS AssetCodeB7 , bc.EquityId, AssetName, AssetAccount,
		bc.DeptId, CAST('' AS NVARCHAR(24)) AS DeptCode, CAST('' AS NVARCHAR(256)) AS DeptName, 
		bc.TerritoryId, CAST('' AS NVARCHAR(24)) AS TerritoryCode,  CAST('' AS NVARCHAR(256)) AS TerritoryName, 
		bc.ProfitCenterId, CAST('' AS NVARCHAR(24)) AS ProfitCenterCode, 
		CAST('' AS NVARCHAR(256)) AS ProfitCenterName, 
		
		MAX(bc.StageId) AS StageId, CAST('' AS NVARCHAR(24)) AS StageCode,  CAST('' AS NVARCHAR(256)) AS StageName, 
		MAX(bc.Quantity) AS Quantity,
		SUM(bc.OriginalCost1) AS OriginalCost1,
		SUM(bc.Depreciation1) AS Depreciation1,
		SUM(bc.NetBookValue1) AS NetBookValue1,
		SUM(bc.IncreaseOriginalCost) AS IncreaseOriginalCost,
		SUM(bc.DecreaseOriginalCost) AS DecreaseOriginalCost,
		SUM(bc.Depreciation_Tk) AS Depreciation_Tk,
		SUM(bc.Depreciation) AS Depreciation,
		SUM(bc.IncreaseDeprAmount) AS IncreaseDeprAmount,		
		SUM(bc.OriginalCost2) AS OriginalCost2,
		SUM(bc.Depreciation2) AS Depreciation2,
		SUM(bc.NetBookValue2) AS NetBookValue2,
		CAST(0 AS TINYINT) AS Level, CAST('' AS Char(1)) AS Bold, 
		CAST(0 AS TINYINT) AS IsGroup, CAST(0 AS INT) AS ParentId,
		CAST('' AS DATE) AS FirstDeprDate, 
		CAST('' AS NVARCHAR(24)) AS Unit,
		CAST('' AS NVARCHAR(64)) AS _FormatStyleKey,
		CAST('' AS NVARCHAR(64)) AS _ParentIdList,
		CAST('' AS VARCHAR(MAX)) AS _GroupOrder,
		CAST(0 AS INT) AS Id_Tree,
		CAST(0 AS INT) AS ParentId_Tree,
		CHAR(24) AS ClassCode1,CAST('' AS NVARCHAR(256)) AS ClassCode1Name,
		CAST(0 AS INT) AS EmployeeId,
		CAST(0 AS INT) AS ExpenseCatgId,
		CAST('' AS NVARCHAR(24))  AS DeprDebitAccount,
		CAST('' AS NVARCHAR(24))  AS DeprCreditAccount,
		CAST('' AS NVARCHAR(16))  AS BizDocId_C2
	INTO #BcTmp 
	FROM #BcTmp1 bc	
	GROUP BY bc.Id, bc.AssetId, bc.EquityId, bc.AssetName, bc.AssetAccount, bc.DeptId,   bc.TerritoryId, bc.ProfitCenterId
 
	EXEC dbo.usp_sys_DefaultTable '#BcTmp'

	EXEC usp_B30AssetDoc_AssetInfo_UpdateData @_DocDate2 = @_DocDate2
											, @_CtTmp = '#BcTmp '
											, @_BranchCode = @_BranchCode
											, @_nUserId = @_nUserId
											, @_LangId = @_LangId
											, @_Debug = 0;

	SELECT @_StrTmp = STRING_AGG(N'
		UPDATE #BcTmp
		SET IsGroup = dm.IsGroup, ParentId = dm.ParentId, 
			Unit = dm.Unit, FirstDeprDate = dm.FirstDeprDate, 
			DeptCode = ISNULL(dept.Code, ''''), 
			DeptName = ISNULL(dept.Name, ''''),
			TerritoryCode = ISNULL(Territory.Code, ''''), 
			TerritoryName = ISNULL(Territory.Name, ''''),
			ProfitCenterCode = ISNULL(ProfitCenter.Code, ''''), 
			ProfitCenterName = ISNULL(ProfitCenter.Name, ''''),
			StageCode = ISNULL(ZStage.Code, ''''), 
			StageName = ISNULL(ZStage.Name, ''''),
			AssetCode = dm.Code,
			AssetCodeB7 = dm.AssetCodeB7,
			ClassCode1 = ISNULL(dm.ClassCode1,'''')
		FROM #BcTmp bc 
			INNER JOIN B2' + DataCode_Branch + N'Asset dm ON bc.AssetId = dm.Id
			LEFT OUTER JOIN B20Dept dept ON bc.DeptId = dept.Id
			LEFT OUTER JOIN B20ZStage ZStage ON bc.StageId = ZStage.Id
			LEFT OUTER JOIN B20Territory Territory ON bc.TerritoryId = Territory.Id
			LEFT OUTER JOIN B20ProfitCenter ProfitCenter ON bc.ProfitCenterId = ProfitCenter.Id', ';')
	FROM @_BranchList
	GROUP BY DataCode_Branch
	EXECUTE sys.sp_executesql @_StrTmp;

	UPDATE #BcTmp SET  ClassCode1Name =  CONCAT(DmTs.ClassCode1,classcode.Name ) 
	FROM #BcTmp DmTs
	LEFT JOIN dbo.B20Class classcode ON classcode.Code = Dmts.ClassCode1 AND classcode.ParentCode = 'TYPE_MMTB'        

	DROP TABLE IF EXISTS #BcTmp1	
	-- T?o cây
	DECLARE @_tblName NVARCHAR(64) = N'#BcTmp'
		   ,@_tblDmName NVARCHAR(64)
		   ,@_colCode NVARCHAR(128)
		   ,@_colDmCode NVARCHAR(128) = N'Code'
		   ,@_colListIns NVARCHAR(128)
		   ,@_colListSel NVARCHAR(128)
		   ,@_colName NVARCHAR(128) = N'AssetName'
		   ,@_colDmName NVARCHAR(128)
		   ,@_colTreeNode NVARCHAR(128) = N'_GroupOrder'
		   ,@_colId NVARCHAR(64) = N'Id_Tree'
		   ,@_colParentId NVARCHAR(64) = N'ParentId_Tree'
		   ,@_IsDetail TINYINT = 1
		   
    IF ISNULL(@_GroupByExprs, '') <> ''     
    begin 	
        SELECT TOP 1
            @_tblDmName = TableName
            ,@_colCode = ValueCol
            ,@_colDmName = NameCol
            ,@_colDmCode = CodeCol
            ,@_colListIns = N'FirstDeprDate'
            ,@_colListSel = N'NULL'
        FROM dbo.B20Class
        WHERE ParentCode = 'REP02_GroupByTs1'
            AND Code = @_GroupByExprs;

       
	EXEC dbo.usp_sys_CreateTreeNodeKey 
		@_tblName		= @_tblName,
		@_tblDmName		= @_tblDmName,
		@_colCode		= @_colCode,
		@_colDmCode		= @_colDmCode,
		@_colListIns	= @_colListIns,
		@_colListSel	= @_colListSel,
		@_colName		= @_colName,
		@_colDmName		= @_colDmName,
		@_colTreeNode	= @_colTreeNode,
		@_colId			= @_colId,
		@_colParentId	= @_colParentId,
		@_IsDetail		= @_IsDetail,
		@_BranchCode	= @_BranchCode,
		@_LangId		= @_LangId     

    end         
 
	IF @_GroupByExprs NOT IN (N'DeptId', N'AssetAccount', N'EquityId') 
		SELECT @_IsDetail = 0

	-- X? lý ch?y kh?u hao theo tháng/quý/n?m
	DECLARE @_StrExc NVARCHAR(MAX) = '', @_StrExcSum NVARCHAR(MAX) = '', @_StrExcPv NVARCHAR(MAX) = '',
			@_StrExcSum_Tk NVARCHAR(MAX) = '', @_StrExcPv_Tk NVARCHAR(MAX) = ''

	UPDATE #T_KhTsByMonth 
	SET _GroupBy = N'C' + CASE @_ByTimeType WHEN '1' THEN STR(YEAR(DocDate), 4) + '_' + dbo.ufn_sys_ConvertIntToRoman(STR(DATEPART(QUARTER, DATEADD(MM, -@_Month, DocDate)), 2))
									WHEN '2' THEN STR(YEAR(DocDate), 4)
									ELSE STR(YEAR(DocDate), 4) + '_' + REPLACE(STR(MONTH(DocDate), 2),' ','0') END,
		_GroupByName = CASE @_ByTimeType WHEN '1' THEN dbo.ufn_sys_ConvertIntToRoman(STR(DATEPART(QUARTER, DATEADD(MM, -@_Month, DocDate)), 2)) + '/' + STR(YEAR(DATEADD(MM, -@_Month, DocDate)), 4)
									WHEN '2' THEN STR(YEAR(DocDate), 4)
									ELSE REPLACE(STR(MONTH(DocDate), 2),' ','0') + '/' + STR(YEAR(DocDate), 4) END

	SELECT @_StrExcSum = @_StrExcSum + N', ISNULL(SUM(' + QUOTENAME(_GroupBy) + N'),0) AS ' + QUOTENAME(_GroupBy),
		@_StrExcPv = @_StrExcPv + N', ' + QUOTENAME(_GroupBy),
		@_StrExcSum_Tk = @_StrExcSum_Tk + N', SUM(' + QUOTENAME(_GroupBy) + N') AS ' + QUOTENAME(_GroupBy+ N'_De') ,
		@_StrExcPv_Tk = @_StrExcPv_Tk + N', ' + QUOTENAME(_GroupBy + '_De')
	FROM #T_KhTsByMonth
	GROUP BY _GroupBy
	ORDER BY _GroupBy
 
	BEGIN
		--20260826 thêm ?o?n này ?? k? th?a d? li?u 
		DECLARE @_StrAlter NVARCHAR(MAX) = '';

		DROP TABLE IF EXISTS #T_DMCot;
		SELECT _GroupBy AS Col
		INTO #T_DMCot
		FROM #T_KhTsByMonth
		GROUP BY _GroupBy
		ORDER BY _GroupBy;

		DROP TABLE IF EXISTS #BcTmpPv0;
		SELECT PV.AssetId
			 , PV.EquityId
			 , PV.AssetAccount
			 , PV.DeptId
		INTO #BcTmpPv0
		FROM #T_KhTsByMonth AS PV;

		SELECT @_StrAlter = @_StrAlter + ' ALTER TABLE #BcTmpPv0 ADD ' + Col + ' NUMERIC(18,2) DEFAULT 0 ;  ' + CHAR(13)
		FROM #T_DMCot;

		EXEC (@_StrAlter);

	END;
 
	IF @_StrExcPv <> '' SET @_StrExcPv = STUFF(@_StrExcPv, 1, 1, '')

	IF @_StrExcPv_Tk <> '' SET @_StrExcPv_Tk = STUFF(@_StrExcPv_Tk, 1, 1, '')

	--20260826 #BcTmpPv thêm b?ng k?t th?a d? li?u
	IF ISNULL(@_tblOutput, '') <> ''
    BEGIN
        DECLARE @Cmd NVARCHAR(MAX) =''
        EXEC usp_sys_CreateTable @_tblOutput, '#BcTmpPv0'

		SET @Cmd = 	 
			N'	INSERT INTO #BcTmpPv0 ' + CHAR(13) +
			N'	SELECT pv.AssetId, pv.EquityId, pv.AssetAccount, pv.DeptId'+ @_StrExcSum + CHAR(13) +
			N'	FROM #T_KhTsByMonth ' + CHAR(13) +
			N'		PIVOT ' + CHAR(13) +
			N'		( ' + CHAR(13) +
			N'			SUM(Depreciation) FOR [_GroupBy] IN (' + @_StrExcPv + ') ' + CHAR(13) +
			N'		)AS pv ' + CHAR(13) +
			N'	GROUP BY pv.AssetId, pv.EquityId, pv.AssetAccount, pv.DeptId ' + CHAR(13)    
		EXEC sp_executesql @Cmd 

	SET @_jsonData =
    (
        SELECT * FROM #T_DMCot FOR JSON AUTO
    )

		SET @Cmd=''
		SELECT @Cmd=@Cmd+IIF(@Cmd<>'', ',', '')+Name
		FROM tempdb.Sys.Columns
		WHERE OBJECT_ID=OBJECT_ID('tempdb..'+@_tblOutput)AND Name IN(SELECT Name
																	 FROM tempdb.Sys.Columns
																	 WHERE OBJECT_ID=OBJECT_ID('tempdb..#BcTmpPv0'))

        SET @Cmd = N'INSERT INTO ' + @_tblOutput + N'(' + @Cmd + N')' + CHAR(13) + N'SELECT ' + @Cmd + N' FROM #BcTmpPv0 '
        EXEC sp_executesql @Cmd  RETURN 
    END
 
	SET @_StrExc = 
	N'	DROP TABLE IF EXISTS #BcTmpPv ' + CHAR(13) +
	N'	SELECT pv.AssetId, pv.EquityId, pv.AssetAccount, pv.DeptId'+ @_StrExcSum + CHAR(13) +
	N'	INTO #BcTmpPv ' + CHAR(13) +
	N'	FROM #T_KhTsByMonth ' + CHAR(13) +
	N'		PIVOT ' + CHAR(13) +
	N'		( ' + CHAR(13) +
	N'			SUM(Depreciation) FOR [_GroupBy] IN (' + @_StrExcPv + ') ' + CHAR(13) +
	N'		)AS pv ' + CHAR(13) +
	N'	GROUP BY pv.AssetId, pv.EquityId, pv.AssetAccount, pv.DeptId ' + CHAR(13) + CHAR(13) +

	N'	DROP TABLE IF EXISTS #BcTmpPv_Depr ' + CHAR(13) +
	N'	SELECT pv.AssetId, pv.EquityId, pv.AssetAccount, pv.DeptId'+ @_StrExcSum_Tk + CHAR(13) +
	N'	INTO #BcTmpPv_Depr ' + CHAR(13) +
	N'	FROM #T_KhTsByMonth ' + CHAR(13) +
	N'		PIVOT ' + CHAR(13) +
	N'		( ' + CHAR(13) +
	N'			SUM(IncreaseDeprAmount) FOR [_GroupBy] IN (' + @_StrExcPv + ') ' + CHAR(13) +
	N'		)AS pv ' + CHAR(13) +
	N'	GROUP BY pv.AssetId, pv.EquityId, pv.AssetAccount, pv.DeptId ' + CHAR(13) + CHAR(13) +

	N'	SELECT bc.*, ' + @_StrExcPv + ',' + @_StrExcPv_Tk+ ', CAST(0 AS INT) AS Order1' + CHAR(13) + 
	N'	FROM #BcTmp bc ' + CHAR(13) +
	N'		LEFT OUTER JOIN #BcTmpPv pv ON bc.AssetId = pv.AssetId AND bc.EquityId = pv.EquityId AND bc.AssetAccount = pv.AssetAccount AND bc.DeptId = pv.DeptId ' + CHAR(13) +
	N'		LEFT OUTER JOIN #BcTmpPv_Depr depr ON bc.AssetId = depr.AssetId AND bc.EquityId = depr.EquityId AND bc.AssetAccount = depr.AssetAccount AND bc.DeptId = depr.DeptId' + CHAR(13) +
	N'	ORDER BY bc._GroupOrder'
 		
		 
	IF @_StrExcSum <> '' AND @_StrExcSum_Tk <> '' AND @_StrExcPv <> '' AND @_StrExcPv_Tk <> ''
	BEGIN 	
		EXEC sys.sp_executesql @_StrExc
	END 
	ELSE 
	BEGIN 
		SELECT *, CAST(0 AS INT) AS Order1
		FROM #BcTmp ORDER BY _GroupOrder ASC ,AssetCode ASC 
	END 

		


	-- T?o layout ??ng
	SET @_LAYOUT_XML = ''
	SELECT @_LAYOUT_XML = @_LAYOUT_XML + 
			N'	<'+_GroupBy+'> ' + CHAR(13) + 
			N'			<Width>97</Width> ' + CHAR(13) + 
			N'			<Style>TextAlign:RightTop;Format:"C";</Style> ' + CHAR(13) + 
			N'			<Rows> ' + CHAR(13) + 
			N'				<Row_0> ' + CHAR(13) + 
			N'					<Text> ' + CHAR(13) + 
			N'						<Vietnamese>Kh?u hao trong k?</Vietnamese> ' + CHAR(13) + 
			N'						<English>Depreciation this period</English> ' + CHAR(13) + 
			N'						<Chinese>?????</Chinese> ' + CHAR(13) + 
			N'						<Japanese>??????</Japanese> ' + CHAR(13) + 
			N'						<Korean>???? ? ??.</Korean> ' + CHAR(13) + 
			N'					</Text> ' + CHAR(13) + 
			N'					<Style>UserData:Depreciation;</Style> ' + CHAR(13) + 
			N'				</Row_0> ' + CHAR(13) + 
			N'				<Row_1> ' + CHAR(13) + 
			N'					<Text> ' + CHAR(13) + 
			N'						<Vietnamese>'+MAX(_GroupByName)+'</Vietnamese> ' + CHAR(13) + 
			N'						<English>'+MAX(_GroupByName)+'</English> ' + CHAR(13) + 
			N'						<Chinese>'+MAX(_GroupByName)+'</Chinese> ' + CHAR(13) + 
			N'						<Japanese>'+MAX(_GroupByName)+'</Japanese> ' + CHAR(13) + 
			N'						<Korean>'+MAX(_GroupByName)+'</Korean> ' + CHAR(13) + 
			N'					</Text> ' + CHAR(13) + 
			N'					<Style>UserData:'+_GroupBy+'_Tk;</Style> ' + CHAR(13) + 
			N'				</Row_1> ' + CHAR(13) + 
			N'			</Rows> ' + CHAR(13) + 
			N'		</'+_GroupBy+'>'
		FROM #T_KhTsByMonth 
		GROUP BY _GroupBy
		ORDER BY MAX(DocDate)
		
		SET @_LAYOUT_XML =@_LAYOUT_XML + CHAR(13) +  N'		<Depreciation></Depreciation>' 
		
		IF @_ShownIncreaseDeprColumn = 1
			SELECT @_LAYOUT_XML = @_LAYOUT_XML + CHAR(13) + 
				N'	<'+_GroupBy+'_De> ' + CHAR(13) + 
				N'			<Name>'+_GroupBy+'_De</Name> ' + CHAR(13) + 
				N'			<Width>97</Width> ' + CHAR(13) + 
				N'			<Style>TextAlign:RightTop;Format:"C";</Style> ' + CHAR(13) + 
				N'			<Rows> ' + CHAR(13) + 
				N'				<Row_0> ' + CHAR(13) + 
				N'					<Text> ' + CHAR(13) + 
				N'						<Vietnamese>Kh?u hao phân b? trong k?</Vietnamese> ' + CHAR(13) + 
				N'						<English>Increase depreciation</English> ' + CHAR(13) + 
				N'						<Chinese>????</Chinese> ' + CHAR(13) + 
				N'						<Japanese>??????????</Japanese> ' + CHAR(13) + 
				N'						<Korean>???? ????.</Korean> ' + CHAR(13) + 
				N'					</Text> ' + CHAR(13) + 
				N'					<Style>UserData:IncreaseDeprAmount;</Style> ' + CHAR(13) + 
				N'				</Row_0> ' + CHAR(13) + 
				N'				<Row_1> ' + CHAR(13) + 
				N'					<Text> ' + CHAR(13) + 
				N'						<Vietnamese>'+MAX(_GroupByName)+'</Vietnamese> ' + CHAR(13) + 
				N'						<English>'+MAX(_GroupByName)+'</English> ' + CHAR(13) + 
				N'						<Chinese>'+MAX(_GroupByName)+'</Chinese> ' + CHAR(13) + 
				N'						<Japanese>'+MAX(_GroupByName)+'</Japanese> ' + CHAR(13) + 
				N'						<Korean>'+MAX(_GroupByName)+'</Korean> ' + CHAR(13) + 
				N'					</Text> ' + CHAR(13) + 
				N'					<Style>UserData:'+_GroupBy+'_De;</Style> ' + CHAR(13) + 
				N'				</Row_1> ' + CHAR(13) + 
				N'			</Rows> ' + CHAR(13) + 
				N'		</'+_GroupBy+'_De>'
			FROM #T_KhTsByMonth 
			GROUP BY _GroupBy
			ORDER BY MAX(DocDate)

	SET @_LAYOUT_XML = 
			N'<DefaultReport><Content><Cols>' + CHAR(13) + 
			N'	<AssetCode></AssetCode>' + CHAR(13) + 
			N'	<AssetCodeB7></AssetCodeB7>' + CHAR(13) + 
			N'	<AssetName></AssetName>' + CHAR(13) + 
			N'	<Unit></Unit>' + CHAR(13) + 
			N'	<DeptCode></DeptCode>' + CHAR(13) + 
			N'	<StageCode></StageCode>' + CHAR(13) + 
			N'	<ProfitCenterCode></ProfitCenterCode>' + CHAR(13) + 
			N'	<TerritoryName></TerritoryName>' + CHAR(13) + 
			N'	<AssetAccount></AssetAccount>' + CHAR(13) + 
			N'	<FirstDeprDate></FirstDeprDate>' + CHAR(13) + 
			N'	<Quantity></Quantity>' + CHAR(13) + 
			N'	<OriginalCost1></OriginalCost1>' + CHAR(13) + 
			N'	<Depreciation1></Depreciation1>' + CHAR(13) + 
			N'	<NetBookValue1></NetBookValue1>' + CHAR(13) + 
			N'	<IncreaseOriginalCost></IncreaseOriginalCost>' + CHAR(13) +
			N'	<DecreaseOriginalCost></DecreaseOriginalCost>' + CHAR(13) +@_LAYOUT_XML + CHAR(13) +
			N'	<IncreaseDeprAmount></IncreaseDeprAmount>' + CHAR(13) + 
			N'	<OriginalCost2></OriginalCost2>' + CHAR(13) + 
			N'	<Depreciation2></Depreciation2>' + CHAR(13) + 
			N'	<NetBookValue2></NetBookValue2>' + CHAR(13) + 
			N'	<_GroupOrder></_GroupOrder>' + CHAR(13) + 
			N'	<DeptId></DeptId>' + CHAR(13) + 
			N'</Cols></Content></DefaultReport>'

	DROP TABLE IF EXISTS #BcTmp
	DROP TABLE IF EXISTS #Tree
	DROP TABLE IF EXISTS #T_KhTsByMonth;
	DROP TABLE IF EXISTS #T_NgTs;
	DROP TABLE IF EXISTS #T_SoTmp9;
	DROP TABLE IF EXISTS #_AssetFilter;

END

GO


SET DATEFORMAT DMY;
EXEC usp_Tth_AssetSummaryTableByTime_test  @_DocDate1 = '01/01/2026 00:00:00.000'
                                        , @_DocDate2 = '31/01/2026 00:00:00.000'
                                        , @_ShownIncreaseDeprColumn = 0
                                        , @_FiscalYear = 2026
                                        , @_nUserId = 1213
                                        , @_LangId = 0
                                        , @_BranchCode = 'I26'
                                        , @_CurrencyCode0 = 'VND'
                                        , @_AssetId = '3378543';
                                        --, @_AssetId = 'C23ATM0019,3378541,3399857,3378543,3378562,3378563';