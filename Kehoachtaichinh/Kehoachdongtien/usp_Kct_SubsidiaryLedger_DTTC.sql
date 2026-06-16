SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================
-- Author: Bravo
-- Create date:
-- Description:  
-- ====================================
ALTER PROC [dbo].[usp_Kct_SubsidiaryLedger_DTTC]
	@_DocDate1 DATE = 'Feb 01 2019',
	@_DocDate2 DATE = 'Mar 01 2019',
	@_Account VARCHAR(1000) = '', 
	@_AccountLevel INT = 0,
	@_ForeignCurrencyOnly TINYINT = 0,
	@_nUserId AS INT = 0,
	@_LangId SMALLINT = 0,
	@_CurrencyCode0 VARCHAR(3) = 'VND',
	@_BranchCode VARCHAR(3) = 'A01'
AS
BEGIN
	SET NOCOUNT ON;

	-- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	--SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)

	SET @_Account = RTRIM(@_Account)	

	DECLARE @_KeyCd NVARCHAR(MAX) = '',
		@_Key1 NVARCHAR(MAX) = '',
		@_Key2 NVARCHAR(MAX),
		@_DebitBal1 NUMERIC(18, 2),
		@_CreditBal1 NUMERIC(18, 2),
		@_OriginalDebitBal1 NUMERIC(18, 2),
		@_OriginalCreditBal1 NUMERIC(18, 2),
		@_DebitAmount NUMERIC(18, 2),
		@_CreditAmount NUMERIC(18, 2),
		@_OriginalDebitAmount NUMERIC(18, 2),
		@_OriginalCreditAmount NUMERIC(18, 2),
		@_DebitBalance2 NUMERIC(18, 2),
		@_OriginalDebitBalance2 NUMERIC(18, 2),
		@_CreditBalance2 NUMERIC(18, 2),
		@_OriginalCreditBalance2 NUMERIC(18, 2),
		@_Temp_Value NUMERIC(18, 2),
		@_Temp_Value_Nt NUMERIC(18, 2),
		@_DocNumber INT
	
	IF @_Account <> ''
	BEGIN
		SET @_KeyCd = N'((Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + '%''))'
		SET @_Key1 = N'(Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + '%'')'
	END

	--IF @_RouteCode <> ''
	--BEGIN
	--	SET @_KeyCd	= @_KeyCd + ' AND (RouteCode LIKE ''' + @_RouteCode + '%'')'
	--	SET @_Key1 = @_Key1 + ' AND (RouteCode LIKE ''' + @_RouteCode + '%'')'
	--END

	SET @_Key2 = @_KeyCd

	-- Lay so du dau tai khoan
	DROP TABLE IF EXISTS #SoDuDau
	SELECT TOP 0 Account, CustomerId, ProductId,
		Amount AS DebitBal1, Amount AS CreditBal1,
		OriginalAmount AS OriginalDebitBal1, OriginalAmount AS OriginalCreditBal1,
		CAST('' AS NVARCHAR(96)) AS AccountName,
		CAST('' AS NVARCHAR(96)) AS AccountCal,
		CAST('' AS NVARCHAR(96)) AS ParentGroupOrder,
		BranchCode, CAST('' AS NVARCHAR(512)) AS RouteName
	INTO #SoDuDau
	FROM B00CtTmp

	EXECUTE [usp_B30OpenBalance_GetData]
		@_DocDate0 = @_DocDate1,
		@_Key = @_KeyCd,
		@_CtTmp = N'#SoDuDau',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_Opening = 0,			
		@_Accumulate = 0,		
		@_AutoCalculate = 1, 	
		@_GroupByColumnList = N'Account,CustomerId,ProductId'	
    
	--DELETE FROM #SoDuDau WHERE ISNULL(BranchCode,'') = ''
	
	--SELECT * FROM #SoDuDau WHERE ISNULL(BranchCode,'') = '' AND Account LIKE N'111%' RETURN

	DROP TABLE IF EXISTS #K_CtTmp0
	SELECT TOP 0 CAST(NULL AS INT) AS Id, DocDate, DocNo, DocCode, DocGroup, 
		Description, CrspAccount, Account, Person,
		DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount,
		CAST('' AS NCHAR(1)) AS DocGroup0, Stt, RowId,
		CustomerId, ProductId, CurrencyCode, ExchangeRate,
		CAST('' AS VARCHAR(24)) AS GroupCode, CAST('' AS NVARCHAR(256)) AS GroupName,
		CAST('' AS NVARCHAR(96)) AS AccountCal,
		CAST('' AS NVARCHAR(96)) AS ParentGroupOrder,
		DocBookingId,
		BranchCode, CAST('' AS NVARCHAR(26)) AS CashFlowId, CAST(0 AS INT) AS DocNumber
	INTO #K_CtTmp0
	FROM B00CtTmp

	EXECUTE usp_B30GeneralLedger_GetData
		@_DocDate1 = @_DocDate1,
		@_DocDate2 = @_DocDate2,
		@_Key1 = @_Key1,
		@_Key2 = @_Key2,
		@_CtTmp = N'#K_CtTmp0',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0

	-- Xóa bản ghi = 0
	DELETE FROM #K_CtTmp0 WHERE CreditAmount = 0 AND DebitAmount = 0

	UPDATE #K_CtTmp0 SET DocGroup0 = '2' WHERE CreditAmount > 0

	UPDATE #K_CtTmp0 SET CashFlowId=''
	FROM #K_CtTmp0 WHERE ISNULL(CashFlowId,'')=''

	-- 08/08/2016 MinhPT: xử lý lấy dữ liệu theo tk tổng hợp
	IF ISNULL(@_AccountLevel, 0) = 1
	BEGIN
		IF ISNULL(@_Account, '') <> ''
		BEGIN
			UPDATE a
			SET a.AccountCal = b.value
				FROM #SoDuDau a
				CROSS APPLY (SELECT ac.value FROM STRING_SPLIT(@_Account,',') ac
							WHERE a.Account LIKE RTRIM(ac.value) + '%') AS b

			UPDATE a
			SET a.AccountCal = b.value
			FROM #K_CtTmp0 a
				CROSS APPLY (SELECT ac.value FROM STRING_SPLIT(@_Account,',') ac
							WHERE a.Account LIKE ac.value + '%') AS b
		END ELSE
		BEGIN
			UPDATE #SoDuDau SET AccountCal = LEFT(Account, 3)
			UPDATE #K_CtTmp0 SET AccountCal = LEFT(Account, 3)
		END
	END ELSE
	BEGIN
		UPDATE #SoDuDau SET AccountCal = Account
		UPDATE #K_CtTmp0 SET AccountCal = Account
	END

	 UPDATE #SoDuDau SET AccountCal=N'111,112'
	 FROM #SoDuDau

	 --UPDATE #SoDuDau SET RouteName=ISNULL(b.Name,'')
	 --FROM #SoDuDau a LEFT OUTER JOIN dbo.B20DmsRoute b ON a.RouteCode=b.Code

	 UPDATE #K_CtTmp0 SET DocNumber=1, Account=IIF(Account LIKE N'111%','111','112')
	 FROM #K_CtTmp0

	 UPDATE #SoDuDau SET Account=IIF(Account LIKE N'111%','111','112')
	 FROM #SoDuDau
    
	--SELECT * FROM #K_CtTmp0 return

	----------------
	DROP TABLE IF EXISTS #K_CtTmpTH
	SELECT MAX(Id) AS Id, CAST('' AS VARCHAR(128)) AS _GroupOrder,
		DocDate, MAX(DocNo) AS DocNo, MAX(DocCode) AS DocCode, MAX(DocGroup) AS DocGroup, MAX(Description) AS Description, MAX(Account) AS Account, MAX(CrspAccount) AS CrspAccount, MAX(Person) AS Person,
		SUM(DebitAmount) AS DebitAmount, SUM(CreditAmount) AS CreditAmount, SUM(OriginalDebitAmount) AS OriginalDebitAmount, SUM(OriginalCreditAmount) AS OriginalCreditAmount,
		CAST(0 AS NUMERIC(18, 2)) AS DebitBalance, CAST(0 AS NUMERIC(18, 2)) AS CreditBalance,
		CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitBalance, CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditBalance,
		MAX(Stt) AS Stt, MAX(DocGroup0) AS DocGroup0, '3' AS _Status, MAX(CustomerId) AS CustomerId, MAX(ProductId) AS ProductId, MAX(CurrencyCode) AS CurrencyCode, MAX(ExchangeRate) AS ExchangeRate,
		CAST(N'' AS NVARCHAR(64)) AS _FormatStyleKey,
		CAST('' AS DATE) AS DocDate1,
		MAX(GroupCode) AS GroupCode, MAX(GroupName) AS GroupName, MAX(AccountCal) AS AccountCal,
		ROW_NUMBER () OVER (PARTITION BY MAX(AccountCal) ORDER BY MAX(AccountCal), BranchCode,DocDate, CashFlowId, MAX(Id)) AS _Rank,
		MAX(DocBookingId) AS DocBookingId, CAST('' AS NVARCHAR(24)) AS DocBookingNo, CAST(NULL AS DATETIME) AS DocBookingDate, 
		BranchCode,CAST('' AS NVARCHAR(156)) AS RouteName, CashFlowId, CAST('' AS NVARCHAR(156)) AS CashFlowName, SUM(DocNumber) AS DocNumber, CAST(0 AS INT) AS _StatusTH,
		CAST(0 AS NUMERIC(18,2)) AS DebitAmount111, CAST(0 AS NUMERIC(18,2)) AS CreditAmount111, CAST(0 AS NUMERIC(18,2)) AS DocNumber111, CAST(0 AS NUMERIC(18, 2)) AS DebitBalance111, CAST(0 AS NUMERIC(18, 2)) AS CreditBalance111,
		CAST(0 AS NUMERIC(18,2)) AS DebitAmount112, CAST(0 AS NUMERIC(18,2)) AS CreditAmount112, CAST(0 AS NUMERIC(18,2)) AS DocNumber112, CAST(0 AS NUMERIC(18, 2)) AS DebitBalance112, CAST(0 AS NUMERIC(18, 2)) AS CreditBalance112,
		CAST('' AS NVARCHAR(2000)) AS _LinkCommand
	INTO #K_CtTmpTH
	FROM #K_CtTmp0
	GROUP BY CashFlowId, DocDate, BranchCode

	CREATE CLUSTERED INDEX IX_Rank_K_CtTmp ON #K_CtTmpTH (_Rank)

	EXEC usp_sys_DefaultTable '#K_CtTmpTH'

	UPDATE #K_CtTmpTH SET CashFlowName=ISNULL(b.Name,''), RouteName=ISNULL(c.Name,'')
	FROM #K_CtTmpTH a LEFT OUTER JOIN dbo.B20CashFlow b ON a.CashFlowId=b.Id
	LEFT OUTER JOIN dbo.B20DmsRoute c ON c.Code=a.BranchCode

	UPDATE #K_CtTmpTH SET CashFlowName=N'Chưa xác định khoản mục dòng tiền'
	FROM #K_CtTmpTH WHERE ISNULL(CashFlowId,'')=''

	UPDATE #K_CtTmpTH SET AccountCal=N'111,112'
	FROM #K_CtTmpTH

	UPDATE #K_CtTmpTH SET _LinkCommand=N'REP09_BKCT DocDate1=''{=DocDate}'';DocDate2=''{=DocDate}'';Account=''{=@_Account}'';CashFlowId=''{=CashFlowId}'';BranchCode=''{=BranchCode}'';'
	FROM #K_CtTmpTH
	---------------------
	
	DROP TABLE IF EXISTS #K_CtTmp
	SELECT  Id, CAST('' AS VARCHAR(128)) AS _GroupOrder,
		DocDate, DocNo, DocCode, DocGroup, Description, Account, CrspAccount, Person,
		DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount,
		CAST(0 AS NUMERIC(18, 2)) AS DebitBalance, CAST(0 AS NUMERIC(18, 2)) AS CreditBalance,
		CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitBalance, CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditBalance,
		Stt, DocGroup0, '1' AS _Status, CustomerId, ProductId, CurrencyCode, ExchangeRate,
		CAST(N'' AS NVARCHAR(64)) AS _FormatStyleKey,
		CAST('' AS DATE) AS DocDate1,
		GroupCode, GroupName, AccountCal,
		ROW_NUMBER () OVER (PARTITION BY AccountCal ORDER BY AccountCal, DocDate, DocGroup0, DocNo, Id) AS _Rank,
		DocBookingId, CAST('' AS NVARCHAR(24)) AS DocBookingNo, CAST(NULL AS DATETIME) AS DocBookingDate, BranchCode, CashFlowId
	INTO #K_CtTmp
	FROM #K_CtTmp0

	CREATE CLUSTERED INDEX IX_Rank_K_CtTmp ON #K_CtTmp (_Rank)

	EXEC usp_sys_DefaultTable '#K_CtTmp'

	----------------TuanPT sửa theo báo cáo mới
	-- Lấy ra danh sách tài khoản từ số dư và phát sinh
	SELECT DISTINCT AccountCal, BranchCode, RouteName
	INTO #DsAccountTempTH
	FROM #K_CtTmpTH
	UNION ALL
	SELECT MAX(AccountCal) AS AccountCal , BranchCode, MAX(RouteName) AS RouteName
	FROM #SoDuDau 
	WHERE AccountCal NOT IN (SELECT AccountCal FROM #K_CtTmpTH) OR BranchCode NOT IN (SELECT BranchCode FROM #K_CtTmpTH)
	GROUP BY BranchCode

	--SELECT * FROM #DsAccountTempTH RETURN
    
	DECLARE @_Account_ScanTH AS VARCHAR(24), @_BranchCode_ScanTH NVARCHAR(64), @_BranchCode_ScanName NVARCHAR(512)
	WHILE EXISTS(SELECT * FROM #DsAccountTempTH)
	BEGIN
		SELECT TOP 1 @_Account_ScanTH = AccountCal , @_BranchCode_ScanTH=BranchCode, @_BranchCode_ScanName=RouteName
		FROM #DsAccountTempTH
		
		SELECT @_DebitBal1 = SUM(DebitBal1),
			@_CreditBal1 = SUM(CreditBal1),
			@_OriginalDebitBal1 = SUM(OriginalDebitBal1),
			@_OriginalCreditBal1 = SUM(OriginalCreditBal1)
		FROM #SoDuDau
		WHERE AccountCal = @_Account_ScanTH AND BranchCode=@_BranchCode_ScanTH
	
		SELECT @_Temp_Value = 0, @_Temp_Value_Nt = 0, @_DebitBal1 = ISNULL(@_DebitBal1, 0), @_CreditBal1 = ISNULL(@_CreditBal1, 0),
			@_OriginalDebitBal1 = ISNULL(@_OriginalDebitBal1, 0), @_OriginalCreditBal1 = ISNULL(@_OriginalCreditBal1, 0),
			@_DebitAmount = 0, @_CreditAmount = 0, @_OriginalDebitAmount = 0, @_OriginalCreditAmount = 0,
			@_DebitBalance2 = 0, @_CreditBalance2 = 0, @_OriginalDebitBalance2 = 0, @_OriginalCreditBalance2 = 0, @_DocNumber=0
				
			IF @_DebitBal1 > @_CreditBal1 
				SET @_DebitBalance2 = @_DebitBal1 - @_CreditBal1
			ELSE
				SET @_CreditBalance2 = @_CreditBal1 - @_DebitBal1
				
			IF @_OriginalDebitBal1 > @_OriginalCreditBal1
				SET @_OriginalDebitBalance2 = @_OriginalDebitBal1 - @_OriginalCreditBal1
			ELSE
				SET @_OriginalCreditBalance2 = @_OriginalCreditBal1 - @_OriginalDebitBal1

			UPDATE #K_CtTmpTH
				SET @_DebitAmount = @_DebitAmount + DebitAmount, @_CreditAmount = @_CreditAmount + CreditAmount,
					@_OriginalDebitAmount = @_OriginalDebitAmount + OriginalDebitAmount, @_OriginalCreditAmount = @_OriginalCreditAmount + OriginalCreditAmount,
					@_Temp_Value = (@_DebitBalance2 - @_CreditBalance2) + (DebitAmount - CreditAmount),
					@_DebitBalance2 = DebitBalance = IIF(@_Temp_Value > 0, @_Temp_Value, 0),
					@_CreditBalance2 = CreditBalance = IIF(@_Temp_Value <= 0, ABS(@_Temp_Value), 0),
					@_Temp_Value_Nt = (@_OriginalDebitBalance2 - @_OriginalCreditBalance2) + (OriginalDebitAmount - OriginalCreditAmount),
					@_OriginalDebitBalance2 = OriginalDebitBalance = IIF(@_Temp_Value_Nt > 0, @_Temp_Value_Nt, 0),
					@_OriginalCreditBalance2 = OriginalCreditBalance = IIF(@_Temp_Value_Nt <= 0, ABS(@_Temp_Value_Nt), 0),
					@_DocNumber=@_DocNumber + DocNumber
				FROM #K_CtTmpTH
				WHERE AccountCal = @_Account_ScanTH AND BranchCode=@_BranchCode_ScanTH
		
		INSERT #K_CtTmpTH (Id, Account, DocDate, Description, DebitBalance, CreditBalance, OriginalDebitBalance, OriginalCreditBalance, _Status, _FormatStyleKey, AccountCal, BranchCode) VALUES
				(NULL, @_Account_ScanTH, NULL, dbo.ufn_sys_MessageText(N'DuDauKy', @_LangId)+ N' - ' +@_BranchCode_ScanName, 
				 ISNULL(@_DebitBal1, 0), ISNULL(@_CreditBal1, 0), ISNULL(@_OriginalDebitBal1, 0), ISNULL(@_OriginalCreditBal1, 0),            
				 N'1', 'BOLD', @_Account_ScanTH, @_BranchCode_ScanTH)

		INSERT #K_CtTmpTH (Id, Account, DocDate, Description, DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey, AccountCal, BranchCode,DocNumber) VALUES
				(NULL, @_Account_ScanTH, NULL, dbo.ufn_sys_MessageText(N'TongPhatSinh', @_LangId)+ N' - ' +@_BranchCode_ScanName,
					ISNULL(@_DebitAmount, 0), ISNULL(@_CreditAmount, 0), ISNULL(@_OriginalDebitAmount, 0), ISNULL(@_OriginalCreditAmount, 0), N'2', 'BOLD', @_Account_ScanTH, @_BranchCode_ScanTH,@_DocNumber)

		INSERT #K_CtTmpTH (Id, Account, DocDate, Description, DebitBalance, CreditBalance, OriginalDebitBalance, OriginalCreditBalance, _Status, _FormatStyleKey, AccountCal, BranchCode) VALUES
				(NULL, @_Account_ScanTH, NULL, N'Tồn quỹ'+ N' - ' +@_BranchCode_ScanName,
					ISNULL(@_DebitBalance2, 0), ISNULL(@_CreditBalance2, 0), ISNULL(@_OriginalDebitBalance2, 0), ISNULL(@_OriginalCreditBalance2, 0), N'8', 'BOLD', @_Account_ScanTH, @_BranchCode_ScanTH)

		DELETE FROM #DsAccountTempTH WHERE AccountCal = @_Account_ScanTH AND BranchCode=@_BranchCode_ScanTH
	END
	------------------

	INSERT #K_CtTmpTH (Id, Account, DocDate, Description, DebitBalance, CreditBalance, OriginalDebitBalance, OriginalCreditBalance, _Status, _FormatStyleKey, AccountCal, BranchCode) 
	SELECT 	NULL, NULL, NULL, N'SỐ DƯ ĐẦU KỲ', 
			SUM(DebitBalance), SUM(CreditBalance), SUM(OriginalDebitBalance), SUM(OriginalCreditBalance), N'0', 'BOLD', '111,112', NULL
	FROM #K_CtTmpTH
	WHERE _Status=1

	INSERT #K_CtTmpTH (Id, Account, DocDate, Description, DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey, AccountCal, BranchCode,DocNumber)
	SELECT 	NULL, NULL, NULL, N'TỔNG CỘNG', 
			SUM(DebitAmount), SUM(CreditAmount), SUM(OriginalDebitAmount), SUM(OriginalCreditAmount), N'4', 'BOLD', '111,112', NULL, SUM(DocNumber)
	FROM #K_CtTmpTH
	WHERE _Status=2

	INSERT #K_CtTmpTH (Id, Account, DocDate, Description, DebitBalance, CreditBalance, OriginalDebitBalance, OriginalCreditBalance, _Status, _FormatStyleKey, AccountCal, BranchCode)
	SELECT 	NULL, NULL, NULL, N'SỐ DƯ CUỐI KỲ', 
			SUM(DebitBalance), SUM(CreditBalance), SUM(OriginalDebitBalance), SUM(OriginalCreditBalance), N'9', 'BOLD', '111,112', NULL
	FROM #K_CtTmpTH
	WHERE _Status=8

	---Update 4 cột tiền mặt/ chuyển khoản
	UPDATE #K_CtTmpTH SET DebitAmount111=ISNULL(ct.DebitAmount,0), CreditAmount111=ISNULL(ct.CreditAmount,0), DocNumber111=ISNULL(ct.DocNumber,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT CashFlowId, DocDate, BranchCode, SUM(DebitAmount) AS DebitAmount, SUM(CreditAmount) AS CreditAmount, SUM(DocNumber) AS DocNumber FROM #K_CtTmp0 
		WHERE Account='111' GROUP BY CashFlowId, DocDate, BranchCode) AS ct ON ct.CashFlowId=a.CashFlowId AND ct.DocDate=a.DocDate AND ct.BranchCode=a.BranchCode

	UPDATE #K_CtTmpTH SET DebitAmount112=ISNULL(ct.DebitAmount,0), CreditAmount112=ISNULL(ct.CreditAmount,0), DocNumber112=ISNULL(ct.DocNumber,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT CashFlowId, DocDate, BranchCode, SUM(DebitAmount) AS DebitAmount, SUM(CreditAmount) AS CreditAmount, SUM(DocNumber) AS DocNumber FROM #K_CtTmp0 
		WHERE Account='112' GROUP BY CashFlowId, DocDate, BranchCode) AS ct ON ct.CashFlowId=a.CashFlowId AND ct.DocDate=a.DocDate AND ct.BranchCode=a.BranchCode

	UPDATE #K_CtTmpTH SET DebitBalance111=ISNULL(ct.DebitBal1,0), CreditBalance111=ISNULL(ct.CreditBal1,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT BranchCode, SUM(DebitBal1) AS DebitBal1, SUM(CreditBal1) AS CreditBal1 FROM #SoDuDau 
		WHERE Account='111' GROUP BY BranchCode) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=1

	UPDATE #K_CtTmpTH SET DebitBalance112=ISNULL(ct.DebitBal1,0), CreditBalance112=ISNULL(ct.CreditBal1,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT BranchCode, SUM(DebitBal1) AS DebitBal1, SUM(CreditBal1) AS CreditBal1 FROM #SoDuDau 
		WHERE Account='112' GROUP BY BranchCode) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=1

	UPDATE #K_CtTmpTH SET DebitBalance111=(SELECT SUM(DebitBalance111) FROM #K_CtTmpTH WHERE _Status=1), 
	                      CreditBalance111=(SELECT SUM(CreditBalance111) FROM #K_CtTmpTH WHERE _Status=1)
		FROM #K_CtTmpTH a
		WHERE a._Status=0

   UPDATE #K_CtTmpTH SET DebitBalance112=(SELECT SUM(DebitBalance112) FROM #K_CtTmpTH WHERE _Status=1), 
	                      CreditBalance112=(SELECT SUM(CreditBalance112) FROM #K_CtTmpTH WHERE _Status=1)
		FROM #K_CtTmpTH a
		WHERE a._Status=0

	UPDATE #K_CtTmpTH SET DebitAmount111=ISNULL(ct.DebitAmount111,0), CreditAmount111=ISNULL(ct.CreditAmount111,0), DocNumber111=ISNULL(ct.DocNumber111,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (
		SELECT BranchCode, SUM(DebitAmount111) AS DebitAmount111, SUM(CreditAmount111) AS CreditAmount111, SUM(DocNumber111) AS DocNumber111 FROM #K_CtTmpTH WHERE _Status=3 GROUP BY BranchCode
		) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=2

	UPDATE #K_CtTmpTH SET DebitAmount112=ISNULL(ct.DebitAmount112,0), CreditAmount112=ISNULL(ct.CreditAmount112,0), DocNumber112=ISNULL(ct.DocNumber112,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (
		SELECT BranchCode, SUM(DebitAmount112) AS DebitAmount112, SUM(CreditAmount112) AS CreditAmount112, SUM(DocNumber112) AS DocNumber112 FROM #K_CtTmpTH WHERE _Status=3 GROUP BY BranchCode
		) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=2

	UPDATE #K_CtTmpTH SET DebitAmount111=(SELECT SUM(DebitAmount111) FROM #K_CtTmpTH WHERE _Status=2), 
	                      CreditAmount111=(SELECT SUM(CreditAmount111) FROM #K_CtTmpTH WHERE _Status=2),
						  DocNumber111=(SELECT SUM(DocNumber111) FROM #K_CtTmpTH WHERE _Status=2)
		FROM #K_CtTmpTH a
		WHERE a._Status=4

	UPDATE #K_CtTmpTH SET DebitAmount112=(SELECT SUM(DebitAmount112) FROM #K_CtTmpTH WHERE _Status=2), 
	                      CreditAmount112=(SELECT SUM(CreditAmount112) FROM #K_CtTmpTH WHERE _Status=2),
						  DocNumber112=(SELECT SUM(DocNumber112) FROM #K_CtTmpTH WHERE _Status=2)
		FROM #K_CtTmpTH a
		WHERE a._Status=4

	----------------
	---Đoạn Update sửa lại lấy dữ liệu
	UPDATE #K_CtTmpTH SET Description=CashFlowName
	FROM #K_CtTmpTH
	WHERE ISNULL(CashFlowName,'') <> ''

	UPDATE #K_CtTmpTH SET _StatusTH=IIF(_Status IN (0,1),0,IIF(_Status=4,7,IIF(_Status=8,8,IIF(_Status=9,9,5))))
	FROM #K_CtTmpTH

	UPDATE #K_CtTmpTH SET DebitAmount=IIF(DebitBalance > CreditBalance,DebitBalance-CreditBalance,0), 
	                      CreditAmount=IIF(CreditBalance > DebitBalance,CreditBalance - DebitBalance,0),
						  DebitAmount111=IIF(DebitBalance111 > CreditBalance111,DebitBalance111-CreditBalance111,0),
						  CreditAmount111=IIF(CreditBalance111 > DebitBalance111,CreditBalance111 - DebitBalance111,0),
						  DebitAmount112=IIF(DebitBalance112 > CreditBalance112,DebitBalance112-CreditBalance112,0),
						  CreditAmount112=IIF(CreditBalance112 > DebitBalance112,CreditBalance112 - DebitBalance112,0)
	FROM #K_CtTmpTH WHERE _Status IN (0,1)

	-------
	UPDATE #K_CtTmpTH SET DebitBalance111=ISNULL(ct.DebitAmount111,0), CreditBalance111=ISNULL(ct.CreditAmount111,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (
		SELECT BranchCode, SUM(DebitAmount111) AS DebitAmount111, SUM(CreditAmount111) AS CreditAmount111 FROM #K_CtTmpTH WHERE _Status IN (1,2) GROUP BY BranchCode
		) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=8

	UPDATE #K_CtTmpTH SET DebitBalance112=ISNULL(ct.DebitAmount112,0), CreditBalance112=ISNULL(ct.CreditAmount112,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (
		SELECT BranchCode, SUM(DebitAmount112) AS DebitAmount112, SUM(CreditAmount112) AS CreditAmount112 FROM #K_CtTmpTH WHERE _Status IN (1,2) GROUP BY BranchCode
		) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=8
	-------

	--UPDATE #K_CtTmpTH SET DebitAmount=DebitBalance, CreditAmount=CreditBalance
	--FROM #K_CtTmpTH WHERE _Status=8

	UPDATE #K_CtTmpTH SET DebitAmount=IIF(DebitBalance > CreditBalance,DebitBalance-CreditBalance,0), 
	                      CreditAmount=IIF(CreditBalance > DebitBalance,CreditBalance - DebitBalance,0),
						  DebitAmount111=IIF(DebitBalance111 > CreditBalance111,DebitBalance111-CreditBalance111,0),
						  CreditAmount111=IIF(CreditBalance111 > DebitBalance111,CreditBalance111 - DebitBalance111,0),
						  DebitAmount112=IIF(DebitBalance112 > CreditBalance112,DebitBalance112-CreditBalance112,0),
						  CreditAmount112=IIF(CreditBalance112 > DebitBalance112,CreditBalance112 - DebitBalance112,0)
	FROM #K_CtTmpTH WHERE _Status IN (8)

	
	UPDATE #K_CtTmpTH SET DebitBalance111=(SELECT SUM(DebitAmount111) FROM #K_CtTmpTH WHERE _Status=8),
	                      CreditBalance111=(SELECT SUM(CreditAmount111) FROM #K_CtTmpTH WHERE _Status=8)
	FROM #K_CtTmpTH a
	WHERE _Status=9

	UPDATE #K_CtTmpTH SET DebitBalance112=(SELECT SUM(DebitAmount112) FROM #K_CtTmpTH WHERE _Status=8),
	                      CreditBalance112=(SELECT SUM(CreditAmount112) FROM #K_CtTmpTH WHERE _Status=8)
	FROM #K_CtTmpTH a
	WHERE _Status=9

	UPDATE #K_CtTmpTH SET DebitAmount=IIF(DebitBalance > CreditBalance,DebitBalance-CreditBalance,0), 
	                      CreditAmount=IIF(CreditBalance > DebitBalance,CreditBalance - DebitBalance,0),
						  DebitAmount111=IIF(DebitBalance111 > CreditBalance111,DebitBalance111-CreditBalance111,0),
						  CreditAmount111=IIF(CreditBalance111 > DebitBalance111,CreditBalance111 - DebitBalance111,0),
						  DebitAmount112=IIF(DebitBalance112 > CreditBalance112,DebitBalance112-CreditBalance112,0),
						  CreditAmount112=IIF(CreditBalance112 > DebitBalance112,CreditBalance112 - DebitBalance112,0)
	FROM #K_CtTmpTH WHERE _Status IN (9)

	--duydnp xử lý tiền 112 ko theo SR
	UPDATE #K_CtTmpTH SET DebitAmount = 0, CreditAmount = 0, OriginalDebitAmount = 0, OriginalCreditAmount = 0, DebitAmount112 = 0, CreditAmount112 = 0 WHERE _Status IN (1,8) AND BranchCode <> ''
	
    -----------
	
	-- Lấy ra danh sách tài khoản từ số dư và phát sinh
	SELECT DISTINCT AccountCal, BranchCode
	INTO #DsAccountTemp
	FROM #K_CtTmp
	UNION ALL
	SELECT AccountCal , BranchCode
	FROM #SoDuDau 
	WHERE AccountCal NOT IN (SELECT AccountCal FROM #K_CtTmp) AND BranchCode NOT IN (SELECT BranchCode FROM #K_CtTmp)
	
	-- xử lý lại danh sách tk,sr
	
	UPDATE #DsAccountTemp SET BranchCode ='' WHERE AccountCal LIKE '112%'
	--UPDATE #K_CtTmp SET BranchCode ='' WHERE AccountCal LIKE '112%'
	ALTER TABLE #K_CtTmp ADD BranchCodeSort varchar(24)
	UPDATE #K_CtTmp SET BranchCodeSort = BranchCode

	DECLARE @_Account_Scan AS VARCHAR(24), @_BranchCode_Scan NVARCHAR(64)
	WHILE EXISTS(SELECT * FROM #DsAccountTemp)
	BEGIN
		SELECT TOP 1 @_Account_Scan = AccountCal , @_BranchCode_Scan=BranchCode
		FROM #DsAccountTemp
		
		SELECT @_DebitBal1 = SUM(DebitBal1),
			@_CreditBal1 = SUM(CreditBal1),
			@_OriginalDebitBal1 = SUM(OriginalDebitBal1),
			@_OriginalCreditBal1 = SUM(OriginalCreditBal1)
		FROM #SoDuDau
		WHERE AccountCal = @_Account_Scan AND BranchCode=@_BranchCode_Scan
	
		SELECT @_Temp_Value = 0, @_Temp_Value_Nt = 0, @_DebitBal1 = ISNULL(@_DebitBal1, 0), @_CreditBal1 = ISNULL(@_CreditBal1, 0),
			@_OriginalDebitBal1 = ISNULL(@_OriginalDebitBal1, 0), @_OriginalCreditBal1 = ISNULL(@_OriginalCreditBal1, 0),
			@_DebitAmount = 0, @_CreditAmount = 0, @_OriginalDebitAmount = 0, @_OriginalCreditAmount = 0,
			@_DebitBalance2 = 0, @_CreditBalance2 = 0, @_OriginalDebitBalance2 = 0, @_OriginalCreditBalance2 = 0
				
		-- Nếu Tk theo dõi SP hoặc đối tượng thì chỉ tính số dư cuối cùng và có thể dư 2 bên
		IF EXISTS (SELECT * FROM dbo.B20ChartOfAccount WHERE Code = @_Account_Scan AND (ProductAccount = 1 OR CustomerAccount = 1))
		BEGIN	
			SELECT @_DebitAmount = SUM(DebitAmount), @_CreditAmount = SUM(CreditAmount),
				@_OriginalDebitAmount = SUM(OriginalDebitAmount), @_OriginalCreditAmount = SUM(OriginalCreditAmount)
			FROM #K_CtTmp
			WHERE AccountCal = @_Account_Scan AND BranchCode=@_BranchCode_Scan

			;WITH cteDetail (AccountCal, CustomerId, ProductId, DebitBal1, CreditBal1, OriginalDebitBal1, OriginalCreditBal1, BranchCode) AS
			(
				SELECT AccountCal, CustomerId, ProductId, DebitBal1, CreditBal1, OriginalDebitBal1, OriginalCreditBal1, BranchCode
				FROM #SoDuDau
				WHERE AccountCal = @_Account_Scan AND BranchCode=@_BranchCode_Scan
				UNION ALL
				SELECT AccountCal, CustomerId, ProductId, DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount, BranchCode
				FROM #K_CtTmp
				WHERE AccountCal = @_Account_Scan AND BranchCode=@_BranchCode_Scan
			), cteSum (AccountCal, CustomerId, ProductId, DebitBal1, CreditBal1, OriginalDebitBal1, OriginalCreditBal1, BranchCode) AS
			(
				SELECT AccountCal, CustomerId, ProductId,
					SUM(DebitBal1) AS DebitBal1, SUM(CreditBal1) AS CreditBal1, SUM(OriginalDebitBal1) AS OriginalDebitBal1, SUM(OriginalCreditBal1) AS OriginalCreditBal1, BranchCode
				FROM cteDetail
				GROUP BY AccountCal, CustomerId, ProductId, BranchCode
			), cteResult (AccountCal, CustomerId, ProductId, DebitBal2, CreditBal2, OriginalDebitBal2, OriginalCreditBal2, BranchCode) AS
			(
				SELECT AccountCal, CustomerId, ProductId,
					IIF(DebitBal1 > CreditBal1, DebitBal1 - CreditBal1, 0) AS DebitBal2,
					IIF(CreditBal1 > DebitBal1, CreditBal1 - DebitBal1, 0) AS CreditBal2,
					IIF(OriginalDebitBal1 > OriginalCreditBal1, OriginalDebitBal1 - OriginalCreditBal1, 0) AS OriginalDebitBal2,
					IIF(OriginalCreditBal1 > OriginalDebitBal1, OriginalCreditBal1 - OriginalDebitBal1, 0) AS OriginalCreditBal2, BranchCode
				FROM cteSum
			)
			SELECT @_DebitBalance2 = SUM(DebitBal2), @_CreditBalance2 = SUM(CreditBal2),
				@_OriginalDebitBalance2 = SUM(OriginalDebitBal2), @_OriginalCreditBalance2 = SUM(OriginalCreditBal2)
			FROM cteResult
		END
		ELSE
		BEGIN
			IF @_DebitBal1 > @_CreditBal1 
				SET @_DebitBalance2 = @_DebitBal1 - @_CreditBal1
			ELSE
				SET @_CreditBalance2 = @_CreditBal1 - @_DebitBal1
				
			IF @_OriginalDebitBal1 > @_OriginalCreditBal1
				SET @_OriginalDebitBalance2 = @_OriginalDebitBal1 - @_OriginalCreditBal1
			ELSE
				SET @_OriginalCreditBalance2 = @_OriginalCreditBal1 - @_OriginalDebitBal1

			UPDATE #K_CtTmp
				SET @_DebitAmount = @_DebitAmount + DebitAmount, @_CreditAmount = @_CreditAmount + CreditAmount,
					@_OriginalDebitAmount = @_OriginalDebitAmount + OriginalDebitAmount, @_OriginalCreditAmount = @_OriginalCreditAmount + OriginalCreditAmount,
					@_Temp_Value = (@_DebitBalance2 - @_CreditBalance2) + (DebitAmount - CreditAmount),
					@_DebitBalance2 = DebitBalance = IIF(@_Temp_Value > 0, @_Temp_Value, 0),
					@_CreditBalance2 = CreditBalance = IIF(@_Temp_Value <= 0, ABS(@_Temp_Value), 0),
					@_Temp_Value_Nt = (@_OriginalDebitBalance2 - @_OriginalCreditBalance2) + (OriginalDebitAmount - OriginalCreditAmount),
					@_OriginalDebitBalance2 = OriginalDebitBalance = IIF(@_Temp_Value_Nt > 0, @_Temp_Value_Nt, 0),
					@_OriginalCreditBalance2 = OriginalCreditBalance = IIF(@_Temp_Value_Nt <= 0, ABS(@_Temp_Value_Nt), 0)
				FROM #K_CtTmp
				WHERE AccountCal = @_Account_Scan AND (BranchCode=@_BranchCode_Scan OR @_BranchCode_Scan ='')
		END
		

		
		
		IF @_Account_Scan LIKE '111%'
		BEGIN
			INSERT #K_CtTmp (Id, Account, DocDate, Description, DebitBalance, CreditBalance, OriginalDebitBalance, OriginalCreditBalance, _Status, _FormatStyleKey, AccountCal, BranchCode, BranchCodeSort) VALUES
				(NULL, @_Account_Scan, NULL, dbo.ufn_sys_MessageText(N'DuDauKy', @_LangId),
					ISNULL(@_DebitBal1, 0), ISNULL(@_CreditBal1, 0), ISNULL(@_OriginalDebitBal1, 0), ISNULL(@_OriginalCreditBal1, 0), N'0', 'BOLD', @_Account_Scan, @_BranchCode_Scan, @_BranchCode_Scan)
			INSERT #K_CtTmp (Id, Account, DocDate, Description, DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey, AccountCal, BranchCode, BranchCodeSort) VALUES
				(NULL, @_Account_Scan, NULL, dbo.ufn_sys_MessageText(N'TongPhatSinh', @_LangId),
					ISNULL(@_DebitAmount, 0), ISNULL(@_CreditAmount, 0), ISNULL(@_OriginalDebitAmount, 0), ISNULL(@_OriginalCreditAmount, 0), N'8', 'BOLD', @_Account_Scan, @_BranchCode_Scan, @_BranchCode_Scan)
		END
		ELSE
		BEGIN
			INSERT #K_CtTmp (Id, Account, DocDate, Description, DebitBalance, CreditBalance, OriginalDebitBalance, OriginalCreditBalance, _Status, _FormatStyleKey, AccountCal, BranchCode, BranchCodeSort) VALUES
				(NULL, @_Account_Scan, NULL, dbo.ufn_sys_MessageText(N'DuDauKy', @_LangId),
					ISNULL(@_DebitBal1, 0), ISNULL(@_CreditBal1, 0), ISNULL(@_OriginalDebitBal1, 0), ISNULL(@_OriginalCreditBal1, 0), N'0', 'BOLD', @_Account_Scan, @_BranchCode_Scan, 'A0')

			INSERT #K_CtTmp (Id, Account, DocDate, Description, DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey, AccountCal, BranchCode, BranchCodeSort)
			SELECT NULL, @_Account_Scan, NULL, dbo.ufn_sys_MessageText(N'TongPhatSinh', @_LangId) + ' - ' + BranchCode,
					SUM(DebitAmount), SUM(CreditAmount), SUM(OriginalDebitAmount), SUM(OriginalCreditAmount), N'8', 'BOLD', @_Account_Scan, BranchCode, 'Z0'
			FROM #K_CtTmp
			WHERE AccountCal = @_Account_Scan AND _Status <> 0
			GROUP BY BranchCode
		END
		INSERT #K_CtTmp (Id, Account, DocDate, Description, DebitBalance, CreditBalance, OriginalDebitBalance, OriginalCreditBalance, _Status, _FormatStyleKey, AccountCal, BranchCode, BranchCodeSort) VALUES
				(NULL, @_Account_Scan, NULL, dbo.ufn_sys_MessageText(N'DuCuoiKy', @_LangId),
					ISNULL(@_DebitBalance2, 0), ISNULL(@_CreditBalance2, 0), ISNULL(@_OriginalDebitBalance2, 0), ISNULL(@_OriginalCreditBalance2, 0), N'9', 'BOLD', @_Account_Scan, @_BranchCode_Scan, 'Z1')
	
		DELETE FROM #DsAccountTemp WHERE AccountCal = @_Account_Scan AND BranchCode=@_BranchCode_Scan
	END

	UPDATE #K_CtTmp 
	SET GroupCode = bc.AccountCal + ' - ' +bc.BranchCode,
		GroupName = RTRIM(bc.AccountCal) + N': ' +
			ISNULL(dbo.ufn_sys_BH(ISNULL(dm.Name, ''), ISNULL(dm.Name_English, ''), '', ISNULL(dm.Name_Japanese, ''), ISNULL(dm.Name_Chinese, ''), ISNULL(dm.Name_Korean, ''), @_LangId), '') + ' - '+ route.Name
	FROM #K_CtTmp AS bc
		LEFT OUTER JOIN B20ChartOfAccount AS dm ON bc.AccountCal = dm.Code
		LEFT OUTER JOIN dbo.B20DmsRoute route ON route.Code=bc.BranchCode
	WHERE AccountCal LIKE '111%'

	UPDATE #K_CtTmp 
	SET GroupCode = bc.AccountCal + N' - Tổng công ty',
		GroupName = RTRIM(bc.AccountCal) + N': ' +
			ISNULL(dbo.ufn_sys_BH(ISNULL(dm.Name, ''), ISNULL(dm.Name_English, ''), '', ISNULL(dm.Name_Japanese, ''), ISNULL(dm.Name_Chinese, ''), ISNULL(dm.Name_Korean, ''), @_LangId), '') + N' - Tổng công ty'
	FROM #K_CtTmp AS bc
		LEFT OUTER JOIN B20ChartOfAccount AS dm ON bc.AccountCal = dm.Code
	WHERE AccountCal LIKE '112%'

	SELECT *
	FROM #K_CtTmp
	ORDER BY AccountCal,BranchCode,_Status,_Rank

	SELECT *
	FROM #K_CtTmpTH
	ORDER BY AccountCal,_StatusTH,BranchCode,_Status,DocDate,_Rank


	DROP TABLE #K_CtTmp0
	DROP TABLE #K_CtTmp
	DROP TABLE #DsAccountTemp
	DROP TABLE #DsAccountTempTH
	--DROP TABLE #DsAccountTempCT
	
END
GO
go

SET DATEFORMAT dmy;

EXECUTE usp_Kct_SubsidiaryLedger_DTTC @_DocDate1 = '01/05/2026 00:00:00.000', @_DocDate2 = '31/05/2026 00:00:00.000', @_Account = '111,112,113', @_AccountLevel = 1, @_ForeignCurrencyOnly = 0, @_nUserId = 1213, @_LangId = 0, @_CurrencyCode0 = 'VND', @_BranchCode = 'I08';