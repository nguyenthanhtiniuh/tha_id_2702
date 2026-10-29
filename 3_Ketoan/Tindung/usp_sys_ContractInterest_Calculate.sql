SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
-- Coder: VuLA
-- Manager: ThangNH
-- Author: Đinh Quang Thắng
-- Create date: 12/2010
-- Description: Tính số lãi suất theo từng LoanContract
ALTER PROCEDURE [dbo].[usp_sys_ContractInterest_Calculate]
	@_DocDate1 DATE	= '',
	@_DocDate2 DATE	= '', 
	@_LCType CHAR(1) = '1',
	@_GrossInterest TINYINT	 = 0,
	@_CurrencyCode0 VARCHAR(3) = N'VND',
	@_TableName VARCHAR(64) = '',
	@_nUserId INT = 4,
	@_LangId INT = 0,
	 @_DataCode VARCHAR(8) = ''
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('TempDb..#K_CtTmp0') IS NULL OR OBJECT_ID('TempDb..#K_CtQkTmp') IS NULL OR OBJECT_ID('TempDb..#BizDoc_Contract') IS NULL
		RETURN

	-- Bảng tính lãi suất	
	DROP TABLE IF EXISTS #CalculateInterestRate
	SELECT TOP 0 bizRate.BizDocId, bizRate.EffectiveDate, bizRate.InterestRate, bizRate.InterestRate1
	INTO #CalculateInterestRate
	FROM dbo.B30BizDocInterestRate bizRate 
		INNER JOIN #BizDoc_Contract c ON bizRate.BizDocId = c.BizDocId
	WHERE bizRate.EffectiveDate <= @_DocDate2

	--2026-10-14 bổ sung lấy dữ liệu theo datacode

	DECLARE @_Key NVARCHAR(max)  = '  BizDocId IN (SELECT BizDocId FROM #BizDoc_Contract ) AND  EffectiveDate<= ''' + CAST(@_DocDate2 AS NVARCHAR(11)) + ''''

	DECLARE @_BizDocInterestRate NVARCHAR(128) = 'B30BizDocInterestRate'

	SELECT @_BizDocInterestRate = REPLACE(@_BizDocInterestRate,'0',@_DataCode)

	

	EXECUTE dbo.usp_sys_Append
		@_TableSource = @_BizDocInterestRate,
		@_TableDestination = '#CalculateInterestRate',
		@_Where_TableSource = @_key,@_Print_Exec = 1

		 

	-- Tạo bảng lãi suất để cập nhật giá trị tính lãi
	DROP TABLE IF EXISTS #CalculateInterest
	CREATE TABLE #CalculateInterest 
	(
		Id INT IDENTITY(1, 1) PRIMARY KEY,
		BizDocId VARCHAR(16),
		Date1 DATE,
		Date2 DATE,
		OpeningAmount NUMERIC(18, 2) DEFAULT 0, 
		IncreaseAmount NUMERIC(18, 2) DEFAULT 0, 
		DecreaseAmount NUMERIC(18, 2) DEFAULT 0, 
		ClosingAmount NUMERIC(18, 2) DEFAULT 0,
		-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
		OriginalOpeningAmount NUMERIC(18, 2) DEFAULT 0, 
		OriginalIncreaseAmount NUMERIC(18, 2) DEFAULT 0, 
		OriginalDecreaseAmount NUMERIC(18, 2) DEFAULT 0, 
		OriginalClosingAmount NUMERIC(18, 2) DEFAULT 0,
		--
		InterestRate NUMERIC(8,4) DEFAULT 0,		--07/07/2025: ThanhVM sửa kiểu dữ liệu theo bảng gốc B30BizDocInterestRate
		NumberOfDaysInterest INT DEFAULT 0, 
		DaysOfYear INT DEFAULT 0,
		InterestAmount FLOAT DEFAULT 0,
		-- Dành cho HDTG
		OriginalDecreaseAmountBeforeDue NUMERIC(18, 2) DEFAULT 0, 
		InterestRate1 NUMERIC(8,4) DEFAULT 0,		--07/07/2025: ThanhVM sửa kiểu dữ liệu theo bảng gốc B30BizDocInterestRate
		InterestAmount1 FLOAT DEFAULT 0,
		InterestAmount2 FLOAT DEFAULT 0,
		ClosingAmountDecrease NUMERIC(18, 2) DEFAULT 0,
		IsOpening TINYINT,
		IsClosing TINYINT
	)

	-- Số dư đầu kỳ
	DROP TABLE IF EXISTS #Contact_Opening
	;WITH Cte AS
    (
		SELECT a.DocDate, a.BizDocId, IIF(@_LCType = '1', a.CreditAmount, a.DebitAmount) AS IncreaseAmount,
			IIF(@_LCType = '1', a.DebitAmount, a.CreditAmount) AS DecreaseAmount, 
			-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
			IIF(@_LCType = '1', a.OriginalCreditAmount, a.OriginalDebitAmount) AS OriginalIncreaseAmount,
			IIF(@_LCType = '1', a.OriginalDebitAmount, a.OriginalCreditAmount) AS OriginalDecreaseAmount
		FROM #K_CtQkTmp	a
			INNER JOIN #BizDoc_Contract LC ON a.BizDocId = LC.BizDocId AND a.Account LIKE LC.Account + '%'
		UNION ALL
		SELECT a.DocDate, a.BizDocId, IIF(@_LCType = '1', a.CreditAmount, a.DebitAmount) AS IncreaseAmount,
			IIF(@_LCType = '1', a.DebitAmount, a.CreditAmount) AS DecreaseAmount, 
			-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
			IIF(@_LCType = '1', a.OriginalCreditAmount, a.OriginalDebitAmount) AS OriginalIncreaseAmount,
			IIF(@_LCType = '1', a.OriginalDebitAmount, a.OriginalCreditAmount) AS OriginalDecreaseAmount
		FROM #K_CtTmp0 a
			INNER JOIN #BizDoc_Contract LC ON a.BizDocId = LC.BizDocId AND a.Account LIKE LC.Account + '%'
		WHERE a.DocDate < @_DocDate1
	)
	SELECT Cte.BizDocId, MAX(Cte.DocDate) AS DocDate, SUM(ISNULL(Cte.IncreaseAmount, 0)) - SUM(ISNULL(Cte.DecreaseAmount, 0)) AS OpeningAmount, 
		-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
		SUM(ISNULL(Cte.OriginalIncreaseAmount, 0)) - SUM(ISNULL(Cte.OriginalDecreaseAmount, 0)) AS OriginalOpeningAmount
	INTO #Contact_Opening
	FROM Cte
	GROUP BY Cte.BizDocId

	

	UPDATE #Contact_Opening SET DocDate = @_DocDate1 
	WHERE DocDate <> @_DocDate1

	-- Phát sinh trong kỳ
	DROP TABLE IF EXISTS #Contact_Incurred
	SELECT a.DocDate, a.BizDocId, IIF(@_LCType = '1', a.CreditAmount, a.DebitAmount) AS IncreaseAmount,
		IIF(@_LCType = '1', a.DebitAmount, a.CreditAmount) AS DecreaseAmount, 
		-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
		IIF(@_LCType = '1', a.OriginalCreditAmount, a.OriginalDebitAmount) AS OriginalIncreaseAmount,
		IIF(@_LCType = '1', a.OriginalDebitAmount, a.OriginalCreditAmount) AS OriginalDecreaseAmount
	INTO #Contact_Incurred
	FROM #K_CtTmp0 a
		INNER JOIN #BizDoc_Contract LC ON a.BizDocId = LC.BizDocId AND a.Account LIKE LC.Account + '%'
	WHERE a.DocDate BETWEEN @_DocDate1 AND @_DocDate2

	-- Tổng hợp biến động tăng, giảm gốc và thay đổi lãi suất
	;WITH Cte AS
    (
		SELECT BizDocId, DocDate, OpeningAmount, CAST(0 AS NUMERIC(18, 2)) AS IncreaseAmount, 
			CAST(0 AS NUMERIC(18, 2)) AS DecreaseAmount, CAST(0 AS NUMERIC(8,4)) AS InterestRate, 
			-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
			OriginalOpeningAmount, CAST(0 AS NUMERIC(18, 2)) AS OriginalIncreaseAmount, CAST(0 AS NUMERIC(18, 2)) AS OriginalDecreaseAmount
		FROM #Contact_Opening
		UNION ALL
		SELECT BizDocId, DocDate, 0, IncreaseAmount, DecreaseAmount, 0,
			-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
			0, OriginalIncreaseAmount, OriginalDecreaseAmount
		FROM #Contact_Incurred
		UNION ALL
		SELECT BizDocId, EffectiveDate, 0, 0, 0, InterestRate,
			0, 0, 0	-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
		FROM #CalculateInterestRate
		WHERE EffectiveDate BETWEEN @_DocDate1 AND @_DocDate2
		UNION ALL
		SELECT BizDocId, DueDate_Tt, 0, 0, 0, 0,
			0, 0, 0	-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
		FROM #BizDoc_Contract
		WHERE DueDate_Tt BETWEEN @_DocDate1 AND @_DocDate2
	)
	INSERT INTO #CalculateInterest(BizDocId, Date1, Date2, OpeningAmount, IncreaseAmount, DecreaseAmount,
		DaysOfYear, InterestRate, ClosingAmount, IsOpening, IsClosing, 
		OriginalOpeningAmount, OriginalIncreaseAmount, OriginalDecreaseAmount, OriginalClosingAmount)	-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
	SELECT Cte.BizDocId, Cte.DocDate, 
		ISNULL(DATEADD(DAY, -1, LEAD(Cte.DocDate) OVER (PARTITION BY Cte.BizDocId ORDER BY Cte.DocDate)), @_DocDate2), 	
		SUM(Cte.OpeningAmount) AS OpeningAmount, SUM(Cte.IncreaseAmount) AS IncreaseAmount, SUM(Cte.DecreaseAmount) AS DecreaseAmount, 
		MAX(LC.DaysOfYear), MAX(InterestRate) AS InterestRate,
		SUM(SUM(Cte.OpeningAmount) + SUM(Cte.IncreaseAmount) - SUM(Cte.DecreaseAmount)) OVER (PARTITION BY Cte.BizDocId ORDER BY Cte.DocDate ROWS UNBOUNDED PRECEDING),
		IIF(ROW_NUMBER() OVER (PARTITION BY Cte.BizDocId ORDER BY Cte.DocDate) = 1, 1, 0), 
		IIF(DATEADD(DAY, -1, LEAD(Cte.DocDate) OVER (PARTITION BY Cte.BizDocId ORDER BY Cte.DocDate)) IS NULL, 1, 0),
		-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
		SUM(Cte.OriginalOpeningAmount) AS OriginalOpeningAmount, SUM(Cte.OriginalIncreaseAmount) AS OriginalIncreaseAmount,
		SUM(Cte.OriginalDecreaseAmount) AS OriginalDecreaseAmount,
		SUM(SUM(Cte.OriginalOpeningAmount) + SUM(Cte.OriginalIncreaseAmount) - SUM(Cte.OriginalDecreaseAmount)) OVER (PARTITION BY Cte.BizDocId ORDER BY Cte.DocDate ROWS UNBOUNDED PRECEDING)
	FROM Cte
		INNER JOIN #BizDoc_Contract LC ON Cte.BizDocId = LC.BizDocId
	GROUP BY Cte.BizDocId, Cte.DocDate	

	UPDATE #CalculateInterest SET 
		OpeningAmount = ClosingAmount + DecreaseAmount - IncreaseAmount,
		InterestRate = ISNULL(tb.InterestRate, 0),
		InterestRate1 = ISNULL(tb.InterestRate1, 0),
		NumberOfDaysInterest = DATEDIFF(DAY, Date1, Date2) + 1,
		-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
		OriginalOpeningAmount = OriginalClosingAmount + OriginalDecreaseAmount - OriginalIncreaseAmount
	FROM #CalculateInterest a
		OUTER APPLY
		(
			SELECT TOP 1 i.InterestRate, i.InterestRate1
			FROM #CalculateInterestRate i
			WHERE i.BizDocId = a.BizDocId AND i.EffectiveDate <= a.Date1
			ORDER BY i.EffectiveDate DESC
		) tb

	UPDATE #CalculateInterest SET InterestAmount = OriginalClosingAmount * InterestRate * NumberOfDaysInterest / IIF(ISNULL(DaysOfYear, 0) = 0, 365, DaysOfYear)

	DECLARE @_OriginalClosingAmount NUMERIC(18, 2), @_BizDocId VARCHAR(16), @_DecreaseDate DATE, @_OriginalDecreaseAmount NUMERIC(18, 2)

	IF @_LCType = '0'
	BEGIN
		-- Phát sinh giảm
		DROP TABLE IF EXISTS #Decrease

		;WITH Cte AS
		(
			SELECT a.DocDate, a.BizDocId, IIF(@_LCType = '1', a.OriginalDebitAmount, a.OriginalCreditAmount) AS DecreaseAmount
			FROM #K_CtTmp0 a
				INNER JOIN #BizDoc_Contract LC ON a.BizDocId = LC.BizDocId AND a.Account LIKE LC.Account + '%'
			WHERE IIF(@_LCType = '1', a.DebitAmount, a.CreditAmount) > 0
			UNION ALL
			SELECT a.DocDate, a.BizDocId, IIF(@_LCType = '1', a.OriginalDebitAmount, a.OriginalCreditAmount) AS DecreaseAmount  
			FROM #K_CtQkTmp a
				INNER JOIN #BizDoc_Contract LC ON a.BizDocId = LC.BizDocId AND a.Account LIKE LC.Account + '%'
			WHERE IIF(@_LCType = '1', a.DebitAmount, a.CreditAmount) > 0
		)
		SELECT DocDate, BizDocId, SUM(DecreaseAmount) AS DecreaseAmount
		INTO #Decrease
		FROM Cte
		GROUP BY DocDate, BizDocId

		DROP TABLE IF EXISTS #ContractDecrease
		SELECT a.BizDocId 
		INTO #ContractDecrease
		FROM #Decrease a
			INNER JOIN #BizDoc_Contract c ON a.BizDocId = c.BizDocId
		WHERE a.DocDate < c.DueDate_TT
		GROUP BY a.BizDocId

		WHILE EXISTS (SELECT * FROM #ContractDecrease)
		BEGIN
		    SELECT TOP 1 @_BizDocId = BizDocId
			FROM #ContractDecrease

			DELETE #ContractDecrease WHERE BizDocId = @_BizDocId

			WHILE EXISTS (SELECT * FROM #Decrease WHERE BizDocId = @_BizDocId)
			BEGIN
			    SELECT TOP 1 @_DecreaseDate = DocDate, @_OriginalDecreaseAmount = ISNULL(DecreaseAmount, 0)
				FROM #Decrease
				WHERE BizDocId = @_BizDocId
				ORDER BY DocDate

				DELETE #Decrease WHERE BizDocId = @_BizDocId AND DocDate = @_DecreaseDate

				UPDATE #CalculateInterest SET ClosingAmountDecrease = 
					IIF(ClosingAmountDecrease + @_OriginalDecreaseAmount > OriginalClosingAmount, OriginalClosingAmount, ClosingAmountDecrease + @_OriginalDecreaseAmount)
				WHERE Date2 < @_DecreaseDate AND BizDocId = @_BizDocId
			END
		END

		UPDATE #CalculateInterest SET
			InterestAmount1 = tb.ClosingAmountDecrease * tb.InterestRate * tb.NumberOfDaysInterest / IIF(ISNULL(tb.DaysOfYear, 0) = 0, 365, tb.DaysOfYear),
			InterestAmount2 = tb.ClosingAmountDecrease * tb.InterestRate1 * tb.NumberOfDaysInterest / IIF(ISNULL(tb.DaysOfYear, 0) = 0, 365, tb.DaysOfYear),
			OriginalDecreaseAmountBeforeDue = tb.ClosingAmountDecrease
		FROM #CalculateInterest tb
			INNER JOIN #BizDoc_Contract c ON tb.BizDocId = c.BizDocId
		WHERE tb.Date2 < c.DueDate_TT

		IF ISNULL(@_GrossInterest, 0) = 1
			WITH Cte AS
            (
				SELECT a.BizDocId, SUM(a.InterestAmount - a.InterestAmount1 + a.InterestAmount2) AS GrossInterest
				FROM #CalculateInterest a
					INNER JOIN #BizDoc_Contract b ON a.BizDocId = b.BizDocId
				WHERE a.Date1 < b.DueDate_Tt
				GROUP BY a.BizDocId
			)
			UPDATE #CalculateInterest SET OriginalIncreaseAmount = a.OriginalIncreaseAmount + Cte.GrossInterest
			FROM #CalculateInterest a
				INNER JOIN #BizDoc_Contract b ON a.BizDocId = b.BizDocId
				INNER JOIN Cte ON Cte.BizDocId = a.BizDocId
			WHERE a.Date1 = b.DueDate_Tt AND a.OriginalClosingAmount <> 0

		SELECT @_OriginalClosingAmount = 0

		-- 03/12/2025 TT99 VũLA xử lý lấy dữ liệu sang TMBCTC
		UPDATE #CalculateInterest SET 
			@_OriginalClosingAmount = OriginalClosingAmount = IIF(IsOpening = 1, OriginalOpeningAmount, ISNULL(@_OriginalClosingAmount, 0)) + OriginalIncreaseAmount - OriginalDecreaseAmount

		UPDATE #CalculateInterest SET OriginalOpeningAmount = a.OriginalClosingAmount + a.OriginalDecreaseAmount - a.OriginalIncreaseAmount,
			InterestAmount = a.OriginalClosingAmount * a.InterestRate * a.NumberOfDaysInterest / IIF(ISNULL(a.DaysOfYear, 0) = 0, 365, a.DaysOfYear)
		FROM #CalculateInterest a
			INNER JOIN #BizDoc_Contract b ON a.BizDocId = b.BizDocId
		WHERE a.Date1 >= b.DueDate_Tt
	END

	IF ISNULL(@_TableName, '') <> ''
	    EXECUTE dbo.usp_sys_Append
			@_TableSource = '#CalculateInterest',
	        @_TableDestination = @_TableName

	DROP TABLE IF EXISTS #CalculateInterest
	DROP TABLE IF EXISTS #CalculateInterestRate
	DROP TABLE IF EXISTS #Contact_Incurred
	DROP TABLE IF EXISTS #Contact_Opening
END
GO


SET DATEFORMAT DMY;
EXEC usp_Kth_DetailLoanInterest_test @_DocDate1 = '01/01/2026 00:00:00.000'
                              , @_DocDate2 = '14/10/2026 00:00:00.000'
                              , @_BizDocId_LC = 'I112229602LC'
                              , @_LCType = '1'
                              , @_nUserId = 1213
                              , @_LangId = 0
                              , @_CurrencyCode0 = 'VND'
                              , @_CurrencyCode = 'VND'
                              , @_BranchCode = 'I25';