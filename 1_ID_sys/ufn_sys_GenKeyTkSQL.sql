SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
ALTER FUNCTION dbo.ufn_sys_GenKeyTkSQL 
(
	@_AccountSide CHAR(1) = '', 
	@_Account VARCHAR(MAX) = '', 
	@_CustomerId VARCHAR(2048) = '', 
	@_CrspAccount VARCHAR(2048) = '', 
	@_CrspCustomerId VARCHAR(2048) = ''
)  
RETURNS NVARCHAR(MAX) AS
BEGIN
-- tao ra key1 cho scanfile cua b r a v o dua tren cac tham so truyen vao
	DECLARE @_KeyDebit NVARCHAR(MAX), @_KeyCredit NVARCHAR(MAX), @_Key NVARCHAR(MAX)
	SET @_KeyDebit = ''	
	SET @_KeyCredit = ''
	IF @_AccountSide = '' SET @_AccountSide = '*'

	IF @_AccountSide = 'N' OR @_AccountSide = '*'
	BEGIN
		SET @_KeyDebit = ''
		IF @_Account <> '' SET @_KeyDebit = @_KeyDebit + 
			CASE WHEN @_KeyDebit = '' THEN '(' ELSE ' AND (' END + 'DebitAccount LIKE ''' + REPLACE(@_Account, ',', '%'' OR DebitAccount LIKE ''') + '%'')'

		IF @_CustomerId <> ''
		BEGIN		 
			SET @_KeyDebit = @_KeyDebit + CASE WHEN @_KeyDebit = '' THEN '' ELSE ' AND ' END
			
			IF CHARINDEX(',', @_CustomerId) > 0
			BEGIN
				SET @_KeyDebit = @_KeyDebit + 
					'CustomerId IN (SELECT Id FROM [dbo].[ufn_sys_GetIdList](''' + @_CustomerId + ''',''B20Customer''))'	
			END ELSE
			IF EXISTS(SELECT * FROM dbo.B20Customer WHERE Id = @_CustomerId)
			BEGIN
				IF EXISTS(SELECT * FROM dbo.B20Customer WHERE Id = @_CustomerId AND isGroup = 0)
					SET @_KeyDebit = @_KeyDebit + '(CustomerId = ' + @_CustomerId + ')'
				ELSE
					SET @_KeyDebit = @_KeyDebit + 
						'CustomerId IN (SELECT Id FROM [dbo].[ufn_sys_GetIdList](''' + @_CustomerId + ''',''B20Customer''))'
			END ELSE
				SET @_KeyDebit = @_KeyDebit + '(0=1)'
		END						 

		IF @_CrspAccount <> '' SET @_KeyDebit = @_KeyDebit + CASE WHEN @_KeyDebit = '' THEN '(' ELSE ' AND (' END + 'CreditAccount LIKE ''' + REPLACE(@_CrspAccount, ',', '%'' OR CreditAccount LIKE ''')  + '%'')'

		IF @_CrspCustomerId <> ''
		BEGIN		 
			SET @_KeyDebit = @_KeyDebit + CASE WHEN @_KeyDebit = '' THEN '' ELSE ' AND ' END
		 
		 	IF CHARINDEX(',', @_CrspCustomerId) > 0
			BEGIN
				SET @_KeyDebit = @_KeyDebit + 
					'CrspCustomerId IN (SELECT Id FROM [dbo].[ufn_sys_GetIdList](''' + @_CrspCustomerId + ''',''B20Customer''))'	
			END ELSE
			IF EXISTS(SELECT * FROM dbo.B20Customer WHERE Id = @_CrspCustomerId)
			BEGIN
				IF EXISTS(SELECT * FROM dbo.B20Customer WHERE Id = @_CrspCustomerId AND isGroup = 0)
					SET @_KeyDebit = @_KeyDebit + '(CrspCustomerId = ' + @_CrspCustomerId + ')'
				ELSE
					SET @_KeyDebit = @_KeyDebit + 
						'CrspCustomerId IN (SELECT Id FROM [dbo].[ufn_sys_GetIdList](''' + @_CrspCustomerId + ''',''B20Customer''))'
			END ELSE 
				SET @_KeyDebit = @_KeyDebit + '(0=1)'
		END

		IF @_KeyDebit <> ''	SET @_KeyDebit = '(' + @_KeyDebit + ')'
	END
	IF @_AccountSide = 'C' OR @_AccountSide = '*'
	BEGIN
		SET @_KeyCredit = ''
		IF @_Account <> '' SET @_KeyCredit = @_KeyCredit + CASE WHEN @_KeyCredit = '' THEN '(' ELSE ' AND (' END + 'CreditAccount LIKE ''' + REPLACE(@_Account, ',', '%'' OR CreditAccount LIKE ''') + '%'')'

		IF @_CustomerId <> ''
		BEGIN		 
			SET @_KeyCredit = @_KeyCredit + CASE WHEN @_KeyCredit = '' THEN '' ELSE ' AND ' END

			IF CHARINDEX(',', @_CustomerId) > 0
			BEGIN
				SET @_KeyCredit = @_KeyCredit + 
					'CustomerId IN (SELECT Id FROM [dbo].[ufn_sys_GetIdList](''' + @_CustomerId + ''',''B20Customer''))'	
			END ELSE		 
			IF EXISTS(SELECT * FROM dbo.B20Customer WHERE Id = @_CustomerId)
			BEGIN
				IF EXISTS(SELECT * FROM dbo.B20Customer WHERE Id = @_CustomerId AND isGroup = 0)
					SET @_KeyCredit = @_KeyCredit + '(CustomerId = ' + @_CustomerId + ')'
				ELSE
					SET @_KeyCredit = @_KeyCredit + 
						'CustomerId IN (SELECT Id FROM [dbo].[ufn_sys_GetIdList](''' + @_CustomerId + ''',''B20Customer''))'
			END ELSE 
				SET @_KeyCredit = @_KeyCredit + '(0=1)'
		END		
				 
		IF @_CrspAccount <> '' SET @_KeyCredit = @_KeyCredit + CASE WHEN @_KeyCredit = '' THEN '(' ELSE ' AND (' END + 'DebitAccount LIKE ''' + REPLACE(@_CrspAccount, ',', '%'' OR DebitAccount LIKE ''') + '%'')'

		IF @_CrspCustomerId <> ''
		BEGIN		 
			SET @_KeyCredit = @_KeyCredit + CASE WHEN @_KeyCredit = '' THEN '' ELSE ' AND ' END

			IF CHARINDEX(',', @_CrspCustomerId) > 0
			BEGIN
				SET @_KeyCredit = @_KeyCredit + 
					'CrspCustomerId IN (SELECT Id FROM [dbo].[ufn_sys_GetIdList](''' + @_CrspCustomerId + ''',''B20Customer''))'	
			END ELSE		 
			IF EXISTS(SELECT * FROM dbo.B20Customer WHERE Id = @_CrspCustomerId)
			BEGIN
				IF EXISTS(SELECT * FROM dbo.B20Customer WHERE Id = @_CrspCustomerId AND isGroup = 0)
					SET @_KeyCredit = @_KeyCredit + '(CrspCustomerId = ' + @_CrspCustomerId + ')'
				ELSE
					SET @_KeyCredit = @_KeyCredit + 
						'CrspCustomerId IN (SELECT Id FROM [dbo].[ufn_sys_GetIdList](''' + @_CrspCustomerId + ''',''B20Customer''))'
			END ELSE 
				SET @_KeyCredit = @_KeyCredit + '(0=1)'
		END
				 
		IF @_KeyCredit <> ''	SET @_KeyCredit = '(' + @_KeyCredit + ')'
	END

	IF @_AccountSide = '*'
	BEGIN
		IF @_KeyDebit = '' AND @_KeyCredit = ''
			SET @_Key = ''
		ELSE IF @_KeyDebit = '' OR @_KeyCredit = ''
			SET @_Key = '(' + @_KeyDebit + @_KeyCredit + ')]'
		ELSE
			SET @_Key = '((' + @_KeyDebit + ') OR (' + @_KeyCredit + '))'
	END
	ELSE
	BEGIN
		IF @_AccountSide = 'N' AND @_KeyDebit <> ''
			SET @_Key = '(' + @_KeyDebit + ')'
		ELSE IF @_AccountSide = 'C' AND @_KeyCredit <> ''
			SET @_Key = '(' + @_KeyCredit + ')'
		ELSE
			SET @_Key = ''
	END

	RETURN @_Key
END







GO

