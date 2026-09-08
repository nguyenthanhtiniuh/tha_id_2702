SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Coder: AnhPK

-- ============================================
-- Description: Thuy?t minh báo cáo tài chính (H?p nh?t)
-- ============================================
ALTER   PROCEDURE dbo.usp_Kqt_FinancialStatementsNote_TT99_HopNhat
	@_DocDate1 DATE = '240101',
	@_DocDate2 DATE = '240831',
	@_DocDate01 DATE = 'Jan 01 2015',-- k? tr??c
	@_DocDate02 DATE = 'Dec 31 2015',
	@_KQTMau VARCHAR(128) = 'vB10Kqt0499_GeneralInformation',
	@_ForeignCurrencyOnly INT = 1,
	@_nUserId INT = 0,
	@_LangId INT = 0,
	@_BranchCode VARCHAR(3) = 'I01',
	@_CurrencyCode0 CHAR(3) = 'VND',
	@_LAYOUT_XML NVARCHAR(MAX) = N'' OUTPUT
AS
BEGIN 
	SET NOCOUNT ON;
	-- T? ??ng l?y thông tin theo AppName khi th?c hi?n trong ch??ng trình, không theo tham s? truy?n vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	
	DECLARE @_LAYOUT_XML2 nvarchar(MAX) = '', @_KeyCd NVARCHAR(MAX) = '',@_AccountList NVARCHAR(4000)='', @_StrExec NVARCHAR(MAX)='', @_DataCode NVARCHAR(24)=''

	SELECT @_DataCode = DataCode FROM B00Branch WHERE BranchCode = @_BranchCode

	SELECT @_AccountList = STRING_AGG(a.Account, ',')
	FROM (
		SELECT DISTINCT Account
		FROM B10KqtConsol
		WHERE ISNULL(Account, '') <> ''
	) a

	IF ISNULL(@_AccountList, '') <> ''
	BEGIN
		SET @_KeyCd = @_KeyCd + N' AND (Account LIKE ''' + REPLACE(@_AccountList, ',', '%'') OR (Account LIKE ''') + '%'')'
	END
	
	IF @_KeyCd <> N'' SET @_KeyCd = SUBSTRING(@_KeyCd, 6, LEN(@_KeyCd) - 5)
 
	DROP TABLE IF EXISTS #SoDu001
	SELECT Account, CrspAccount,CustomerId,ExpenseCatgId,
		DebitAmount AS DebitBal1, CreditAmount AS CreditBal1
	INTO #SoDu001
	FROM B00CtTmp
	
	EXECUTE dbo.usp_sys_DefaultTable '#SoDu001'
 
	DROP TABLE IF EXISTS #SoDu002
	SELECT TOP 0 * INTO #SoDu002 FROM #SoDu001

	DROP TABLE IF EXISTS #SoDu01
	SELECT TOP 0 * INTO #SoDu01 FROM #SoDu001

	DROP TABLE IF EXISTS #SoDu02
	SELECT TOP 0 * INTO #SoDu02 FROM #SoDu001
	
	EXECUTE dbo.usp_B30OpenBalance_GetData
		@_DocDate0 = @_DocDate01, 
		@_Key = '', 
		@_CtTmp = N'#SoDu001',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode, 
		@_CurrencyCode0 = @_CurrencyCode0,
		@_Opening = 0,			
		@_Accumulate = 0,		
		@_AutoCalculate = 1, 	
		@_GroupByColumnList = 'Account,CrspAccount,CustomerId,ExpenseCatgId'
		
	EXECUTE usp_B30OpenBalance_GetEndOfDayBalance
		@_DocDate0 = @_DocDate02,
		@_Key = '',
		@_CtTmp = '#SoDu002',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_Opening = 0,			
		@_Accumulate = 0,		
		@_AutoCalculate = 1, 	
		@_GroupByColumnList = ''

	EXECUTE usp_B30OpenBalance_GetData
		@_DocDate0 = @_DocDate1,
		@_Key = N'',
		@_CtTmp = N'#SoDu01',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_Opening = 0,			
		@_Accumulate = 0,		
		@_AutoCalculate = 1, 	
		@_GroupByColumnList = ''
	
	EXECUTE usp_B30OpenBalance_GetEndOfDayBalance
		@_DocDate0 = @_DocDate2,
		@_Key = N'',
		@_CtTmp = N'#SoDu02',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_Opening = 0,			
		@_Accumulate = 0,		
		@_AutoCalculate = 1, 	
		@_GroupByColumnList = ''
	
		-- Lay so phat sinh trong ky
	DROP TABLE IF EXISTS #Tmp1
	SELECT TOP 0 DocDate,
		Account,CustomerId,ExpenseCatgId, CrspAccount, DebitAmount, CreditAmount
		
	INTO #Tmp1
	FROM B00CtTmp

	DROP TABLE IF EXISTS #Tmp2
	SELECT TOP 0 *
	INTO #Tmp2
	FROM #Tmp1	

	--PS trong k? 
	EXECUTE usp_B30GeneralLedger_GetData
		@_DocDate1 = @_DocDate1,
		@_DocDate2 = @_DocDate2,
		@_Key1 = '',
		@_Key2 = '',
		@_CtTmp = '#Tmp1',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_GroupByCols = 'Account,CrspAccount,CustomerId,ExpenseCatgId'
		
	-- PS k? tr??c
	EXECUTE usp_B30GeneralLedger_GetData
		@_DocDate1 = @_DocDate01,
		@_DocDate2 = @_DocDate02,
		@_Key1 = N'',
		@_Key2 = N'',
		@_CtTmp = N'#Tmp2',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_GroupByCols = 'Account,CrspAccount,CustomerId,ExpenseCatgId'
 
	-- D? ??u d? cu?i k? này k? tr??c, PS trong k?

	DROP TABLE IF EXISTS #K_CdTmp1
	;WITH Cte
	AS(
		SELECT  Account,CrspAccount,CustomerId,ExpenseCatgId,
			SUM(DebitBal1) AS DebitBal01, 
			SUM(CreditBal1) AS CreditBal01,
			0 AS DebitBal02,0 AS CreditBal02,
			0 AS DebitBal1, 0 AS CreditBal1,
			0 AS DebitBal2, 0 AS CreditBal2,
			0 AS DebitAmount, 0 AS CreditAmount,
			0 AS DebitAmount0, 0 AS CreditAmount0
		FROM #SoDu001
		GROUP BY Account,CrspAccount,CustomerId,ExpenseCatgId
		UNION ALL
		SELECT  Account,CrspAccount,CustomerId,ExpenseCatgId,
			0 AS DebitBal01,0 AS CreditBal01,
			SUM(DebitBal1) AS DebitBal02, 
			SUM(CreditBal1) AS CreditBal02,
			0 AS DebitBal1, 0 AS CreditBal1,
			0 AS DebitBal2, 0 AS CreditBal2,
			0 AS DebitAmount, 0 AS CreditAmount,
			0 AS DebitAmount0, 0 AS CreditAmount0
		FROM #SoDu002
		GROUP BY Account,CrspAccount,CustomerId,ExpenseCatgId
		UNION ALL
		SELECT  Account,CrspAccount,CustomerId,ExpenseCatgId,
			0 AS DebitBal01,0 AS CreditBal01,
			0 AS DebitBal02,0 AS CreditBal02,
			SUM(DebitBal1) AS DebitBal1, 
			SUM(CreditBal1) AS CreditBal1,
			0 AS DebitBal2, 0 AS CreditBal2,
			0 AS DebitAmount, 0 AS CreditAmount,
			0 AS DebitAmount0, 0 AS CreditAmount0
		FROM #SoDu01
		GROUP BY Account,CrspAccount,CustomerId,ExpenseCatgId
		UNION ALL
		SELECT  Account,CrspAccount,CustomerId,ExpenseCatgId,
			0 AS DebitBal01,0 AS CreditBal01,
			0 AS DebitBal02,0 AS CreditBal02,
			0 AS DebitBal1, 0 AS CreditBal1,
			SUM(DebitBal1) AS DebitBal2, 
			SUM(CreditBal1) AS CreditBal2,
			0 AS DebitAmount, 0 AS CreditAmount,
			0 AS DebitAmount0, 0 AS CreditAmount0
		FROM #SoDu02
		GROUP BY Account,CrspAccount,CustomerId,ExpenseCatgId
		UNION ALL
		SELECT  Account,CrspAccount,CustomerId, ExpenseCatgId,
			0 AS DebitBal01, 0 AS CreditBal01,
			0 AS DebitBal02, 0 AS CreditBal02,
			0 AS DebitBal1, 0 AS CreditBal1,
			0 AS DebitBal2, 0 AS CreditBal2,
			SUM(DebitAmount) AS DebitAmount,
			SUM(CreditAmount) AS CreditAmount,
			0 AS DebitAmount0, 	0 AS CreditAmount0
		FROM #Tmp1
		GROUP BY Account,CrspAccount,CustomerId,ExpenseCatgId
		UNION ALL
		SELECT  Account,CrspAccount,CustomerId, ExpenseCatgId,
			0 AS DebitBal01, 0 AS CreditBal01,
			0 AS DebitBal02, 0 AS CreditBal02,
			0 AS DebitBal1, 0 AS CreditBal1,
			0 AS DebitBal2, 0 AS CreditBal2,
			0 AS DebitAmount,0 AS CreditAmount,
			SUM(DebitAmount) AS DebitAmount0, 	
			SUM(CreditAmount) AS CreditAmount0
		FROM #Tmp2
		GROUP BY Account,CrspAccount,CustomerId,ExpenseCatgId
		)
	SELECT  Account,CrspAccount,CustomerId, ExpenseCatgId,CAST('' AS NVARCHAR(24)) AS MESGroupCode,
			--K? tr??c
			----??u k?
			SUM(DebitBal01) AS DebitBal01,
			SUM(CreditBal01) AS CreditBal01,
			----Cu?i k?
			SUM(DebitBal02) AS DebitBal02,
			SUM(CreditBal02) AS CreditBal02,
			--K? này
			----??u k?
			SUM(DebitBal1) AS DebitBal1, 
			SUM(CreditBal1) AS CreditBal1,
			----Cu?i k?
			SUM(DebitBal2) AS DebitBal2, 
			SUM(CreditBal2) AS CreditBal2,
			-- Ps k? này
			SUM(DebitAmount) AS DebitAmount, 
			SUM(CreditAmount) AS CreditAmount,
			-- Ps k? tr??c
			SUM(DebitAmount0) AS DebitAmount0, 
			SUM(CreditAmount0) AS CreditAmount0
	INTO #K_CdTmp1
	FROM Cte
	GROUP BY Account,CrspAccount,CustomerId,ExpenseCatgId
 
	UPDATE a 
	SET MESGroupCode = b.MESGroupCode
	FROM #K_CdTmp1 a LEFT JOIN B20Customer b (NOLOCK) ON a.CustomerId = b.Id
 
	-- cân ??i k? toán
	-- cu?i k?
	DROP TABLE IF EXISTS #BS2
	CREATE TABLE #BS2 (Description NVARCHAR(512),ItemNo VARCHAR(64),CloseAmount NUMERIC(18,5)) 
	-- ??u k?
	DROP TABLE IF EXISTS #BS1
	CREATE TABLE #BS1 (Description NVARCHAR(512),ItemNo VARCHAR(64),CloseAmount NUMERIC(18,5)) 

	EXECUTE dbo.usp_sys_DefaultTable '#BS1'
	EXECUTE dbo.usp_sys_DefaultTable '#BS2'
	-- BSCK
	EXEC usp_Kqt_BalanceSheet_TT99 
			@_DocDate1=@_DocDate2,
			@_DocDate2=@_DocDate2,
			@_Ngay_Dau_Nam=@_DocDate2 ,
			@_LangId=@_LangId,
			@_BranchCode=@_BranchCode,
			@_CurrencyCode0=@_CurrencyCode0,
			@_DefinitionTableName='B10Kqt0199' ,
			@_CtTmp='#BS2'
	-- BSDK
	EXEC usp_Kqt_BalanceSheet_TT99 
			@_DocDate1=@_DocDate1,
			@_DocDate2=@_DocDate1,
			@_Ngay_Dau_Nam=@_DocDate1 ,
			@_LangId=@_LangId,
			@_BranchCode=@_BranchCode,
			@_CurrencyCode0=@_CurrencyCode0,
			@_DefinitionTableName='B10Kqt0199',
			@_CtTmp='#BS1'
 
	-- PL BÁO CÁO K?T QU? SXKD (THEO ?VCS) - TT99
	-- cu?i k?
	DROP TABLE IF EXISTS #PL2
	CREATE TABLE #PL2 (Description NVARCHAR(512),ItemNo VARCHAR(64),ThisPeriod  NUMERIC(18,5)) 
	-- ??u k?
	DROP TABLE IF EXISTS #PL1
	CREATE TABLE #PL1 (Description NVARCHAR(512),ItemNo VARCHAR(64),ThisPeriod NUMERIC(18,5)) 

	EXECUTE dbo.usp_sys_DefaultTable '#PL1'
	EXECUTE dbo.usp_sys_DefaultTable '#PL2'
	-- PLCK
	SET DATEFORMAT DMY
	EXEC usp_Kqt_ProfitAndLossStatement_TT99 
		@_DocDate1=@_DocDate1,
		@_DocDate2=@_DocDate2,
		@_ForeignCurrencyOnly=@_ForeignCurrencyOnly,
		@_nUserId=@_nUserId,
		@_LangId=@_LangId,
		@_BranchCode=@_BranchCode,
		@_DefinitionTableName='B10Kqt02199',
		@_SourceTable='B10Kqt02199',
		@_HTKK_Exp=0,
		@_CtTmp='#PL2'
 
	-- PLDK
	EXEC usp_Kqt_ProfitAndLossStatement_TT99 
		@_DocDate1=@_DocDate1,
		@_DocDate2=@_DocDate2,
		@_ForeignCurrencyOnly=@_ForeignCurrencyOnly,
		@_nUserId=@_nUserId,
		@_LangId=@_LangId,
		@_BranchCode=@_BranchCode,
		@_DefinitionTableName='B10Kqt02199',
		@_SourceTable='B10Kqt02199',
		@_HTKK_Exp=0,
		@_CtTmp='#PL1'

	-- B?ng t?ng h?p tài s?n 
	DROP TABLE IF EXISTS #Asset
	CREATE TABLE #Asset (AssetId INT, AssetCode NVARCHAR(24),
		OriginalCost1 NUMERIC(18,5), Depreciation1 NUMERIC(18,5),
		IncreaseOriginalCost NUMERIC(18,5),IncreaseDepreciation NUMERIC(18,5),DecreaseOriginalCost NUMERIC(18,5),DecreaseDepreciation NUMERIC(18,5),
		OriginalCost2 NUMERIC(18,5),Depreciation2 NUMERIC(18,5),AssetTransCode NVARCHAR(24)) 

	EXEC usp_Tth_AssetSummaryTable
			@_DocDate1=@_DocDate1,
			@_DocDate2=@_DocDate2,
			@_GroupByExprs='AssetId',
			@_BranchCode=@_BranchCode, 
			@_nUserId=@_nUserId ,
			@_LangId =@_LangId,
			@_CurrencyCode0=@_CurrencyCode0,
			@_CtTmp = '#Asset'

	ALTER TABLE #Asset ADD ParentAssetId INT
	SET @_StrExec =' UPDATE #Asset SET ParentAssetId = b.ParentId FROM #Asset a INNER JOIN B2'+@_DataCode+'Asset b ON a.AssetId = b.Id'
	EXEC (@_StrExec)

	-- D? li?u 2025	
	DROP TABLE IF EXISTS #Data2025
	CREATE TABLE #Data2025 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24),CriteriaOnReport NVARCHAR(128),
			Amount25_01 NUMERIC(18,5), Amount25_02  NUMERIC(18,5),Amount25_03 NUMERIC(18,5), Amount25_04  NUMERIC(18,5),Amount25_05 NUMERIC(18,5), 
			Amount25_06  NUMERIC(18,5), Amount25_07 NUMERIC(18,5), Amount25_08  NUMERIC(18,5),Amount25_09 NUMERIC(18,5),Amount25_10 NUMERIC(18,5))
	
	EXECUTE dbo.usp_sys_DefaultTable '#Data2025'

	IF (YEAR(@_DocDate01)=2025 OR YEAR(@_DocDate02)=2025)
	BEGIN
		INSERT INTO #Data2025 (Id, Stt, ItemNo, CriteriaOnReport,Amount25_01 ,Amount25_02 ,Amount25_03, Amount25_04, Amount25_05, 
				Amount25_06, Amount25_07 , Amount25_08 ,Amount25_09 ,Amount25_10)
		SELECT Id, Stt, ItemNo, CriteriaOnReport, Amount25_01 ,Amount25_02 ,Amount25_03, Amount25_04, Amount25_05, 
				Amount25_06, Amount25_07 , Amount25_08 ,Amount25_09 ,Amount25_10
		FROM B10KqtConsol WHERE IsActive =1 AND CriteriaOnReport ='2025'
	END

	--==============
	-- Rep 01
	DROP TABLE IF EXISTS #KqtConsol01
	CREATE TABLE #KqtConsol01 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol01'

	INSERT INTO #KqtConsol01 (Id ,Stt, ItemNo, Account, Formula, Loai_PS,_FormatStyleKey,ItemLevel, IsPrint,ReportGroup, CriteriaOnReport, Description, OpenBalance, CloseBalance)
	SELECT Id ,Stt, ItemNo,Account, Formula, Loai_PS,_FormatStyleKey,ItemLevel,IsPrint,ReportGroup, CriteriaOnReport, Description, 0 AS OpenBalance, 0 AS CloseBalance
	FROM B10KqtConsol
	WHERE IsActive =1 AND  ReportGroup ='01' AND IsPrint =1

	-- Rep 02
	-- 1. Ti?n
	-- Lay so du dau tai khoan
	DROP TABLE IF EXISTS #KqtConsol02
	CREATE TABLE #KqtConsol02 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol02'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep02
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
	
	-- Rep03 Ph?i thu ng?n h?n
	DROP TABLE IF EXISTS #KqtConsol03
	CREATE TABLE #KqtConsol03 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),MESGroupCode NVARCHAR(24),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol03'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep03
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep04 16. Chi ti?t tình hình t?ng gi?m d? phòng ph?i thu ng?n h?n khó ?òi
	DROP TABLE IF EXISTS #KqtConsol04
	CREATE TABLE #KqtConsol04 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol04'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep04
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep05 17. ??u t? n?m gi? ??n ngày ?áo h?n
	DROP TABLE IF EXISTS #KqtConsol05
	CREATE TABLE #KqtConsol05 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24),CustomerId INT)
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol05'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep05
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
		
	-- Rep06 18. Tr? tr??c cho ng??i bán ng?n h?n
	DROP TABLE IF EXISTS #KqtConsol06
	CREATE TABLE #KqtConsol06 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol06'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep06
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep07 19. Ph?i thu khác
	DROP TABLE IF EXISTS #KqtConsol07
	CREATE TABLE #KqtConsol07 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol07'

	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep07
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
	
	-- Rep08 20. Hàng t?n kho
	DROP TABLE IF EXISTS #KqtConsol08
	CREATE TABLE #KqtConsol08 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			ProvisionAccount NVARCHAR(4000), ProvisionItemType NVARCHAR(128),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),OpenBalance1 NUMERIC(18,5), CloseBalance1 NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol08'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep08
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
		
	-- Rep09 21.Chi ti?t tình hình t?ng (gi?m) d? phòng gi?m giá hàng t?n kho
	DROP TABLE IF EXISTS #KqtConsol09
	CREATE TABLE #KqtConsol09 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64), Description NVARCHAR(4000), 
			OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol09'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep09
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep10 22. Tài s?n c? ??nh
	DROP TABLE IF EXISTS #KqtConsol10
	CREATE TABLE #KqtConsol10 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			Col01 VARCHAR(128),Col02 VARCHAR(128),Col03 VARCHAR(128),Col04 VARCHAR(128),Col05 VARCHAR(128),
			Col06 VARCHAR(128),Col07 VARCHAR(128),Col08 VARCHAR(128),Col09 VARCHAR(128),Col10 VARCHAR(128),
			Amount01 NUMERIC(18,5),Amount02 NUMERIC(18,5),Amount03 NUMERIC(18,5),Amount04 NUMERIC(18,5),Amount05 NUMERIC(18,5),
			Amount06 NUMERIC(18,5),Amount07 NUMERIC(18,5),Amount08 NUMERIC(18,5),Amount09 NUMERIC(18,5),Amount10 NUMERIC(18,5),AmountTT NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol10'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep10
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0	
	
	---- Rep11 23.B?t ??ng s?n ??u t?
	--DROP TABLE IF EXISTS #KqtConsol11
	--CREATE TABLE #KqtConsol11 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
	--		Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
	--		Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
	--		Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
	--		_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	
	--EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep11
	--	@_DocDate1  = @_DocDate1,
	--	@_DocDate2  = @_DocDate2,
	--	@_DocDate01  = @_DocDate01,
	--	@_DocDate02  = @_DocDate02,
	--	@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
	--	@_nUserId  = @_nUserId,
	--	@_LangId  = @_LangId,
	--	@_BranchCode  = @_BranchCode,
	--	@_CurrencyCode0  = @_CurrencyCode0
	
	-- Rep12 24. Chi phí ?i vay ???c v?n hóa
	DROP TABLE IF EXISTS #KqtConsol12
	CREATE TABLE #KqtConsol12 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol12'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep12
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
	
	-- Rep13 25. Chi phí xây d?ng c? b?n d? dang
	DROP TABLE IF EXISTS #KqtConsol13
	CREATE TABLE #KqtConsol13 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol13'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep13
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
		
	-- Rep14 26. Chi phí ch? phân b?
	DROP TABLE IF EXISTS #KqtConsol14
	CREATE TABLE #KqtConsol14 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol14'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep14
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep15 27. ??u t? tài chính dài h?n
	DROP TABLE IF EXISTS #KqtConsol15
	CREATE TABLE #KqtConsol15 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol15'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep15
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
		
	-- Rep16 28. L?i th? th??ng m?i
	DROP TABLE IF EXISTS #KqtConsol16
	CREATE TABLE #KqtConsol16 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol16'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep16
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep17 29. Ph?i tr? ng??i bán ng?n h?n
	DROP TABLE IF EXISTS #KqtConsol17
	CREATE TABLE #KqtConsol17 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol17'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep17
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
	
	-- Rep18 30. Ng??i mua tr? tr??c ng?n h?n
	DROP TABLE IF EXISTS #KqtConsol18
	CREATE TABLE #KqtConsol18 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol18'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep18
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep19 31. Ph?i tr? v? c? t?c, l?i nhu?n
	DROP TABLE IF EXISTS #KqtConsol19
	CREATE TABLE #KqtConsol19 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol19'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep19
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
	
	-- Rep20 32. Thu? và các kho?n ph?i n?p nhà n??c
	DROP TABLE IF EXISTS #KqtConsol20
	CREATE TABLE #KqtConsol20 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),DebitBalance NUMERIC(18,5), CreditBalance NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol20'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep20
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep21 33. Chi phí tr? tr??c ng?n h?n
	DROP TABLE IF EXISTS #KqtConsol21
	CREATE TABLE #KqtConsol21 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24),)
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol21'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep21
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
		
	-- Rep22 34. Ph?i tr? khác
	DROP TABLE IF EXISTS #KqtConsol22
	CREATE TABLE #KqtConsol22 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol22'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep22
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep23 35. Vay
	DROP TABLE IF EXISTS #KqtConsol23
	CREATE TABLE #KqtConsol23 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol23'
		
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep23
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
		
	-- Rep24 36. D? phòng ph?i tr?
	DROP TABLE IF EXISTS #KqtConsol24
	CREATE TABLE #KqtConsol24 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol24'
		
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep24
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
	
	-- Rep25 37. L?i ích c? ?ông không ki?m soát
	DROP TABLE IF EXISTS #KqtConsol25
	CREATE TABLE #KqtConsol25 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol25'
		
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep25
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep26 38. V?n ch? s? h?u
	DROP TABLE IF EXISTS #KqtConsol26
	CREATE TABLE #KqtConsol26 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			Col01 VARCHAR(128),Col02 VARCHAR(128),Col03 VARCHAR(128),Col04 VARCHAR(128),Col05 VARCHAR(128),
			Col06 VARCHAR(128),Col07 VARCHAR(128),Col08 VARCHAR(128),Col09 VARCHAR(128),Col10 VARCHAR(128),
			Amount01 NUMERIC(18,5),Amount02 NUMERIC(18,5),Amount03 NUMERIC(18,5),Amount04 NUMERIC(18,5),Amount05 NUMERIC(18,5),
			Amount06 NUMERIC(18,5),Amount07 NUMERIC(18,5),Amount08 NUMERIC(18,5),Amount09 NUMERIC(18,5),Amount10 NUMERIC(18,5),AmountTT NUMERIC(18,5),
			PercentAmount NUMERIC(18,5), Amount NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24),CustomerId INT)
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol26'
		
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep26
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep27 38. V?n ch? s? h?u
	DROP TABLE IF EXISTS #KqtConsol27
	CREATE TABLE #KqtConsol27 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol27'
 
	--EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep27
	--	@_DocDate1  = @_DocDate1,
	--	@_DocDate2  = @_DocDate2,
	--	@_DocDate01  = @_DocDate01,
	--	@_DocDate02  = @_DocDate02,
	--	@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
	--	@_nUserId  = @_nUserId,
	--	@_LangId  = @_LangId,
	--	@_BranchCode  = @_BranchCode,
	--	@_CurrencyCode0  = @_CurrencyCode0
 
	-- Rep28 39. L?i ích c? ?ông góp v?n
	DROP TABLE IF EXISTS #KqtConsol28
	CREATE TABLE #KqtConsol28 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol28'
 
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep28
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
 
	-- Rep29 40. Doanh thu
	DROP TABLE IF EXISTS #KqtConsol29
	CREATE TABLE #KqtConsol29 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol29'
 
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep29
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
 
	-- Rep30 41. Giá v?n
	DROP TABLE IF EXISTS #KqtConsol30
	CREATE TABLE #KqtConsol30 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000),  OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol30'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep30
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
 
	-- Rep31 42. Doanh thu tài chính
	DROP TABLE IF EXISTS #KqtConsol31
	CREATE TABLE #KqtConsol31 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol31'
 
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep31
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep32 43. Chi phí tài chính
	DROP TABLE IF EXISTS #KqtConsol32
	CREATE TABLE #KqtConsol32 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol32'
 
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep32
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0
 
	-- X? lý thêm cho b?ng 31,32
	DROP TABLE IF EXISTS #KqtConsol31_Tmp
	SELECT Id,IsPrint,CurrentPeriod,LastPeriod,ItemNo,Formula,ItemLevel
	INTO #KqtConsol31_Tmp
	FROM #KqtConsol31
	UNION ALL
	SELECT Id,IsPrint,CurrentPeriod,LastPeriod,ItemNo,Formula,ItemLevel
	FROM #KqtConsol32
	
	EXECUTE usp_sys_SumValue '#KqtConsol31_Tmp', N'CurrentPeriod,LastPeriod', N'ItemNo', N'Formula', N'ItemLevel'
	
	UPDATE a
	SET CurrentPeriod = b.CurrentPeriod
	FROM #KqtConsol31 a INNER JOIN #KqtConsol31_Tmp b ON a.ItemNo = b.ItemNo
	
	UPDATE a
	SET CurrentPeriod = b.CurrentPeriod
	FROM #KqtConsol32 a INNER JOIN #KqtConsol31_Tmp b ON a.ItemNo = b.ItemNo

	DROP TABLE IF EXISTS #KqtConsol31_Tmp
		-- Tong cong bao cao
	EXECUTE usp_sys_SumValue '#KqtConsol31', N'OpenBalance,CloseBalance,CurrentPeriod,LastPeriod', N'ItemNo', N'Formula', N'ItemLevel'		
	EXECUTE usp_sys_SumValue '#KqtConsol32', N'OpenBalance,CloseBalance,CurrentPeriod,LastPeriod', N'ItemNo', N'Formula', N'ItemLevel'
	
	-- Rep33 44. Chi phí bán hàng và qu?n lý doanh nghi?p
	DROP TABLE IF EXISTS #KqtConsol33
	CREATE TABLE #KqtConsol33 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), ExpenseCatgList NVARCHAR(1024),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol33'
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep33
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode	,
		@_CurrencyCode0  = @_CurrencyCode0
		
	-- Rep34 45. Thu nh?p khác và chi phí
	DROP TABLE IF EXISTS #KqtConsol34
	CREATE TABLE #KqtConsol34 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol34'
		
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep34
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep35 46. Chi phí thu? TNDN
	DROP TABLE IF EXISTS #KqtConsol35
	CREATE TABLE #KqtConsol35 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256), 
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000), OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol35'	
	
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep35
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	-- Rep36 47. Chi phí thu? TNDN hoãn l?i
	DROP TABLE IF EXISTS #KqtConsol36
	CREATE TABLE #KqtConsol36 (Id INT DEFAULT 0, Stt INT DEFAULT 0, ItemNo NVARCHAR(24), Formula NVARCHAR(256),
			Account NVARCHAR(4000),ExcludeAccount NVARCHAR(4000),ExcludeCrspAccount NVARCHAR(4000),
			Loai_PS NVARCHAR(128),CriteriaOnReport NVARCHAR(128),ItemLevel NVARCHAR(64),IsPrint TINYINT ,ReportGroup NVARCHAR(64),
			Description NVARCHAR(4000),
			Col01 VARCHAR(128),Col02 VARCHAR(128),Col03 VARCHAR(128),Col04 VARCHAR(128),Col05 VARCHAR(128),
			OpenBalance NUMERIC(18,5), CloseBalance NUMERIC(18,5),LastPeriod NUMERIC(18,5), CurrentPeriod NUMERIC(18,5),
			_FormatStyleKey NVARCHAR(256), FilterKey NVARCHAR(256),MSCode NVARCHAR(24))
	EXECUTE dbo.usp_sys_DefaultTable '#KqtConsol36'
		
	EXEC usp_Kqt_FinancialStatementsNote_TT99_DVi_Rep36
		@_DocDate1  = @_DocDate1,
		@_DocDate2  = @_DocDate2,
		@_DocDate01  = @_DocDate01,
		@_DocDate02  = @_DocDate02,
		@_ForeignCurrencyOnly  = @_ForeignCurrencyOnly,
		@_nUserId  = @_nUserId,
		@_LangId  = @_LangId,
		@_BranchCode  = @_BranchCode,
		@_CurrencyCode0  = @_CurrencyCode0

	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol01 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol02 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol03 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol04 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol05 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol06 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol07 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol08 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol09 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol10 WHERE ReportGroup = '10.1' ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol10 WHERE ReportGroup = '10.2' ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol10 WHERE ReportGroup = '10.3' ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol13 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol14 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol15 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol16 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol17 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol18 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol19 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol20 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol21 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol22 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol23 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol24 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol25 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol26 WHERE ReportGroup = '26.1'  ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol26 WHERE ReportGroup = '26.2'  ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol28 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol29 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol30 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol31 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol32 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol33 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol34 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol35 ORDER BY ItemNo
	SELECT *, Stt AS _Stt, ItemNo AS _FormulaKey, Formula AS _Formula FROM #KqtConsol36 ORDER BY ItemNo
 
	DROP TABLE #KqtConsol02,#KqtConsol03,#KqtConsol04,#KqtConsol05,#KqtConsol06,#KqtConsol07,#KqtConsol08,#KqtConsol09,#KqtConsol10
	DROP TABLE #KqtConsol12,#KqtConsol13,#KqtConsol14,#KqtConsol15, #KqtConsol16,#KqtConsol17,#KqtConsol18,#KqtConsol19,#KqtConsol20
	DROP TABLE #KqtConsol21,#KqtConsol22,#KqtConsol23,#KqtConsol24,#KqtConsol25,#KqtConsol26,#KqtConsol27,#KqtConsol28,#KqtConsol29,#KqtConsol30
	DROP TABLE #KqtConsol31,#KqtConsol32,#KqtConsol33, #KqtConsol34, #KqtConsol35,#KqtConsol36
 
END
GO



DECLARE @p11 NVARCHAR(MAX);

EXEC usp_Kqt_FinancialStatementsNote_TT99_HopNhat @_DocDate1 = '2026-02-01',
                                              @_DocDate2 = '2026-02-10',
                                              @_DocDate01 = '2026-01-01',
                                              @_DocDate02 = '2026-01-10',
                                              @_KQTMau = DEFAULT,
                                              @_ForeignCurrencyOnly = DEFAULT,
                                              @_nUserId = 1213,
                                              @_LangId = 0,
                                              @_BranchCode = 'I26',
                                              @_CurrencyCode0 = 'VND',
                                              @_LAYOUT_XML = @p11 OUTPUT;
