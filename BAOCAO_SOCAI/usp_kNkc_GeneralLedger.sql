-- Coder: ThangNH

-- ====================================
-- Description: Sổ cái tài khoản - hình thức nhật ký chung
-- ====================================
ALTER PROCEDURE dbo.usp_kNkc_GeneralLedger
	@_DocDate1 DATE	= 'Jan 01 2012',
	@_DocDate2 DATE	= 'Mar 31 2012',
	@_Account VARCHAR(MAX) = N'',
	@_ForeignCurrencyOnly INT = 0,
	@_nUserId AS INT = 0,
	@_LangId INT = 0,
	@_CurrencyCode0 CHAR(3) = 'VND',
	@_BranchCode VARCHAR(3) = 'A01'
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	-- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)

	SET @_Account = RTRIM(@_Account)	

	DECLARE @_Ngay_Dau_Quy DATE = dbo.ufn_sys_GetFirstDayOfQuarter(@_DocDate1, @_BranchCode);

	DECLARE @_KeyCd NVARCHAR(MAX) = '', @_Key1 NVARCHAR(MAX) = '', @_Key2 NVARCHAR(MAX) = '', 
			@_Description AS NVARCHAR(254),
			@_DebitBal0 NUMERIC(18, 2), @_CreditBal0 NUMERIC(18, 2), 
			@_OriginalDebitBal0 NUMERIC(18, 2), @_OriginalCreditBal0 NUMERIC(18, 2),
			@_DebitBal1 NUMERIC(18, 2), @_CreditBal1 NUMERIC(18, 2), 
			@_OriginalDebitBal1 NUMERIC(18, 2), @_OriginalCreditBal1 NUMERIC(18, 2),
			@_DebitAmount NUMERIC(18, 2), @_CreditAmount NUMERIC(18, 2), 
			@_OriginalDebitAmount NUMERIC(18, 2), @_OriginalCreditAmount NUMERIC(18, 2),
			@_DebitAmount_Lk NUMERIC(18, 2), @_CreditAmount_Lk NUMERIC(18, 2), 
			@_OriginalDebitAmountLk NUMERIC(18, 2), @_OriginalCreditAmountLk NUMERIC(18, 2),
			@_DebitBal2 NUMERIC(18, 2), @_OriginalDebitBal2 NUMERIC(18, 2), 
			@_CreditBal2 NUMERIC(18, 2), @_OriginalCreditBal2 NUMERIC(18, 2)
	
	IF @_Account <> ''
		SET @_KeyCd = N'(Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + '%'')' --24/12/2024: Sửa lại key do điều kiện lọc cho chọn nhiều

	-- Lay so du dau tai khoan
	DROP TABLE IF EXISTS #SoDuDau
	SELECT TOP 0 Account, CustomerId,
		Amount AS DebitBal0, Amount AS CreditBal0,
		OriginalAmount AS OriginalDebitBal0, OriginalAmount AS OriginalCreditBal0,
		Amount AS DebitBal1, Amount AS CreditBal1,
		OriginalAmount AS OriginalDebitBal1, OriginalAmount AS OriginalCreditBal1
	INTO #SoDuDau 
	FROM B00CtTmp

	EXECUTE usp_B30OpenBalance_GetData
		@_DocDate0			= @_DocDate1, 
		@_Key				= @_KeyCd, 
		@_CtTmp				= N'#SoDuDau',
		@_nUserId			= @_nUserId,
		@_LangId			= @_LangId,
		@_BranchCode		= @_BranchCode, 
		@_CurrencyCode0		= @_CurrencyCode0,
		@_Opening			= 1,			
		@_Accumulate		= 0,		
		@_AutoCalculate		= 1

	-- Lay so du cuoi tai khoan
	DROP TABLE IF EXISTS #SoDuCuoi
	SELECT TOP 0 Account, CustomerId,
		Amount AS DebitBal1, Amount AS CreditBal1,
		OriginalAmount AS OriginalDebitBal1, OriginalAmount AS OriginalCreditBal1
	INTO #SoDuCuoi 
	FROM B00CtTmp

	EXECUTE usp_B30OpenBalance_GetEndOfDayBalance
		@_DocDate0			= @_DocDate2, 
		@_Key				= @_KeyCd, 
		@_CtTmp				= N'#SoDuCuoi',
		@_nUserId			= @_nUserId,
		@_LangId			= @_LangId,
		@_BranchCode		= @_BranchCode, 
		@_CurrencyCode0		= @_CurrencyCode0,
		@_Opening			= 0,			
		@_Accumulate		= 0,		
		@_AutoCalculate		= 1

	IF @_Account <> ''
		SET @_Key1 = @_KeyCd

	DROP TABLE IF EXISTS #K_CtTmp0
	DROP TABLE IF EXISTS #K_CtTmp
	
	SELECT TOP 0 Id, DocDate, DocNo, DocCode, DocGroup, Description, CrspAccount, Account, Person,
			DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount,
			DocGroup AS DocGroup0, Stt, CustomerId0, CurrencyCode, ExchangeRate,
			CAST('' AS varchar(24)) AS GroupCode, CAST('' AS NVARCHAR(128)) AS GroupName
		INTO #K_CtTmp0
		FROM B00CtTmp

	EXECUTE usp_B30GeneralLedger_GetData 
		@_DocDate1	= @_Ngay_Dau_Quy, 
		@_DocDate2	= @_DocDate2, 
		@_Key1		= @_Key1, 
		@_Key2		= @_Key2, 
		@_CtTmp		= N'#K_CtTmp0',
		@_nUserId	= @_nUserId,
		@_LangId	= @_LangId, 
		@_BranchCode	= @_BranchCode, 
		@_CurrencyCode0	= @_CurrencyCode0

	DELETE FROM #K_CtTmp0 
		WHERE ABS(DebitAmount) + ABS(CreditAmount) + ABS(OriginalDebitAmount) + ABS(OriginalCreditAmount) =0;

	UPDATE #K_CtTmp0 SET DocGroup0 = '2' WHERE CreditAmount > 0

	DROP TABLE IF EXISTS #K_PsLk
	SELECT Account, SUM(DebitAmount) AS DebitAmount, SUM(CreditAmount) AS CreditAmount, 
			SUM(OriginalDebitAmount) AS OriginalDebitAmount, SUM(OriginalCreditAmount) AS OriginalCreditAmount
		INTO #K_PsLk
		FROM #K_CtTmp0
		WHERE DocDate < @_DocDate1
		GROUP BY Account

	SELECT Id, DocDate, DocNo, DocCode, DocGroup, Description, Account, CrspAccount, Person,
			DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount,
			Stt, DocGroup0, '2' AS _Status, CustomerId0, CurrencyCode, ExchangeRate, 
			CAST(N'' AS NVARCHAR(64)) AS _FormatStyleKey,
			DocDate AS BookingDate, GroupCode, GroupName,
			CAST('' AS NVARCHAR(32)) AS PageNo,
			CAST('' AS NVARCHAR(32)) AS RowId,
			CAST('' AS NVARCHAR(64)) AS Notice
		INTO #K_CtTmp
		FROM #K_CtTmp0
		WHERE DocDate >= @_DocDate1
		ORDER BY DocDate, DocGroup0, DocNo, Stt
	
	EXEC usp_sys_DefaultTable '#K_CtTmp'
	
	/*Cách lên báo cáo như sau:
		- Chọn tk mẹ (có các tiểu khoản)
			+ muốn lên chi tiết các tk con: tk mẹ ko tích "là tk sổ cái"
			+ muốn lên tk mẹ, ko lên các tk con: tk mẹ chọn tích "là tk sổ cái"
		- chọn tk con (không có tiểu khoản): báo cáo lên đích danh tài khoản con
		- ko chọn tk nào: lên chi tiết các tk con
	*/
	-- Lấy danh sách tài khoản nhập vào
	DROP TABLE IF EXISTS #AccTemp
	SELECT [value] AS Code
		INTO #AccTemp
		FROM STRING_SPLIT(@_Account, ',')

	-- Lấy các thuộc tính "là tài khoản sổ cái", "là tài khoản mẹ"
	DROP TABLE IF EXISTS #TkSc
	SELECT a.Code, b.GLAccount, b.IsParentAccount
		INTO #TkSc
		FROM #AccTemp AS a
			LEFT OUTER JOIN dbo.vB20ChartOfAccount AS b ON a.Code = b.Code

	DECLARE @_Acc VARCHAR(24), @_IsParentAccount TINYINT, @_GLAccount TINYINT

	-- Thực hiện kiểm tra
	WHILE EXISTS (SELECT * FROM #TkSc)
	BEGIN
		SELECT TOP 1 @_Acc = Code, 
				@_IsParentAccount = IsParentAccount, 
				@_GLAccount = GLAccount
		FROM #TkSc

		-- Nếu là tài khoản mẹ
		IF (@_IsParentAccount = 1)
		BEGIN
			-- Nếu là tài khoản sổ cáir
			IF (@_GLAccount = 1)
			BEGIN
				UPDATE #K_CtTmp0 SET Account = @_Acc WHERE Account LIKE @_Acc + '%'
				UPDATE #SoDuDau SET Account = @_Acc WHERE Account LIKE @_Acc + '%'
				UPDATE #SoDuCuoi SET Account = @_Acc WHERE Account LIKE @_Acc + '%'
				UPDATE #K_CtTmp SET Account = @_Acc WHERE Account LIKE @_Acc + '%'
				UPDATE #K_PsLk SET Account = @_Acc WHERE Account LIKE @_Acc + '%'
			END 
			ELSE
			BEGIN
				DROP TABLE IF EXISTS #AccList
				SELECT a.Account, a.IsParentAccount, a.ParentCode, b.GLAccount
					INTO #AccList
					FROM 
						(
							SELECT DISTINCT a.Account, b.ParentCode, b.IsParentAccount
								FROM #K_CtTmp0 a
								LEFT OUTER JOIN dbo.vB20ChartOfAccount b ON a.Account = b.Code
							UNION ALL 
							SELECT a.Account, b.ParentCode, b.IsParentAccount
								FROM #SoDuDau a
								LEFT OUTER JOIN dbo.vB20ChartOfAccount b ON a.Account = b.Code
							WHERE a.Account NOT IN (SELECT Account FROM #K_CtTmp0)
						) AS a 
						LEFT OUTER JOIN dbo.vB20ChartOfAccount AS b ON a.ParentCode = b.Code	
					WHERE a.Account LIKE @_Acc + '%'

				DECLARE @_AccTemp VARCHAR(24), @_ParentCode VARCHAR(24), @_TkSc TINYINT
				WHILE EXISTS (SELECT * FROM #AccList)
				BEGIN
					SELECT TOP 1 @_AccTemp = Account, @_ParentCode = ParentCode, @_TkSc = GLAccount
					FROM #AccList

					IF (@_TkSc = 1)
					BEGIN
						UPDATE #K_CtTmp0 SET Account = @_ParentCode WHERE Account = @_AccTemp
						UPDATE #SoDuDau SET Account = @_ParentCode WHERE Account = @_AccTemp
						UPDATE #SoDuCuoi SET Account = @_ParentCode WHERE Account = @_AccTemp
						UPDATE #K_CtTmp SET Account = @_ParentCode WHERE Account = @_AccTemp
					END

					DELETE #AccList WHERE Account = @_AccTemp
				END
			END
		END
		
		DELETE FROM #TkSc WHERE Code = @_Acc
	END

	-- Lấy ra danh sách tài khoản từ số dư và phát sinh
	SELECT DISTINCT Account 
		INTO #DsAccountTemp
		FROM #K_CtTmp0
	UNION ALL 
	SELECT Account 
		FROM #SoDuDau 
		WHERE Account NOT IN (SELECT Account FROM #K_CtTmp0)

	DECLARE @_Account_Scan AS VARCHAR(24)
	WHILE EXISTS(SELECT * FROM #DsAccountTemp)
	BEGIN
		SELECT TOP 1 @_Account_Scan = Account FROM #DsAccountTemp
		
		SELECT @_DebitBal1 = SUM(DebitBal1), @_CreditBal1 = SUM(CreditBal1), 
				@_OriginalDebitBal1 = SUM(OriginalDebitBal1), @_OriginalCreditBal1 = SUM(OriginalCreditBal1),
				@_DebitBal0 = SUM(DebitBal0), @_CreditBal0 = SUM(CreditBal0), 
				@_OriginalDebitBal0 = SUM(OriginalDebitBal0), @_OriginalCreditBal0 = SUM(OriginalCreditBal0)
		FROM #SoDuDau 
		WHERE Account = @_Account_Scan	

		SELECT @_DebitAmount_Lk = SUM(DebitAmount), @_CreditAmount_Lk = SUM(CreditAmount), 
				@_OriginalDebitAmountLk = SUM(OriginalDebitAmount), @_OriginalCreditAmountLk = SUM(OriginalCreditAmount)
		FROM #K_PsLk 
		WHERE Account = @_Account_Scan	
	
		SELECT @_DebitAmount = SUM(DebitAmount), @_CreditAmount = SUM(CreditAmount), 
				@_OriginalDebitAmount = SUM(OriginalDebitAmount), @_OriginalCreditAmount = SUM(OriginalCreditAmount)
		FROM #K_CtTmp 
		WHERE Account = @_Account_Scan	

		SELECT @_DebitBal2 = SUM(DebitBal1), @_CreditBal2 = SUM(CreditBal1), 
				@_OriginalDebitBal2 = SUM(OriginalDebitBal1), @_OriginalCreditBal2 = SUM(OriginalCreditBal1)
		FROM #SoDuCuoi 
		WHERE Account = @_Account_Scan	

		SELECT @_DebitBal0 = ISNULL(@_DebitBal0, 0), @_CreditBal0 = ISNULL(@_CreditBal0, 0),
				@_OriginalDebitBal0 = ISNULL(@_OriginalDebitBal0, 0), @_OriginalCreditBal0 = ISNULL(@_OriginalCreditBal0, 0),		
				@_DebitBal1 = ISNULL(@_DebitBal1, 0), @_CreditBal1 = ISNULL(@_CreditBal1, 0),
				@_OriginalDebitBal1 = ISNULL(@_OriginalDebitBal1, 0), @_OriginalCreditBal1 = ISNULL(@_OriginalCreditBal1, 0),	
				@_DebitAmount = ISNULL(@_DebitAmount, 0), @_CreditAmount = ISNULL(@_CreditAmount, 0), 
				@_OriginalDebitAmount = ISNULL(@_OriginalDebitAmount, 0), @_OriginalCreditAmount = ISNULL(@_OriginalCreditAmount, 0),
				@_DebitAmount_Lk = ISNULL(@_DebitAmount_Lk, 0), @_CreditAmount_Lk = ISNULL(@_CreditAmount_Lk, 0), 
				@_OriginalDebitAmountLk = ISNULL(@_OriginalDebitAmountLk, 0), @_OriginalCreditAmountLk = ISNULL(@_OriginalCreditAmountLk, 0),
				@_DebitBal2 = ISNULL(@_DebitBal2, 0), @_CreditBal2 = ISNULL(@_CreditBal2, 0),
				@_OriginalDebitBal2 = ISNULL(@_OriginalDebitBal2, 0), @_OriginalCreditBal2 = ISNULL(@_OriginalCreditBal2, 0)
		
		INSERT #K_CtTmp (Id, Account, DocDate, BookingDate, Description, DebitAmount, CreditAmount, 
				OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey) 
		VALUES (NULL, @_Account_Scan, NULL, NULL, '- ' + dbo.ufn_sys_MessageText(N'SOCAI_DN', @_LangId),
				@_DebitBal0, @_CreditBal0, @_OriginalDebitBal0, @_OriginalCreditBal0, N'0', 'BOLD')

		INSERT #K_CtTmp (Id, Account, DocDate, BookingDate, Description, _Status, _FormatStyleKey) 
		VALUES (NULL, @_Account_Scan, NULL, NULL, '- ' + dbo.ufn_sys_MessageText(N'SOCAI_PS', @_LangId), N'1', 'BOLD')

		INSERT #K_CtTmp (Id, Account, DocDate, BookingDate, Description, DebitAmount, CreditAmount, 
				OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey) 
		VALUES (NULL, @_Account_Scan, NULL, NULL, '- ' + dbo.ufn_sys_MessageText(N'SOCAI_CPS', @_LangId),
				@_DebitAmount, @_CreditAmount, @_OriginalDebitAmount, @_OriginalCreditAmount, N'3', 'BOLD')

		INSERT #K_CtTmp (Id, Account, DocDate, BookingDate, Description, DebitAmount, CreditAmount, 
				OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey) 
		VALUES (NULL, @_Account_Scan, NULL, NULL, '- ' + dbo.ufn_sys_MessageText(N'SOCAI_DU', @_LangId),
				@_DebitBal2, @_CreditBal2, @_OriginalDebitBal2, @_OriginalCreditBal2, N'4', 'BOLD')

		INSERT #K_CtTmp (Id, Account, DocDate, BookingDate, Description, DebitAmount, CreditAmount, 
				OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey) 
		VALUES (NULL, @_Account_Scan, NULL, NULL, '- ' + dbo.ufn_sys_MessageText(N'SOCAI_LKQ', @_LangId),
				@_DebitAmount_Lk + @_DebitAmount, @_CreditAmount_Lk + @_CreditAmount, 
				@_OriginalDebitAmountLk + @_OriginalDebitAmount, @_OriginalCreditAmountLk + @_OriginalCreditAmount, N'5', 'BOLD')

		DELETE FROM #DsAccountTemp WHERE Account = @_Account_Scan
	END

	UPDATE #K_CtTmp SET GroupCode = bc.Account, 
			GroupName = RTRIM(bc.Account) + ' - ' + RTRIM(CASE WHEN @_LangId = 0 THEN dm.Name ELSE dm.Name_English END)
		FROM #K_CtTmp AS bc 
			LEFT OUTER JOIN B20ChartOfAccount AS dm ON bc.Account = dm.Code

	SELECT * FROM #K_CtTmp 

	DROP TABLE IF EXISTS #K_PsLk
	DROP TABLE IF EXISTS #SoDuDau
	DROP TABLE IF EXISTS #SoDuCuoi	
	DROP TABLE IF EXISTS #DsAccountTemp
	DROP TABLE IF EXISTS #K_CtTmp0
	DROP TABLE IF EXISTS #K_CtTmp
END

GO
