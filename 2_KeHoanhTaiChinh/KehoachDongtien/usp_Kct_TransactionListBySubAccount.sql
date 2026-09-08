SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Coder: KhuongNV

-- ============================================
-- Description: B?ng kê chi tiet ch?ng t? theo tài kho?n
-- ============================================
ALTER   PROCEDURE dbo.usp_Kct_TransactionListBySubAccount 
	@_DocDate1 DATE	= 'Jan 01 2007',
	@_DocDate2 DATE	= 'Jan 31 2007',
	@_Account VARCHAR(24) = N'',
	@_DocCode NVARCHAR(4) = N'',
	@_DocNo1 NVARCHAR(24) = N'',
	@_DocNo2 NVARCHAR(24) = N'',
	@_CrspAccount VARCHAR(24) = N'',
	@_ExcludeCrspAccount            VARCHAR(2000)  = '911',
	@_CustomerId VARCHAR(512) = N'',
	@_CustomerId00 VARCHAR(512) = N'',
	@_CrspCustomerId VARCHAR(512) = N'',
	@_ExpenseCatgId VARCHAR(512) = N'',
	@_BizDocId_PO VARCHAR(24) = N'',
	@_BizDocId_SO VARCHAR(24) = N'',
	@_ProductId VARCHAR(24) = N'',
	@_No_Co NCHAR(1) = N'*',
	@_nUserId INT = 0,
	@_LangId INT = 0,
	@_CurrencyCode0 CHAR(3)	= 'VND',
	@_BranchCode VARCHAR(3) = N'A02',
	@_OtherKey1 NVARCHAR(1000) = N'', -- Ph?c v? enter chi ti?t báo cáo khác theo key1
 	@_OtherKey2 NVARCHAR(1000) = N'', -- Ph?c v? enter chi ti?t báo cáo khác theo key2
	@_ExchangeRateConvertDesc NVARCHAR(1000) = NULL OUTPUT, -- Chu?i hi?n th? t? giá chuy?n ??i khi enter chi ti?t t? các báo cáo tài chính chuy?n ??i VND 
	@_BranchReportId INT = NULL		-- X? lý báo báo IAS/IFRS
AS
BEGIN
	SET NOCOUNT ON;
	-- T? ??ng l?y thông tin theo AppName khi th?c hi?n trong ch??ng trình, không theo tham s? truy?n vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)

	DECLARE @_Key1 NVARCHAR(MAX),@_Key2 NVARCHAR(MAX),@_DataCode VARCHAR(8)

	SELECT TOP 1  @_DataCode = DataCode FROM dbo.B00Branch WHERE  BranchCode = @_BranchCode 

	SELECT @_Account = RTRIM(@_Account), 
		@_DocCode = RTRIM(@_DocCode), 
		@_CrspAccount = RTRIM(@_CrspAccount),
		@_CustomerId = RTRIM(@_CustomerId), 
		@_CrspCustomerId = RTRIM(@_CrspCustomerId),
		@_OtherKey1 = RTRIM(@_OtherKey1), 
		@_OtherKey2 = RTRIM(@_OtherKey2),
		-- Tr??ng h?p nh?p ?i?u ki?n l?c ch?a ký t? ph?y trên
		@_DocNo1 = REPLACE(@_DocNo1, NCHAR(39), NCHAR(39) + NCHAR(39)), 
		@_DocNo2 = REPLACE(@_DocNo2, NCHAR(39), NCHAR(39) + NCHAR(39))
 
	SET @_Key1 = dbo.ufn_sys_GenKeyTkSQL(@_No_Co, @_Account, @_CustomerId, @_CrspAccount, @_CrspCustomerId)
	
	IF @_OtherKey1 <> ''
		SET @_Key1 = CASE WHEN @_Key1 = N'' THEN '' ELSE '(' + @_Key1 + ') AND ' END + 
			N'(' + @_OtherKey1 + ')'

	IF OBJECT_ID(N'Tempdb..#K_CtTmp0', 'U') IS NOT NULL DROP TABLE #K_CtTmp0
	SELECT TOP (0) CAST(0 AS INT) AS Id,
		DocDate, DocCode, DocNo, DocGroup, 
		Description, Person, Account, CrspAccount, 
		CustomerId0,CustomerId0 AS CustomerId00, DebitAmount, CreditAmount, 
		OriginalDebitAmount, OriginalCreditAmount, 
		CurrencyCode, ExchangeRate, ExpenseCatgId, ProductId, 
		Stt AS BizDocId_PO, Stt AS BizDocId_SO, Stt, Stt0,
		ProfitCenterId,Stt AS BizDocId_LC,RowId , AssetId 
	INTO #K_CtTmp0
	FROM dbo.B00CtTmp
	
	SET @_Key2 = N'(Account LIKE ''' + @_Account + '%'')'

	IF @_CrspAccount <> N''
		SET @_Key2 = @_Key2 + N' AND (CrspAccount LIKE ''' + @_CrspAccount + '%'')'

	IF @_ExcludeCrspAccount <> ''
        SET @_Key2 += N' AND ' + N'(' + N'(CrspAccount NOT LIKE '''
                     + REPLACE(@_ExcludeCrspAccount, ',', '%'') AND (CrspAccount NOT LIKE ''') + N'%'')' + N')'

	IF @_CrspCustomerId <> N''
	BEGIN
	    EXECUTE dbo.usp_sys_GenKey @_Code = @_CrspCustomerId, @_ColGen = 'CrspCustomerId', 
			@_ColName = 'Id', @_TableName = 'B20Customer', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT
	END

    IF @_CustomerId00 <> ''
    BEGIN
	    EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId00, @_ColGen = 'CustomerId00', 
			@_ColName = 'Id', @_TableName = 'B20Customer', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT
	END

	IF @_DocCode <> N'' SET @_Key2 = @_Key2 + N' AND (DocCode = ''' + @_DocCode + ''')'
	
	IF @_DocNo1 <> N'' AND @_DocNo2 <> N'' AND @_DocNo1 = @_DocNo2
		SET @_Key2 = @_Key2 + N' AND (DocNo = N''' + @_DocNo1 + N''')'
	ELSE
	BEGIN
		IF @_DocNo1 <> N''
			SET @_Key2 = @_Key2 + N' AND (DocNo >= N''' + @_DocNo1 + N''')'
		
		IF @_DocNo2 <> N''
			SET @_Key2 = @_Key2 + N' AND (DocNo <= N''' + @_DocNo2 + N''')'
	END
	
	IF @_BizDocId_PO <> N''
		SET @_Key2 = @_Key2 + N' AND (BizdocId_PO = ''' + @_BizDocId_PO + ''')'

	IF @_BizDocId_SO <> N''
		SET @_Key2 = @_Key2 + N' AND (BizdocId_SO = ''' + @_BizDocId_SO + ''')'

	IF @_ExpenseCatgId <> N''
		SET @_Key2 = @_Key2 + N' AND (ExpenseCatgId IN (' + @_ExpenseCatgId + '))'

	IF @_ProductId <> N''
		SET @_Key2 = @_Key2 + N' AND (ProductId = ''' + @_ProductId + ''')'
	
	IF @_OtherKey2 <> ''
		SET @_Key2 = CASE WHEN @_Key2 = N'' THEN '' ELSE '(' + @_Key2 + ') AND ' END + 
			N'(' + @_OtherKey2 + ')'
 
	

	--15/04/2024: GROUP l?i v?i các tr??ng t?i thi?u khi GetData
	EXECUTE dbo.usp_B30GeneralLedger_GetData 
		@_DocDate1	= @_DocDate1, 
		@_DocDate2	= @_DocDate2, 
		@_Key1		= @_Key1, 
		@_Key2		= @_Key2, 
		@_CtTmp		= N'#K_CtTmp0',
		@_nUserId	= @_nUserId,
		@_LangId	= @_LangId,
		@_BranchCode	= @_BranchCode, 
		@_CurrencyCode0	= @_CurrencyCode0,
		@_BranchReportId = @_BranchReportId, -- X? lý báo báo IAS/IFRS	
		@_GroupByCols = 'Stt,RowId, CustomerId0,CustomerId00,Account, CrspAccount, ProfitCenterId, ExpenseCatgId, Description',
		@_NotSumCols = 'Id,RowId, CustomerId0,CustomerId00, ExchangeRate, ExpenseCatgId, ProductId, ProfitCenterId',
		@_PrintExec = 0
 
	--15/04/2024: GROUP l?i v?i các tr??ng t?i thi?u khi GetData 
	SELECT Id, DocDate, '1' AS _Status, DocNo, DocGroup, DocCode, Description, Account, CrspAccount,
		Person, CurrencyCode, ExchangeRate,
		DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount,
		N'K' AS Line, Stt, RowId ,CAST(NULL AS NVARCHAR(64)) AS _FormatStyleKey,
		ProfitCenterId, ExpenseCatgId, CAST(NULL AS NVARCHAR(24)) AS ExpenseCatgCode,CAST(NULL AS NVARCHAR(256)) AS ExpenseCatgName, BizDocId_LC,
		CustomerId0, CAST(NULL AS NVARCHAR(24)) AS CustomerCode0,CAST(NULL AS NVARCHAR(256)) AS CustomerName0,
		CustomerId00, CAST(NULL AS NVARCHAR(24)) AS CustomerCode00,CAST(NULL AS NVARCHAR(256)) AS CustomerName00,
		AssetId, CAST(NULL AS NVARCHAR(24)) AS AssetCode,CAST(NULL AS NVARCHAR(256)) AS AssetName
	INTO #K_CtTmp
	FROM #K_CtTmp0
 
	UPDATE ctt
	SET ctt.CustomerCode0 = bc.Code
	   ,ctt.CustomerName0 = bc.Name
	FROM #K_CtTmp AS ctt
		 INNER JOIN dbo.B20Customer AS bc (NOLOCK) ON ctt.CustomerId0 = bc.Id

	UPDATE ctt
	SET ctt.CustomerCode00 = bc.Code
	   ,ctt.CustomerName00 = bc.Name
	FROM #K_CtTmp AS ctt
		 INNER JOIN dbo.B20Customer AS bc (NOLOCK) ON ctt.CustomerId00 = bc.Id

		UPDATE ctt
	SET ctt.ExpenseCatgCode = bc.Code
	   ,ctt.ExpenseCatgName = bc.Name
	FROM #K_CtTmp AS ctt
		 INNER JOIN dbo.B20ExpenseCatg AS bc (NOLOCK) ON ctt.ExpenseCatgId = bc.Id	
		 
	DECLARE @_strExec AS NVARCHAR(MAX);
	SELECT @_strExec = 
		'UPDATE ctt
	SET ctt.AssetId = bc.AssetId	   
	FROM #K_CtTmp AS ctt
		 INNER JOIN dbo.B3'+@_DataCode+'AccDocAutoEntry1 AS bc (NOLOCK) ON ctt.RowId = bc.RowId	'
	EXEC (@_strExec)
 
	SELECT @_strExec = 
		'UPDATE ctt
	SET ctt.AssetCode = bc.Code
	   ,ctt.AssetName = bc.Name
	FROM #K_CtTmp AS ctt
		 INNER JOIN dbo.B2'+@_DataCode+'Asset AS bc (NOLOCK) ON ctt.AssetId = bc.Id	'
	EXEC (@_strExec)
 
	EXECUTE dbo.usp_sys_DefaultTable '#K_CtTmp'

	DECLARE @_Msg_TongPhatSinh NVARCHAR(128) = dbo.ufn_sys_MessageText(N'TongPhatSinh', @_LangId)
 
	SELECT tb.Id, tb.DocDate, tb._Status, tb.DocNo, tb.DocGroup, tb.DocCode,
		tb.Description, tb.Account, tb.CrspAccount, 
		tb.CustomerId0, tb.CustomerCode0,tb.CustomerName0,
		tb.CustomerId00, tb.CustomerCode00, tb.CustomerName00,
		tb.Person, tb.CurrencyCode, tb.ExchangeRate, tb.DebitAmount, tb.CreditAmount,
		tb.OriginalDebitAmount, tb.OriginalCreditAmount, tb.Line, tb.Stt,tb.RowId, tb._FormatStyleKey,
		tb.ProfitCenterId, tb.ExpenseCatgId,tb.BizDocId_LC, tb.ExpenseCatgCode,tb.ExpenseCatgName,
		tb.AssetCode,tb.AssetName,
		CASE WHEN tb.DebitAmount <> 0 THEN tb.DocNo ELSE '' END AS DocNo_No,
		CASE WHEN tb.DebitAmount = 0 THEN tb.DocNo ELSE '' END AS DocNo_Co,
		CASE WHEN tb.DocCode <> '' THEN 'EDIT_' + tb.DocCode + ' PrimaryKeyValue={=Id};' ELSE NULL END AS _LinkCommand
	FROM #K_CtTmp AS tb		
        ORDER BY tb.DocDate ASC ,tb.DocNo ASC

	DROP TABLE #K_CtTmp0,#K_CtTmp
END
GO



SET DATEFORMAT DMY 
EXEC usp_Kct_TransactionListBySubAccount @_DocDate1='01/01/2026 00:00:00.000',@_DocDate2='30/06/2026 00:00:00.000',@_Account='214',@_nUserId=1213,@_LangId=0,@_CurrencyCode0='VND',@_BranchCode='I09'