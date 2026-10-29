SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Coder: VuLA

-- =============================================
-- Author:		MinhNH
-- Create date: 23 Aug 2017
-- Description:	Update Last-transacted asset info
-- =============================================
ALTER PROCEDURE [dbo].[usp_B30AssetDoc_AssetInfo_UpdateData]
	@_DocDate2 DATE	= 'Jan 31 2006',
	@_CtTmp	VARCHAR(32)	= '',
	@_BranchCode VARCHAR(3) = '',
	@_nUserId INT = 0,
	@_LangId INT = 0,
	@_Debug TINYINT	= 0
AS
BEGIN
	SET NOCOUNT ON;

	IF ISNULL(@_CtTmp, '') = ''
		RETURN

	IF NOT EXISTS(SELECT name FROM tempdb.sys.columns WITH (NOLOCK)
		WHERE object_id = OBJECT_ID(N'TempDb..' + @_CtTmp) AND Name IN ('AssetId', 'EquityId'))
	BEGIN
		PRINT N'Insufficient columns'
		RETURN
	END
	
	DECLARE @_DataCode_Branch VARCHAR(8)
	SELECT TOP 1 @_DataCode_Branch = DataCode FROM B00Branch WHERE BranchCode = @_BranchCode;
	SET @_DataCode_Branch = ISNULL(@_DataCode_Branch, '0')

	DECLARE @_ColList VARCHAR(MAX), @_Col VARCHAR(24), @_Str NVARCHAR(MAX), @_IsNullable BIT 
	
	SET @_DocDate2 = EOMONTH(@_DocDate2)
	
	DROP TABLE IF EXISTS #Cols
	CREATE TABLE #Cols(Name VARCHAR(48), IsNullable BIT)
		
	INSERT INTO	#Cols (Name)
	VALUES ('DeptId'), ('EmployeeId'), ('WorkProcessId'), ('ExpenseCatgId'), 
		('CostCentreId'), ('ProductId'), ('DeprDebitAccount'), ('DeprCreditAccount'),
		-- 18/03/2024 ĐứcCM: Bổ sung các trường CustomFieldId trên các chứng từ TSCĐ
		('CustomFieldId1'), ('CustomFieldId2'), ('CustomFieldId3'),		
		('ProfitCenterId'), ('StageId'), ('RouteCode'),('TerritoryId')

	-- Xử lí update NULL với các trường Allow Nulls, '' với các trường không Allow Nulls
	UPDATE #Cols SET IsNullable = c.is_nullable
	FROM #Cols cols
		INNER JOIN tempdb.sys.columns AS c WITH (NOLOCK) ON cols.Name = c.Name AND c.object_id = OBJECT_ID(N'tempdb.dbo.' + @_CtTmp);
	
	
	
	
	WHILE EXISTS(SELECT	1 FROM #Cols)
	BEGIN
		SELECT TOP 1 @_Col = Name, @_IsNullable = IsNullable FROM #Cols

		SET @_Str = N'
			;WITH Cte AS
			(
				SELECT Ctts.AssetId
				FROM B3' + @_DataCode_Branch + N'AssetDoc ctts
					INNER JOIN ' + @_CtTmp + ' kh ON kh.AssetId = ctts.AssetId AND kh.EquityId = ctts.EquityId
				WHERE ctts.DocDate <= ''' + CONVERT(NVARCHAR, @_DocDate2, 13) + ''' AND 
					ctts.AssetTransType <> ''KHAUHAO'' AND ctts.IsActive = 1 AND ctts.DeprAllocationRate = 0 
					--AND ctts.AssetTransType IN (SELECT Code FROM dbo.B20AssetTransType WHERE Using' + @_Col + ' = 1) 
					--AND ctts.AssetTransType IN (SELECT Code FROM dbo.B20AssetTransType WHERE IsActive = 1) 
			)
			UPDATE ' + @_CtTmp + ' SET ' + @_Col + ' = ' + IIF(@_IsNullable = 1, 'ctts.' + @_Col + ' ', 'ISNULL(ctts.' + @_Col + ', '''')') + ' 
			FROM ' + @_CtTmp + ' kh
				INNER JOIN Cte ON kh.AssetId = Cte.AssetId
				OUTER APPLY (	
					SELECT TOP 1 ctts.AssetId, ctts.' + @_Col +'
					FROM B3' + @_DataCode_Branch + N'AssetDoc ctts
					WHERE kh.AssetId = ctts.AssetId AND kh.EquityId = ctts.EquityId AND 
						ctts.DocDate <= ''' + CONVERT(NVARCHAR, @_DocDate2, 13) + ''' AND 
						ctts.AssetTransType <> ''KHAUHAO'' AND ctts.IsActive = 1 AND DeprAllocationRate = 0 
						--AND ctts.AssetTransType IN ( SELECT Code FROM dbo.B20AssetTransType WHERE Using' + @_Col + ' = 1) 
						--AND ctts.AssetTransType IN ( SELECT Code FROM dbo.B20AssetTransType WHERE IsActive = 1) 
					ORDER BY DocDate DESC	
				) ctts
			' +	
			IIF(@_Col IN ('DeprDebitAccount', 'DeprCreditAccount'), 'WHERE ctts.'+ @_Col +' IS NOT NULL', '')  
		PRINT @_Str
		EXECUTE sp_executesql @_Str

		IF @_Debug = 1 PRINT @_Str

		DELETE #Cols WHERE Name = @_Col 
	END
	
	DROP TABLE IF EXISTS #Cols
END
GO
