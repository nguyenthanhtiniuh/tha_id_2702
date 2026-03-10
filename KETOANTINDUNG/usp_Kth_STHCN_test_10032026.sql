SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
-- Description:	Sổ theo dõi công nợ theo khế ước, hợp đồng mua/ bán/ tiền gửi
ALTER  PROCEDURE [dbo].[usp_Kth_STHCN_test_10032026]
	@_DocDate1 DATE				= NULL,
	@_DocDate2 DATE				= NULL,
	@_Account VARCHAR(MAX)		= '',
	@_CustomerId VARCHAR(512)	= '',
	@_BizDocId_LC VARCHAR(512)	= '',
	@_LCType VARCHAR(1)			= N'1',
	@_nUserId INT				= 0,
	@_LangId INT				= 1, 
	@_BranchCode VARCHAR(3)		= '',
	@_TblInsert VARCHAR(64)		= '',
	@_CalculateInterest TINYINT = 1,
	@_CurrencyCode0 CHAR(3)		= 'VND',
	@_ForeignCurrencyOnly TINYINT = 0,
	@_DocCode NVARCHAR(24) = ''
AS
BEGIN
	SET NOCOUNT ON;

	-- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);
	SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode);
	
	DECLARE @_Ngay_Bd_Ht_Ct DATE, @_Ngay_Bd_Ht_Ct0 DATE;

	SELECT @_Ngay_Bd_Ht_Ct = dbo.ufn_B00FiscalYear_GetStartedUsingDate(@_BranchCode),
			@_Ngay_Bd_Ht_Ct0 = DATEADD(day, -1, @_Ngay_Bd_Ht_Ct);

	DECLARE @_Key2 NVARCHAR(MAX) = '', @_Key NVARCHAR(MAX) = '', @_KeyCd NVARCHAR(MAX) = '';
 
	IF ISNULL(@_Account, '') <> ''
	BEGIN
	    SET @_Key = @_Key + N' AND ((Account LIKE N''' + REPLACE(@_Account, N',', '%'') OR (Account LIKE N' + NCHAR(39)) + N'%''))'
 
	    SELECT @_Key2 = @_Key, @_KeyCd= @_Key
 
	END
 	
	SET  @_Keycd = ' AND (BizDocId <> '''') ';

	IF @_DocCode <> ''
	BEGIN

		SET @_Key = @_Key + ' AND DocCode =''' +RTRIM(@_DocCode)+'''';
		--SET @_Keycd = @_Keycd + ' AND DocCode =''' +RTRIM(@_DocCode)+'''';
	
	END


	IF @_BizDocId_LC <> ''
	BEGIN

		SET @_Key = @_Key + N' AND ((BizDocId  = N''' + REPLACE(@_BizDocId_LC, N',', ''') OR (BizDocId = N' + NCHAR(39)) +  '''))'
			 
		SET @_Key2 = @_Key2 + N' AND ((BizDocId_LC = N''' + REPLACE(@_BizDocId_LC,  ',', ''') OR (BizDocId_LC  = N' + NCHAR(39)) +  '''))'
		
		SET @_Keycd = @_Keycd + N' AND ((BizDocId  = N''' + REPLACE(@_BizDocId_LC,  ',', ''') OR (BizDocId = N' + NCHAR(39)) +  '''))'
		
		--SELECT @_Keycd
		--SELECT	@_Key = @_Key + N' AND (BizDocId = ''' + RTRIM(@_BizDocId_LC) + ''')';


			--SELECT @_Key2 = @_Key2 + N' AND (BizDocId_LC = ''' + RTRIM(@_BizDocId_LC) + ''')'
	END; 

	ELSE

	BEGIN
		--SELECT @_Key2 = @_Key2 + N' AND BizDocId_LC IN (SELECT BizDocId_LC FROM #BizDoc WHERE IsDebt = 1) AND (BizDocId_LC <> '''') ';	

		SELECT @_Key2 = @_Key2 + N' AND BizDocId_LC IN (SELECT BizDocId_LC FROM #BizDoc ) AND (BizDocId_LC <> '''') ';	
	END; 
 
	IF @_CustomerId <> ''
	BEGIN
		EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId, @_ColGen = 'CustomerId', 
			@_ColName = 'Id', @_TableName = 'B20Customer', 
			@_AndOrKey = 'AND', @_Key = @_Key OUTPUT;

		EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId, @_ColGen = 'CustomerId', 
			@_ColName = 'Id', @_TableName = 'B20Customer', 
			@_AndOrKey = 'AND', @_Key = @_Keycd OUTPUT;
	END;
 
	IF @_Key <> N'' SET @_Key = SUBSTRING(@_Key, 6, LEN(@_Key) - 5);
	--IF @_KeyCd <> N'' SET @_KeyCd = SUBSTRING(@_KeyCd, 6, LEN(@_KeyCd) - 5)
	IF @_Key2 <> N'' SET @_Key2 = SUBSTRING(@_Key2, 6, LEN(@_Key2) - 5);
 
	DROP TABLE IF EXISTS #BizDoc;
	SELECT TOP 0 BranchCode,BizDocId,CAST(0 AS INT) AS IsDebt, DocNo,
		CustomerId, ProductId, ProductCatgId, Account,CAST('' AS NVARCHAR(24))  AS LoanAccountNo, 
		CAST('' AS NVARCHAR(32))  AS CustomerCode, CAST('' AS NVARCHAR(192)) AS CustomerName, 
		CAST('' AS NVARCHAR(32))  AS ProductCode, CAST('' AS NVARCHAR(192)) AS ProductName, 
		CAST('' AS NVARCHAR(32))  AS ProductCatgCode, CAST('' AS NVARCHAR(192)) AS ProductCatgName, 
		CAST(0 AS NUMERIC(18, 2)) DebitBiz1,CAST(0 AS NUMERIC(18, 2)) CreditBiz1, 
		DebitAmount,CreditAmount,
		CAST(0 AS NUMERIC(18, 2))DebitBiz2,CAST(0 AS NUMERIC(18, 2))CreditBiz2,
		CAST(0 AS NUMERIC(18, 2))OriginalDebitBiz1,CAST(0 AS NUMERIC(18, 2))OriginalCreditBiz1,
		OriginalDebitAmount,OriginalCreditAmount,CAST(0 AS NUMERIC(18, 2))OriginalDebitBiz2,
		CAST(0 AS NUMERIC(18, 2))OriginalCreditBiz2,DocDate,
		DocDate AS DateDue,CAST(0 AS INT ) AS DueDate
	INTO #BizDoc
	FROM B00CtTmp;

	EXECUTE usp_sys_DefaultTable '#BizDoc';

	EXECUTE dbo.usp_THACOID_GetData_LC
		@_DocDate1 = '',
		@_DocDate2 = @_DocDate2,
		@_Key1 = @_Key,
		@_CtTmp = N'#BizDoc',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode, 
		@_CurrencyCode0	= @_CurrencyCode0,
		@_PrintExec =0,
		@_FieldSelect  = 'BranchCode,BizDocId,IsDebt,CustomerId,ProductId,Account,DocNo,LoanAccountNo,DueDate,DateDue,DocDate', 
		@_FieldInsert  ='BranchCode,BizDocId,IsDebt,CustomerId,ProductId,Account,DocNo,LoanAccountNo,DueDate,DateDue,DocDate'
 
	DROP TABLE IF EXISTS #OpenBiz;
	SELECT TOP 0  
		Account, CustomerId, ProductId, ProductCatgId, BizDocId,DocCode,
		BizDocId AS BizDocId_LC,BizDocId AS BizDocId_C1, BizDocId AS BizDocId_C2,BizDocId AS BizDocId_DA,
		BranchCode,
		Amount AS DebitBiz1, Amount AS CreditBiz1, 
		OriginalAmount AS OriginalDebitBiz1, OriginalAmount AS OriginalCreditBiz1
	INTO #OpenBiz
	FROM dbo.B00CtTmp;

	EXECUTE usp_sys_DefaultTable '#OpenBiz';
 
	EXECUTE dbo.usp_B30OpenBizDoc_GetData
		@_DocDate0 = @_DocDate1,
		@_Key = @_KeyCd,
		@_CtTmp = N'#OpenBiz',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_PrintExec = 1;

		SELECT * FROM #OpenBiz RETURN 
 
	DROP TABLE IF EXISTS #K_CtTmp;
	SELECT TOP 0 Account, CustomerId, ProductId, ProductCatgId, BranchCode, BizDocId, BizDocId_LC,BizDocId_C1,BizDocId_C2, BizDocId AS BizDocId_DA,
		DebitBiz1, CreditBiz1, CAST(0 AS NUMERIC(18, 2)) AS DebitAmount, CAST(0 AS NUMERIC(18, 2)) AS CreditAmount,
		CAST(0 AS NUMERIC(18, 2)) AS DebitBiz2, CAST(0 AS NUMERIC(18, 2)) AS CreditBiz2, OriginalDebitBiz1, 
		OriginalCreditBiz1, CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitAmount, CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditAmount,
		CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitBiz2, CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditBiz2
	INTO #K_CtTmp
	FROM #OpenBiz;
	EXECUTE usp_sys_DefaultTable '#K_CtTmp';
	
	EXECUTE dbo.usp_B30GeneralLedger_GetData 
		@_DocDate1	= @_DocDate1, 
		@_DocDate2	= @_DocDate2, 
		@_Key1		= '', 
		@_Key2		= @_Key2, 
		@_CtTmp		= '#K_CtTmp', 
		@_nUserId	= @_nUserId,
		@_LangId	= @_LangId,
		@_BranchCode	= @_BranchCode, 
		@_CurrencyCode0	= @_CurrencyCode0,
		@_PrintExec=0;
 
	DELETE #K_CtTmp WHERE ABS(DebitAmount) + ABS(CreditAmount) = 0;
 
	INSERT INTO #K_CtTmp (Account, CustomerId, ProductId, ProductCatgId, BranchCode, BizDocId, BizDocId_LC,BizDocId_C1,BizDocId_C2, BizDocId_DA,
						DebitBiz1, CreditBiz1, OriginalDebitBiz1, OriginalCreditBiz1)
	SELECT Account, CustomerId, ProductId, ProductCatgId, BranchCode,BizDocId, BizDocId_LC,BizDocId_C1,BizDocId_C2,BizDocId_DA,
		SUM(DebitBiz1) AS DebitBiz1, SUM(CreditBiz1) AS CreditBiz1, 
		SUM(OriginalDebitBiz1) AS OriginalDebitBiz1, SUM(OriginalCreditBiz1) AS OriginalCreditBiz1
	FROM #OpenBiz
	GROUP BY Account, CustomerId, ProductId, ProductCatgId, BranchCode, BizDocId, BizDocId_LC,BizDocId_C1,BizDocId_C2,BizDocId_DA;
 
	UPDATE #K_CtTmp
	SET BizDocId = CASE
					   WHEN ISNULL(BizDocId_LC, '') <> '' THEN BizDocId_LC
					   WHEN ISNULL(BizDocId_C1, '') <> '' THEN BizDocId_C1
					   WHEN ISNULL(BizDocId_C2, '') <> '' THEN BizDocId_C2
					   WHEN ISNULL(BizDocId_DA, '') <> '' THEN BizDocId_DA
					   ELSE BizDocId
				   END;
 
	UPDATE #K_CtTmp
	SET CustomerId = CASE WHEN a.CustomerId IS NULL THEN b.CustomerId ELSE a.CustomerId END ,
		ProductId = CASE WHEN a.ProductId IS NULL THEN b.ProductId ELSE a.ProductId END ,
		Account = CASE WHEN a.Account IS NULL THEN b.Account ELSE a.Account END ,
		ProductCatgId = CASE WHEN a.ProductCatgId = 0 THEN NULL ELSE a.ProductCatgId END 
	
	FROM #K_CtTmp a LEFT JOIN #BizDoc b ON a.BizDocId = b.BizDocId;

	DECLARE @_Biz NUMERIC(18,5)=0, @_OriginalBiz NUMERIC(18,5)=0;
 
	DROP TABLE IF EXISTS #K_CtTmp1;
	SELECT BranchCode, BizDocId AS BizDocId,
		CustomerId,
		ProductId, 
		ProductCatgId,
		Account,
		SUM(DebitBiz1) AS DebitBiz1,	
		SUM(CreditBiz1) AS CreditBiz1,
		SUM(DebitAmount) AS DebitAmount, 
		SUM(CreditAmount) AS CreditAmount,
		CAST(0 AS NUMERIC(18, 2)) AS DebitBiz2, 
		CAST(0 AS NUMERIC(18, 2)) AS CreditBiz2,
		SUM(OriginalDebitBiz1) AS OriginalDebitBiz1, 
		SUM(OriginalCreditBiz1) AS OriginalCreditBiz1,
		SUM(OriginalDebitAmount) AS OriginalDebitAmount, 
		SUM(OriginalCreditAmount) AS OriginalCreditAmount,
		CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitBiz2, 
		CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditBiz2,
		CAST(0 AS BIT) AS IsGroup
	INTO #K_CtTmp1
	FROM #K_CtTmp
	GROUP BY CustomerId, BranchCode, ProductId, ProductCatgId, Account, BizDocId;
 
	UPDATE #K_CtTmp1 
	SET @_Biz = (tb.DebitBiz1 - tb.CreditBiz1) + (tb.DebitAmount - tb.CreditAmount),
		DebitBiz2 = IIF(@_Biz >= 0, @_Biz, 0),
		CreditBiz2 = IIF(@_Biz >= 0, 0, -@_Biz),		
		@_OriginalBiz = (tb.OriginalDebitBiz1 - tb.OriginalCreditBiz1) + (tb.OriginalDebitAmount - tb.OriginalCreditAmount),
		OriginalDebitBiz2 = IIF(@_OriginalBiz >= 0, @_OriginalBiz, 0),
		OriginalCreditBiz2 = IIF(@_OriginalBiz >= 0, 0, -@_OriginalBiz)
	FROM #K_CtTmp1 tb; 

	UPDATE #K_CtTmp1
	SET
    DebitBiz1  = CASE 
                    WHEN DebitBiz1 > CreditBiz1 
                        THEN DebitBiz1 - CreditBiz1 
                    ELSE 0 
                 END,
    CreditBiz1 = CASE 
                    WHEN CreditBiz1 > DebitBiz1 
                        THEN CreditBiz1 - DebitBiz1 
                    ELSE 0 
                 END;
	
	UPDATE #BizDoc
	SET CustomerCode = dm.Code,
		CustomerName = dm.Name,
		ProductCode = pr.Code,
		ProductName= Pr.Name,
		ProductCatgCode = catg.Code,
		ProductCatgName = catg.Name
	FROM #BizDoc tb
	LEFT JOIN dbo.B20Customer dm ON tb.CustomerId = dm.Id
		LEFT JOIN dbo.B20Product pr ON tb.ProductId = pr.Id
		LEFT JOIN dbo.B20ProductCatg catg ON tb.ProductCatgId = catg.Id;
 
	UPDATE #BizDoc
	SET CustomerId= b.CustomerId, ProductId = b.ProductId, ProductCatgId= b.ProductCatgId,
		DebitBiz1= ISNULL(b.DebitBiz1,0), CreditBiz1=ISNULL(b.CreditBiz1,0),
		DebitAmount = ISNULL(b.DebitAmount,0), CreditAmount = ISNULL(b.CreditAmount,0),
		DebitBiz2 = ISNULL(b.DebitBiz2,0), CreditBiz2 = ISNULL(b.CreditBiz2,0),
		OriginalDebitBiz1 = ISNULL(b.OriginalDebitBiz1,0), OriginalCreditBiz1 = ISNULL(b.OriginalCreditBiz1,0),
		OriginalDebitAmount = ISNULL(b.OriginalDebitAmount,0), OriginalCreditAmount = ISNULL(b.OriginalCreditAmount,0),
		OriginalDebitBiz2 = ISNULL(b.OriginalDebitBiz2,0), OriginalCreditBiz2 = ISNULL(b.OriginalDebitBiz2,0)
	FROM #BizDoc a LEFT JOIN #K_CtTmp1 b ON a.BizDocId = b.BizDocId AND  a.Account = b.Account;
 
	EXECUTE dbo.usp_sys_DefaultTable @_Table = N'#K_SoTmp';
 
	SELECT * FROM #BizDoc;
 
	DROP TABLE IF EXISTS #K_CtTmp;
	DROP TABLE IF EXISTS #OpenBiz;
	DROP TABLE IF EXISTS #BizDoc;
	DROP TABLE IF EXISTS #K_CtTmp1;
END;
GO

GO

SET DATEFORMAT DMY
EXEC usp_Kth_STHCN_test_10032026 @_DocDate1 = '01/01/2026 00:00:00.000'
                  ,@_DocDate2 = '31/01/2026 00:00:00.000'
                  ,@_BizDocId_LC = 'I232232522LC'
                  ,@_nUserId = 1213
                  ,@_LangId = 0
                  ,@_BranchCode = 'I23'
                  ,@_CurrencyCode0 = 'VND'
                  ,@_DocCode = 'LC'
