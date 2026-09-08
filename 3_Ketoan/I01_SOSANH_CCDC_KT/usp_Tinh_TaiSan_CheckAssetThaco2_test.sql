SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC dbo.usp_Tinh_TaiSan_CheckAssetThaco2_test
	@_DocDate1 DATETIME= NULL,
	@_DocDate2 DATETIME= NULL,
	@_tblTmp NVARCHAR(32)='',
	@_DefinitionTableName  NVARCHAR(32)		= N'B10CheckAsset2',
	@_nUserId INT = 0,
	@_LangId INT =0,
	@_BranchCode1 NVARCHAR(512) = '',
	@_Not_BranchCode1 NVARCHAR(512) = '',
	@_Not_BranchCode1Detail NVARCHAR(512) = '',		
	@_BranchCode NCHAR(3)			= N'A00',
	@_CurrencyCode0 NVARCHAR(3)		= N'VND',
	@_NewVer TINYINT=1 ,--Cuonglm viet lai vi bao cao xu ly  sai tinhs chat tk 214
	@_BranchReportId INT = NULL,		-- V?LA x? lý báo báo IAS/IFRS,
	@_PRINT_Exec INT = 0
AS	
BEGIN
	SET NOCOUNT ON;
	DECLARE @_DocDateTmp DATETIME= NULL, @_DataCode_Branch VARCHAR(8),@_StrExec NVARCHAR(MAX)=''
	
	SELECT @_DataCode_Branch = ISNULL((SELECT TOP (1) DataCode FROM dbo.B00Branch WHERE BranchCode = @_BranchCode), '0')	

	IF OBJECT_ID(N'Tempdb..#tblTmp1') IS NOT NULL DROP TABLE #tblTmp1			
		CREATE TABLE #tblTmp1 (Id INT DEFAULT 0)	
		EXECUTE usp_sys_CreateTable '#tblTmp1', @_DefinitionTableName		
		EXECUTE usp_sys_Append @_DefinitionTableName, '#tblTmp1'
		
	IF @_NewVer=1
	BEGIN 
		UPDATE #tblTmp1
		SET TableSource_AssetT = N'#T_CdTmp2.IncDepreciation',
			TableSource_AssetG = N'#T_CdTmp2.DeDepreciation',
			Key_Where_AssetG = REPLACE(Key_Where_AssetG, 'AssetTransType=''KHAUHAO''', '1=1')
		WHERE Account LIKE N'214%'
	END 

	ALTER TABLE #tblTmp1
	ADD OpenAmountAccount NUMERIC(18, 2) DEFAULT 0 NOT NULL, DebitAmountAccount NUMERIC(18, 2) DEFAULT 0 NOT NULL, CreditAmountAccount NUMERIC(18, 2) DEFAULT 0 NOT NULL, CloseAmountAccount NUMERIC(18, 2) DEFAULT 0 NOT NULL, OpenAmountAsset NUMERIC(18, 2) DEFAULT 0 NOT NULL, AmountAssetT NUMERIC(18, 2) DEFAULT 0 NOT NULL, AmountAssetG NUMERIC(18, 2) DEFAULT 0 NOT NULL, CloseAmountAsset NUMERIC(18, 2) DEFAULT 0 NOT NULL;				
	-- ??u k?
	IF OBJECT_ID('TempDb..#T_CdTmp') IS NOT NULL DROP TABLE #T_CdTmp;
	SELECT TOP 0 CAST(0 AS INT) AS Id, IsGroup, ParentId, CAST('' AS NCHAR(3)) AS BranchCode, Code, CAST('' AS NVARCHAR(16)) AS IncrNo, Name, Unit, CardNo, MadeIn, MadeYear, Capacity, UsefulYear, AssetAccount, FirstUsedDate, FirstDeprDate, CAST(NULL AS SMALLDATETIME) AS LastDeprDate, CAST(0 AS NUMERIC(18, 2)) AS OriginalCost, CAST(0 AS NUMERIC(18, 2)) AS Depreciation, CAST(0 AS NUMERIC(18, 2)) AS NetBookValue, CAST(0 AS NUMERIC(18, 2)) AS AmountForDepr, CAST(0 AS NUMERIC(15)) AS Quantity, CAST('' AS NCHAR(16)) AS EquityCode, CAST('' AS NCHAR(24)) AS ProductId, CAST('' AS NCHAR(16)) AS ExpenseCatgCode, CAST('' AS NCHAR(24)) AS DeptCode, CAST('' AS NCHAR(16)) AS DeprDebitAccount, CAST('' AS NCHAR(16)) AS DeprCreditAccount, CAST(0 AS INT) AS AssetId, CAST(0 AS INT) AS EquityId, CAST(0 AS INT) AS ExpenseCatgId, CAST(0 AS INT) AS DeptId
	INTO #T_CdTmp
	FROM B20Asset;
  
	ALTER TABLE #T_CdTmp ADD AssetCode NVARCHAR(24) DEFAULT '' NOT NULL   	
 
	-- Cu?i k?
	IF OBJECT_ID('TempDb..#T_CdTmp2') IS NOT NULL DROP TABLE #T_CdTmp2;
	SELECT TOP 0 CAST(0 AS INT) AS Id, IsGroup, ParentId, CAST('' AS NVARCHAR(16)) AS IncrNo, CAST('' AS NCHAR(3)) AS BranchCode, Code, Name, Unit, CardNo, MadeIn, MadeYear, Capacity, UsefulYear, AssetAccount, FirstUsedDate, FirstDeprDate, CAST(NULL AS SMALLDATETIME) AS LastDeprDate, CAST(0 AS NUMERIC(18, 2)) AS OriginalCost, CAST(0 AS NUMERIC(18, 2)) AS Depreciation, CAST(0 AS NUMERIC(18, 2)) AS NetBookValue, CAST(0 AS NUMERIC(18, 2)) AS AmountForDepr, CAST(0 AS NUMERIC(15)) AS Quantity, CAST('' AS NCHAR(16)) AS EquityCode, CAST('' AS NCHAR(24)) AS ProductId, CAST('' AS NCHAR(16)) AS ExpenseCatgCode, CAST('' AS NCHAR(24)) AS DeptCode, CAST('' AS NCHAR(16)) AS DeprDebitAccount, CAST('' AS NCHAR(16)) AS DeprCreditAccount, CAST(0 AS NUMERIC(18, 2)) AS DeOriginalCost, CAST(0 AS NUMERIC(18, 2)) AS DeDepreciation_Capital, CAST(0 AS NUMERIC(18, 2)) AS IncOriginalCost, CAST(0 AS NUMERIC(18, 2)) AS DeDepreciation, --Cuonglm them xu lys lai tang giam khau hao(bao cao viet sai tinh chat tk)
		CAST(0 AS NUMERIC(18, 2)) AS IncDepreciation, CAST(0 AS INT) AS AssetId, CAST(0 AS INT) AS EquityId, CAST(0 AS INT) AS ExpenseCatgId, CAST(0 AS INT) AS DeptId
	INTO #T_CdTmp2
	FROM B20Asset;
  
	ALTER TABLE #T_CdTmp2 ADD AssetCode NVARCHAR(16) DEFAULT '' NOT NULL
	
	-- S? phát sinh
	SELECT TOP 0 *, CAST('' AS NVARCHAR(56)) AS EquityCode, CAST('' AS DATE) AS DocDateIncr, CAST('' AS NVARCHAR(56)) AS ExpenseCatgCode, CAST('' AS NVARCHAR(24)) AS DeptCode, CAST('' AS NVARCHAR(56)) AS AssetTransCode
	INTO #T_SoTmp0
	FROM vB30AssetDoc;

	SELECT TOP 0 *, CAST('' AS NVARCHAR(56)) AS EquityCode, CAST('' AS DATE) AS DocDateIncr, CAST('' AS NVARCHAR(56)) AS ExpenseCatgCode, CAST('' AS NVARCHAR(24)) AS DeptCode, CAST('' AS NVARCHAR(56)) AS AssetTransCode
	INTO #T_SoTmp9
	FROM vB30AssetDoc;
       
	  EXECUTE usp_B30AssetDoc_GetData
		@_Date1 = '',
		@_Date2 = @_DocDate2,
		@_Key1 = '',
		@_CtTmp = N'#T_SoTmp0',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode
 
	--TuanPT t?m th?i rào
	--UPDATE #T_SoTmp0 SET AssetTransType='KHAUHAO' WHERE isKH=1 AND AssetTransType=''

	UPDATE #T_SoTmp0 SET DocDateIncr=DocDate
	UPDATE #T_SoTmp0 SET EquityCode=b.Code FROM #T_SoTmp0 a LEFT OUTER JOIN dbo.B20Equity b ON a.EquityId=b.Id
	UPDATE #T_SoTmp0 SET ExpenseCatgCode=b.Code FROM #T_SoTmp0 a LEFT OUTER JOIN dbo.B20ExpenseCatg b ON a.ExpenseCatgId=b.Id
	UPDATE #T_SoTmp0 SET DeptCode=b.Code FROM #T_SoTmp0 a LEFT OUTER JOIN dbo.B20Dept b ON a.DeptId=b.Id
	UPDATE #T_SoTmp0 SET AssetTransCode=b.Code FROM #T_SoTmp0 a LEFT OUTER JOIN dbo.B20AssetTrans b ON a.AssetTransId=b.Id
    	
	--- insert vao  b?ng chi ti?t t?ng
	INSERT INTO #T_SoTmp9
	SELECT * FROM #T_SoTmp0 
	WHERE CASE WHEN DocDateIncr  IS NULL THEN  DocDate  ELSE DocDateIncr END BETWEEN @_DocDate1 AND @_DocDate2 AND BranchCode =@_BranchCode	
	
	----------------------------------- thuc hien insert ban dau ky tai san
	IF @_DocDate1 = '' 
		BEGIN
		   SET @_DocDateTmp = @_DocDate1
		END
	ELSE
		BEGIN
			SET @_DocDateTmp = @_DocDate1 - 1
		END; 
		
	-- ?? d? li?u vào b?ng ??u k?
	SET @_StrExec=''
	SET @_StrExec =  '
	WITH ResumeDepreciation AS (
		SELECT MAX(b.Code) AS AssetCode, MAX(a.DocDate) AS LastTransDate
		FROM vB3' + @_DataCode_Branch + 'AssetDoc_ResumeDepreciation a
		LEFT OUTER JOIN dbo.B2' + @_DataCode_Branch + 'Asset b ON a.AssetId = b.Id
		WHERE a.DocDate <= @_DocDateTmp
		GROUP BY a.AssetId
	),
	SuspendDepreciation AS (
		SELECT MAX(b.Code) AS AssetCode, MAX(a.DocDate) AS LastTransDate
		FROM vB3' + @_DataCode_Branch + 'AssetDoc_SuspendDepreciation a
		LEFT OUTER JOIN dbo.B2' + @_DataCode_Branch + 'Asset b ON a.AssetId = b.Id
		WHERE a.DocDate <= @_DocDateTmp
		GROUP BY a.AssetId
	)
	INSERT INTO #T_CdTmp(
		Id, IsGroup, ParentId, BranchCode, Code, AssetCode, Name, Unit, CardNo, MadeIn, MadeYear, Capacity,
		UsefulYear, AssetAccount, FirstUsedDate, FirstDeprDate, LastDeprDate, OriginalCost, Depreciation,
		NetBookValue, AmountForDepr, Quantity, EquityCode, ProductId, ExpenseCatgCode, DeptCode,
		DeprDebitAccount, DeprCreditAccount
	)
	SELECT 
		DmTs.Id, ISNULL(DmTs.IsGroup,0), ISNULL(DmTs.ParentId,-1), DmTs.BranchCode, DmTs.Code, DmTs.Code AS AssetCode, 
		DmTs.Name, DmTs.Unit, DmTs.CardNo, DmTs.MadeIn, DmTs.MadeYear, DmTs.Capacity, 
		DmTs.UsefulYear, DmTs.AssetAccount, DmTs.FirstUsedDate, DmTs.FirstDeprDate,
		CASE 
			WHEN ISNULL(ResumeDate.LastTransDate, '''') > ISNULL(SuspendDate.LastTransDate, '''') 
			THEN CAST(NULL AS Smalldatetime)
			ELSE SuspendDate.LastTransDate 
		END AS LastDeprDate,
		ISNULL(CtTsView.OriginalCost, 0) as OriginalCost , ISNULL(CtTsView.Depreciation, 0) as Depreciation,
		ISNULL(CtTsView.OriginalCost - CtTsView.Depreciation, 0) as NetBookValue, 
		CtTsView.AmountForDepr, CtTsView.Quantity, CtTsView.EquityCode,
		CtTsView.ProductId, CtTsView.ExpenseCatgCode, CtTsView.DeptCode,
		CtTsView.DeprDebitAccount, CtTsView.DeprCreditAccount
	FROM dbo.B2' + @_DataCode_Branch + 'Asset AS DmTs
	RIGHT OUTER JOIN (
		SELECT 
			AssetCode, EquityCode, BranchCode,
			ISNULL(SUM(Quantity * Trans), 0) AS Quantity,
			ISNULL(SUM(OriginalCost * Trans), 0) AS OriginalCost,
			ISNULL(SUM(Depreciation * Trans), 0) AS Depreciation,
			ISNULL(SUM(AmountForDepr * Trans), 0) AS AmountForDepr,
			ISNULL(MAX(ProductId), CAST('''' AS NChar(24))) AS ProductId,
			ISNULL(MAX(ExpenseCatgCode), CAST('''' AS NChar(16))) AS ExpenseCatgCode,
			ISNULL(MAX(DeptCode), CAST('''' AS NChar(16))) AS DeptCode,
			ISNULL(MAX(DeprDebitAccount), CAST('''' AS NChar(16))) AS DeprDebitAccount,
			ISNULL(MAX(DeprCreditAccount), CAST('''' AS NChar(16))) AS DeprCreditAccount
		FROM #T_SoTmp0
		WHERE CASE WHEN DocDateIncr IS NULL THEN DocDate ELSE DocDateIncr END < @_DocDate1
		GROUP BY BranchCode, AssetCode, EquityCode
	) AS CtTsView ON DmTs.Code = CtTsView.AssetCode AND DmTs.BranchCode = CtTsView.BranchCode
	LEFT OUTER JOIN SuspendDepreciation AS SuspendDate ON DmTs.Code = SuspendDate.AssetCode
	LEFT OUTER JOIN ResumeDepreciation AS ResumeDate ON DmTs.Code = ResumeDate.AssetCode '
	
	EXEC sp_executesql @_StrExec,
					N'@_DocDateTmp DATE OUTPUT, @_DocDate1 DATE OUTPUT',
					@_DocDateTmp OUTPUT,@_DocDate1 OUTPUT
						
	UPDATE #T_CdTmp
	SET ProductId=B.ProductId, ExpenseCatgCode=B.ExpenseCatgCode, DeptCode=B.DeptCode, DeprDebitAccount=B.DeprDebitAccount, DeprCreditAccount=B.DeprCreditAccount
	FROM #T_CdTmp AS A
		 INNER JOIN(SELECT DISTINCT D.BranchCode, D.AssetCode, D.EquityCode, ProductId, ExpenseCatgCode, DeptCode, DeprDebitAccount, DeprCreditAccount, E.DocDate
					FROM #T_SoTmp0 AS D
						 INNER JOIN(SELECT DISTINCT BranchCode, AssetCode, EquityCode, MAX(DocDate) AS DocDate
									FROM #T_SoTmp0
									WHERE DocGroup<>N'2' AND AssetTransType<>N'KHAUHAO' AND DocDate<@_DocDate1
									GROUP BY BranchCode, AssetCode, EquityCode) AS E ON D.BranchCode=E.BranchCode AND D.AssetCode=E.AssetCode AND D.EquityCode=E.EquityCode AND D.DocDate=E.DocDate
					WHERE D.DocDate<=@_DocDate1 AND D.DeprDebitAccount<>'') AS B ON A.BranchCode=B.BranchCode AND A.Code=B.AssetCode AND A.EquityCode=B.EquityCode;
	
	-- ket thuc dua dau ky vào
	----------------------------------- thuc hien insert ban cuoi ky tai san
	IF @_DocDate2 = '' 
		BEGIN
		   SET @_DocDateTmp = @_DocDate2
		END
	ELSE
		BEGIN
			SET @_DocDateTmp = @_DocDate2 - 1
		END;

 
	SET @_StrExec = ''
	SET @_StrExec = @_StrExec + '
	WITH ResumeDepreciation AS (
		SELECT MAX(b.Code) AS AssetCode, MAX(a.DocDate) AS LastTransDate
		FROM vB3' + @_DataCode_Branch + 'AssetDoc_ResumeDepreciation a
		LEFT OUTER JOIN dbo.B2' + @_DataCode_Branch + 'Asset b ON a.AssetId = b.Id
		WHERE a.DocDate <= @_DocDateTmp
		GROUP BY a.AssetId
	),
	SuspendDepreciation AS (
		SELECT MAX(b.Code) AS AssetCode, MAX(a.DocDate) AS LastTransDate
		FROM vB3' + @_DataCode_Branch + 'AssetDoc_SuspendDepreciation a
		LEFT OUTER JOIN dbo.B2' + @_DataCode_Branch + 'Asset b ON a.AssetId = b.Id
		WHERE a.DocDate <= @_DocDateTmp
		GROUP BY a.AssetId
	)
	INSERT INTO #T_CdTmp2(
		Id, IsGroup, ParentId, BranchCode, Code, AssetCode, Name, Unit, CardNo, MadeIn, MadeYear, Capacity,
		UsefulYear, AssetAccount, FirstUsedDate, FirstDeprDate, LastDeprDate, OriginalCost, Depreciation,
		NetBookValue, AmountForDepr, Quantity, EquityCode, ProductId, ExpenseCatgCode, DeptCode,
		DeprDebitAccount, DeprCreditAccount
	)
	SELECT 
		DmTs.Id, DmTs.IsGroup, DmTs.ParentId, DmTs.BranchCode, DmTs.Code, DmTs.Code AS AssetCode,
		DmTs.Name, DmTs.Unit, DmTs.CardNo, DmTs.MadeIn, DmTs.MadeYear, DmTs.Capacity,
		DmTs.UsefulYear, DmTs.AssetAccount, DmTs.FirstUsedDate, DmTs.FirstDeprDate,
		CASE 
			WHEN ISNULL(ResumeDate.LastTransDate, '''') > ISNULL(SuspendDate.LastTransDate, '''')
			THEN CAST(NULL AS Smalldatetime)
			ELSE SuspendDate.LastTransDate 
		END AS LastDeprDate,
		ISNULL(CtTsView.OriginalCost, 0), ISNULL(CtTsView.Depreciation, 0),
		ISNULL(CtTsView.OriginalCost - CtTsView.Depreciation, 0),
		CtTsView.AmountForDepr, CtTsView.Quantity, CtTsView.EquityCode,
		CtTsView.ProductId, CtTsView.ExpenseCatgCode, CtTsView.DeptCode,
		CtTsView.DeprDebitAccount, CtTsView.DeprCreditAccount
	FROM dbo.B2' + @_DataCode_Branch + 'Asset AS DmTs
	RIGHT OUTER JOIN (
		SELECT 
			AssetCode, EquityCode, BranchCode,
			ISNULL(SUM(Quantity * Trans), 0) AS Quantity,
			ISNULL(SUM(OriginalCost * Trans), 0) AS OriginalCost,
			ISNULL(SUM(Depreciation * Trans), 0) AS Depreciation,
			ISNULL(SUM(AmountForDepr * Trans), 0) AS AmountForDepr,
			ISNULL(MAX(ProductId), CAST('''' AS NChar(24))) AS ProductId,
			ISNULL(MAX(ExpenseCatgCode), CAST('''' AS NChar(16))) AS ExpenseCatgCode,
			ISNULL(MAX(DeptCode), CAST('''' AS NChar(24))) AS DeptCode,
			ISNULL(MAX(DeprDebitAccount), CAST('''' AS NChar(16))) AS DeprDebitAccount,
			ISNULL(MAX(DeprCreditAccount), CAST('''' AS NChar(16))) AS DeprCreditAccount
		FROM #T_SoTmp0
		WHERE CASE WHEN DocDateIncr IS NULL THEN DocDate ELSE DocDateIncr END <= @_DocDate2
		GROUP BY BranchCode, AssetCode, EquityCode
	) AS CtTsView ON DmTs.Code = CtTsView.AssetCode AND DmTs.BranchCode = CtTsView.BranchCode
	LEFT OUTER JOIN SuspendDepreciation AS SuspendDate ON DmTs.Code = SuspendDate.AssetCode
	LEFT OUTER JOIN ResumeDepreciation AS ResumeDate ON DmTs.Code = ResumeDate.AssetCode
	'
	 EXEC sp_executesql @_StrExec, 
		 N'@_DocDateTmp DATE OUTPUT,@_DocDate2 DATE OUTPUT',@_DocDateTmp OUTPUT,@_DocDate2 OUTPUT

	UPDATE #T_CdTmp2 SET ProductId = B.ProductId, ExpenseCatgCode = B.ExpenseCatgCode, DeptCode = B.DeptCode, 
					DeprDebitAccount = B.DeprDebitAccount, DeprCreditAccount = B.DeprCreditAccount
	FROM #T_CdTmp2 AS A INNER JOIN (SELECT DISTINCT D.BranchCode, D.AssetCode, D.EquityCode, 
											   ProductId, ExpenseCatgCode, DeptCode, DeprDebitAccount, DeprCreditAccount, E.DocDate
									FROM #T_SoTmp0 AS D
												INNER JOIN (
	                         								SELECT DISTINCT BranchCode, AssetCode, EquityCode, MAX(DocDate) AS DocDate
	                         								FROM #T_SoTmp0
	                         								WHERE DocGroup <> N'2' AND AssetTransType <> N'KHAUHAO' AND DocDate<=@_DocDate2
	                         								GROUP BY BranchCode, AssetCode, EquityCode) AS E
	                         								ON D.BranchCode = E.BranchCode AND D.AssetCode = E.AssetCode AND 
	                         								D.EquityCode = E.EquityCode AND D.DocDate = E.DocDate
		                                WHERE D.DocDate<=@_DocDate2) AS B
				ON A.BranchCode = B.BranchCode AND A.Code = B.AssetCode AND A.EquityCode = B.EquityCode	
				
	UPDATE #T_CdTmp2 SET EquityId=b.Id FROM #T_CdTmp2 a INNER JOIN dbo.B20Equity b ON a.EquityCode=b.Code
	UPDATE #T_CdTmp2 SET ExpenseCatgId=b.Id FROM #T_CdTmp2 a INNER JOIN dbo.B20ExpenseCatg b ON a.ExpenseCatgCode=b.Code
	UPDATE #T_CdTmp2 SET DeptId=b.Id FROM #T_CdTmp2 a INNER JOIN dbo.B20Dept b ON a.DeptCode=b.Code
	
	SET @_StrExec = 'UPDATE #T_CdTmp2 SET AssetId = b.Id FROM #T_CdTmp2 a LEFT OUTER JOIN dbo.B2' + @_DataCode_Branch + 'Asset b  ON a.AssetCode = b.Code'
	EXEC(@_StrExec)  
 	
	SET @_StrExec = '
	UPDATE #T_CdTmp2
	SET 
		IncOriginalCost = ISNULL(T2.IncOriginalCost, 0),
		DeOriginalCost = ISNULL(T2.DeOriginalCost, 0),
		DeDepreciation_Capital = ISNULL(T2.Depreciation, 0),
		Quantity = T2.Quantity
	FROM #T_CdTmp2 T
	INNER JOIN (
		SELECT 
			AssetCode,
			EquityId,
			SUM(IncOriginalCost) AS IncOriginalCost,
			SUM(ISNULL(DeOriginalCost, 0)) AS DeOriginalCost,
			SUM(Depreciation) AS Depreciation,
			SUM(DeDepreciation) AS DeDepreciation,
			SUM(IncDepreciation) AS IncDepreciation,
			SUM(Quantity) AS Quantity
		FROM vB3' + @_DataCode_Branch + 'AssetDoc_Detail
		WHERE 
			DocDate BETWEEN @_DocDate1 AND @_DocDate2
			AND AssetTransType = ''''
			AND BranchCode = @_BranchCode
			AND IsActive = 1
		GROUP BY AssetCode, EquityId
	) T2 ON T.AssetCode = T2.AssetCode AND T.EquityId = T2.EquityId'
	 EXEC sp_executesql @_StrExec, 
		 N'@_DocDate1 DATE OUTPUT,@_DocDate2 DATE OUTPUT,@_BranchCode NVARCHAR(16) OUTPUT',
		   @_DocDate1 OUTPUT,@_DocDate2 OUTPUT,@_BranchCode OUTPUT
 
	--Cuonglm them doan nay	
	SET @_StrExec =  '
	UPDATE #T_CdTmp2
	SET 
		DeDepreciation = ISNULL(T2.DeDepreciation, 0),
		IncDepreciation = ISNULL(T2.IncDepreciation, 0),
		DeOriginalCost = ISNULL(T2.DeOriginalCost, 0)
	FROM #T_CdTmp2 T
	INNER JOIN (
		SELECT 
			AssetCode,
			EquityId,
			SUM(ISNULL(DeOriginalCost, 0)) AS DeOriginalCost,
			SUM(Depreciation) AS Depreciation,
			SUM(DeDepreciation) AS DeDepreciation,
			SUM(IncDepreciation) AS IncDepreciation,
			SUM(Quantity) AS Quantity
		FROM vB3' + @_DataCode_Branch + 'AssetDoc
		WHERE 
			DocDate BETWEEN @_DocDate1 AND @_DocDate2
			AND BranchCode = @_BranchCode
			AND IsActive = 1
		GROUP BY AssetCode, EquityId
	) T2 ON T.AssetCode = T2.AssetCode AND T.EquityId = T2.EquityId
	'
	 EXEC sp_executesql @_StrExec, 
		 N'@_DocDate1 DATE OUTPUT,@_DocDate2 DATE OUTPUT,@_BranchCode NVARCHAR(16) OUTPUT',
		   @_DocDate1 OUTPUT,@_DocDate2 OUTPUT,@_BranchCode OUTPUT
			
	--quanhp: sua lai lay phat sinh giam (2022/11/10)
	UPDATE #T_CdTmp2 SET DeDepreciation_Capital = DeDepreciation

	---- ket thuc insert cuoi ky
	------------cong cu---------------------	
	--------------------So du Cong cu dung cu--------------------------------------------------        
     IF OBJECT_ID('TempDb..#CtTmpCc', 'U') IS NOT NULL DROP TABLE #CtTmpCc   
     CREATE TABLE #CtTmpCc (Id INT DEFAULT 0)
 
     EXECUTE usp_sys_CreateTable N'#CtTmpCc', N'vB30AssetDoc'
     EXECUTE usp_sys_DefaultTable N'#CtTmpCc'
 
     ALTER TABLE #CtTmpCc ADD _Head SMALLINT DEFAULT 1

     ALTER TABLE #CtTmpCc ADD OriginalCostDecrease_tk NUMERIC(18,0) DEFAULT 0

	 ALTER TABLE #CtTmpCc ADD DeprDeptId INT

	 ALTER TABLE #CtTmpCc ADD DocDateIncr DATE 
	 ALTER TABLE #CtTmpCc ADD DeptCode NVARCHAR(56) 	 
	 ALTER TABLE #CtTmpCc ADD DeprDeptCode NVARCHAR(56) 

	 ALTER TABLE #CtTmpCc ADD ExpenseCatgCode NVARCHAR(56) 
	 ALTER TABLE #CtTmpCc ADD ProfitCenterCode NVARCHAR(56) 
	 ALTER TABLE #CtTmpCc ADD StageCode NVARCHAR(56) 
 
     EXECUTE usp_B30AssetDoc_GetData
             @_Date1 = '',
             @_Date2 = @_DocDate2,
             @_AssetType = 1,
             @_Key1      = '',
             @_CtTmp     = N'#CtTmpCc',
             @_nUserId   = @_nUserId,
             @_LangId    = @_LangId,
             @_BranchCode    = @_BranchCode
			 --,@_PRINT_Exec = 1
 
	UPDATE #CtTmpCc SET DocDateIncr=DocDate

	UPDATE #CtTmpCc SET ProfitCenterCode=b.Code FROM #CtTmpCc a LEFT OUTER JOIN dbo.B20ProfitCenter b ON a.ProfitCenterId=b.Id

	UPDATE #CtTmpCc SET ExpenseCatgCode=b.Code FROM #CtTmpCc a LEFT OUTER JOIN dbo.B20ExpenseCatg b ON a.ExpenseCatgId=b.Id

	UPDATE #CtTmpCc SET DeptCode=b.Code FROM #CtTmpCc a LEFT OUTER JOIN dbo.B20Dept b ON a.DeptId=b.Id

	UPDATE #CtTmpCc SET DeprDeptCode=b.Code FROM #CtTmpCc a LEFT OUTER JOIN dbo.B20Dept b ON a.DeprDeptId=b.Id

	UPDATE #CtTmpCc SET StageCode=b.Code FROM #CtTmpCc a LEFT OUTER JOIN dbo.B20ZStage b ON a.StageId=b.Id
		 
	--quanhp: lay ngay giong bao cao ben tai san
	UPDATE #CtTmpCc SET DocDate = DocDateIncr WHERE DocDateIncr IS NOT NULL
	
	UPDATE #CtTmpCc SET _Head=-1 WHERE DocGroup = '2'	 
 
	DELETE FROM #CtTmpCc
	WHERE AssetCode IN(SELECT DISTINCT AssetCode
					   FROM #CtTmpCc
					   WHERE AssetTransType='GIAMTAISAN' AND DocDate < @_DocDate1 AND BranchCode=@_BranchCode);
	
	SELECT TOP 0 MAX(ISNULL(ccdc.Id, -1)) AS Id, MAX(ISNULL(ccdc.ParentId, -1)) AS ParentId, MAX(CASE WHEN ISNULL(ccdc.IsGroup, 0)=0 THEN 0 ELSE 1 END) AS IsGroup, tb.AssetCode, tb.BranchCode, MAX(ccdc.Name) AS AssetName, MAX(ccdc.Unit) AS Unit, SUM(tb.IncQuantity-tb.DeQuantity) AS Quantity,	 
		MIN(tb.DocDate) AS DocDate, MAX(tb.UsefulMonth) AS UsefulMonth, MAX(DeptCode) AS DeptCode, MAX(StageCode) AS StageCode, MAX(DeprDeptCode) AS DeprDeptCode, MAX(ExpenseCatgCode) AS ExpenseCatgCode, MAX(ProfitCenterCode) AS ProfitCenterCode, MAX(DeprDebitAccount) AS DeprDebitAccount, MAX(DeprCreditAccount) AS DeprCreditAccount, SUM(tb.OriginalCost * _Head) AS OriginalCost, SUM(CASE WHEN tb.DocDate<@_DocDate1 THEN tb.OriginalCost * _Head ELSE CAST(0 AS NUMERIC(18, 2))END) AS OpenOriginalCost, SUM(CASE WHEN tb.DocDate<@_DocDate1 THEN tb.Depreciation * _Head ELSE CAST(0 AS NUMERIC(18, 2))END) AS OpenDepreciation, CAST(0 AS NUMERIC(18, 2)) AS OpenBookValue, SUM(CASE WHEN tb.DocDate>=@_DocDate1 THEN tb.OriginalCost * _Head ELSE CAST(0 AS NUMERIC(18, 2))END) AS ThisPeriodOriginalCost, SUM(CASE WHEN tb.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND tb.AssetTransType<>'GIAMTAISAN' THEN tb.Depreciation * _Head ELSE CAST(0 AS NUMERIC(18, 2))END) AS Depreciation, -- trunght them doan nay de bat phan bo trong ky   (quanhp bo sung *_Head)      
		SUM(CASE WHEN tb.DocDate>=@_DocDate1 AND tb.AssetTransType<>'GIAMTAISAN' THEN tb.Depreciation * _Head ELSE CAST(0 AS NUMERIC(18, 2))END+CASE WHEN tb.AssetTransType='GIAMTAISAN' THEN tb.NetBookValue ELSE 0 END) AS ThisPeriodDepreciation, SUM(tb.OriginalCost * _Head) AS CloseOriginalCost, SUM(CASE WHEN tb.AssetTransType='GIAMTAISAN' THEN tb.NetBookValue ELSE tb.Depreciation * _Head END) AS CloseDepreciation, CAST(0 AS NUMERIC(18, 2)) AS CloseBookValue, CAST(0 AS NUMERIC(18, 2)) AS OriginalCostIncrease, CAST(0 AS NUMERIC(18, 2)) AS OriginalCostDecrease, CAST('' AS NVARCHAR(MAX)) AS _GroupOrder, CAST('' AS NVARCHAR(24)) AS _FormatStyleKey, SUM(CASE WHEN tb.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND tb.AssetTransType LIKE 'G%' THEN tb.OriginalCost ELSE CAST(0 AS NUMERIC(18, 2))END) AS GiamTrongKy -- quanhp
	INTO #BcTempCc
	FROM #CtTmpCc tb
		 LEFT OUTER JOIN B2101Asset ccdc ON ccdc.Code=tb.AssetCode
	GROUP BY tb.AssetCode, tb.BranchCode;

   --??U K? CCDC
   SET @_StrExec = 
	'INSERT INTO #BcTempCc (
		Id, ParentId, IsGroup, AssetCode, BranchCode, AssetName, Unit, Quantity, DocDate, UsefulMonth,
		DeptCode, StageCode, DeprDeptCode, ExpenseCatgCode, ProfitCenterCode,
		DeprDebitAccount, DeprCreditAccount, OriginalCost, OpenOriginalCost, OpenDepreciation, OpenBookValue,
		ThisPeriodOriginalCost, Depreciation, ThisPeriodDepreciation, CloseOriginalCost, CloseDepreciation,
		CloseBookValue, OriginalCostIncrease, OriginalCostDecrease, _GroupOrder, _FormatStyleKey, GiamTrongKy
	) SELECT 
		MAX(ISNULL(ccdc.Id, -1)) as Id, MAX(ISNULL(ccdc.ParentId, -1)) as ParentId,
		MAX(CASE WHEN ISNULL(ccdc.IsGroup, 0) = 0 THEN 0 ELSE 1 END) as IsGroup,
		tb.AssetCode, tb.BranchCode, MAX(ccdc.Name), MAX(ccdc.Unit),
		SUM(tb.IncQuantity - tb.DeQuantity), MIN(tb.DocDate) as DocDate, MAX(tb.UsefulMonth) as UsefulMonth,
		MAX(DeptCode), MAX(StageCode), MAX(DeprDeptCode), MAX(ExpenseCatgCode), MAX(ProfitCenterCode),
		MAX(DeprDebitAccount), MAX(DeprCreditAccount), 
		SUM(tb.OriginalCost*_Head) as OriginalCost,
		SUM(CASE WHEN tb.DocDate < @_DocDate1 THEN tb.OriginalCost*_Head ELSE 0 END) as OpenOriginalCost,
		SUM(CASE WHEN tb.DocDate < @_DocDate1 THEN tb.Depreciation*_Head ELSE 0 END) as OpenDepreciation,
		0 as OpenBookValue,
		SUM(CASE WHEN tb.DocDate >= @_DocDate1 THEN tb.OriginalCost*_Head ELSE 0 END) as ThisPeriodOriginalCost,
		SUM(CASE WHEN tb.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND Tb.AssetTransType <> ''GIAMTAISAN'' 
			THEN tb.Depreciation*_Head ELSE 0 END) as Depreciation,
		SUM(CASE WHEN tb.DocDate >= @_DocDate1 AND tb.AssetTransType <> ''GIAMTAISAN'' THEN tb.Depreciation*_Head ELSE 0 END
			+ CASE WHEN tb.AssetTransType = ''GIAMTAISAN'' THEN tb.NetBookValue ELSE 0 END) as ThisPeriodDepreciation,
		SUM(tb.OriginalCost*_Head) as CloseOriginalCost ,
		SUM(CASE WHEN tb.AssetTransType = ''GIAMTAISAN'' THEN tb.NetBookValue ELSE tb.Depreciation*_Head END) as CloseDepreciation,
		0 as CloseBookValue , 0 as OriginalCostIncrease , 0 as OriginalCostDecrease, '''' as _GroupOrder , '''' as _FormatStyleKey ,
		SUM(CASE WHEN tb.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND Tb.AssetTransType LIKE ''G%'' THEN tb.OriginalCost ELSE 0 END) as GiamTrongKy
	FROM #CtTmpCc tb
	LEFT OUTER JOIN B2' + @_DataCode_Branch + 'Asset ccdc ON ccdc.Code = tb.AssetCode
	GROUP BY tb.AssetCode, tb.BranchCode'
	 EXEC sp_executesql @_StrExec, N'@_DocDate1 DATE OUTPUT,@_DocDate2 DATE OUTPUT,@_BranchCode NVARCHAR(16) OUTPUT',
									@_DocDate1 OUTPUT,@_DocDate2 OUTPUT,@_BranchCode OUTPUT
 
	UPDATE #BcTempCc
	SET DeprDebitAccount=T2.DeprDebitAccount, DeprCreditAccount=T2.DeprCreditAccount
	FROM #BcTempCc T1
		 INNER JOIN(SELECT AssetCode, DeptCode, DeprDeptCode, ExpenseCatgCode, ProfitCenterCode, DeprDebitAccount, DeprCreditAccount, StageCode
					FROM(SELECT ROW_NUMBER() OVER (PARTITION BY AssetCode ORDER BY DocDate DESC) AS Tt, DocDate, AssetCode, DeptCode, DeprDeptCode, ExpenseCatgCode, ProfitCenterCode, DeprDebitAccount, DeprCreditAccount, StageCode
						 FROM #CtTmpCc
						 WHERE AssetTransType<>'GIAMTAISAN') T
					WHERE Tt=1) T2 ON T1.AssetCode=T2.AssetCode;
 
    SET @_StrExec=''
	SET @_StrExec = @_StrExec + '
	UPDATE #BcTempCc  
	SET OriginalCostDecrease = tb.ThisPeriodDepreciation 
	FROM #BcTempCc tb 
	INNER JOIN vB3' + @_DataCode_Branch + 'AssetDoc ctts 
		ON tb.AssetCode = ctts.AssetCode 
		AND ctts.AssetType IN (0, 1 )
		AND AssetTransType = ''GIAMTAISAN'' 
		AND ctts.DocDate BETWEEN @_DocDate1 AND @_DocDate2  
		AND ctts.IsActive = 1 

	UPDATE #BcTempCc  
	SET CloseOriginalCost = 0, 
		CloseDepreciation = 0
	FROM #BcTempCc tb 
	INNER JOIN vB3' + @_DataCode_Branch + 'AssetDoc ctts 
		ON tb.AssetCode = ctts.AssetCode 
		AND ctts.AssetType IN (0, 1 )
		AND AssetTransType = ''GIAMTAISAN'' 
		AND ctts.DocDate <= @_DocDate2 
		AND ctts.IsActive = 1 
		AND Ctts.BranchCode = @_BranchCode'

	EXEC sp_executesql @_StrExec,
					   N'@_DocDate1 DATE OUTPUT,@_DocDate2 DATE OUTPUT,@_BranchCode NVARCHAR(16) OUTPUT',
					   @_DocDate1 OUTPUT,@_DocDate2 OUTPUT,@_BranchCode OUTPUT
 
	--quanhp : lay phan giam
	IF OBJECT_ID('TempDb..#NG_Giam', 'U') IS NOT NULL DROP TABLE #NG_Giam
	SELECT TOP 0 AssetCode, SUM(DeOriginalCost) AS DeOriginalCost
	INTO #NG_Giam
	FROM vB30AssetDoc ctts
	WHERE ctts.AssetTransId IN(SELECT Id FROM B20AssetTrans WHERE Type=2 AND IsActive=1)AND ctts.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND ctts.IsActive=1 AND ctts.AssetTransType<>'GIAMTAISAN' AND AssetCode IN(SELECT AssetCode FROM #BcTempCc)
	GROUP BY AssetCode;
 	
	SET @_StrExec = 'INSERT INTO #NG_Giam (AssetCode,DeOriginalCost) 
	SELECT AssetCode,SUM(DeOriginalCost) AS DeOriginalCost FROM vB3' + @_DataCode_Branch + 'AssetDoc ctts 
	WHERE ctts.AssetTransId IN (SELECT Id FROM B20AssetTrans WHERE [Type]=2 AND IsActive=1) 
	AND ctts.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND ctts.IsActive = 1 
	AND ctts.AssetTransType<>''GIAMTAISAN'' AND AssetCode IN (SELECT AssetCode FROM #BcTempCc) GROUP BY AssetCode'
	EXEC sp_executesql @_StrExec, 
			 N'@_DocDate1 DATE OUTPUT,@_DocDate2 DATE OUTPUT',
			   @_DocDate1 OUTPUT,@_DocDate2 OUTPUT

	UPDATE #BcTempCc
	SET OriginalCostDecrease = tb.OriginalCostDecrease + gi.DeOriginalCost
	FROM #BcTempCc tb
		INNER JOIN #NG_Giam gi
			ON tb.AssetCode = gi.AssetCode

	SELECT SUM(CloseOriginalCost),SUM(CloseDepreciation),SUM( CloseOriginalCost-CloseDepreciation) ,DeprCreditAccount  FROM #BcTempCc WHERE DeprCreditAccount = '242202' GROUP BY DeprCreditAccount RETURN 

	UPDATE #BcTempCc
	SET OpenBookValue=OpenOriginalCost-OpenDepreciation, 
		CloseBookValue=CloseOriginalCost-CloseDepreciation;
 
    --C?p nh?t t?ng Nguyên giá trong k?
	SET @_StrExec = @_StrExec + '
	UPDATE #BcTempCc 
	SET OriginalCostIncrease = T2.OriginalCost 
	FROM #BcTempCc T 
	OUTER APPLY (
		SELECT AssetCode, SUM(OriginalCost) AS OriginalCost
		FROM vB3' + @_DataCode_Branch + 'AssetDoc  
		WHERE AssetCode = T.AssetCode 
		AND DocDate BETWEEN @_DocDate1 AND @_DocDate2 
		AND IsActive = 1
		AND AssetTransId IN (SELECT Id FROM dbo.B20AssetTrans WHERE Type = 1 AND IsActive = 1)
		GROUP BY AssetCode
	) T2
	'
		 EXEC sp_executesql @_StrExec, 
			 N'@_DocDate1 DATE OUTPUT,@_DocDate2 DATE OUTPUT',
			   @_DocDate1 OUTPUT,@_DocDate2 OUTPUT

	   --- gia tri con lai dau ky va cuoi ky=0 va khau hao trong ky=0 thi loai
	DELETE FROM #BcTempCc WHERE  (OpenBookValue=0 AND CloseBookValue=0 AND Depreciation = 0)
 
---------------------------------------						
	DECLARE @_KeyAccount NVARCHAR(MAX)='',@_AccountTmp NVARCHAR(MAX)='',@_IdTmp INT=0,@_ItemLevelTmp INT=0,@_ItemNoTmp NVARCHAR(3)='',
			@_ItemTypeTmp NVARCHAR(24)='',
			@_TableSource_OpenAsset NVARCHAR(64)='',@_TableName_OpenAsset NVARCHAR(64)='',@_ColName_OpenAsset NVARCHAR(64)='',
			@_TableSource_AssetT NVARCHAR(64)='',@_TableName_AssetT NVARCHAR(64)='',@_ColName_AssetT NVARCHAR(64)='',
			@_TableSource_AssetG NVARCHAR(64)='',@_TableName_AssetG NVARCHAR(64)='',@_ColName_AssetG NVARCHAR(64)='',
			@_TableSource_CloseAsset NVARCHAR(64)='',@_TableName_CloseAsset NVARCHAR(64)='',@_ColName_CloseAsset NVARCHAR(64)='',
			@_Key_Where_AssetOpen NVARCHAR(MAX)='',@_Key_Where_AssetT NVARCHAR(MAX)='',@_Key_Where_AssetG NVARCHAR(MAX)='',
			@_Key_Where_AssetClose NVARCHAR(MAX)=''			
	
	SELECT Id,ItemNo,ItemType,TableSource_OpenAsset,TableSource_AssetT,TableSource_AssetG,TableSource_CloseAsset,
			Key_Where_AssetOpen,Key_Where_AssetClose,Key_Where_AssetT,Key_Where_AssetG,CAST('' AS CHAR(1)) AS Tinh,Account			
	INTO #tblT
	FROM  #tblTmp1
	WHERE ItemLevel=9 
 
	SET @_StrExec = 
	'UPDATE #T_CdTmp2
	SET DeprDebitAccount = CASE WHEN T1.DeprDebitAccount <> '''' THEN T1.DeprDebitAccount ELSE T2.DeprDebitAccount END,
		DeprCreditAccount = CASE WHEN T1.DeprCreditAccount <> '''' THEN T1.DeprCreditAccount ELSE T2.DeprCreditAccount END 
	FROM #T_CdTmp2 T1
	INNER JOIN (
		SELECT MAX(DocDate) AS DocDate, AssetId, IncrNo,
			   MAX(DeprDebitAccount) AS DeprDebitAccount, MAX(DeprCreditAccount) AS DeprCreditAccount
		FROM B3' + @_DataCode_Branch + 'AssetDoc
		WHERE DocDate < @_DocDate2 AND BranchCode = @_BranchCode AND IsActive = 1
		GROUP BY AssetId, IncrNo
	) T2 
	ON T1.AssetId = T2.AssetId'
	EXEC sp_executesql @_StrExec, 
		N'@_DocDate2 DATE OUTPUT,@_BranchCode NVARCHAR(16) OUTPUT',
		@_DocDate2 OUTPUT,@_BranchCode OUTPUT
 		 
	WHILE EXISTS(SELECT * FROM #tblT WHERE Tinh ='')
		BEGIN
			
			SELECT TOP 1 @_IdTmp =  Id,@_ItemTypeTmp = ItemType,@_TableSource_OpenAsset=TableSource_OpenAsset,
						@_TableSource_AssetT=TableSource_AssetT,
						@_TableSource_AssetG=TableSource_AssetG,
						@_TableSource_CloseAsset=TableSource_CloseAsset,
						@_Key_Where_AssetOpen=Key_Where_AssetOpen,
						@_Key_Where_AssetT=Key_Where_AssetT,
						@_Key_Where_AssetG=Key_Where_AssetG,
						@_Key_Where_AssetClose=Key_Where_AssetClose							
			FROM #tblT
			WHERE Tinh=''	
																
			SELECT @_TableName_OpenAsset=LEFT(@_TableSource_OpenAsset,CHARINDEX('.',@_TableSource_OpenAsset,0)-1)
			SELECT @_ColName_OpenAsset=LTRIM(RTRIM(SUBSTRING(@_TableSource_OpenAsset,CHARINDEX('.',@_TableSource_OpenAsset,0)+1,LEN(@_TableSource_OpenAsset))))
			
			
			SELECT @_TableName_CloseAsset=LEFT(@_TableSource_CloseAsset,CHARINDEX('.',@_TableSource_CloseAsset,0)-1)
			SELECT @_ColName_CloseAsset=LTRIM(RTRIM(SUBSTRING(@_TableSource_CloseAsset,CHARINDEX('.',@_TableSource_CloseAsset,0)+1,LEN(@_TableSource_CloseAsset))))
			
			SELECT @_TableName_AssetT=LEFT(@_TableSource_AssetT,CHARINDEX('.',@_TableSource_AssetT,0)-1)
			SELECT @_ColName_AssetT=LTRIM(RTRIM(SUBSTRING(@_TableSource_AssetT,CHARINDEX('.',@_TableSource_AssetT,0)+1,LEN(@_TableSource_AssetT))))
			
			SELECT @_TableName_AssetG=LEFT(@_TableSource_AssetG,CHARINDEX('.',@_TableSource_AssetG,0)-1)
			SELECT @_ColName_AssetG=LTRIM(RTRIM(SUBSTRING(@_TableSource_AssetG,CHARINDEX('.',@_TableSource_AssetG,0)+1,LEN(@_TableSource_AssetG))))
			
			---- cap nhât so du dau ky
			SET @_StrExec= ' DECLARE @_Num NUMERIC(18,2) = 0 '+CHAR(13)+
						   ' SELECT @_Num=ISNULL(SUM('+@_ColName_OpenAsset+'),0) '+CHAR(13)+
						   ' FROM ' +@_TableName_OpenAsset + CHAR(13)+
						   ' WHERE ' +@_Key_Where_AssetOpen  + CHAR(13)+
						   ' UPDATE #tblTmp1 SET  OpenAmountAsset = @_Num WHERE Id='+STR(@_IdTmp)			
			EXEC(@_StrExec) 
			IF @_PRINT_Exec = 1 PRINT @_StrExec
						
			SET @_StrExec= ' DECLARE @_Num NUMERIC(18,2) = 0 '+CHAR(13)+
						   ' SELECT @_Num=ISNULL(SUM('+@_ColName_CloseAsset+'),0) '+CHAR(13)+
						   ' FROM ' +@_TableName_CloseAsset + CHAR(13)+
						   ' WHERE ' +@_Key_Where_AssetClose  + CHAR(13)+
						   ' UPDATE #tblTmp1 SET  CloseAmountAsset= @_Num WHERE Id='+STR(@_IdTmp)
			EXEC(@_StrExec) 
			IF @_PRINT_Exec = 1 PRINT @_StrExec
						
			SET @_StrExec= ' DECLARE @_Num NUMERIC(18,2) = 0 '+CHAR(13)+
						   ' SELECT @_Num=ISNULL(SUM('+@_ColName_AssetT+'),0) '+CHAR(13)+
						   ' FROM ' +@_TableName_AssetT + CHAR(13)+
						   ' WHERE ' +@_Key_Where_AssetT  + CHAR(13)+
						   ' UPDATE #tblTmp1 SET  AmountAssetT = @_Num WHERE Id='+STR(@_IdTmp)	  
			EXEC(@_StrExec)  		
			IF @_PRINT_Exec = 1 PRINT @_StrExec
											
			SET @_StrExec= ' DECLARE @_Num NUMERIC(18,2) = 0 '+CHAR(13)+
						   ' SELECT @_Num=ISNULL(SUM('+@_ColName_AssetG+'),0) '+CHAR(13)+
						   ' FROM ' +@_TableName_AssetG + CHAR(13)+
						   ' WHERE ' +@_Key_Where_AssetG  + CHAR(13)+
						   ' UPDATE #tblTmp1 SET  AmountAssetG = @_Num WHERE Id='+STR(@_IdTmp)	
			EXEC(@_StrExec) 					
			IF @_PRINT_Exec = 1 PRINT @_StrExec			   

			UPDATE #tblT SET Tinh='x' WHERE Id = @_IdTmp	
		END	
 
	SET @_StrExec = ' UPDATE ' +@_tblTmp + CHAR(13)+
					' SET OpenAmountAsset = ISNULL(T2.OpenAmountAsset,0),'+ CHAR(13)+
				    '     CloseAmountAsset = ISNULL(T2.CloseAmountAsset,0),'+ CHAR(13)+
				    '     AmountAssetT = ISNULL(T2.AmountAssetT,0),'+ CHAR(13)+
				    '     AmountAssetG = ISNULL(T2.AmountAssetG,0)'+ CHAR(13)+
					' FROM ' + @_tblTmp +' T1 INNER JOIN  #tblTmp1 T2 ON T1.Id=T2.Id'
	EXEC (@_StrExec)
	IF @_PRINT_Exec = 1 PRINT @_StrExec
 
	DROP TABLE #BcTempCc, #CtTmpCc, #T_CdTmp, #T_CdTmp2, #T_SoTmp0, #T_SoTmp9, #NG_Giam;
END

GO

declare @p17 nvarchar(max)
 
declare @p18 varchar(max)
 
exec usp_CheckAssetThaco2_test @_DocDate1='2026-07-01 00:00:00',@_DocDate2='2026-07-31 00:00:00',@_nUserId=default,@_LangId=0,@_DefinitionTableName='B10CheckAsset2',@_ConsolCode=default,@_Not_ConsolCode=default,@_Not_BranchCode=default,@_Not_RouteCode=default,@_BranchCode1=default,@_Not_BranchCode1=default,@_Not_BranchCode1Detail=default,@_CheckType=default,@_ReportType=default,@_BranchCode='I01',@_CurrencyCode0='VND',@_LAYOUT_XML=@p17 output,@_StrTime=@p18 output,@_Test=default,@_NewVer=1,@_BranchReportId=default