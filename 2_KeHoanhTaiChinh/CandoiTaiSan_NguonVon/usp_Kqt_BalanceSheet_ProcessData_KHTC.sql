SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================
--KHTC

-- ===============================================
CREATE OR ALTER PROCEDURE [dbo].usp_Kqt_BalanceSheet_ProcessData_KHTC 
	@_DocDate1 DATE = 'Jan 01 2023',
	@_DocDate2 DATE = 'Jan 31 2023', 
	@_FirstDayOfYear DATE = 'Jan 01 2023',
	@_tblTKTStmp NVARCHAR(32) = '#Kqt01',
	@_ForeignCurrencyOnly INT = 1,
	@_nUserId INT = 0,
	@_LangId INT = 0,
	@_BranchCode VARCHAR(3) = 'A01',
	@_CurrencyCode0 CHAR(3) = 'VND',
	@_Kd_Cp_Tam CHAR(1) = 'K',
	@_IssuedByNo NVARCHAR(32) = '',				-- 02/2015 ThắngĐQ: Sửa riêng TT200/2014/TT-BTC
	@_ResetFormula TINYINT = NULL,
	@_AdjustClosingBal TINYINT = 1,			-- 1: Mặc định cộng thêm giá trị điều chỉnh phân loại lại số dư (Ngắn hạn / Dài hạn)
	@_GetIsOutsideAccount TINYINT = 0,		-- 1: Báo cáo chủ đầu tư mẫu cũ nên còn khai báo này
	@_ExchangeRateConvReport TINYINT = 0,	-- 1: Báo cáo chuyển đổi sang đồng tiền VNĐ
	@_VNDRound INT = 0,
	@_ColName  NVARCHAR(24) = ''--13-05-2026 TINNT them cot cap nhat du lieu
AS
BEGIN
	SET NOCOUNT ON;
	  
	SET @_BranchCode = RTRIM(@_BranchCode);
	SET @_ExchangeRateConvReport = ISNULL(@_ExchangeRateConvReport, 0);

	DECLARE @_KeyCd NVARCHAR(MAX) = N'', @_Key1 NVARCHAR(MAX) = N'', @_KqtAccountList NVARCHAR(MAX),
		@_IsGetOpen SMALLINT, @_strExec NVARCHAR(MAX), @_DocDate01 DATE, @_DocDate02 DATE,
		@_StartDate DATE = dbo.ufn_B00FiscalYear_GetStartDate(@_DocDate2, @_BranchCode)

	-- Xử lý số đầu kỳ luôn là đầu năm, phát sinh của cột đầu kỳ sẽ là số phát sinh của cả năm trước, Từ ngày - Đến ngày chỉ ảnh hưởng tới phát sinh của Số cuối kỳ này
	SET @_DocDate02 = DATEADD(dd, -1, @_StartDate)
	SET @_DocDate01 = dbo.ufn_B00FiscalYear_GetStartDate(@_DocDate02, @_BranchCode)


	--ALTER TABLE #CdTmp ADD  MESGroupCode VARCHAR(24) DEFAULT ''
	-- Tao bang CdTmp1: Phuc vu chi tiet cong no
	DROP TABLE IF EXISTS #CdTmp1
	SELECT TOP (0) Account,   BranchCode, CustomerId,CAST('' AS VARCHAR(24)) AS MESGroupCode,
		Amount AS DebitBal00, Amount AS CreditBal00, -- Số đầu năm kỳ trước
		Amount AS DebitBal01, Amount AS CreditBal01, -- Số đầu kỳ kỳ trước
		Amount AS DebitBal02, Amount AS CreditBal02, -- Số cuối kỳ kỳ trước
		Amount AS DebitBal0, Amount AS CreditBal0, -- Số đầu năm kỳ này
		Amount AS DebitBal1, Amount AS CreditBal1, -- Số đầu kỳ kỳ này
		Amount AS DebitBal2, Amount AS CreditBal2 -- Số cuối kỳ kỳ này
	INTO #CdTmp1
	FROM dbo.B00CtTmp

	EXECUTE dbo.usp_sys_DefaultTable '#CdTmp1'

	-- Tao bang CdTmp: Lay so lieu dau nam theo tai khoan
	DROP TABLE IF EXISTS #CdTmp
	SELECT TOP 0 Account, CustomerId,CAST('' AS VARCHAR(24) )  AS MESGroupCode,
		DebitBal00, CreditBal00, DebitBal01, CreditBal01,
		DebitBal02, CreditBal02, DebitBal0, CreditBal0, 
		DebitBal1, CreditBal1, DebitBal2, CreditBal2
	INTO #CdTmp
	FROM #CdTmp1
	EXECUTE dbo.usp_sys_DefaultTable '#CdTmp'

	CREATE INDEX Account ON #CdTmp (Account)

	-- Lấy số dư cuối kỳ này
	DROP TABLE IF EXISTS #CloseBalance1
	SELECT TOP 0 Account,  BranchCode, Amount AS DebitBal1, Amount AS CreditBal1, 
		DebitAmount, CreditAmount, Amount AS DebitBal2, Amount AS CreditBal2,CustomerId
	INTO #CloseBalance1
	FROM dbo.B00CtTmp
		
	-- Lấy số dư cuối kỳ trước
	DROP TABLE IF EXISTS #CloseBalance0
	SELECT TOP 0 *
	INTO #CloseBalance0
	FROM #CloseBalance1
		
	-- Lấy số dư đầu kỳ trước
	DROP TABLE IF EXISTS #OpenBalance0
	SELECT TOP 0
		   Account
		  ,DocDate 
		  ,BranchCode
		  ,CustomerId
		  ,Amount AS DebitBal0
		  ,Amount AS CreditBal0
		  ,Amount AS DebitBal1
		  ,Amount AS CreditBal1
	INTO #OpenBalance0
	FROM dbo.B00CtTmp
		
	-- Lấy số dư đầu kỳ này
	DROP TABLE IF EXISTS #OpenBalance1
	SELECT TOP 0 *
	INTO #OpenBalance1
	FROM #OpenBalance0

	EXEC dbo.usp_sys_DefaultTable @_Table = '#CloseBalance1'
	EXEC dbo.usp_sys_DefaultTable @_Table = '#CloseBalance0'
	EXEC dbo.usp_sys_DefaultTable @_Table = '#OpenBalance0'
	EXEC dbo.usp_sys_DefaultTable @_Table = '#OpenBalance1'
	
	-- Tạo bảng dữ liệu ghi nhận chuyển đổi 
	IF @_ExchangeRateConvReport = 1
	BEGIN
		DROP TABLE IF EXISTS #ExchangeRateConv_CtTmp;
		SELECT TOP 0 CAST(0 AS TINYINT) IsOpenning,
			DocDate, Account,  
			DebitAmount, CreditAmount, 
			DebitAmount VNDDebitAmount, CreditAmount VNDCreditAmount, 
			CAST('' AS VARCHAR(24)) ExchangeRateConvId,
			CAST(0 AS NUMERIC(20, 6)) ExchangeRate
		INTO #ExchangeRateConv_CtTmp
		FROM dbo.B00CtTmp
	END
		
	-- Phát sinh kỳ này
	DROP TABLE IF EXISTS #K_CtTmp1
	SELECT TOP 0 DocDate,  BranchCode, Account, CrspAccount, DebitAmount, CreditAmount, Stt,CustomerId
	INTO #K_CtTmp1
	FROM dbo.B00CtTmp
		
	-- Phát sinh kỳ trước
	DROP TABLE IF EXISTS #K_CtTmp0
	SELECT TOP 0 *
	INTO #K_CtTmp0
	FROM #K_CtTmp1

	-- Group theo đơn vị cơ sở
	DECLARE @_GroupByBranchCode TINYINT = ISNULL(dbo.ufn_vB00Config_GetValue('M_GroupByBranchCode', @_BranchCode), 0), -- 1: Group theo đơn vị cơ sở, 0-Không group
		@_GroupByColumnList NVARCHAR(128) = 'Account,CustomerId'

	IF @_GroupByBranchCode = 1
		SET @_GroupByColumnList = 'Account,BranchCode,CustomerId'
	
	-- Lấy số dư đầu kỳ kỳ này
	EXECUTE dbo.usp_B30OpenBalance_GetData
		@_DocDate0 = @_DocDate1, 
		@_Key = @_KeyCd, 
		@_CtTmp = N'#OpenBalance1',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode, 
		@_CurrencyCode0 = @_CurrencyCode0,
		@_Opening = 1,			
		@_Accumulate = 0,
		@_AutoCalculate = 1,
		@_GroupByColumnList = @_GroupByColumnList,
		@_GroupByBranchCode = @_GroupByBranchCode

		--SELECT * FROM #OpenBalance1 RETURN 
  
	IF @_StartDate <> @_FirstDayOfYear
		UPDATE #OpenBalance1 SET DebitBal0 = DebitBal1, CreditBal0 = CreditBal1

 	-- Lay So phat sinh trong kỳ này
	EXECUTE dbo.usp_B30GeneralLedger_GetData_YTD
		@_DocDate1 = @_DocDate1,
		@_DocDate2 = @_DocDate2,
		@_Key1 = @_Key1,
		@_Key2 = '',
		@_CtTmp = N'#K_CtTmp1',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_Field_GroupBy = @_GroupByColumnList,
		@_Field_Sum = N'DebitAmount,CreditAmount'
 
	-- Lấy số dư đầu kỳ kỳ trước
	IF @_tblTKTStmp <>''
	BEGIN 
	SET @_strExec = 'SELECT @_KeyCd = STRING_AGG(''Account LIKE '''''' + Account + ''%'''''', '' OR '')
		FROM ' + @_tblTKTStmp + '
		WHERE DataType = ''DU_DAU'''
	EXECUTE sys.sp_executesql @_strExec, N'@_KeyCd NVARCHAR(MAX) OUTPUT', @_KeyCd = @_KeyCd OUTPUT
	END 
 
	EXECUTE dbo.usp_B30OpenBalance_GetData	
				@_DocDate0 = @_DocDate01, 
				@_Key = @_KeyCd, 
				@_CtTmp = N'#OpenBalance0',
				@_nUserId = @_nUserId,
				@_LangId = @_LangId,
				@_BranchCode = @_BranchCode, 
				@_CurrencyCode0 = @_CurrencyCode0,
				@_Opening = 1,			
				@_Accumulate = 0,
				@_AutoCalculate = 1,
				@_GroupByColumnList = @_GroupByColumnList,
				@_GroupByBranchCode = @_GroupByBranchCode
 
	-- Xử lý riêng với năm đầu tiên sử dụng chương trình, các dòng khai báo lấy số dư đầu kỳ, với cột Kỳ trước sẽ cần lấy thêm Số dư đầu năm trước ở Số dư đầu kỳ tài khoản
	IF YEAR(@_DocDate2) = YEAR(dbo.ufn_B00FiscalYear_GetStartedUsingDate(@_BranchCode))
		INSERT INTO #OpenBalance0 (
			Account, BranchCode, DebitBal0, CreditBal0, DebitBal1, CreditBal1
		)
		SELECT Account, BranchCode, DebitYearBal0, CreditYearBal0, 0, 0
		FROM dbo.B30OpenBalance
		WHERE IsActive = 1 AND Year = FORMAT(YEAR(@_DocDate2), '') AND (DebitYearBal0 <> 0 OR CreditYearBal0 <> 0)
			AND BranchCode IN (SELECT BranchCode FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode))	

	IF ISNULL(@_tblTKTStmp ,'')<>''
	BEGIN
 	-- Lấy số phát sinh trong kỳ trước
	SET @_strExec = 'SELECT @_Key1 = STRING_AGG(''Account LIKE '''''' + Account + ''%'''''', '' OR '')
		FROM ' + @_tblTKTStmp + '
		WHERE DataType LIKE ''PS%'''
	EXECUTE sys.sp_executesql @_strExec, N'@_Key1 NVARCHAR(MAX) OUTPUT', @_Key1 = @_Key1 OUTPUT
	END 
 
  	EXECUTE dbo.usp_B30GeneralLedger_GetData_YTD
		@_DocDate1 = @_DocDate01,
		@_DocDate2 = @_DocDate02,
		@_Key1 = @_Key1,
		@_Key2 = '',
		@_CtTmp = N'#K_CtTmp0',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_Field_GroupBy = @_GroupByColumnList,
		@_Field_Sum = N'DebitAmount,CreditAmount'
		 
	--SELECT * FROM #K_CtTmp0 RETURN 


	-- Xử lý riêng với năm đầu tiên sử dụng chương trình, các dòng khai báo lấy số dư đầu kỳ, 
	-- với cột Kỳ trước sẽ cần lấy thêm Số dư đầu năm trước, Phát sinh năm trước ở Số dư đầu kỳ tài khoản
	IF YEAR(@_DocDate2) = YEAR(dbo.ufn_B00FiscalYear_GetStartedUsingDate(@_BranchCode))
		INSERT INTO #K_CtTmp0 (
			Account,  BranchCode, DebitAmount, CreditAmount
		)
		SELECT Account, BranchCode, DebitAmount0, CreditAmount0
		FROM dbo.B30OpenBalance
		WHERE IsActive = 1 AND Year = FORMAT(YEAR(@_DocDate2), '') AND (DebitAmount0 <> 0 OR CreditAmount0 <> 0)
			AND BranchCode IN (SELECT BranchCode FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode))
		
	IF @_GroupByBranchCode = 0
	BEGIN
		UPDATE #OpenBalance0 SET BranchCode = ''
		UPDATE #OpenBalance1 SET BranchCode = ''
		UPDATE #K_CtTmp1 SET BranchCode = ''
		UPDATE #K_CtTmp0 SET BranchCode = ''
	END

	 
	--Lấy số dư cuối kỳ này
	INSERT INTO #CloseBalance1 (Account,  BranchCode, DebitBal1, CreditBal1, DebitAmount, CreditAmount,CustomerId)
	SELECT tmp.Account, tmp.BranchCode, SUM(tmp.DebitBal1), SUM(tmp.CreditBal1), SUM(tmp.DebitAmount), SUM(tmp.CreditAmount),CustomerId
	FROM (
			SELECT Account, BranchCode, DebitBal1, CreditBal1, CAST(0 AS NUMERIC(18, 2)) AS DebitAmount, CAST(0 AS NUMERIC(18, 2)) AS CreditAmount,CustomerId
			FROM #OpenBalance1
			UNION ALL
			SELECT Account,   BranchCode, 0 AS DebitBal1, 0 AS CreditBal1, DebitAmount, CreditAmount,CustomerId
			FROM #K_CtTmp1
		) tmp
	GROUP BY tmp.Account,   tmp.BranchCode,CustomerId
 
	UPDATE #CloseBalance1 
	SET DebitBal2 = CASE WHEN (DebitBal1 - CreditBal1 + DebitAmount - CreditAmount >= 0) THEN DebitBal1 - CreditBal1 + DebitAmount - CreditAmount ELSE 0 END,
		CreditBal2 = CASE WHEN (DebitBal1 - CreditBal1 + DebitAmount - CreditAmount < 0) THEN -1*(DebitBal1 - CreditBal1 + DebitAmount - CreditAmount) ELSE 0 END
 
	--Lấy số dư cuối kỳ trước
	INSERT INTO #CloseBalance0 (
		Account,  BranchCode, DebitBal1, CreditBal1, DebitAmount, CreditAmount,CustomerId
	)
	SELECT tmp.Account,   tmp.BranchCode, SUM(tmp.DebitBal1), SUM(tmp.CreditBal1), SUM(tmp.DebitAmount), SUM(tmp.CreditAmount),tmp.CustomerId
	FROM (
			SELECT Account,   BranchCode, DebitBal1, CreditBal1, CAST(0 AS NUMERIC(18, 2)) AS DebitAmount, CAST(0 AS NUMERIC(18, 2)) AS CreditAmount,CustomerId
			FROM #OpenBalance0
			UNION ALL
			SELECT Account,   BranchCode, 0 AS DebitBal1, 0 AS CreditBal1, DebitAmount, CreditAmount,CustomerId
			FROM #K_CtTmp0
		) tmp
	GROUP BY tmp.Account,  tmp.BranchCode,tmp.CustomerId

	--SELECT * FROM #CloseBalance0 RETURN 

	UPDATE #CloseBalance0 
	SET DebitBal2 = CASE WHEN (DebitBal1 - CreditBal1 + DebitAmount - CreditAmount >= 0) THEN DebitBal1 - CreditBal1 + DebitAmount - CreditAmount ELSE 0 END,
		CreditBal2 = CASE WHEN (DebitBal1 - CreditBal1 + DebitAmount - CreditAmount < 0) THEN -1*(DebitBal1 - CreditBal1 + DebitAmount - CreditAmount) ELSE 0 END
 
	DECLARE @_Cmd NVARCHAR(MAX)

	INSERT INTO #CdTmp1 (
		Account, BranchCode, 
		DebitBal00, CreditBal00, DebitBal01, CreditBal01, DebitBal02, CreditBal02, 
		DebitBal0, CreditBal0, DebitBal1, CreditBal1, DebitBal2, CreditBal2,CustomerId)
	SELECT tmp.Account, tmp.BranchCode, 
		SUM(tmp.DebitBal00), SUM(tmp.CreditBal00), SUM(tmp.DebitBal01), SUM(tmp.CreditBal01), SUM(tmp.DebitBal02), SUM(tmp.CreditBal02),
		SUM(tmp.DebitBal0), SUM(tmp.CreditBal0), SUM(tmp.DebitBal1), SUM(tmp.CreditBal1), SUM(tmp.DebitBal2), SUM(tmp.CreditBal2),CustomerId
	FROM (
			SELECT Account,   BranchCode, 
				DebitBal0 AS DebitBal00, CreditBal0 AS CreditBal00, 
				DebitBal1 AS DebitBal01, CreditBal1 AS CreditBal01, 
				CAST(0 AS NUMERIC(18, 2)) AS DebitBal02, CAST(0 AS NUMERIC(18, 2)) AS CreditBal02, 
				CAST(0 AS NUMERIC(18, 2)) AS DebitBal0, CAST(0 AS NUMERIC(18, 2)) AS CreditBal0, 
				CAST(0 AS NUMERIC(18, 2)) AS DebitBal1, CAST(0 AS NUMERIC(18, 2)) AS CreditBal1, 
				CAST(0 AS NUMERIC(18, 2)) AS DebitBal2, CAST(0 AS NUMERIC(18, 2)) AS CreditBal2,CustomerId
			FROM #OpenBalance0
			UNION ALL
			SELECT Account,   BranchCode, 0, 0, 0, 0, DebitBal2, CreditBal2, 0, 0, 0, 0, 0, 0,CustomerId
			FROM #CloseBalance0
			UNION ALL
			SELECT Account,   BranchCode, 0, 0, 0, 0, 0, 0, DebitBal0, CreditBal0, DebitBal1, CreditBal1, 0, 0,CustomerId
			FROM #OpenBalance1
			UNION ALL
			SELECT Account,   BranchCode, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, DebitBal2, CreditBal2,CustomerId
			FROM #CloseBalance1
		) tmp
	GROUP BY tmp.Account,   tmp.BranchCode,CustomerId
 
	UPDATE #CdTmp1
	SET DebitBal00 = CASE WHEN DebitBal00 - CreditBal00 >= 0 THEN DebitBal00 - CreditBal00 ELSE 0 END,
		CreditBal00 = CASE WHEN DebitBal00 - CreditBal00 < 0 THEN CreditBal00 - DebitBal00 ELSE 0 END,
		DebitBal01 = CASE WHEN DebitBal01 - CreditBal01 >= 0 THEN DebitBal01 - CreditBal01 ELSE 0 END,
		CreditBal01 = CASE WHEN DebitBal01 - CreditBal01 < 0 THEN CreditBal01 - DebitBal01 ELSE 0 END,
		DebitBal02 = CASE WHEN DebitBal02 - CreditBal02 >= 0 THEN DebitBal02 - CreditBal02 ELSE 0 END,
		CreditBal02 = CASE WHEN DebitBal02 - CreditBal02 < 0 THEN CreditBal02 - DebitBal02 ELSE 0 END,
		DebitBal0 = CASE WHEN DebitBal0 - CreditBal0 >= 0 THEN DebitBal0 - CreditBal0 ELSE 0 END,
		CreditBal0 = CASE WHEN DebitBal0 - CreditBal0 < 0 THEN CreditBal0 - DebitBal0 ELSE 0 END,
		DebitBal1 = CASE WHEN DebitBal1 - CreditBal1 >= 0 THEN DebitBal1 - CreditBal1 ELSE 0 END,
		CreditBal1 = CASE WHEN DebitBal1 - CreditBal1 < 0 THEN CreditBal1 - DebitBal1 ELSE 0 END,
		DebitBal2 = CASE WHEN DebitBal2 - CreditBal2 >= 0 THEN DebitBal2 - CreditBal2 ELSE 0 END,
		CreditBal2 = CASE WHEN DebitBal2 - CreditBal2 < 0 THEN CreditBal2 - DebitBal2 ELSE 0 END
	
	INSERT INTO #CdTmp (
		Account, DebitBal00, CreditBal00, DebitBal01, CreditBal01, DebitBal02, CreditBal02, 
		DebitBal0, CreditBal0, DebitBal1, CreditBal1, DebitBal2, CreditBal2,CustomerId)
	SELECT Account, SUM(DebitBal00), SUM(CreditBal00), SUM(DebitBal01), SUM(CreditBal01), SUM(DebitBal02), SUM(CreditBal02), 
		SUM(DebitBal0), SUM(CreditBal0), SUM(DebitBal1), SUM(CreditBal1), SUM(DebitBal2), SUM(CreditBal2),CustomerId
	FROM #CdTmp1
	GROUP BY Account,CustomerId

		
	UPDATE #CdTmp SET MESGroupCode  = cus.MESGroupCode
	FROM #CdTmp cdt INNER JOIN B20Customer cus ON cdt.CustomerId = cus.id
 
	-- Lấy số dư theo tài khoản vốn chủ sở hữu, các quỹ, lãi lỗ:
	IF @_ExchangeRateConvReport = 1 AND OBJECT_ID('tempdb..#ExchangeRateConv_CtTmp') IS NOT NULL
	BEGIN
		DECLARE @_ExchangeRateConvKey NVARCHAR(256)
		SET @_ExchangeRateConvKey = 'DocDate <= ''' + CAST(@_DocDate2 AS VARCHAR(11)) + ''' AND IsActive = 1'
		EXECUTE [dbo].[usp_sys_GetData]
			@_TblSource = 'B30GeneralLedgerExchange',
			@_TblDes = '#ExchangeRateConv_CtTmp',
			@_Key = @_ExchangeRateConvKey,
			@_nUserId = @_nUserId,
			@_LangId = @_LangId,
			@_BranchCode = @_BranchCode,
			@_GroupByCols = 'DocDate,Account',
			@_NotSumCols = ''
	END
 
	-- Lấy dữ liệu điều chỉnh số dư cuối
	IF ISNULL(@_AdjustClosingBal, 1) = 1
	BEGIN
		DROP TABLE IF EXISTS #_AdjClosingBal
		SELECT BranchCode, DocDate, Account, LongTermAccount,  OrgLongTermAccount, DebitBal, CreditBal,
			CASE WHEN OrgLongTermAccount = 1 AND LongTermAccount = 0 THEN 1 -- gặp điều chỉnh từ dài hạn sang ngắn hạn thì tăng tiền
				WHEN OrgLongTermAccount = 0 AND LongTermAccount = 2 THEN -1 -- gặp điều chỉnh từ ngắn hạn qua tương đương tiền thì giảm
				ELSE 0 END * ISNULL(DebitBal, 0) AS ShortTermDebitBal, -- còn TH khác: ví dụ từ dài hạn qua tương đường tiền thì ko cần điều chỉnh gì ở ngắn hạn
			CASE WHEN OrgLongTermAccount = 1 AND LongTermAccount = 0 THEN 1
				WHEN OrgLongTermAccount = 0 AND LongTermAccount = 2 THEN -1
				ELSE 0 END * ISNULL(CreditBal, 0) AS ShortTermCreditBal,
			CASE WHEN LongTermAccount = 2 THEN DebitBal
				ELSE 0 END AS CashEquivalentDebitBal,
			CASE WHEN LongTermAccount = 2 THEN CreditBal
				ELSE 0 END AS CashEquivalentCreditBal,
			-DebitBal AS LongTermDebitBal, -CreditBal AS LongTermCreditBal
		INTO #_AdjClosingBal
		FROM dbo.vB30AdjustClosingBal_GetData
		WHERE IsActive = 1 AND 
		LongTermAccount IN (0, 2) 
		AND (BranchCode = '' OR BranchCode = @_BranchCode) 
		AND DocDate IN (@_DocDate02, @_DocDate2)
   
		DROP TABLE IF EXISTS #AccountTmp
		CREATE TABLE #AccountTmp (Account VARCHAR(24), LongTermAccount TINYINT)

		IF ISNULL(@_tblTKTStmp,'') <>''
		BEGIN 
		SET @_strExec = '
			INSERT INTO #AccountTmp (Account, LongTermAccount)
			SELECT Account, LongTermAccount 
			FROM ' + @_tblTKTStmp + '
			WHERE LongTermAccount IS NOT NULL AND Account <> ''''
			GROUP BY Account, LongTermAccount'
		EXECUTE (@_strExec)		
		END 

		-- Xóa các điều chỉnh dài hạn sang khoản ngắn hạn, mà lại ko có KBCT ngắn hạn tương ứng. Để tránh số dài hạn bị trừ, số ngắn hạn lại ko đc cộng => mất tính cân đối
		DELETE #_AdjClosingBal
		WHERE LongTermAccount = 0 
			AND Account IN (SELECT Account FROM #AccountTmp WHERE LongTermAccount = 1 GROUP BY Account)
			AND Account NOT IN (SELECT Account FROM #AccountTmp WHERE LongTermAccount = 0 GROUP BY Account)
			
		-- Xóa các điều chỉnh dài hạn sang khoản ngắn hạn, mà lại ko có KBCT của dài hạn tương ứng. Để tránh số ngắn hạn được cộng thêm, mà ko có khoản dài hạn nào bị trừ đi => mất tính cân đối
		DELETE #_AdjClosingBal
		WHERE LongTermAccount = 0 
			AND Account NOT IN (SELECT Account FROM #AccountTmp WHERE LongTermAccount = 1 GROUP BY Account)
			AND Account IN (SELECT Account FROM #AccountTmp WHERE LongTermAccount = 0 GROUP BY Account)
			
		-- Tương tự với tương đương tiền. Ngắn/dài -> tương đương tiền
		DELETE #_AdjClosingBal
		WHERE LongTermAccount = 2
			AND Account IN (SELECT Account FROM #AccountTmp WHERE LongTermAccount IN (0, 1) GROUP BY Account)
			AND Account NOT IN (SELECT Account FROM #AccountTmp WHERE LongTermAccount = 2 GROUP BY Account)
			
		DELETE #_AdjClosingBal
		WHERE LongTermAccount = 2
			AND Account NOT IN (SELECT Account FROM #AccountTmp WHERE LongTermAccount IN (0, 1) GROUP BY Account)
			AND Account IN (SELECT Account FROM #AccountTmp WHERE LongTermAccount = 2 GROUP BY Account)

		DROP TABLE IF EXISTS #AccountTmp
	END

	

	DECLARE @_Id INT, @_Account VARCHAR(24), @_ItemSide NCHAR(1), @_ItemType NCHAR(1), @_ItemLevel INT, @_IsOutsideAccount CHAR(1),
		@_DebitBal0 dbo.MoneyType, @_CreditBal0 dbo.MoneyType, @_DebitBal1 dbo.MoneyType, @_CreditBal1 dbo.MoneyType, 
		@_DebitBal2 dbo.MoneyType, @_CreditBal2 dbo.MoneyType, @_OpenAmount dbo.MoneyType, @_CloseAmount dbo.MoneyType, 
		@_IsForeignCurrency INT, @_LongTermAccount TINYINT,
		@_ExchangeRateConvId VARCHAR(24), @_ExchangeRatePrevious TINYINT, @_ConvertType TINYINT, @_ConvertMethod TINYINT, 
		@_ExchangeRateOperator TINYINT, @_VNDDebitBal0 dbo.MoneyType, @_VNDCreditBal0 dbo.MoneyType, @_VNDDebitBal1 dbo.MoneyType, 
		@_VNDCreditBal1 dbo.MoneyType, @_VNDDebitBal2 dbo.MoneyType, @_VNDCreditBal2 dbo.MoneyType, @_VNDOpenAmount dbo.MoneyType, 
		@_VNDCloseAmount dbo.MoneyType, @_ExchangeRate0 NUMERIC(18, 6), @_ExchangeRate2 NUMERIC(18, 6), @_ExchangeRate1 NUMERIC(18, 6), 
		@_DocDate0 DATE, @_DataType VARCHAR(24), @_OpenFiscalYearAmount dbo.MoneyType, @_VNDOpenFiscalYearAmount dbo.MoneyType, 
		@_AdjDebitBal2 dbo.MoneyType, @_AdjCreditBal2 dbo.MoneyType, @_AdjDebitBal1 dbo.MoneyType, @_AdjCreditBal1 dbo.MoneyType,
		@_AdjDebitBal0 dbo.MoneyType, @_AdjCreditBal0 dbo.MoneyType,
		@_MESGroupCode_Lst VARCHAR(256)

	-- Tỷ giá đến ngày cuối năm trước
	SET @_DocDate0 = DATEADD(DAY, -1, dbo.ufn_sys_GetOpenDateOfFinanceYear(@_DocDate1, @_BranchCode))

	-- Tinh theo chi tieu
	DROP TABLE IF EXISTS #Kqt01TableVar;
	CREATE TABLE #Kqt01TableVar (
		Id INT, Account VARCHAR(24), ItemSide CHAR(1), ItemType CHAR(1), ItemLevel INT, DataType VARCHAR(24),
		IsOutsideAccount NCHAR(1), LongTermAccount TINYINT, ExchangeRateConvId VARCHAR(24), ExchangeRatePrevious TINYINT, 
		ConvertType TINYINT, ConvertMethod TINYINT, ExchangeRateOperator TINYINT, ThisExchangeRate NUMERIC(20, 6), PreExchangeRate NUMERIC(20, 6),MESGroupCode_Lst NVARCHAR(256))
	DECLARE @_ThisExchangeRate NUMERIC(20, 6), @_PrevExchangeRate NUMERIC(20, 6)
	  
	IF ISNULL(@_tblTKTStmp,'') <>''
	BEGIN 
	SET @_strExec = N'
		INSERT INTO #Kqt01TableVar (
			Id, Account, ItemSide, ItemType, ItemLevel, DataType, IsOutsideAccount, LongTermAccount, ExchangeRateConvId, ExchangeRatePrevious,MESGroupCode_Lst)
		SELECT Id, Account, ItemSide, ItemType, ItemLevel, DataType, IsOutsideAccount, LongTermAccount, ExchangeRateConvId, ExchangeRatePrevious,MESGroupCode_Lst
			FROM ' + @_tblTKTStmp + N' 
			WHERE ItemLevel = 9 AND Account <> SPACE(0) AND Account <> ''KHAC'''
		EXECUTE(@_strExec)
	END 
 
	IF @_ExchangeRateConvReport = 1 
	BEGIN
		UPDATE #Kqt01TableVar
		SET ConvertType = tb1.ConvertType, ConvertMethod = tb1.ConvertMethod, ExchangeRateOperator = tb1.ExchangeRateOperator
		FROM #Kqt01TableVar tb
			INNER JOIN dbo.B20ExchangeRateConv tb1 ON tb1.Code = tb.ExchangeRateConvId
	END
	
	DECLARE @_OpenAmountExists TINYINT = 0, @_EchangeRateConvIsActive TINYINT
	IF EXISTS(SELECT * FROM tempdb.sys.columns WITH (NOLOCK) WHERE object_id = OBJECT_ID('tempdb..' + @_tblTKTStmp) AND name = 'OpenAmount')
	BEGIN
		SET @_OpenAmountExists = 1
	END


	 
 
	WHILE (SELECT COUNT(*) FROM #Kqt01TableVar) > 0
	BEGIN
		SELECT TOP 1 @_Id = Id, 
			@_Account = Account, 
			@_ItemSide = ItemSide, @_ItemType = ItemType, 
			@_ItemLevel = ItemLevel, @_IsOutsideAccount = IsOutsideAccount,
			@_LongTermAccount = LongTermAccount,
			@_ExchangeRateConvId = ExchangeRateConvId,
			@_ExchangeRatePrevious = ExchangeRatePrevious,
			@_ConvertType = ConvertType,
			@_ConvertMethod = ConvertMethod,
			@_ExchangeRateOperator = ExchangeRateOperator,
			@_DataType = DataType,
			@_MESGroupCode_Lst = ISNULL(MESGroupCode_Lst ,'')
		FROM #Kqt01TableVar	 
		
		SET @_EchangeRateConvIsActive = 0

		IF @_ExchangeRateConvReport = 1 AND ISNULL(@_ExchangeRateConvId, '') <> '' 
			AND EXISTS (SELECT * FROM dbo.B20ExchangeRateConv WHERE Id = @_ExchangeRateConvId AND IsActive = 1)
			SET @_EchangeRateConvIsActive = 1

		SELECT @_ExchangeRate0 = 0, @_ExchangeRate1 = 0, @_ExchangeRate2 = 0
			
			--SELECT @_MESGroupCode_Lst 

		IF @_DataType IN ('', 'DU_CUOI')
		BEGIN
			IF @_LongTermAccount IS NOT NULL
			BEGIN 
				IF @_Kd_Cp_Tam = 'C' AND @_LongTermAccount IN (0, 1)
				BEGIN
					-- Neu la phan Tai san
					IF @_ItemSide = 'C' AND @_ItemType = 'L' 
						UPDATE #CdTmp 
						SET DebitBal0 = 0, DebitBal1 = 0, DebitBal2 = 0
						FROM #CdTmp tb 
							INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code AND acc.LongTermAccount = @_LongTermAccount AND acc.Code LIKE @_Account + '%'
						WHERE tb.Account LIKE @_Account + '%' 
					ELSE IF @_ItemSide = 'N' AND @_ItemType = 'L' 
						UPDATE #CdTmp 
						SET CreditBal0 = 0, CreditBal1 = 0, CreditBal2 = 0 
						FROM #CdTmp tb 
							INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code AND acc.LongTermAccount = @_LongTermAccount AND acc.Code LIKE @_Account + '%'
						WHERE tb.Account LIKE @_Account + '%'
					ELSE 
						UPDATE #CdTmp 
						SET DebitBal0 = 0, CreditBal0 = 0, DebitBal1 = 0, CreditBal1 = 0, DebitBal2 = 0, CreditBal2 = 0 
						FROM #CdTmp tb 
							INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code AND acc.LongTermAccount = @_LongTermAccount AND acc.Code LIKE @_Account + '%'
						WHERE tb.Account LIKE @_Account + '%'
				END
 
				-- Tinh gia tri ra bien
				SELECT	@_DebitBal0 = ISNULL(SUM(tb.DebitBal0), 0),
						@_CreditBal0 = ISNULL(SUM(tb.CreditBal0), 0),
						@_DebitBal1 = ISNULL(SUM(tb.DebitBal1), 0),
						@_CreditBal1 = ISNULL(SUM(tb.CreditBal1), 0),
						@_DebitBal2 = ISNULL(SUM(tb.DebitBal2), 0),
						@_CreditBal2 = ISNULL(SUM(tb.CreditBal2), 0)
				FROM #CdTmp AS tb 
					INNER JOIN B20ChartOfAccount AS acc ON tb.Account = acc.Code AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + '%' 
				WHERE tb.Account LIKE @_Account + '%' 
				AND IIF(@_MESGroupCode_Lst<>'', CHARINDEX(CONCAT(',',tb.MESGroupCode,','), CONCAT(',',@_MESGroupCode_Lst,',')) ,1) >=1
				
 
			END ELSE
			BEGIN
				IF @_Kd_Cp_Tam = 'C'
				BEGIN
					-- Neu la phan Tai san
					IF @_ItemSide = 'C' AND @_ItemType = 'L' 
						UPDATE #CdTmp SET DebitBal0 = 0, DebitBal1 = 0, DebitBal2 = 0 WHERE Account LIKE RTRIM(@_Account) + '%'
					ELSE IF @_ItemSide = 'N' AND @_ItemType = 'L' 
						UPDATE #CdTmp SET CreditBal0 = 0, CreditBal1 = 0, CreditBal2 = 0 WHERE Account LIKE RTRIM(@_Account) + N'%'
					ELSE 
						UPDATE #CdTmp
						SET DebitBal0 = 0, CreditBal0 = 0, 
							DebitBal1 = 0, CreditBal1 = 0, 
							DebitBal2 = 0, CreditBal2 = 0
						WHERE Account LIKE RTRIM(@_Account) + N'%'
				END

				-- Tinh gia tri ra bien
				SELECT @_DebitBal0 = ISNULL(SUM(DebitBal0), 0),
					@_CreditBal0 = ISNULL(SUM(CreditBal0), 0),
					@_DebitBal1 = ISNULL(SUM(DebitBal1), 0),
					@_CreditBal1 = ISNULL(SUM(CreditBal1), 0),
					@_DebitBal2 = ISNULL(SUM(DebitBal2), 0),
					@_CreditBal2 = ISNULL(SUM(CreditBal2), 0)
				FROM #CdTmp	tb
				WHERE Account LIKE RTRIM(@_Account) + '%'
				AND IIF(@_MESGroupCode_Lst<>'', CHARINDEX(CONCAT(',',tb.MESGroupCode,','), CONCAT(',',@_MESGroupCode_Lst,',')) ,1) >=1
			END
		END
		ELSE IF @_DataType IN ('DU_DAU')
		BEGIN
			IF @_LongTermAccount IS NOT NULL AND @_LongTermAccount IN (0, 1)
			BEGIN 
				IF @_Kd_Cp_Tam = 'C'
				BEGIN
					-- Neu la phan Tai san
					IF @_ItemSide = 'C' AND @_ItemType = 'L' 
						UPDATE #CdTmp 
						SET DebitBal00 = 0, DebitBal01 = 0, DebitBal02 = 0
						FROM #CdTmp tb 
							INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + N'%'
						WHERE tb.Account LIKE @_Account + '%'
					ELSE IF @_ItemSide = 'N' AND @_ItemType = 'L' 
						UPDATE #CdTmp 
						SET CreditBal00 = 0, CreditBal01 = 0, CreditBal02 = 0 
						FROM #CdTmp tb 
							INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + N'%'
						WHERE tb.Account LIKE @_Account + '%'
					ELSE 
						UPDATE #CdTmp 
						SET DebitBal00 = 0, CreditBal00 = 0, DebitBal01 = 0, CreditBal01 = 0, DebitBal02 = 0, CreditBal02 = 0 
						FROM #CdTmp tb 
							INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + N'%'
						WHERE tb.Account LIKE @_Account + '%'
				END

				-- Tinh gia tri ra bien
				SELECT @_DebitBal0 = ISNULL(SUM(tb.DebitBal00), 0),
					@_CreditBal0 = ISNULL(SUM(tb.CreditBal00), 0),
					@_DebitBal1 = ISNULL(SUM(tb.DebitBal01), 0),
					@_CreditBal1 = ISNULL(SUM(tb.CreditBal01), 0),
					@_DebitBal2 = ISNULL(SUM(tb.DebitBal1), 0),
					@_CreditBal2 = ISNULL(SUM(tb.DebitBal1), 0)
				FROM #CdTmp tb INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code 
					AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + N'%'
				WHERE tb.Account LIKE @_Account + '%'
				AND IIF(@_MESGroupCode_Lst<>'', CHARINDEX(CONCAT(',',tb.MESGroupCode,','), CONCAT(',',@_MESGroupCode_Lst,',')) ,1) >=1
			END ELSE
			BEGIN
				IF @_Kd_Cp_Tam = 'C'
				BEGIN
					-- Neu la phan Tai san
					IF @_ItemSide = 'C' AND @_ItemType = 'L' 
						UPDATE #CdTmp 
						SET DebitBal00 = 0, DebitBal01 = 0, DebitBal02 = 0 WHERE Account LIKE RTRIM(@_Account) + '%'
					ELSE IF @_ItemSide = 'N' AND @_ItemType = 'L' 
						UPDATE #CdTmp 
						SET CreditBal00 = 0, CreditBal01 = 0, CreditBal02 = 0 WHERE Account LIKE RTRIM(@_Account) + N'%'
					ELSE 
						UPDATE #CdTmp 
						SET DebitBal00 = 0, CreditBal00 = 0, 
							DebitBal01 = 0, CreditBal01 = 0, 
							DebitBal02 = 0, CreditBal02 = 0
						WHERE Account LIKE RTRIM(@_Account) + N'%'
				END

				-- Tinh gia tri ra bien
				SELECT @_DebitBal0 = ISNULL(SUM(DebitBal00), 0),
					@_CreditBal0 = ISNULL(SUM(CreditBal00), 0),
					@_DebitBal1 = ISNULL(SUM(DebitBal01), 0),
					@_CreditBal1 = ISNULL(SUM(CreditBal01), 0),
					@_DebitBal2 = ISNULL(SUM(DebitBal1), 0),
					@_CreditBal2 = ISNULL(SUM(CreditBal1), 0)
				FROM #CdTmp	tb
				WHERE Account LIKE RTRIM(@_Account) + '%'
				AND IIF(@_MESGroupCode_Lst<>'', CHARINDEX(CONCAT(',',tb.MESGroupCode,','), CONCAT(',',@_MESGroupCode_Lst,',')) ,1) >=1
			END
		END
		ELSE IF @_DataType IN ('PS_NO')
		BEGIN
			IF @_LongTermAccount IS NOT NULL AND @_LongTermAccount IN (0, 1)
			BEGIN 
				SELECT @_DebitBal1 = ISNULL(SUM(tb.DebitAmount), 0), @_CreditBal1 = 0
				FROM #K_CtTmp0 tb 
					INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + N'%'
				WHERE tb.Account LIKE RTRIM(@_Account) + '%'
				
				SELECT @_DebitBal2 = ISNULL(SUM(tb.DebitAmount), 0), @_CreditBal2 = 0
				FROM #K_CtTmp1 tb 
					INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + N'%'
				WHERE tb.Account LIKE RTRIM(@_Account) + '%'

				SELECT @_DebitBal0 = @_DebitBal1, @_CreditBal0 = @_CreditBal1
			END
			ELSE
			BEGIN
				SELECT @_DebitBal1 = ISNULL(SUM(DebitAmount), 0), @_CreditBal1 = 0
				FROM #K_CtTmp0
				WHERE Account LIKE RTRIM(@_Account) + '%'
				
				SELECT @_DebitBal2 = ISNULL(SUM(DebitAmount), 0), @_CreditBal2 = 0
				FROM #K_CtTmp1	
				WHERE Account LIKE RTRIM(@_Account) + '%'

				SELECT @_DebitBal0 = @_DebitBal1, @_CreditBal0 = @_CreditBal1
			END
		END
		ELSE IF @_DataType IN ('PS_CO')
		BEGIN
			IF @_LongTermAccount IS NOT NULL AND @_LongTermAccount IN (0, 1)
			BEGIN 
				SELECT @_DebitBal1 = 0, @_CreditBal1 = ISNULL(SUM(tb.CreditAmount), 0)
				FROM #K_CtTmp0 tb INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code 
					AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + N'%'
				WHERE tb.Account LIKE RTRIM(@_Account) + '%'
				
				SELECT @_DebitBal2 = 0, @_CreditBal2 = ISNULL(SUM(tb.CreditAmount), 0)
				FROM #K_CtTmp1 tb INNER JOIN B20ChartOfAccount acc ON tb.Account = acc.Code 
					AND ISNULL(acc.LongTermAccount, 0) = @_LongTermAccount AND acc.Code LIKE @_Account + N'%'
				WHERE tb.Account LIKE RTRIM(@_Account) + '%'

				SELECT @_DebitBal0 = @_DebitBal1, @_CreditBal0 = @_CreditBal1
			END
			ELSE
			BEGIN
				SELECT @_DebitBal1 = 0, @_CreditBal1 = ISNULL(SUM(CreditAmount), 0)
				FROM #K_CtTmp0
				WHERE Account LIKE RTRIM(@_Account) + '%'
				
				SELECT @_DebitBal2 = 0, @_CreditBal2 = ISNULL(SUM(CreditAmount), 0)
				FROM #K_CtTmp1	
				WHERE Account LIKE RTRIM(@_Account) + '%'

				SELECT @_DebitBal0 = @_DebitBal1, @_CreditBal0 = @_CreditBal1
			END
		END
 
		IF @_ExchangeRateConvReport = 1 AND @_EchangeRateConvIsActive = 1
		BEGIN
			SELECT TOP 1 @_ExchangeRate0 = ExchangeRate
			FROM dbo.B20ExchangeRateConvDetail tb1
			WHERE tb1.ExchangeRateConvId = @_ExchangeRateConvId AND tb1.EffectiveDate <= @_DocDate0 AND
				(tb1.ExpiryDate IS NULL OR tb1.ExpiryDate >= @_DocDate0)
			ORDER BY tb1.EffectiveDate DESC, tb1.ExpiryDate

			SELECT TOP 1 @_ExchangeRate2 = ExchangeRate
			FROM dbo.B20ExchangeRateConvDetail tb1
			WHERE tb1.ExchangeRateConvId = @_ExchangeRateConvId AND tb1.EffectiveDate <= @_DocDate2 AND
				(tb1.ExpiryDate IS NULL OR tb1.ExpiryDate >= @_DocDate2) 
			ORDER BY tb1.EffectiveDate DESC, tb1.ExpiryDate
			
			SELECT TOP 1 @_ExchangeRate1 = ExchangeRate
			FROM dbo.B20ExchangeRateConvDetail tb1
			WHERE tb1.ExchangeRateConvId = @_ExchangeRateConvId AND tb1.EffectiveDate <= DATEADD(DAY, -1, @_DocDate1) AND
				(tb1.ExpiryDate IS NULL OR tb1.ExpiryDate >= DATEADD(DAY, -1, @_DocDate1)) 
			ORDER BY tb1.EffectiveDate DESC, tb1.ExpiryDate

			SET @_ExchangeRate0 = ISNULL(@_ExchangeRate0, 0)
			SET @_ExchangeRate2 = ISNULL(@_ExchangeRate2, 0)
			SET @_ExchangeRate1 = ISNULL(@_ExchangeRate1, 0)

			-- Lấy tỷ giá kỳ này bằng tỷ giá kỳ trước: áp dụng cho lợi nhuận chưa phân phối của năm trước
			IF ISNULL(@_ExchangeRatePrevious, 0) = 1
			BEGIN
				SET @_ExchangeRate2 = @_ExchangeRate0;
				SET @_ExchangeRate1 = @_ExchangeRate0;
			END

			IF @_ExchangeRateOperator = 0
				SELECT @_VNDDebitBal0 = IIF(@_ExchangeRate0 = 0, 0, ROUND(@_DebitBal0/@_ExchangeRate0, @_VNDRound)),
					@_VNDCreditBal0 = IIF(@_ExchangeRate0 = 0, 0, ROUND(@_CreditBal0/@_ExchangeRate0, @_VNDRound)),
					@_VNDDebitBal1 = IIF(@_ExchangeRate1 = 0, 0, ROUND(@_DebitBal1/@_ExchangeRate1, @_VNDRound)),
					@_VNDCreditBal1 = IIF(@_ExchangeRate1 = 0, 0, ROUND(@_CreditBal1/@_ExchangeRate1, @_VNDRound)),
					@_VNDDebitBal2 = IIF(@_ExchangeRate2 = 0, 0, ROUND(@_DebitBal2/@_ExchangeRate2, @_VNDRound)),
					@_VNDCreditBal2 = IIF(@_ExchangeRate2 = 0, 0, ROUND(@_CreditBal2/@_ExchangeRate2, @_VNDRound))
			ELSE
				SELECT @_VNDDebitBal0  = ROUND(@_DebitBal0*@_ExchangeRate0, @_VNDRound),
					@_VNDCreditBal0 = ROUND(@_CreditBal0*@_ExchangeRate0, @_VNDRound),
					@_VNDDebitBal1 = ROUND(@_DebitBal1*@_ExchangeRate1, @_VNDRound),
					@_VNDCreditBal1 = ROUND(@_CreditBal1*@_ExchangeRate1, @_VNDRound),
					@_VNDDebitBal2 = ROUND(@_DebitBal2*@_ExchangeRate2, @_VNDRound),
					@_VNDCreditBal2 = ROUND(@_CreditBal2*@_ExchangeRate2, @_VNDRound)

			SELECT @_ThisExchangeRate = @_ExchangeRate2, @_PrevExchangeRate = @_ExchangeRate1

			-- Xử lý tình huống @_ConvertType = 2 lấy trong sổ cái riêng
			IF @_ConvertType = 1
			BEGIN
				SELECT @_VNDDebitBal0 = ISNULL(SUM(IIF(DocDate < @_StartDate OR (IsOpenning = 1 AND DocDate = @_StartDate), VNDDebitAmount, 0)), 0),
					@_VNDCreditBal0 = ISNULL(SUM(IIF(DocDate < @_StartDate OR (IsOpenning = 1 AND DocDate = @_StartDate), VNDCreditAmount, 0)), 0),
					@_VNDDebitBal2 = ISNULL(SUM(VNDDebitAmount), 0),
					@_VNDCreditBal2 = ISNULL(SUM(VNDCreditAmount), 0),
					@_VNDDebitBal1 = ISNULL(SUM(IIF(DocDate < @_DocDate1 OR (IsOpenning = 1 AND DocDate = @_DocDate1), VNDDebitAmount, 0)), 0),
					@_VNDCreditBal1 = ISNULL(SUM(IIF(DocDate < @_DocDate1 OR (IsOpenning = 1 AND DocDate = @_DocDate1), VNDCreditAmount, 0)), 0)
				FROM #ExchangeRateConv_CtTmp	
				WHERE Account LIKE RTRIM(@_Account) + '%' AND ExchangeRateConvId = @_ExchangeRateConvId

				SELECT @_ThisExchangeRate = 0, @_PrevExchangeRate = 0
			END
		END
		
		IF (@_ItemSide = 'C' AND @_ItemType = 'L') OR @_DataType = 'PS_NO'
		BEGIN
			SELECT @_OpenFiscalYearAmount = @_DebitBal0, @_CloseAmount = @_DebitBal2, @_OpenAmount = @_DebitBal1

			IF @_ExchangeRateConvReport = 1 
				SELECT @_VNDOpenFiscalYearAmount = @_VNDDebitBal0, @_VNDCloseAmount = @_VNDDebitBal2, @_VNDOpenAmount = @_VNDDebitBal1
		END 
		ELSE IF @_ItemSide = 'C' AND @_ItemType <> 'L'
		BEGIN
			SELECT @_OpenFiscalYearAmount = @_DebitBal0 - @_CreditBal0, @_CloseAmount = @_DebitBal2 - @_CreditBal2, @_OpenAmount = @_DebitBal1 - @_CreditBal1

			IF @_ExchangeRateConvReport = 1 
				SELECT @_VNDOpenFiscalYearAmount = @_VNDDebitBal0 - @_VNDCreditBal0, @_VNDCloseAmount = @_VNDDebitBal2 - @_VNDCreditBal2, @_VNDOpenAmount = @_VNDDebitBal1 - @_VNDCreditBal1
		END 
		ELSE IF @_ItemSide = 'N' AND @_ItemType = 'L' OR @_DataType = 'PS_CO'
		BEGIN
			SELECT @_OpenFiscalYearAmount = @_CreditBal0, @_CloseAmount = @_CreditBal2, @_OpenAmount = @_CreditBal1
			
			IF @_ExchangeRateConvReport = 1 
				SELECT @_VNDOpenFiscalYearAmount = @_VNDCreditBal0, @_VNDCloseAmount = @_VNDCreditBal2, @_VNDOpenAmount = @_VNDCreditBal1
		END 
		ELSE
		BEGIN
			SELECT @_OpenFiscalYearAmount = @_CreditBal0 - @_DebitBal0, @_CloseAmount = @_CreditBal2 - @_DebitBal2, @_OpenAmount = @_CreditBal1 - @_DebitBal1

			IF @_ExchangeRateConvReport = 1 
				SELECT @_VNDOpenFiscalYearAmount = @_VNDCreditBal0 - @_VNDDebitBal0, @_VNDCloseAmount = @_VNDCreditBal2 - @_VNDDebitBal2, @_VNDOpenAmount = @_VNDCreditBal1 - @_VNDDebitBal1
		END

		IF @_OpenAmountExists = 0
		BEGIN
			IF @_ExchangeRateConvReport = 1 AND @_EchangeRateConvIsActive = 1
				SET @_strExec = N'
				UPDATE ' + @_tblTKTStmp + N'
				SET '+@_ColName+' = ' + FORMAT(@_CloseAmount, '') + 
				N', OpenFiscalYearAmount = ' + FORMAT(@_OpenFiscalYearAmount, '') + 
				N', VNDCloseAmount = ' + FORMAT(@_VNDCloseAmount, '') + 
				N', VNDOpenFiscalYearAmount = ' + FORMAT(@_VNDOpenFiscalYearAmount, '') + 
				N', ThisExchangeRate = ' + FORMAT(@_ThisExchangeRate, '') + 
				N', PrevExchangeRate = ' + FORMAT(@_PrevExchangeRate, '') + N'
				WHERE Id = @_Id'
			ELSE
				SET @_strExec = N'
				UPDATE ' + @_tblTKTStmp + N'
				SET '+@_ColName+'= ' + FORMAT(@_CloseAmount, '') + 
				N', OpenFiscalYearAmount = ' + FORMAT(@_OpenFiscalYearAmount, '') + 
				N'	WHERE Id = @_Id'
		END 
		ELSE
		BEGIN
			IF @_ExchangeRateConvReport = 1 AND @_EchangeRateConvIsActive = 1 
				SET @_strExec = N'
				UPDATE ' + @_tblTKTStmp + N'
				SET '+@_ColName+' = ' + FORMAT(@_CloseAmount, '') + 
				N', OpenFiscalYearAmount = ' + FORMAT(@_OpenFiscalYearAmount, '') + 
				N', VNDCloseAmount = ' + FORMAT(@_VNDCloseAmount, '') + 
				N', VNDOpenFiscalYearAmount = ' + FORMAT(@_VNDOpenFiscalYearAmount, '') + 
				N', OpenAmount = ' + FORMAT(@_OpenAmount, '') + 
				N', VNDOpenAmount = ' + FORMAT(@_VNDOpenAmount, '') + 
				N',	ThisExchangeRate = ' + FORMAT(@_ThisExchangeRate, '') + 
				N', PrevExchangeRate = ' + FORMAT(@_PrevExchangeRate, '') + 
				N'	WHERE Id = @_Id '
			ELSE
				SET @_strExec = N'
				UPDATE ' + @_tblTKTStmp + N'
				SET '+@_ColName+' = ' + FORMAT(@_CloseAmount, '') + 
				N', OpenAmount = ' + FORMAT(@_OpenAmount, '') + 
				N', OpenFiscalYearAmount = ' + FORMAT(@_OpenFiscalYearAmount, '') + N'
				WHERE Id = @_Id '
		END
		
		EXECUTE sys.sp_executesql @_strExec, N'@_Id INT', @_Id

		DELETE FROM #Kqt01TableVar WHERE Id = @_Id
	END

	

	IF @_Kd_Cp_Tam = 'C' AND @_ExchangeRateConvReport = 0
	BEGIN
		-- Tinh gia tri ra bien
		SELECT @_DebitBal0 = ISNULL(SUM(DebitBal0), 0), @_CreditBal0 = ISNULL(SUM(CreditBal0), 0),
			@_DebitBal2 = ISNULL(SUM(DebitBal2), 0), @_CreditBal2 = ISNULL(SUM(CreditBal2), 0),
			@_DebitBal1 = ISNULL(SUM(DebitBal1), 0), @_CreditBal1 = ISNULL(SUM(CreditBal1), 0)
		FROM #CdTmp	

		SELECT @_OpenFiscalYearAmount = @_CreditBal0 - @_DebitBal0, @_CloseAmount = @_CreditBal2 - @_DebitBal2, @_OpenAmount = @_CreditBal1 - @_DebitBal1

		IF @_OpenAmountExists = 0
			SET @_strExec = 
				'UPDATE ' + @_tblTKTStmp + CHAR(13) +
				'SET '+@_ColName+' = ' + CAST(@_CloseAmount AS VARCHAR(30)) + N', OpenFiscalYearAmount = ' + CAST(@_OpenFiscalYearAmount AS VARCHAR(30)) + CHAR(13) +
				'WHERE Account = ''KHAC'''
		ELSE
			SET @_strExec = 
				'UPDATE ' + @_tblTKTStmp + CHAR(13) +
				'SET '+@_ColName+' = ' + CAST(@_CloseAmount AS VARCHAR(30)) + N', OpenFiscalYearAmount = ' + CAST(@_OpenFiscalYearAmount AS VARCHAR(30)) + ', OpenAmount = ' + FORMAT(@_OpenAmount, '') + CHAR(13) +
				'WHERE Account = ''KHAC'' '
		
		EXECUTE(@_strExec)
	END
	
	DECLARE @_FieldList VARCHAR(128) =  @_ColName

	IF @_ExchangeRateConvReport = 1 
		SET @_FieldList = N'OpenFiscalYearAmount,'+@_ColName+',VNDOpenFiscalYearAmount,VNDCloseAmount'
 
	DECLARE @_ConversionItemNo NVARCHAR(16), @_ConversionItemId INT

	IF ISNULL(@_tblTKTStmp,'') <>''
	SET @_strExec = N'
		IF EXISTS(SELECT * FROM ' + @_tblTKTStmp + N' WHERE ConversionFinancial = 1)
			SELECT TOP 1 @_ConversionItemId = Id, @_ConversionItemNo = ItemNo FROM ' + @_tblTKTStmp + N' WHERE ConversionFinancial = 1'
		
	EXECUTE sys.sp_executesql @_strExec, N'@_ConversionItemNo NVARCHAR(16) OUTPUT, @_ConversionItemId INT OUTPUT', @_ConversionItemNo OUTPUT, @_ConversionItemId OUTPUT

	-- Xử lý thêm phần chênh lệch do chuyển đổi báo cáo tài chính
	-- Chú ý bảng cân đối phải cân thì mới xử lý CloseAmount = 0 và OpenFiscalYearAmount = 0
	IF @_ExchangeRateConvReport = 1 AND ISNULL(@_ConversionItemId, 0) <> 0
	BEGIN
		DECLARE @_VNDAmountUpdate dbo.MoneyType, @_VNDOpenFiscalYearAmountUpdate dbo.MoneyType
		
		--EXECUTE [usp_sys_SumValue]
		--		@_Table = @_tblTKTStmp,
		--		@_FieldList = @_FieldList,	
		--		@_FieldKey = 'ItemNo',
		--		@_FieldCal = 'Formula',
		--		@_FieldBac = 'ItemLevel',
		--		@_Key = '',
		--		@_FieldIn_Ck = '',	
		--		@_ResetFormula = 1
	
		-- Nếu bảng cân đối chưa cân thì không tính chỉ tiêu ảnh hưởng BCTC
		IF ISNULL(@_tblTKTStmp,'') <>''
		BEGIN 
		SET @_strExec = N'
		IF EXISTS(SELECT * FROM ' + @_tblTKTStmp + N' WHERE Id = @_ConversionItemId)
		BEGIN	
			IF EXISTS(SELECT * FROM ' + @_tblTKTStmp + N' WHERE Id = @_ConversionItemId AND (CloseAmount <> 0 OR OpenFiscalYearAmount <> 0))
				UPDATE ' + @_tblTKTStmp + N' 
				SET CloseAmount = 0, OpenFiscalYearAmount = 0, VNDCloseAmount = 0, VNDOpenFiscalYearAmount = 0	
				WHERE Id = @_ConversionItemId
			ELSE
				SELECT TOP 1 @_VNDAmountUpdate = VNDCloseAmount, @_VNDOpenFiscalYearAmountUpdate = VNDOpenFiscalYearAmount
				FROM ' + @_tblTKTStmp + N' 
				WHERE Id = @_ConversionItemId
		END'

		SELECT @_VNDAmountUpdate = 0, @_VNDOpenFiscalYearAmountUpdate = 0

		EXECUTE sys.sp_executesql @_strExec, N'@_VNDAmountUpdate dbo.MoneyType OUTPUT, @_VNDOpenFiscalYearAmountUpdate dbo.MoneyType OUTPUT, @_ConversionItemId INT', 
			@_VNDAmountUpdate OUTPUT, @_VNDOpenFiscalYearAmountUpdate OUTPUT, @_ConversionItemId
		

		SET @_strExec = N' 		
			UPDATE ' + @_tblTKTStmp + N'
			SET ItemLevel = 9, Formula = ''''
			WHERE Id = @_ConversionItemId'
	
		EXECUTE sys.sp_executesql @_strExec, N'@_ConversionItemId INT', @_ConversionItemId
		END 
	
		 
	END 
	ELSE	
	IF ISNULL(@_ConversionItemId, 0) <> 0	-- Xóa chỉ tiêu chênh lệch do chuyển đổi báo cáo tài chính khỏi báo cáo
	BEGIN
		SET @_strExec = N'DELETE FROM ' + @_tblTKTStmp + N' WHERE Id = @_ConversionItemId'

		EXECUTE sys.sp_executesql @_strExec, N'@_ConversionItemId INT', @_ConversionItemId
	END

	PRINT @_FieldList
	EXECUTE dbo.usp_sys_SumValue
		@_Table = @_tblTKTStmp,
		@_FieldList = @_FieldList,	
		@_FieldKey = N'ItemNo',
		@_FieldCal = N'Formula',
		@_FieldBac = N'ItemLevel',
		@_Key = N'',
		@_FieldIn_Ck = 'IsPrint',
		@_ResetFormula = 0
 
	DROP TABLE IF EXISTS #Kqt01TableVar
	DROP TABLE IF EXISTS #CdTmp1
	DROP TABLE IF EXISTS #CdTmp
	DROP TABLE IF EXISTS #CloseBalance1
	DROP TABLE IF EXISTS #CloseBalance0
	DROP TABLE IF EXISTS #OpenBalance0
	DROP TABLE IF EXISTS #OpenBalance1
	DROP TABLE IF EXISTS #K_CtTmp0
	DROP TABLE IF EXISTS #K_CtTmp1
	DROP TABLE IF EXISTS #ExchangeRateConv_CtTmp
	DROP TABLE IF EXISTS #_AdjClosingBal
END
GO
GO


SET DATEFORMAT DMY
EXEC dbo.usp_BusinessPlanKqt_BalanceSheet_test @_DocDate1 = '01/01/2026 00:00:00.000'
                                    , @_DocDate2 = '31/01/2026 00:00:00.000'
                                    , @_Ngay_Dau_Nam = '01/01/2026 00:00:00.000'
                                    , @_LangId = 0
                                    , @_BranchCode = 'I26'
                                    , @_RepId1 = 'IBC0000003'
                                    , @_CurrencyCode0 = 'VND'
                                    , @_DefinitionTableName = 'B10BusinessPlanKqt01'
                                    , @_TableValue = ''
                                    , @_HTKK_Exp = 0
                                    , @_Filename_XML = ''
                                    , @_IssuedByNo = '200/2014/TT-BTC'
