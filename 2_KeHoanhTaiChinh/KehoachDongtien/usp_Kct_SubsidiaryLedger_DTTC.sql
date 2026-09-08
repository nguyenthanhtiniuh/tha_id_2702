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
	@_DocDate1 DATE = '' OUTPUT,
	@_DocDate2 DATE = '' OUTPUT,
	@_Account VARCHAR(1000) = '', 
	@_CashFlowId VARCHAR(1000) = '', 
	@_AccountLevel INT = 0,
	@_ForeignCurrencyOnly TINYINT = 0,
	@_nUserId AS INT = 0,
	@_LangId SMALLINT = 0,
	@_CurrencyCode0 VARCHAR(3) = 'VND',
	@_BranchCode VARCHAR(3) = 'A01' ,
    @_MonthString VARCHAR(64)    = ''   ,
    @_Loai_Ps VARCHAR(24) = N'',
    @_No_Co VARCHAR(1) = N'' OUTPUT,	
    @_MESGroupCode_List VARCHAR(24) = N'' ,
    @_Key_Other NVARCHAR(MAX) = ''
AS
BEGIN
	SET NOCOUNT ON;

	-- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	--SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)

	SET @_Account = RTRIM(@_Account)	

    IF ISNULL(@_MonthString, '') <> ''
       AND CHARINDEX('Y', @_MonthString) = 0 --K202601 --xem theo tháng
        EXEC dbo.usp_Get_MonthStartDate_MonthEndDate_ByString @_String = @_MonthString, @_MonthStartDate = @_DocDate1 OUTPUT, @_MonthEndDate = @_DocDate2 OUTPUT,@_TypeMonth ='yyyyMM'
    ELSE IF (
                ISNULL(@_MonthString, '') <> ''
                AND CHARINDEX('Y', @_MonthString) <> 0
                AND ISNUMERIC(RIGHT(@_MonthString, 4)) = 1
            ) --K_Total_2026 --xem theo năm
        SELECT @_DocDate1 = DATEFROMPARTS(RIGHT(@_MonthString, 4), 01, 31)
              ,@_DocDate2 = DATEFROMPARTS(RIGHT(@_MonthString, 4), 12, 31)
    ELSE --TOTAL 
        SELECT @_DocDate1 = @_DocDate1
              ,@_DocDate2 = @_DocDate2

	DECLARE @_KeyCd NVARCHAR(MAX) = '',
		@_Key1 NVARCHAR(MAX) = '',
		@_Key2 NVARCHAR(MAX) = '',
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

        -- Xử lý key cho phiên bản R2:
    DECLARE @_FilterDebitRow NVARCHAR(128) -- Fix thêm xử lý EntryNo        
	
	IF @_Account <> ''
	BEGIN 
		SELECT @_KeyCd += N'(' + N'(Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + N'%'')' + N')'		  
				,@_Key1 += N'(' + N'(Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + N'%'')' + N')'
	END

    SELECT @_No_Co = @_No_Co,@_Loai_Ps = ISNULL(@_Loai_Ps,'')

    IF ISNULL(@_Loai_Ps,'') <> ''
    SELECT @_No_Co = CASE   WHEN @_Loai_Ps = 'PS_CO' AND @_No_Co='' THEN 'C' 
                            WHEN @_Loai_Ps = 'PS_NO' AND @_No_Co='' THEN 'N' 
                            WHEN @_Loai_Ps = '' THEN '' 
                            ELSE '' END 
    
    IF @_No_Co = 'C'
    BEGIN
        SET @_FilterDebitRow = N' AND (EntryNo LIKE ''%B'')'
    END
    ELSE IF @_No_Co = 'N'
    BEGIN
        SET @_FilterDebitRow = N' AND (EntryNo LIKE ''%A'')'
    END
    ELSE
        SET @_FilterDebitRow = N''
 

    IF RTRIM(@_CashFlowId) <> ''
	EXECUTE dbo.usp_sys_GenKey @_Code = @_CashFlowId, @_ColGen = 'CashFlowId', 
		@_ColName = 'Id', @_TableName = 'B20CashFlow', 
		@_AndOrKey = 'AND', @_Key = @_Key1 OUTPUT

	IF LTRIM(RTRIM(@_MESGroupCode_List)) <> N''
	SET @_Key1 = @_Key1 + N' AND CustomerId0 IN (SELECT Id FROM dbo.B20Customer WITH (NOLOCK)
									WHERE MESGroupCode IN (''' + REPLACE(REPLACE(LTRIM(RTRIM(@_MESGroupCode_List)), N' ', N''), N',', N''',''') + N'''))';
 
	SET @_Key2 =  @_KeyCd + @_FilterDebitRow   

	if isnull(@_Key_Other,'')<>''
		select @_Key2=@_Key2+@_Key_Other

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
	FROM dbo.B00CtTmp

	EXECUTE dbo.usp_B30OpenBalance_GetData
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
 
	DROP TABLE IF EXISTS #K_CtTmp0;
	SELECT TOP 0 CAST (NULL AS INT) AS Id,
				 DocDate,
				 DocNo,
				 DocCode,
				 DocGroup,
				 DocBookingId,
				 BranchCode,
				 Description,
				 EntryNo,
				 Account,
				 CAST ('' AS NVARCHAR (24)) AS AccountCal,
				 CrspAccount,
				 DebitAccount,
				 CreditAccount,
				 ProductId,				 
				 ExchangeRate,
				 CurrencyCode,
				 DebitAmount,
				 CreditAmount,
				 OriginalDebitAmount,
				 OriginalCreditAmount,
				 CAST ('' AS NCHAR (1)) AS DocGroup0,
				 Stt,
				 RowId,
				 CustomerId,
				 CustomerId AS CustomerId0,
				 CAST ('' AS VARCHAR (24)) AS MesGroupCode,
				 Person,				
				 CAST ('' AS VARCHAR (24)) AS GroupCode,
				 CAST ('' AS NVARCHAR (256)) AS GroupName,
				 CAST ('' AS NVARCHAR (96)) AS ParentGroupOrder,				 
				 CAST ('' AS NVARCHAR (26)) AS CashFlowId,
				 CAST (N'' AS VARCHAR (24)) AS CashFlowCode,
				 CAST (N'' AS NVARCHAR (256)) AS CashFlowName,
				 CAST (0 AS INT) AS DocNumber				 
	INTO   #K_CtTmp0
	FROM   dbo.B00CtTmp;

	EXECUTE dbo.usp_B30GeneralLedger_GetData
		@_DocDate1 = @_DocDate1,
		@_DocDate2 = @_DocDate2,
		@_Key1 = @_Key1,
		@_Key2 = @_Key2,
		@_CtTmp = N'#K_CtTmp0',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_PrintExec = 0
		
	UPDATE  t
		SET MesGroupCode = cus.MESGroupCode
	FROM    #K_CtTmp0 AS t
			INNER JOIN
			B20Customer AS cus WITH (NOLOCK)
			ON t.CustomerId0 = cus.Id;
	 
	UPDATE  ctt
		SET CashFlowCode = cf.Code,
			CashFlowName = cf.Name
	FROM    #K_CtTmp0 AS ctt
			INNER JOIN
			dbo.B20CashFlow AS cf WITH (NOLOCK)
			ON ctt.CashFlowId = cf.Id;		
 
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

	UPDATE #SoDuDau SET AccountCal=N'111,112,113' FROM #SoDuDau
 
	UPDATE #K_CtTmp0 SET DocNumber = 1 FROM #K_CtTmp0
 
	UPDATE a
			SET a.Account  = b.value
			FROM #K_CtTmp0 a
				CROSS APPLY (SELECT ac.value FROM STRING_SPLIT(@_Account,',') ac
							WHERE a.Account LIKE ac.value + '%') AS b 														

	UPDATE #SoDuDau SET Account = IIF(Account LIKE N'111%','111','112') FROM #SoDuDau

	--UPDATE a
	--	SET a.AccountCal = b.value
	--	FROM #K_CtTmp0 a
	--		CROSS APPLY (SELECT ac.value FROM STRING_SPLIT(@_Account,',') ac
	--					WHERE a.Account LIKE ac.value + '%') AS b

	--UPDATE a
	--SET a.AccountCal = b.value
	--FROM #SoDuDau a
	--	CROSS APPLY (SELECT ac.value FROM STRING_SPLIT(@_Account,',') ac
	--				WHERE a.Account LIKE ac.value + '%') AS b
    
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
		BranchCode,CAST('' AS NVARCHAR(156)) AS RouteName, CashFlowId, 
		CAST('' AS NVARCHAR(156)) AS CashFlowName, SUM(DocNumber) AS DocNumber, CAST(0 AS INT) AS _StatusTH,
		CAST(0 AS NUMERIC(18,2)) AS DebitAmount111, CAST(0 AS NUMERIC(18,2)) AS CreditAmount111, CAST(0 AS NUMERIC(18,2)) AS DocNumber111, CAST(0 AS NUMERIC(18, 2)) AS DebitBalance111, CAST(0 AS NUMERIC(18, 2)) AS CreditBalance111,
		CAST(0 AS NUMERIC(18,2)) AS DebitAmount112, CAST(0 AS NUMERIC(18,2)) AS CreditAmount112, CAST(0 AS NUMERIC(18,2)) AS DocNumber112, CAST(0 AS NUMERIC(18, 2)) AS DebitBalance112, CAST(0 AS NUMERIC(18, 2)) AS CreditBalance112,
		CAST(0 AS NUMERIC(18,2)) AS DebitAmount113, CAST(0 AS NUMERIC(18,2)) AS CreditAmount113, CAST(0 AS NUMERIC(18,2)) AS DocNumber113, CAST(0 AS NUMERIC(18, 2)) AS DebitBalance113, CAST(0 AS NUMERIC(18, 2)) AS CreditBalance113,
		CAST('' AS NVARCHAR(2000)) AS _LinkCommand
	INTO #K_CtTmpTH
	FROM #K_CtTmp0
	GROUP BY CashFlowId, DocDate, BranchCode 
 
	CREATE CLUSTERED INDEX IX_Rank_K_CtTmp ON #K_CtTmpTH (_Rank)

	EXEC dbo.usp_sys_DefaultTable '#K_CtTmpTH'

	UPDATE #K_CtTmpTH SET CashFlowName = ISNULL(b.Name,'') 
	FROM #K_CtTmpTH a LEFT OUTER JOIN dbo.B20CashFlow (NOLOCK) b ON a.CashFlowId=b.Id
	 
	UPDATE #K_CtTmpTH SET CashFlowName=N'Chưa xác định khoản mục dòng tiền'
	FROM #K_CtTmpTH WHERE ISNULL(CashFlowId,'')=''

	UPDATE #K_CtTmpTH SET AccountCal = N'111,112,113'
	FROM #K_CtTmpTH

	UPDATE #K_CtTmpTH SET _LinkCommand = N'REP09_BKCT DocDate1=''{=DocDate}'';DocDate2=''{=DocDate}'';Account=''{=@_Account}'';CashFlowId=''{=CashFlowId}'';BranchCode=''{=BranchCode}'';'
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
		DocBookingId, CAST('' AS NVARCHAR(24)) AS DocBookingNo, CAST(NULL AS DATETIME) AS DocBookingDate, BranchCode, CashFlowId ,
		CashFlowCode,CashFlowName,		
		BranchCode AS BranchCodeSort,MesGroupCode , CAST(N'' AS NVARCHAR(256)) AS MesGroupInfo
	INTO #K_CtTmp
	FROM #K_CtTmp0
 
	UPDATE t SET MesGroupInfo = CONCAT(cl.Code,' : ', cl.Name)
	FROM #K_CtTmp t INNER JOIN B20Class cl  (NOLOCK) ON t.MesGroupCode=cl.Code and cl.ParentCode = 'MesGroupCode'
 
	CREATE CLUSTERED INDEX IX_Rank_K_CtTmp ON #K_CtTmp (_Rank)

	EXEC dbo.usp_sys_DefaultTable '#K_CtTmp'

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
			SUM(DebitBalance), SUM(CreditBalance), SUM(OriginalDebitBalance), SUM(OriginalCreditBalance), N'0', 'BOLD', '111,112,113', NULL
	FROM #K_CtTmpTH
	WHERE _Status=1

	INSERT #K_CtTmpTH (Id, Account, DocDate, Description, DebitAmount, CreditAmount, OriginalDebitAmount, OriginalCreditAmount, _Status, _FormatStyleKey, AccountCal, BranchCode,DocNumber)
	SELECT 	NULL, NULL, NULL, N'TỔNG CỘNG', 
			SUM(DebitAmount), SUM(CreditAmount), SUM(OriginalDebitAmount), SUM(OriginalCreditAmount), N'4', 'BOLD', '111,112,113', NULL, SUM(DocNumber)
	FROM #K_CtTmpTH
	WHERE _Status=2

	INSERT #K_CtTmpTH (Id, Account, DocDate, Description, DebitBalance, CreditBalance, OriginalDebitBalance, OriginalCreditBalance, _Status, _FormatStyleKey, AccountCal, BranchCode)
	SELECT 	NULL, NULL, NULL, N'SỐ DƯ CUỐI KỲ', 
			SUM(DebitBalance), SUM(CreditBalance), SUM(OriginalDebitBalance), SUM(OriginalCreditBalance), N'9', 'BOLD', '111,112,113', NULL
	FROM #K_CtTmpTH
	WHERE _Status=8

	---Update 4 cột tiền mặt/ chuyển khoản
	UPDATE #K_CtTmpTH SET DebitAmount111=ISNULL(ct.DebitAmount,0), CreditAmount111=ISNULL(ct.CreditAmount,0), DocNumber111=ISNULL(ct.DocNumber,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT CashFlowId, DocDate, BranchCode, SUM(DebitAmount) AS DebitAmount, SUM(CreditAmount) AS CreditAmount, SUM(DocNumber) AS DocNumber FROM #K_CtTmp0 
		WHERE Account='111' GROUP BY CashFlowId, DocDate, BranchCode) AS ct ON ct.CashFlowId=a.CashFlowId AND ct.DocDate=a.DocDate AND ct.BranchCode=a.BranchCode

	UPDATE #K_CtTmpTH SET DebitAmount112=ISNULL(ct.DebitAmount,0), CreditAmount112=ISNULL(ct.CreditAmount,0), DocNumber112=ISNULL(ct.DocNumber,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT CashFlowId, DocDate, BranchCode, SUM(DebitAmount) AS DebitAmount, SUM(CreditAmount) AS CreditAmount, SUM(DocNumber) AS DocNumber FROM #K_CtTmp0 
		WHERE Account='112' GROUP BY CashFlowId, DocDate, BranchCode) AS ct ON ct.CashFlowId=a.CashFlowId AND ct.DocDate=a.DocDate AND ct.BranchCode=a.BranchCode
	
	UPDATE #K_CtTmpTH SET DebitAmount113=ISNULL(ct.DebitAmount,0), CreditAmount113=ISNULL(ct.CreditAmount,0), DocNumber113=ISNULL(ct.DocNumber,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT CashFlowId, DocDate, BranchCode, SUM(DebitAmount) AS DebitAmount, SUM(CreditAmount) AS CreditAmount, SUM(DocNumber) AS DocNumber FROM #K_CtTmp0 
		WHERE Account='113' GROUP BY CashFlowId, DocDate, BranchCode) AS ct ON ct.CashFlowId=a.CashFlowId AND ct.DocDate=a.DocDate AND ct.BranchCode=a.BranchCode

	UPDATE #K_CtTmpTH SET DebitBalance111=ISNULL(ct.DebitBal1,0), CreditBalance111=ISNULL(ct.CreditBal1,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT BranchCode, SUM(DebitBal1) AS DebitBal1, SUM(CreditBal1) AS CreditBal1 FROM #SoDuDau 
		WHERE Account='111' GROUP BY BranchCode) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=1

	UPDATE #K_CtTmpTH SET DebitBalance112=ISNULL(ct.DebitBal1,0), CreditBalance112=ISNULL(ct.CreditBal1,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (SELECT BranchCode, SUM(DebitBal1) AS DebitBal1, SUM(CreditBal1) AS CreditBal1 FROM #SoDuDau 
		WHERE Account='112' GROUP BY BranchCode) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=1

	UPDATE  #K_CtTmpTH
		SET DebitBalance113  = ISNULL(ct.DebitBal1, 0),
			CreditBalance113 = ISNULL(ct.CreditBal1, 0)
	FROM    #K_CtTmpTH AS a
			LEFT OUTER JOIN
			(SELECT   BranchCode,
					  SUM(DebitBal1) AS DebitBal1,
					  SUM(CreditBal1) AS CreditBal1
			 FROM     #SoDuDau
			 WHERE    Account = '113'
			 GROUP BY BranchCode) AS ct
			ON ct.BranchCode = a.BranchCode
	WHERE   a._Status = 1

	UPDATE #K_CtTmpTH SET DebitBalance111=(SELECT SUM(DebitBalance111) FROM #K_CtTmpTH WHERE _Status=1), 
	                      CreditBalance111=(SELECT SUM(CreditBalance111) FROM #K_CtTmpTH WHERE _Status=1)
		FROM #K_CtTmpTH a
		WHERE a._Status=0

   UPDATE #K_CtTmpTH SET DebitBalance112=(SELECT SUM(DebitBalance112) FROM #K_CtTmpTH WHERE _Status=1), 
	                      CreditBalance112=(SELECT SUM(CreditBalance112) FROM #K_CtTmpTH WHERE _Status=1)
		FROM #K_CtTmpTH a
		WHERE a._Status=0

	UPDATE #K_CtTmpTH SET DebitBalance113=(SELECT SUM(DebitBalance113) FROM #K_CtTmpTH WHERE _Status=1), 
	                      CreditBalance113=(SELECT SUM(CreditBalance113) FROM #K_CtTmpTH WHERE _Status=1)
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

	UPDATE #K_CtTmpTH SET DebitAmount113=ISNULL(ct.DebitAmount113,0), CreditAmount113=ISNULL(ct.CreditAmount113,0), DocNumber113=ISNULL(ct.DocNumber113,0)
	FROM #K_CtTmpTH a LEFT OUTER JOIN (
	SELECT BranchCode, SUM(DebitAmount113) AS DebitAmount113, SUM(CreditAmount113) AS CreditAmount113, SUM(DocNumber113) AS DocNumber113 FROM #K_CtTmpTH WHERE _Status=3 GROUP BY BranchCode
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

	UPDATE #K_CtTmpTH SET DebitAmount113=(SELECT SUM(DebitAmount113) FROM #K_CtTmpTH WHERE _Status=2), 
                      CreditAmount113=(SELECT SUM(CreditAmount113) FROM #K_CtTmpTH WHERE _Status=2),
					  DocNumber113=(SELECT SUM(DocNumber113) FROM #K_CtTmpTH WHERE _Status=2)
	FROM #K_CtTmpTH a
	WHERE a._Status=4

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
						  CreditAmount112=IIF(CreditBalance112 > DebitBalance112,CreditBalance112 - DebitBalance112,0),
						    DebitAmount113=IIF(DebitBalance113 > CreditBalance113,DebitBalance113-CreditBalance113,0),
						  CreditAmount113=IIF(CreditBalance113 > DebitBalance113,CreditBalance113 - DebitBalance113,0)
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
	
	UPDATE #K_CtTmpTH SET DebitBalance113=ISNULL(ct.DebitAmount113,0), CreditBalance113=ISNULL(ct.CreditAmount113,0)
		FROM #K_CtTmpTH a LEFT OUTER JOIN (
		SELECT BranchCode, SUM(DebitAmount113) AS DebitAmount113, SUM(CreditAmount113) AS CreditAmount113 FROM #K_CtTmpTH WHERE _Status IN (1,2) GROUP BY BranchCode
		) AS ct ON ct.BranchCode=a.BranchCode
		WHERE a._Status=8

	UPDATE #K_CtTmpTH SET DebitAmount=IIF(DebitBalance > CreditBalance,DebitBalance-CreditBalance,0), 
	                      CreditAmount=IIF(CreditBalance > DebitBalance,CreditBalance - DebitBalance,0),
						  DebitAmount111=IIF(DebitBalance111 > CreditBalance111,DebitBalance111-CreditBalance111,0),
						  CreditAmount111=IIF(CreditBalance111 > DebitBalance111,CreditBalance111 - DebitBalance111,0),
						  DebitAmount112=IIF(DebitBalance112 > CreditBalance112,DebitBalance112-CreditBalance112,0),
						  CreditAmount112=IIF(CreditBalance112 > DebitBalance112,CreditBalance112 - DebitBalance112,0),	
						  DebitAmount113=IIF(DebitBalance113 > CreditBalance113,DebitBalance113-CreditBalance113,0),
						  CreditAmount113=IIF(CreditBalance113 > DebitBalance113,CreditBalance113 - DebitBalance113,0)
	FROM #K_CtTmpTH WHERE _Status IN (8)

	
	UPDATE #K_CtTmpTH SET DebitBalance111=(SELECT SUM(DebitAmount111) FROM #K_CtTmpTH WHERE _Status=8),
	                      CreditBalance111=(SELECT SUM(CreditAmount111) FROM #K_CtTmpTH WHERE _Status=8)
	FROM #K_CtTmpTH a
	WHERE _Status=9

	UPDATE #K_CtTmpTH SET DebitBalance112=(SELECT SUM(DebitAmount112) FROM #K_CtTmpTH WHERE _Status=8),
	                      CreditBalance112=(SELECT SUM(CreditAmount112) FROM #K_CtTmpTH WHERE _Status=8)
	FROM #K_CtTmpTH a
	WHERE _Status=9

	UPDATE #K_CtTmpTH SET DebitBalance113=(SELECT SUM(DebitAmount113) FROM #K_CtTmpTH WHERE _Status=8),
	                      CreditBalance113=(SELECT SUM(CreditAmount113) FROM #K_CtTmpTH WHERE _Status=8)
	FROM #K_CtTmpTH a
	WHERE _Status=9

	UPDATE #K_CtTmpTH SET DebitAmount=IIF(DebitBalance > CreditBalance,DebitBalance-CreditBalance,0), 
	                      CreditAmount=IIF(CreditBalance > DebitBalance,CreditBalance - DebitBalance,0),
						  DebitAmount111=IIF(DebitBalance111 > CreditBalance111,DebitBalance111-CreditBalance111,0),
						  CreditAmount111=IIF(CreditBalance111 > DebitBalance111,CreditBalance111 - DebitBalance111,0),
						  DebitAmount112=IIF(DebitBalance112 > CreditBalance112,DebitBalance112-CreditBalance112,0),
						  CreditAmount112=IIF(CreditBalance112 > DebitBalance112,CreditBalance112 - DebitBalance112,0),
						  DebitAmount113=IIF(DebitBalance113 > CreditBalance113,DebitBalance113-CreditBalance113,0),
						  CreditAmount113=IIF(CreditBalance113 > DebitBalance113,CreditBalance113 - DebitBalance113,0)
	FROM #K_CtTmpTH WHERE _Status IN (9)

	--duydnp xử lý tiền 112 ko theo SR
	UPDATE #K_CtTmpTH SET
	DebitAmount = 0, CreditAmount = 0, 
	OriginalDebitAmount = 0, OriginalCreditAmount = 0, 
	DebitAmount112 = 0, CreditAmount112 = 0,DebitAmount113 = 0, CreditAmount113 = 0	
	WHERE _Status IN (1,8) AND BranchCode <> ''
	    	
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
				SELECT cteDetail.AccountCal, cteDetail.CustomerId, cteDetail.ProductId,
					SUM(cteDetail.DebitBal1) AS DebitBal1, SUM(cteDetail.CreditBal1) AS CreditBal1, SUM(cteDetail.OriginalDebitBal1) AS OriginalDebitBal1, SUM(cteDetail.OriginalCreditBal1) AS OriginalCreditBal1, cteDetail.BranchCode
				FROM cteDetail
				GROUP BY cteDetail.AccountCal, cteDetail.CustomerId, cteDetail.ProductId, cteDetail.BranchCode
			), cteResult (AccountCal, CustomerId, ProductId, DebitBal2, CreditBal2, OriginalDebitBal2, OriginalCreditBal2, BranchCode) AS
			(
				SELECT cteSum.AccountCal, cteSum.CustomerId, cteSum.ProductId,
					IIF(cteSum.DebitBal1 > cteSum.CreditBal1, cteSum.DebitBal1 - cteSum.CreditBal1, 0) AS DebitBal2,
					IIF(cteSum.CreditBal1 > cteSum.DebitBal1, cteSum.CreditBal1 - cteSum.DebitBal1, 0) AS CreditBal2,
					IIF(cteSum.OriginalDebitBal1 > cteSum.OriginalCreditBal1, cteSum.OriginalDebitBal1 - cteSum.OriginalCreditBal1, 0) AS OriginalDebitBal2,
					IIF(cteSum.OriginalCreditBal1 > cteSum.OriginalDebitBal1, cteSum.OriginalCreditBal1 - cteSum.OriginalDebitBal1, 0) AS OriginalCreditBal2, cteSum.BranchCode
				FROM cteSum
			)
			SELECT	@_DebitBalance2 = SUM(cteResult.DebitBal2), @_CreditBalance2 = SUM(cteResult.CreditBal2),
					@_OriginalDebitBalance2 = SUM(cteResult.OriginalDebitBal2), @_OriginalCreditBalance2 = SUM(cteResult.OriginalCreditBal2)
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
		LEFT OUTER JOIN dbo.B20ChartOfAccount AS dm ON bc.AccountCal = dm.Code
		LEFT OUTER JOIN dbo.B20DmsRoute route ON route.Code=bc.BranchCode
	WHERE bc.AccountCal LIKE '111%'

	UPDATE #K_CtTmp 
	SET GroupCode = bc.AccountCal + N' - Tổng công ty',
		GroupName = RTRIM(bc.AccountCal) + N': ' +
			ISNULL(dbo.ufn_sys_BH(ISNULL(dm.Name, ''), ISNULL(dm.Name_English, ''), '', ISNULL(dm.Name_Japanese, ''), ISNULL(dm.Name_Chinese, ''), ISNULL(dm.Name_Korean, ''), @_LangId), '') + N' - Tổng công ty'
	FROM #K_CtTmp AS bc
		LEFT OUTER JOIN dbo.B20ChartOfAccount AS dm ON bc.AccountCal = dm.Code
	WHERE bc.AccountCal LIKE '112%' OR bc.AccountCal LIKE '113%'

	UPDATE #K_CtTmp SET _FormatStyleKey =  IIF(ISNULL(CashFlowCode,'') = '','RedColor',_FormatStyleKey)
	WHERE _FormatStyleKey = ''

	SELECT * 
	FROM #K_CtTmp
	ORDER BY AccountCal,BranchCode,_Status,_Rank

	DELETE #K_CtTmpTH WHERE _Status IN (0) AND ISNULL(_StatusTH,0) = 0

	DELETE #K_CtTmpTH WHERE _Status IN (8) AND ISNULL(_StatusTH,0) = 8
	
	--xóa dòng Tổng số phát sinh 
	DELETE #K_CtTmpTH WHERE _StatusTH IN (5) AND ISNULL(_Status ,0) = 2
 
	DELETE #K_CtTmpTH WHERE DebitAmount = 0 AND  CreditAmount = 0 AND  DocNumber = 0 

	UPDATE  #K_CtTmpTH
    SET _FormatStyleKey = IIF ((CashFlowId = ''), 'RedColor', _FormatStyleKey)
	WHERE   _FormatStyleKey = '';

	SELECT *
	FROM #K_CtTmpTH 
	ORDER BY AccountCal,_StatusTH,BranchCode,_Status,DocDate,_Rank

	BEGIN
    DROP TABLE IF EXISTS #K_BcTmp;
    SELECT *,
           CAST ('' AS NVARCHAR (MAX)) AS CashFlowCode,
           CAST ('' AS NVARCHAR (MAX)) AS CashFlowId_List
    INTO   #K_BcTmp
    FROM   B10KqtCashFlowPlan
    WHERE  SourceTable = 'B10KqtCashFlowPlan'
           AND KqtCashFlowPlanId = 'T000000003';
    
	;WITH cte
    AS   (SELECT dbo.ufn_Get_List_CatgDetail(ca.value, 'B20CashFlow', 'Code') AS CashFlowCode,
                 dbo.ufn_Get_List_CatgDetail(ca.value, 'B20CashFlow', 'Id') AS CashFlowId,
                 tmp.Id
          FROM   #K_BcTmp AS tmp CROSS APPLY (SELECT value
                                              FROM   STRING_SPLIT (CashFlowId, ',')) AS ca
          WHERE  ISNULL(tmp.CashFlowId, '') <> ''),
         cte1
    AS   (SELECT   STRING_AGG(cte.CashFlowCode, ',') AS List_CatgDetailCode,
                   STRING_AGG(cte.CashFlowId, ',') AS List_CashFlowId,
                   cte.Id
          FROM     cte
          WHERE    cte.CashFlowCode <> ''
          GROUP BY cte.Id)
    UPDATE  #K_BcTmp
        SET CashFlowCode    = ISNULL(IIF (c1.List_CatgDetailCode <> '', c1.List_CatgDetailCode, ''), ''),
            CashFlowId_List = ISNULL(IIF (c1.List_CashFlowId <> '', c1.List_CashFlowId, ''), ''),
            VarValue        = isnull(VarValue, '')
    FROM    #K_BcTmp AS tmp2
            LEFT OUTER JOIN
            cte1 AS c1
            ON tmp2.Id = c1.Id;

    UPDATE  #K_BcTmp
        SET CashFlowId_List = CashFlowId
    WHERE   ItemLevel = 9
            AND CashFlowId_List = ''
            AND CashFlowId <> '';
    
;WITH     cte2
AS       (SELECT DISTINCT Id,
                          cav.value AS MESGroupCode,
                          ca.value AS CashFlowId
          FROM   #K_BcTmp CROSS APPLY (SELECT value
                                       FROM   STRING_SPLIT (CashFlowId_List, ',')) AS ca CROSS APPLY (SELECT value
                                                                                                      FROM   STRING_SPLIT (VarValue, ',')) AS cav
          WHERE  Loai_Ps = 'PS_NO'
                 AND cav.value <> ''
                 AND ca.value <> '')
SELECT   *
FROM     #K_CtTmp0
WHERE    CashFlowId NOT IN (SELECT CashFlowId
                            FROM   cte2)
         --AND    EXISTS (SELECT *
         --            FROM   cte2 AS bc
         --            WHERE  charindex((',' + MESGroupCode + ','), (',' + bc.MESGroupCode + ',')) = 0)
         AND EntryNo = 'A'
         AND CashFlowId <> ''
ORDER BY DocDate ASC,Stt,RowId;
    
	;WITH     cte2
AS       (SELECT DISTINCT Id,
                          cav.value AS MESGroupCode,
                          ca.value AS CashFlowId
          FROM   #K_BcTmp CROSS APPLY (SELECT value
                                       FROM   STRING_SPLIT (CashFlowId_List, ',')) AS ca CROSS APPLY (SELECT value
                                                                                                      FROM   STRING_SPLIT (VarValue, ',')) AS cav
          WHERE  Loai_Ps = 'PS_CO'
                 AND cav.value <> ''
                 AND ca.value <> '')
SELECT   *
FROM     #K_CtTmp0
WHERE    CashFlowId NOT IN (SELECT CashFlowId
                            FROM   cte2)
         --AND    EXISTS (SELECT *
         --            FROM   cte2 AS bc
         --            WHERE  charindex((',' + MESGroupCode + ','), (',' + bc.MESGroupCode + ',')) = 0)
         AND EntryNo = 'B'
         AND CashFlowId <> ''
ORDER BY DocDate ASC,Stt,RowId;

SELECT DISTINCT Id,Loai_Ps,
                          ca.value AS CashFlowId,
                          cav.value AS MESGroupCode
          FROM   #K_BcTmp CROSS APPLY (SELECT value
                                       FROM   STRING_SPLIT (CashFlowId_List, ',')) AS ca 
							CROSS APPLY (SELECT value FROM   STRING_SPLIT (VarValue, ',')) AS cav
          WHERE    cav.value <> ''
                 AND ca.value <> '' order by Loai_Ps,Id

END
 
	DROP TABLE #K_CtTmp0
	DROP TABLE #K_CtTmp
	DROP TABLE #DsAccountTemp
	DROP TABLE #DsAccountTempTH
	DROP TABLE #K_BcTmp	
END
GO
declare @p1 date
set @p1='2026-06-01'
declare @p2 date
set @p2='2026-06-30'
declare @p13 varchar(max)
set @p13=''
exec usp_Kct_SubsidiaryLedger_DTTC @_DocDate1=@p1 output,@_DocDate2=@p2 output,
@_Account='111,112,113',@_CashFlowId=default,@_AccountLevel=1,
@_ForeignCurrencyOnly=0,@_nUserId=1213,@_LangId=0,@_CurrencyCode0='VND',
@_BranchCode='I23',@_MonthString=default,@_Loai_Ps=default,@_No_Co=@p13 output,
@_MESGroupCode_List=default,@_Key_Other=default 