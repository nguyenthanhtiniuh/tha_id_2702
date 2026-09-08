SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Coder: PhanNH
-- Manager: VuLA
-- =============================================
-- Author: PhanNH	
-- Create date: 11/05/2022
-- Description:	Báo cáo Kế hoạch dòng tiền trực tiếp
-- REP_DirectCashPlan
-- =============================================
ALTER      PROC [dbo].[usp_Kqt_AnalysingDirectCashPlanByTime_test]
	@_DocDate1 DATE				= NULL,
	@_DocDate2 DATE				= NULL,	
	@_Kqt NVARCHAR(64)			= N'B10KqtCashFlowPlan',
	@_KqtCashFlowPlanId NVARCHAR(64)	= N'T000000003',
	@_SourceTable NVARCHAR(512) = N'B10KqtCashFlowPlan',
	/*1-Tháng,2-Quý,3-Năm*/
	@_Period VARCHAR(2)			= '1',
	@_BudgetTypeCode NVARCHAR(26)			= '',
	@_nUserId INT				= 0,
	@_LangId INT				= 0,
	@_BranchCode VARCHAR(3)		= N'A01',
	@_CurrencyCode0 CHAR(3)		= N'VND',
	@_TreeView TINYINT			= 0,
	@_InsertTable VARCHAR(128)	= '', 
	@_CtTmp NVARCHAR(MAX)	= '',
	@_LAYOUT_XML NVARCHAR(MAX)  = N'' OUTPUT
AS
BEGIN
SET NOCOUNT ON

	-- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)
	
	DECLARE @_Account VARCHAR(256)
			,@_CrspAccount VARCHAR(256)
			,@_ExcludeCrspAccount VARCHAR(256)
			,@_CashFlowId NVARCHAR(256)
			,@_LstAccount VARCHAR(4000) = ''
			,@_LstCashFlowId VARCHAR(4000) = ''
			,@_Loai_Ps VARCHAR(8)
			,@_Stt_Group NVARCHAR(MAX)
			,@_strExec NVARCHAR(MAX)
			,@_Id INT
			,@_ItemNo NVARCHAR(MAX)
			,@_Detail NVARCHAR(MAX)
			,@_Detail0 NVARCHAR(MAX)
			,@_IsPrint INT
			,@_tblDmName VARCHAR(64)
			,@_colCode VARCHAR(128)
			,@_colName VARCHAR(128)
			,@_colListIns VARCHAR(128)
			,@_MesGroupCode VARCHAR(24)

	DECLARE @_MoneyType AS dbo.MoneyType = 0
           ,@_TINYINTType TINYINT = 0
           ,@_INTType INT = 0
           ,@_CodeType VARCHAR(24) = ''
           ,@_NameType NVARCHAR(256) = N''

	--Tạo bảng chứa bảng khai báo công thức
	CREATE TABLE #K_BcTmp
	(
		Id INT
		,BuiltinOrder INT
	   ,KqtCashFlowPlanId NVARCHAR(16)
	   ,Stt_Group NVARCHAR(128) NULL
	   ,_GroupOrder NVARCHAR(MAX)
	   ,CashFlowId NVARCHAR(256)
	   ,CashFlowCode VARCHAR(4000)
	   ,CashFlowId_List VARCHAR(4000)
	   ,PrintOrder VARCHAR(256)
	   ,ItemNo VARCHAR(256)
			DEFAULT ''
	   ,Actual NUMERIC(20, 2)
			DEFAULT 0
	   ,Budget NUMERIC(20, 2)
			DEFAULT 0
	   ,[Percent] NUMERIC(18, 4)
			DEFAULT 0
	   ,Difference NUMERIC(20, 2)
			DEFAULT 0 ,VarValue varchar(24) default ''
	);
	EXECUTE usp_sys_CreateTable N'#K_BcTmp', @_Kqt

	DECLARE @_KeySourceTable VARCHAR(128) = ''
	SET @_KeySourceTable = ' SourceTable IN (''' + ISNULL(REPLACE(@_SourceTable,',',''','''), '') + ''')'
 
	IF @_KqtCashFlowPlanId <> ''
	SELECT @_KeySourceTable += ' AND  KqtCashFlowPlanId IN (''' + ISNULL(REPLACE(@_KqtCashFlowPlanId,',',''','''), '') + ''')'

	EXECUTE usp_sys_Append @_Kqt, N'#K_BcTmp', @_KeySourceTable
 	;
	WITH cte
	AS (
        SELECT  dbo.ufn_Get_List_CatgDetail(ca.value, 'B20CashFlow','Code') AS CashFlowCode,
                dbo.ufn_Get_List_CatgDetail(ca.value, 'B20CashFlow','Id') AS CashFlowId 
			    ,tmp.Id
		FROM #K_BcTmp AS tmp
			 CROSS APPLY
		(SELECT value FROM STRING_SPLIT(CashFlowId, ',')
		) AS ca
		WHERE ISNULL(tmp.CashFlowId,'')<>'' )
		,cte1
	AS (SELECT 
    STRING_AGG(cte.CashFlowCode, ',') AS List_CatgDetailCode
    ,STRING_AGG(cte.CashFlowId, ',') AS List_CashFlowId
			  ,cte.Id
		FROM cte
		WHERE cte.CashFlowCode <> ''
		GROUP BY cte.Id) 
	UPDATE #K_BcTmp
	SET CashFlowCode = ISNULL(IIF(c1.List_CatgDetailCode <> '', c1.List_CatgDetailCode, ''), '')
	    , CashFlowId_List = ISNULL(IIF(c1.List_CashFlowId <> '', c1.List_CashFlowId, ''), '')
	FROM #K_BcTmp AS tmp2
		 LEFT JOIN cte1 AS c1 ON tmp2.Id = c1.Id

	UPDATE #K_BcTmp
	SET CashFlowId_List=CashFlowId
	WHERE ItemLevel=9 AND CashFlowId_List='' AND CashFlowId<>''


    UPDATE #K_BcTmp
	SET CashFlowCode=iif(CF.Code <>'',cf.Code,k.CashFlowCode)
    FROM #K_BcTmp K LEFT JOIN B20CashFlow CF ON K.CashFlowId = CF.Id
	WHERE K.ItemLevel=9 AND CashFlowCode = '' and k.CashFlowId not like '%,%'

	SELECT @_LstAccount=STRING_AGG(value, ',')WITHIN GROUP(ORDER BY value)
	FROM(
		-- Bước 1: Tách tất cả các giá trị trong chuỗi ra thành các dòng riêng biệt
		SELECT DISTINCT LTRIM(RTRIM(value)) AS value
		FROM #K_BcTmp
			 CROSS APPLY STRING_SPLIT(Account, ',')
		WHERE Account<>'' AND Account IS NOT NULL) AS UniqueAccounts;
 
	;WITH cte AS (
		SELECT  DISTINCT CashFlowId
	FROM #K_BcTmp 
	WHERE CashFlowId <> ''
	) 
	SELECT @_LstCashFlowId = @_LstCashFlowId + ',' + RTRIM(CashFlowId)
	FROM cte 
	WHERE CashFlowId <> ''	
 
	SET @_LstCashFlowId = STUFF(@_LstCashFlowId, 1, 1, '')

	IF @_LstAccount <> '' 
		SET @_LstAccount = SUBSTRING(@_LstAccount, 2, LEN(@_LstAccount) - 1)

	IF @_LstCashFlowId <> '' 
		SET @_LstCashFlowId = SUBSTRING(@_LstCashFlowId, 2, LEN(@_LstCashFlowId) - 1)

	DECLARE @_Key NVARCHAR(MAX) = N'',  @_Key_Cd NVARCHAR(MAX) = N'', @_KeyOB NVARCHAR(MAX) = N''

	IF @_LstAccount <> ''  
	BEGIN
		SET @_Key = @_Key + N' (Account LIKE ''' + REPLACE(@_LstAccount, N',', N'%'' OR Account LIKE ''') + N'%'')'
		SET @_KeyOB = @_KeyOB + N' (Account LIKE ''' + REPLACE(@_LstAccount, N',', N'%'' OR Account LIKE ''') + N'%'')'
	END
 
	IF @_BudgetTypeCode <> ''
	BEGIN
		SET @_Key_Cd	= @_Key_Cd + ' AND (BudgetTypeCode LIKE ''' + @_BudgetTypeCode + '%'')'
	END

	IF ISNULL(@_Key_Cd, '') <> ''
		SET @_Key_Cd = STUFF(@_Key_Cd, 1, 4, '')

	--Tạo bảng số liệu đầu kỳ
	DROP TABLE IF EXISTS #OpenBalance
	SELECT TOP 0 DocDate, Account,
		DebitAmount AS DebitBal1, CreditAmount AS CreditBal1,
		DebitAmount AS DebitBal0, CreditAmount AS CreditBal0,
		DebitAmount AS No_Co, CAST(0 AS INT) AS IsOpen
	INTO #OpenBalance
	FROM B00CtTmp

	EXECUTE usp_B30OpenBalance_GetData
		@_DocDate0			= @_DocDate1, 
		@_Key				= @_KeyOB, 
		@_CtTmp				= N'#OpenBalance',
		@_nUserId			= @_nUserId,
		@_LangId			= @_LangId,
		@_BranchCode		= @_BranchCode, 
		@_CurrencyCode0		= @_CurrencyCode0,
		@_Opening			= 1,			
		@_Accumulate		= 0,		
		@_AutoCalculate		= 1, 	
		@_GroupByColumnList = N''
 
	-- VũLA: Cập nhật ngày đầu kỳ
	UPDATE #OpenBalance SET No_Co = DebitBal1 - CreditBal1, DocDate = @_DocDate1, IsOpen=1

	--Tạo bảng số liệu phát sinh 
	DROP TABLE IF EXISTS #K_CtTmp
	SELECT TOP (0)
		   Id
		  ,Id AS ParentId
		  ,CAST(0 AS BIT) AS IsGroup
		  ,Stt
		  ,CAST('' AS NVARCHAR(MAX)) AS _GroupOrder
		  ,RowId
		  ,DocDate
		  ,BranchCode
		  ,Account
		  ,CrspAccount
		  ,DebitAmount
		  ,CreditAmount
		  ,OriginalDebitAmount
		  ,OriginalCreditAmount
		  ,ExpenseCatgId AS CashFlowId
		  ,ExpenseCatgName AS CashFlowName
		  ,ItemName AS Ten_Nh
		  ,CustomerId 
		  ,CustomerId0
		  ,CustomerId AS CrspCustomerId
		  ,CustomerName AS CrspCustomerName
		  ,SPACE(11) AS Cot
		  ,DebitAmount AS No_Co
		  ,CreditAmount AS Co_No
		  ,DocCode
		  ,@_MesGroupCode AS MesGroupCode
	INTO #K_CtTmp
	FROM dbo.B00CtTmp

	DROP TABLE IF EXISTS #K_CtTmp0
	SELECT TOP 0 *
	INTO #K_CtTmp0
	FROM #K_CtTmp	

	EXECUTE dbo.usp_sys_DefaultTable @_Table= N'#K_CtTmp'

	EXECUTE dbo.usp_sys_DefaultTable @_Table= N'#K_CtTmp0'
 
	--Lấy số liệu phát sinh
	EXECUTE dbo.usp_B30GeneralLedger_GetData
		@_DocDate1 = @_DocDate1,
		@_DocDate2 = @_DocDate2,
		@_Key1 = @_Key,
		@_Key2 = N'',
		@_CtTmp = N'#K_CtTmp',
		@_nUserId   = @_nUserId,
		@_LangId    = @_LangId,
		@_branchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_PrintExec = 0
 
	UPDATE #K_CtTmp SET No_Co = DebitAmount - CreditAmount,
						Co_No = CreditAmount - DebitAmount

	UPDATE k SET k.MesGroupCode = cus.MesGroupCode FROM #K_CtTmp k LEFT JOIN dbo.B20Customer cus WITH (NOLOCK) ON k.CustomerId0 = cus.Id
					 
	-- Xử lý số dư đầu của mỗi kỳ
	INSERT INTO #OpenBalance(DocDate, Account, DebitBal1, CreditBal1, No_Co)
	SELECT		 DocDate, Account, 0 as DebitBal1, 0 as CreditBal1, No_Co
	FROM #K_CtTmp
	
		
	DROP TABLE IF EXISTS #OpenBalanceTmp
	SELECT DocDate, Account, SUM(No_Co) AS No_Co, SPACE(11) AS Cot, 0 AS IsOpenBal
	INTO #OpenBalanceTmp
	FROM #OpenBalance
	WHERE ISNULL(No_Co, 0) <> 0
	GROUP BY DocDate, Account

	--select * from #OpenBalanceTmp return 
	
	UPDATE #OpenBalanceTmp SET DocDate = @_DocDate1, IsOpenBal = 1 WHERE DocDate < @_DocDate1

	DROP TABLE IF EXISTS #OpenBalanceTmpData
	SELECT DocDate, Account, No_Co, Cot
	INTO #OpenBalanceTmpData
	FROM #OpenBalanceTmp

 
 
	DECLARE @_Date1 DATE = @_DocDate1, @_Date2 DATE, @_Date2Tmp DATE
	
	SET @_Date2 = @_DocDate2

	--Sửa while lấy theo từng ngày
	WHILE @_Date1 <= @_DocDate2
	BEGIN
		
		INSERT INTO #OpenBalanceTmp (Account, DocDate, No_Co, IsOpenBal)
		SELECT Account, @_Date1, SUM(No_Co), 1
		FROM #OpenBalanceTmpData
		WHERE DocDate <= DATEADD(DAY, -1, @_Date1)
		GROUP BY Account

		SET @_Date1 = DATEADD(DAY, 1, @_Date1);
 
	END
 
	DROP TABLE #OpenBalanceTmpData;
	UPDATE #OpenBalanceTmp SET Cot = IIF(@_Period = '1', REPLACE(STR(MONTH(DocDate),2),' ', '0') + '_', 
										IIF(@_Period = '2', REPLACE(STR(DATEPART(QUARTER, DocDate), 2), ' ', '0') + '_', '')) + STR(YEAR(DocDate), 4)
	
	UPDATE #OpenBalanceTmp SET Cot=CAST(DocDate AS NVARCHAR(26))
	 
	SELECT Cot, Account, SUM(No_Co) AS No_Co
	INTO #EndBalanceTmp
	FROM #OpenBalanceTmp 
	GROUP BY Cot, Account
 
	DELETE FROM #OpenBalanceTmp WHERE IsOpenBal = 0

	INSERT INTO #OpenBalanceTmp (DocDate,Account,No_Co,Cot,IsOpenBal)
	SELECT DocDate,Account,No_Co,CAST(DocDate AS NVARCHAR(26)),IsOpen
	FROM #OpenBalance WHERE IsOpen=1   
	DROP TABLE #OpenBalance;

	------Tạo bảng số liệu kế hoạch  
	DROP TABLE IF EXISTS #Budget 
	SELECT TOP 0 Stt, DocDate AS BudgetDate, BranchCode,
		Account, Amount, OriginalAmount, AccountName, CustomerId, CustomerName,
		ExpenseCatgId AS CashFlowId, ExpenseCatgName AS CashFlowName, CustomerId AS CrspCustomerId, CustomerName AS CrspCustomerName,
		ItemName AS Ten_Nh, CAST(0 AS INT) AS ParentId, SPACE(11) AS [Cot_KH],
		CAST(0 AS NUMERIC(20,2)) AS AmountKH, CAST('' AS NVARCHAR(26)) AS BudgetTypeCode,
		CAST('' AS NVARCHAR(26)) AS ItemNoBC, CAST('' AS NVARCHAR(2000)) AS DescriptionBC
	INTO #Budget
	FROM B00CtTmp

	--Lấy số liệu kế hoạch
	EXECUTE dbo.usp_B30Budget_GetData
		@_Date1 = @_DocDate1,
		@_Date2 = @_DocDate2,
		@_Key = @_Key_Cd,
		@_CtTmp = N'#Budget',
		@_DateCol = 'BudgetDate',
		@_BudgetStyleCode = @_Period,
		@_IsUpdateBudgetDate = 0,
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0 = @_CurrencyCode0,
		@_nUserId = @_nUserId,
		@_LangId = @_LangId

	UPDATE #Budget SET BranchCode=@_BranchCode
	
	DECLARE @_MsgNoCustomer NVARCHAR(128), @_MsgNoCashFlow NVARCHAR(128)

	SET @_MsgNoCustomer = dbo.ufn_sys_BH(N'<Không có đối tượng>',N'<No object>',N'',N'<オブジェクトなし>',N'<没有对象>',N'<객체 없음>', @_LangId)

	SET @_MsgNoCashFlow = dbo.ufn_sys_BH(N'<Không có khoản mục dòng tiền>',N'<No cash flow item>',N'',N'<キャッシュフローアイテムなし>',N'<无现金流量项目>',N'<현금 흐름 항목 없음>', @_LangId)

	UPDATE #K_CtTmp SET 
		CashFlowName = IIF(tb.CashFlowId IS NOT NULL, ISNULL(cash.Name, tb.CashFlowId), @_MsgNoCashFlow),
		CrspCustomerName = IIF(CrspCustomerId IS NULL, @_MsgNoCustomer, ISNULL(cus.Name, ''))
	FROM #K_CtTmp tb 
		LEFT JOIN dbo.B20CashFlow cash (nolock) ON cash.Id = tb.CashFlowId 
		LEFT JOIN dbo.B20Customer cus (nolock) ON cus.Id = tb.CrspCustomerId
			
	UPDATE #K_CtTmp SET Cot = IIF(@_Period = '1', REPLACE(STR(MONTH(DocDate),2),' ', '0') + '_', 
								IIF(@_Period = '2', REPLACE(STR(DATEPART(QUARTER, DocDate), 2), ' ', '0') + '_', '')) + STR(YEAR(DocDate), 4)
 
	--TuanPT update lại Cot
	UPDATE #K_CtTmp SET Cot =CAST(DocDate AS NVARCHAR(26))
 
	UPDATE #Budget SET 
		Cot_KH = IIF(@_Period = '1', REPLACE(STR(MONTH(BudgetDate),2),' ', '0') + '_', IIF(@_Period = '2', REPLACE(STR(DATEPART(QUARTER, BudgetDate), 2), ' ', '0') + '_', '')) + STR(YEAR(BudgetDate), 4),
		CrspCustomerId = CustomerId,
		CrspCustomerName = IIF(ISNULL(CustomerName, '') = '', @_MsgNoCustomer, CustomerName)

	--TuanPT update lại Cot
	UPDATE #Budget SET Cot_KH =CAST(BudgetDate AS NVARCHAR(26))

	DECLARE @_DsCot TABLE ([Cot] varchar(26), [Cot_KH] VARCHAR(26), [Percent] varchar(26), [Difference] varchar(26), [Month] NVARCHAR(32), 
	                       [MonthStr] NVARCHAR(128), DocDate DATE,[MonthStrTH] NVARCHAR(128), [YearStrTH] NVARCHAR(128), 
						   [MonthStrKH] NVARCHAR(128), [YearStrKH] NVARCHAR(128),
						   DocDateStartM DATE, DocDateEndM DATE, DocDateStartY DATE, DocDateEndY DATE,
						   Id INT IDENTITY(1, 1))

	DECLARE @_FieldList NVARCHAR(MAX),
			@_FieldList_IsNull NVARCHAR(MAX), @_FieldList_IsNullKH NVARCHAR(MAX),
			@_SumFieldList NVARCHAR(MAX), @_SumFieldListKH NVARCHAR(MAX),
			@_FieldTotal NVARCHAR(MAX), @_FieldTotalKH NVARCHAR(MAX),
			@_strUpdate NVARCHAR(MAX), @_strUpdateKH NVARCHAR(MAX),
			@_PsSum NVARCHAR(MAX),
			@_FieldListMBC NVARCHAR(MAX), @_FieldListYBC NVARCHAR(MAX)
 
	WHILE @_DocDate1 <= @_DocDate2
	BEGIN 
		INSERT INTO @_DsCot(Cot, Cot_KH, Month, MonthStr, DocDate)  
		SELECT '', '', MONTH(@_DocDate1), DATEADD(DAY, 0, @_DocDate1) AS MonthStr, DATEADD(DAY, 0, @_DocDate1)
		SET @_DocDate1 = IIF(@_Period = '1', DATEADD(DAY, -DAY(@_DocDate1) + 1, DATEADD(MONTH, 1, @_DocDate1)),
							IIF(@_Period = '2', DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @_DocDate1) + 1, 0), DATEADD(YEAR, DATEDIFF(YEAR, 0, @_DocDate1) + 1, 0)))
	END
 
	UPDATE @_DsCot
		SET [Cot] = 'T' + REPLACE(STR(Id, 3), SPACE(1), '0'),
			[Cot_KH] = 'KH' + REPLACE(STR(Id, 3), SPACE(1), '0'),
			[Percent]= 'T' + REPLACE(STR(Id, 3), SPACE(1), '0') + '/' + 'KH' + REPLACE(STR(Id, 3), SPACE(1), '0'),
			[Difference] = 'T' + REPLACE(STR(Id, 3), SPACE(1), '0') + '_' + 'KH' + REPLACE(STR(Id, 3), SPACE(1), '0') + '_' + 'Diff',
			MonthStrTH='M'+CAST(FORMAT(DocDate, 'MMyyyy') AS NVARCHAR(26)),
			YearStrTH='Y'+CAST(YEAR(DocDate) AS NVARCHAR(26)),
			MonthStrKH='MKH'+CAST(FORMAT(DocDate, 'MMyyyy') AS NVARCHAR(26)),
			YearStrKH='YKH'+CAST(YEAR(DocDate) AS NVARCHAR(26)),
			DocDateStartM=DATEADD(DAY, - DAY(DocDate) + 1, DocDate),
			DocDateEndM=EOMONTH(DocDate),
			DocDateStartY=DATEADD(yy, DATEDIFF(yy, 0, DocDate), 0),
			DocDateEndY=DATEADD(yy, DATEDIFF(yy, 0, DocDate) + 1, -1) 

	--yyyyMM
	--tinnt 28-07-2026
	BEGIN 
	UPDATE @_DsCot set [Cot] = 'T' + format(DocDateStartM,'yyyyMM')   
	END 
			   
	UPDATE @_DsCot SET DocDateStartM=IIF(a.DocDateStartM=ct.DocDateStar,a.DocDateStartM,ct.DocDateStar), DocDateEndM=IIF(a.DocDateEndM=ct.DocDateEnd,a.DocDateEndM,ct.DocDateEnd)
		FROM @_DsCot a LEFT OUTER JOIN (SELECT MIN(DocDate) AS DocDateStar, MAX(DocDate) AS DocDateEnd, MonthStrTH FROM @_DsCot GROUP BY MonthStrTH) AS ct ON ct.MonthStrTH=a.MonthStrTH

	UPDATE @_DsCot SET DocDateStartY=IIF(a.DocDateStartY=ct.DocDateStar,a.DocDateStartY,ct.DocDateStar), DocDateEndY=IIF(a.DocDateEndY=ct.DocDateEnd,a.DocDateEndY,ct.DocDateEnd)
		FROM @_DsCot a LEFT OUTER JOIN (SELECT MIN(DocDate) AS DocDateStar, MAX(DocDate) AS DocDateEnd, YearStrTH FROM @_DsCot GROUP BY YearStrTH) AS ct ON ct.YearStrTH=a.YearStrTH

	UPDATE #OpenBalanceTmp SET [Cot] = ds.[Cot] FROM #OpenBalanceTmp ob  INNER JOIN @_DsCot ds ON ds.MonthStr = ob.Cot

	UPDATE #EndBalanceTmp SET [Cot] = ds.[Cot] FROM #EndBalanceTmp eb  INNER JOIN @_DsCot ds ON ds.MonthStr = eb.Cot
	
	UPDATE #K_CtTmp SET No_Co =  DebitAmount -  CreditAmount,Co_No =  CreditAmount -  DebitAmount
	UPDATE #K_CtTmp SET Cot  = DATEFROMPARTS(YEAR(tb.DocDate),MONTH(tb.DocDate),'01') FROM  #K_CtTmp tb

	UPDATE #K_CtTmp SET [Cot] = ds.[Cot] FROM #K_CtTmp tb  INNER JOIN @_DsCot ds ON ds. MonthStr = tb.Cot
 	  
	UPDATE #Budget SET [Cot_KH] = ds.[Cot_KH], AmountKH = tb.Amount FROM #Budget tb  INNER JOIN @_DsCot ds ON ds.MonthStr = tb.Cot_KH
	
	SET @_FieldList = 
	(SELECT N',' + QUOTENAME(RTRIM([Cot_KH])) FROM @_DsCot ORDER BY id FOR XML PATH('')) + 
	(SELECT N',' + QUOTENAME(RTRIM([Cot])) FROM @_DsCot ORDER BY id FOR XML PATH(''))

	 
 
	SET @_FieldListMBC = 
	(SELECT N',' + QUOTENAME(RTRIM([MonthStrKH])) FROM @_DsCot GROUP BY [MonthStrKH] ORDER BY MAX(id) FOR XML PATH('')) + 
	(SELECT N',' + QUOTENAME(RTRIM([MonthStrTH])) FROM @_DsCot GROUP BY [MonthStrTH] ORDER BY MAX(id) FOR XML PATH(''))

	SET @_FieldListYBC = 
	(SELECT N',' + QUOTENAME(RTRIM([YearStrKH])) FROM @_DsCot GROUP BY [YearStrKH] ORDER BY MAX(id) FOR XML PATH('')) + 
	(SELECT N',' + QUOTENAME(RTRIM([YearStrTH])) FROM @_DsCot GROUP BY [YearStrTH] ORDER BY MAX(id) FOR XML PATH(''))
 
	SET @_strUpdate = (SELECT N',' + QUOTENAME(RTRIM([Cot])) + N' = tb.' + QUOTENAME(RTRIM([Cot])) FROM @_DsCot ORDER BY id FOR XML PATH('')) 
	SET @_strUpdateKH = (SELECT N',' + QUOTENAME(RTRIM([Cot_KH])) + N' = tb1.' + QUOTENAME(RTRIM([Cot_KH])) FROM @_DsCot ORDER BY id FOR XML PATH(''))

	SET @_FieldList_IsNull = (SELECT N', ISNULL(' + QUOTENAME(RTRIM([Cot])) + N', 0) AS ' + QUOTENAME(RTRIM([Cot])) FROM @_DsCot ORDER BY id FOR XML PATH('')) 
	SET @_FieldList_IsNullKH = (SELECT N', ISNULL(' + QUOTENAME(RTRIM([Cot_KH])) + N', 0) AS ' + QUOTENAME(RTRIM([Cot_KH])) FROM @_DsCot ORDER BY id FOR XML PATH(''))

	SET @_SumFieldList = (SELECT N', ISNULL(SUM(' + QUOTENAME(RTRIM([Cot])) + N'), 0) AS ' + QUOTENAME(RTRIM([Cot])) FROM @_DsCot ORDER BY id FOR XML PATH('')) 
	SET @_SumFieldListKH = (SELECT N', ISNULL(SUM(' + QUOTENAME(RTRIM([Cot_KH])) + N'), 0) AS ' + QUOTENAME(RTRIM([Cot_KH])) FROM @_DsCot ORDER BY id FOR XML PATH(''))

	SET @_FieldTotal = REPLACE((SELECT N',' + QUOTENAME(RTRIM([Cot])) FROM @_DsCot ORDER BY id FOR XML PATH('')), N',', N' + ')
	SET @_FieldTotalKH = REPLACE((SELECT N',' + QUOTENAME(RTRIM([Cot_KH])) FROM @_DsCot ORDER BY id FOR XML PATH('')), N',', N' + ')

	SELECT @_strUpdate = STUFF(@_strUpdate, 1, 1, N''), 
			@_strUpdateKH = STUFF(@_strUpdateKH, 1, 1, N''),
			@_FieldList_IsNull = STUFF(@_FieldList_IsNull, 1, 1, N''),
			@_FieldList_IsNullKH = STUFF(@_FieldList_IsNullKH, 1, 1, N''),
			@_SumFieldList = STUFF(@_SumFieldList, 1, 1, N''),
			@_SumFieldListKH = STUFF(@_SumFieldListKH, 1, 1, N'')
 
	
	
	
	-- Tao bang bao cao
	SET @_strExec = REPLACE(@_FieldList, N',[', N'ALTER TABLE #K_BcTmp ADD [')
	SET @_strExec = REPLACE(@_strExec, N']', N'] NUMERIC(20, 2) NOT NULL DEFAULT 0;')	
	EXECUTE sp_executesql @_StrExec

	SET @_FieldList = STUFF(@_FieldList, 1, 1, N'') 
	
	--select @_FieldList return 
	
	-- Tao bang bao cao tháng
	SET @_strExec = REPLACE(@_FieldListMBC, N',[', N'ALTER TABLE #K_BcTmp ADD [') SET @_strExec = REPLACE(@_strExec, N']', N'] NUMERIC(20, 2) NOT NULL DEFAULT 0;')
	EXECUTE sp_executesql @_StrExec

	SET @_FieldListMBC = STUFF(@_FieldListMBC, 1, 1, N'')
			
	-- Tao bang bao cao năm
	SET @_strExec = REPLACE(@_FieldListYBC, N',[', N'ALTER TABLE #K_BcTmp ADD [') SET @_strExec = REPLACE(@_strExec, N']', N'] Numeric(20, 2) NOT NULL DEFAULT 0;')	
	EXECUTE sp_executesql @_StrExec
	
	SET @_FieldListYBC = STUFF(@_FieldListYBC, 1, 1, N'')

	UPDATE #K_BcTmp SET Stt_Group = REPLICATE(N'0', 3 - LEN(CAST(Stt AS NVARCHAR(3)))) + CAST(Stt AS NVARCHAR(3)) + RTRIM(ItemNo)

	--Bắt đầu xử lý báo cáo
	SELECT Id, ItemNo, Account, CrspAccount, ExcludeCrspAccount, CashFlowId, Loai_Ps, Detail, Stt_Group, IsPrint,ItemLevel,VarValue
	INTO #Kqt
	FROM #K_BcTmp
	WHERE ItemLevel = 9


	--select * from #Kqt return 
	--Bắt đầu xử lý từng dòng báo cáo
	WHILE EXISTS(SELECT * FROM #Kqt)
	BEGIN
		SELECT TOP 1
			   @_Id = Id
			  ,@_ItemNo = ItemNo
			  ,@_Account = Account
			  ,@_CrspAccount = CrspAccount
			  ,@_ExcludeCrspAccount = ExcludeCrspAccount
			  ,@_CashFlowId = CashFlowId
			  ,@_Loai_Ps = Loai_Ps
			  ,@_Detail = Detail
			  ,@_Stt_Group = Stt_Group
			  ,@_IsPrint = IsPrint
			  ,@_MesGroupCode = VarValue
		FROM #Kqt

		DELETE FROM #Kqt WHERE Id = @_Id

		IF EXISTS(SELECT * FROM tempdb.sys.columns WHERE name = @_Detail + 'Id' AND object_id = OBJECT_ID('TempDb..#K_CtTmp', 'U'))
			SET @_Detail0 = @_Detail + 'Id'
		ELSE
			SET @_Detail0 = @_Detail + 'Code'

		SET @_Account = REPLACE(@_Account, SPACE(1), SPACE(0))
		SET @_CrspAccount = REPLACE(@_CrspAccount, SPACE(1), SPACE(0))
		SET @_ExcludeCrspAccount = REPLACE(@_ExcludeCrspAccount, SPACE(1), SPACE(0))

		SET @_Key = ''
		SET @_Key_Cd = ''
		SET @_KeyOB = ''

		IF @_Account <> ''
		BEGIN
			SET @_Key = N' AND (Account LIKE N''' + REPLACE(@_Account, ',', '%'' OR Account LIKE ''') + '%'')'
			SET @_KeyOB = N'(Account LIKE ''' + REPLACE(@_Account, ',', '%'' OR Account LIKE ''') + '%'')'
		END

		IF @_CrspAccount <> ''
			SET @_Key = @_Key + N' AND (CrspAccount LIKE ''' + REPLACE(@_CrspAccount, ',', '%'' OR CrspAccount LIKE ''') + '%'')'

		IF @_ExcludeCrspAccount <> ''
			SET @_Key = @_Key + N' AND NOT (CrspAccount LIKE ''' + REPLACE(@_ExcludeCrspAccount, N',', N'%'' OR CrspAccount LIKE ''') + '%'')'

		IF @_CashFlowId <> ''
		BEGIN
			EXECUTE dbo.usp_sys_GenKey @_Code = @_CashFlowId, @_ColGen = 'CashFlowId', 
			@_ColName = 'Id', @_TableName = 'B20CashFlow', 
			@_AndOrKey = 'AND', @_Key = @_Key OUTPUT

			EXECUTE dbo.usp_sys_GenKey @_Code = @_CashFlowId, @_ColGen = 'CashFlowId', 
			@_ColName = 'Id', @_TableName = 'B20CashFlow', 
			@_AndOrKey = 'AND', @_Key = @_Key_Cd OUTPUT
		END

		IF ISNULL(@_MesGroupCode,'') <>''
		BEGIN        	
			SET @_Key = @_Key + N' AND (MesGroupCode  = ''' + REPLACE(@_MesGroupCode, ',', ''' OR MesGroupCode = ''') + ''')'
		END 

		-- Chỉ lấy PS nợ
		IF @_Loai_Ps = 'PS_NO'	
			SET @_Key = @_Key + IIF(@_Key = '', '', ' AND DebitAmount <> 0 AND CreditAmount = 0')

		-- Chỉ lấy PS có
		IF @_Loai_Ps = 'PS_CO'	
			SET @_Key = @_Key + IIF(@_Key = '', '', ' AND DebitAmount = 0 AND CreditAmount <> 0')
		
		IF @_Key <> '' AND @_Account <> ''
			SET @_Key = N'WHERE ' + SUBSTRING(@_Key, 6, LEN(@_Key) - 5)
		ELSE
			SET @_Key = ''

		IF @_Key_Cd <> ''
			SET @_Key_Cd = N'WHERE ' + SUBSTRING(@_Key_Cd, 6, LEN(@_Key_Cd) - 5)
		ELSE
			SET @_Key_Cd = ''

		IF @_KeyOB <> ''
			SET @_KeyOB = N'WHERE ' + @_KeyOB

		SET @_PsSum = CASE WHEN @_Loai_Ps = N'CO_NO' THEN N'CO_NO' 
							WHEN @_Loai_Ps = N'PS_NO' THEN N'DebitAmount'
							WHEN @_Loai_Ps = N'PS_CO' THEN N'CreditAmount'
							ELSE N'NO_CO' END
	
		IF @_Loai_Ps IN (N'DAU_KY', N'CUOI_KY')
		BEGIN
			SET @_strExec = 
				N'UPDATE #K_BcTmp SET ' + @_strUpdate + ' FROM #K_BcTmp bc, ' + CHAR(13) +
				N'( SELECT ' + @_SumFieldList + ' FROM ' + CHAR(13) +   
				N'  (   SELECT ' + @_FieldList_IsNull + CHAR(13) + 
				N'      FROM (SELECT [Cot], No_Co, 0 AS CO_NO FROM ' + IIF(@_Loai_Ps = N'DAU_KY', '#OpenBalanceTmp ', '#EndBalanceTmp ') + @_KeyOB + ') AS tblTmp' + NCHAR(13) + 
				N'      PIVOT' + CHAR(13) + 
				N'      (' + CHAR(13) + 
				N'          SUM(' + @_PsSum + ')' + NCHAR(13) + 
				N'          FOR [Cot] IN (' + @_FieldList + ')' + NCHAR(13) + 
				N'      ) AS pv' + CHAR(13) + 
				N'  ) pv1' + CHAR(13) + 
				N') tb' + CHAR(13) + 
				N'WHERE Id = ' + STR(@_Id)
		END
		ELSE
		BEGIN
			---Update phát sinh
			SET @_strExec = 
				N'UPDATE #K_BcTmp SET ' + @_strUpdate + ',' + @_strUpdateKH + ' FROM #K_BcTmp bc, ' + CHAR(13) +
				N'( SELECT ' + @_SumFieldList + ' FROM ' + CHAR(13) +   
				N'  (   SELECT ' + @_FieldList_IsNull + CHAR(13) + 
				N'      FROM (SELECT [Cot], No_Co, Co_No, DebitAmount, CreditAmount FROM #K_CtTmp ' + @_Key + ') AS tblTmp' + NCHAR(13) + 
				N'      PIVOT' + CHAR(13) + 
				N'      (' + CHAR(13) + 
				N'          SUM(' + @_PsSum + ')' + NCHAR(13) + 
				N'          FOR [Cot] IN (' + @_FieldList + ')' + NCHAR(13) + 
				N'      ) AS pv' + CHAR(13) + 
				N'  ) pv1' + CHAR(13) + 
				N') tb,' + CHAR(13) + 
				N'( SELECT ' + @_SumFieldListKH + ' FROM ' + CHAR(13) +   
				N'  (   SELECT ' + @_FieldList_IsNullKH + CHAR(13) + 
				N'      FROM (SELECT [Cot_KH], AmountKH FROM #Budget ' + '' + ') AS tblTmp' + NCHAR(13) + 
				N'      PIVOT' + CHAR(13) + 
				N'      (' + CHAR(13) + 
				N'          SUM(AmountKH)' + NCHAR(13) + 
				N'          FOR [Cot_KH] IN (' + @_FieldList + ')' + NCHAR(13) + 
				N'      ) AS pv' + CHAR(13) + 
				N'  ) pv1' + CHAR(13) + 
				N') tb1' + CHAR(13) + 
				N'WHERE Id = ' + STR(@_Id)	
		END
 		
		EXECUTE sp_executesql @_strExec	

		IF @_Detail <> N'' AND @_Loai_Ps NOT IN ('DAU_KY', 'CUOI_KY')
		BEGIN
			TRUNCATE TABLE #K_CtTmp0
			
			SET @_strExec =
				N'INSERT INTO #K_CtTmp0' + CHAR(13) +
				N'SELECT *' + CHAR(13) +
				N'FROM #K_CtTmp ' + @_Key

			EXECUTE (@_strExec)

			IF @_TreeView = 1
			BEGIN
				SET @_colListIns = 'IsGroup,DocDate'	

				IF @_Detail = N'CashFlow'
					SELECT @_tblDmName = 'B20CashFlow',
						@_colCode = 'CashFlowId',
						@_colName = 'CashFlowName',
						@_colListIns = @_colListIns + ',CashFlowId'
				ELSE IF @_Detail = 'CrspCustomer'
					SELECT @_tblDmName = 'B20Customer',
						@_colCode = 'CrspCustomerId',
						@_colName = 'CrspCustomerName',
						@_colListIns = @_colListIns + ',CrspCustomerId'

				EXEC dbo.usp_sys_CreateTreeNodeKey
					@_tblName		= '#K_CtTmp0',
					@_tblDmName		= @_tblDmName,
					@_colDmCode		= 'Id', 
					@_colCode 		= @_colCode, 
					@_colListIns 	= @_colListIns,
					@_colListSel 	= '1,NULL,Id',
					@_colName		= @_colName,
					@_IsDetail		= 0,
					@_LangId		= @_LangId
			END

			SET @_strExec = N''

			SET @_strExec = N'
			INSERT INTO #K_BcTmp (Stt_Group, _GroupOrder, ItemNo, CashFlowCode, Detail, Description, IsPrint, _FormatStyleKey, ' + @_FieldList + ')
			SELECT N''' + @_Stt_Group + N''', MAX(_GroupOrder), ''' + @_ItemNo + N'z'' AS ItemNo, GroupCode, ''' + @_Detail + N''', SPACE(5*MAX(Level)) + ''+ '' + MAX(GroupName) AS Description, ' + STR(@_IsPrint, 1) + N' AS IsPrint, IIF(MAX(IsGroup) = 0, ''Italic'', ''BOLD'') AS_FormatStyleKey , ' + @_SumFieldListKH + N',' + @_SumFieldList + N'
			FROM 
			(
				SELECT GroupCode, IsGroup, GroupName, Level + 1 AS Level, _GroupOrder, ' + @_FieldList_IsNull + N',' + @_FieldList_IsNullKH + N'
				FROM 
					(   
						SELECT GroupCode, IsGroup, GroupName, Level, _GroupOrder, ' + @_FieldList_IsNull + N',' + @_FieldList_IsNullKH + N'
						FROM (SELECT _GroupOrder, IsGroup, CAST(ISNULL(' + @_Detail0 + N', '''') AS varchar(24)) AS GroupCode, ISNULL(' + @_Detail + N'Name, '''') AS GroupName, [Cot], No_Co, Co_No, DebitAmount, CreditAmount, (LEN(_GroupOrder) - LEN(REPLACE(_GroupOrder, '','', ''''))) AS Level FROM #K_CtTmp0) AS tblTmp
							PIVOT (SUM(' + @_PsSum + N') FOR [Cot] IN (' + @_FieldList + N')) AS pv
					) pv1
				UNION ALL
				SELECT GroupCode, 0 AS IsGroup, GroupName, 0 AS Level, '''' AS _GroupOrder, ' + @_FieldList_IsNull + N',' + @_FieldList_IsNullKH + N'
				FROM
					(  
						SELECT GroupCode, GroupName, ' + @_FieldList_IsNull + N',' + @_FieldList_IsNullKH + N'
						FROM (SELECT CAST(ISNULL(' + @_Detail0 + N', '''') AS varchar(24)) AS GroupCode, ISNULL(' + @_Detail + N'Name, '''') AS GroupName, [Cot_KH], AmountKH FROM #Budget ' + @_Key_Cd + N') AS tblTmp
							PIVOT (SUM(AmountKH) FOR [Cot_KH] IN (' + @_FieldList + N')) AS pv
					) pv2
			) AS tb
			GROUP BY GroupCode'

			EXECUTE sp_executesql @_strExec
			
		END
	END
	--Kết thúc xử lý từng dòng báo cáo
	  
	  --select * from #K_BcTmp return


	UPDATE #K_BcTmp SET Description = dbo.ufn_sys_BH(Description, Description_English, Description_French, 
														Description_Japanese, Description_Chinese, Description_Korean, @_LangId)
	WHERE Id IS NOT NULL

	UPDATE #K_BcTmp SET CashFlowCode = cf.Code
	FROM #K_BcTmp a
		INNER JOIN dbo.B20CashFlow cf ON a.CashFlowCode = cf.Id
	WHERE a.Id IS NULL AND Detail = N'CashFlow'

	UPDATE #K_BcTmp SET CashFlowCode = cus.Code
	FROM #K_BcTmp a
		INNER JOIN dbo.B20Customer cus ON a.CashFlowCode = cus.Id
	WHERE a.Id IS NULL AND Detail = N'CrspCustomer'

	UPDATE #K_BcTmp SET CashFlowCode = ''
	WHERE CashFlowCode = '0'

	EXECUTE(N'UPDATE #K_BcTmp SET Actual = 0 ' + @_FieldTotal + N' WHERE Loai_Ps NOT IN (N''DAU_KY'', N''CUOI_KY'')')
	EXECUTE(N'UPDATE #K_BcTmp SET Budget = 0 ' + @_FieldTotalKH + N' WHERE Loai_Ps NOT IN (N''DAU_KY'', N''CUOI_KY'')')

	DECLARE @_FieldTotal_DK VARCHAR(26), @_FieldTotalKH_DK VARCHAR(26)

	SET @_FieldTotal_DK = LEFT(@_FieldTotal, 12)
	SET @_FieldTotalKH_DK = LEFT(@_FieldTotalKH, 10)
 	 	
	SELECT @_strExec = 'UPDATE #K_BcTmp SET Actual = 0 ' + @_FieldTotal_DK + N' WHERE Loai_Ps = N''DAU_KY'''	EXEC (@_strExec)
	SELECT @_strExec = N'UPDATE #K_BcTmp SET Budget = 0 ' + @_FieldTotalKH_DK + N' WHERE Loai_Ps = N''DAU_KY''' EXEC (@_strExec)
 
	DECLARE @_FieldTotal_CK VARCHAR(26), @_FieldTotalKH_CK VARCHAR(26)

	SET @_FieldTotal_CK = RIGHT(@_FieldTotal, 12)
	SET @_FieldTotalKH_CK = RIGHT(@_FieldTotalKH, 10)

	SELECT @_strExec = N'UPDATE #K_BcTmp SET Actual = 0 ' + @_FieldTotal_CK + N' WHERE Loai_Ps = N''CUOI_KY'''		EXEC (@_strExec)
	SELECT @_strExec = N'UPDATE #K_BcTmp SET Budget = 0 ' + @_FieldTotalKH_CK + N' WHERE Loai_Ps = N''CUOI_KY'''	EXEC (@_strExec)
 
	SET @_FieldList = REPLACE(REPLACE(@_FieldList, N'[', N''), N']', '') + N',Actual, Budget'
	
	SET @_FieldListYBC = REPLACE(REPLACE(@_FieldListYBC, N'[', N''), N']', '')  

	-------TuanPT update kế hoạch
	SET @_strExec = N''
	SELECT @_strExec=@_strExec+N' UPDATE #K_BcTmp SET '+Cot_KH+N'=0' +CHAR(13)
	FROM @_DsCot
	EXECUTE (@_strExec)

	SET @_strExec = N''
	SELECT @_strExec=@_strExec+N' UPDATE #K_BcTmp SET '+Cot_KH+N'=ISNULL(AmountKH,0)' +CHAR(13) +
	N'FROM #K_BcTmp a LEFT OUTER JOIN (SELECT ItemNoBC, SUM(AmountKH) AS AmountKH FROM #Budget WHERE Cot_KH='''+Cot_KH+N''' GROUP BY ItemNoBC)' +CHAR(13) +
	N'AS dt ON ISNULL(dt.ItemNoBC,'''')=ISNULL(a.ItemNo,'''')' +CHAR(13)
	FROM @_DsCot
	EXECUTE (@_strExec)
 
	
	--------Update theo tháng
	SET @_strExec = N''
	SELECT @_strExec=@_strExec+N'
	                           UPDATE #K_BcTmp SET '+MonthStrTH+' = ' + CAST(STRING_AGG(Cot,' + ') AS NVARCHAR(MAX)) +CHAR(13)+ 
	                           N' WHERE Loai_Ps NOT IN (N''DAU_KY'', N''CUOI_KY'')
							   
							   UPDATE #K_BcTmp SET '+MAX(MonthStrKH)+' = ' + CAST(STRING_AGG(Cot_KH,' + ') AS NVARCHAR(MAX)) +CHAR(13)+ 
	                           N' 
							   '
	FROM @_DsCot
	GROUP BY MonthStrTH
	EXECUTE (@_strExec)

	SET @_strExec = N''
	SELECT @_strExec=@_strExec+N'
	                           UPDATE #K_BcTmp SET '+MonthStrTH+' = ' + CAST(STRING_AGG(Cot,' + ') AS NVARCHAR(MAX)) +CHAR(13)+ 
							   N' WHERE Loai_Ps = N''DAU_KY'''
	FROM @_DsCot
	WHERE DocDate=DocDateStartM
	GROUP BY MonthStrTH
	EXECUTE (@_strExec)

	SET @_strExec = N''
	SELECT @_strExec=@_strExec+N'
	                           UPDATE #K_BcTmp SET '+MonthStrTH+' = ' + CAST(STRING_AGG(Cot,' + ') AS NVARCHAR(MAX)) +CHAR(13)+ 
							   N' WHERE Loai_Ps = N''CUOI_KY'''
	FROM @_DsCot
	WHERE DocDate=DocDateEndM
	GROUP BY MonthStrTH
	EXECUTE (@_strExec)
 
	
	

	--------Update theo năm
	SET @_strExec = N''
	SELECT @_strExec=@_strExec+N' UPDATE #K_BcTmp SET '+YearStrTH+' = ' + CAST(STRING_AGG(Cot,' + ') AS NVARCHAR(MAX)) +CHAR(13)+ 
	                           N' WHERE Loai_Ps NOT IN (N''DAU_KY'', N''CUOI_KY'')'+CHAR(13)+
							   N' UPDATE #K_BcTmp SET '+MAX(YearStrKH)+' = ' + CAST(STRING_AGG(Cot_KH,' + ') AS NVARCHAR(MAX)) +CHAR(13)+ 
	                           N' WHERE Loai_Ps NOT IN (N''DAU_KY'', N''CUOI_KY'')							   '
	FROM @_DsCot
	GROUP BY YearStrTH
	EXECUTE (@_strExec)   

	SET @_strExec = N''
	SELECT @_strExec=@_strExec+N' UPDATE #K_BcTmp SET '+YearStrTH+' = ' + CAST(STRING_AGG(Cot,' + ') AS NVARCHAR(MAX)) +CHAR(13)+ 
							   N' WHERE Loai_Ps = N''DAU_KY'''
	FROM @_DsCot
	WHERE DocDate=DocDateStartY
	GROUP BY YearStrTH
	EXECUTE (@_strExec)

	SET @_strExec = N''
	SELECT @_strExec=@_strExec+N' UPDATE #K_BcTmp SET '+YearStrTH+' = ' + CAST(STRING_AGG(Cot,' + ') AS NVARCHAR(MAX)) +CHAR(13)+ 
							   N' WHERE Loai_Ps = N''CUOI_KY'''
	FROM @_DsCot
	WHERE DocDate=DocDateEndY
	GROUP BY YearStrTH
	EXECUTE (@_strExec)
	
	select @_FieldList=@_FieldList+', '+@_FieldListYBC   
	IF ISNULL(@_FieldList, '') <> ''
		EXECUTE usp_sys_SumValue 
			@_Table = '#K_BcTmp', 
			@_FieldList = @_FieldList,
			@_FieldKey = 'ItemNo',
			@_FieldCal = 'Formula',
			@_FieldBac = 'ItemLevel'

		 
	 

		

	DECLARE @_strUpdate2 NVARCHAR(MAX), @_strExec2 NVARCHAR(MAX)

	--Tạo cột tỷ lệ 
	UPDATE #K_BcTmp SET [Percent] = CASE WHEN Budget <> 0 THEN (Actual/Budget) ELSE 0 END
	WHERE Loai_Ps IN ('NO_CO', 'CO_NO') OR Id IS NULL

	UPDATE #K_BcTmp SET [Difference] = Actual - Budget
	WHERE Loai_Ps IN ('NO_CO', 'CO_NO') OR Id IS NULL

	IF @_CtTmp <> ''
	BEGIN 	
		EXECUTE dbo.usp_sys_Append @_TableSource = N'#K_BcTmp', @_TableDestination = @_CtTmp
		RETURN;
	END
 

	SET @_LAYOUT_XML=N''
    SET @_LAYOUT_XML=@_LAYOUT_XML +	N'<DefaultReport><Content><Cols>'	

	SELECT @_LAYOUT_XML = @_LAYOUT_XML + N' 		
					    <'+Cot+N'>
							<Width>150</Width>
							<Style>TextAlign:RightTop;Format:"C";</Style>
							<Rows>
								<Row_0>
									<Text>
										<Vietnamese>DÒNG TIỀN THỰC HIỆN</Vietnamese>
										<English>ACTUAL CASH FLOW</English>
									</Text>
									<Style>UserData:4l3t3cfz;</Style>
								</Row_0>
								<Row_1>
									<Text>
										<Vietnamese>'+CONVERT(VARCHAR(10), CAST(MonthStr AS DATE), 103)+N'</Vietnamese>
										<English>'+CONVERT(VARCHAR(10), CAST(MonthStr AS DATE), 103)+N'</English>
									</Text>
									<Style></Style>
								</Row_1>
							</Rows>
						</'+Cot+N'>
							'
	FROM @_DsCot
	ORDER BY Id
 
	SELECT @_LAYOUT_XML = @_LAYOUT_XML + N' 		
					   	<'+YearStrTH+N'>
							<Width>150</Width>
							<Style>TextAlign:RightTop;Format:"C";</Style>
							<Rows>
								<Row_0>
									<Text>
										<Vietnamese>DÒNG TIỀN THỰC HIỆN</Vietnamese>
										<English>ACTUAL CASH FLOW</English>
									</Text>
									<Style>UserData:4l3t3cfz;</Style>                                    
								</Row_0>
								<Row_1>
									<Text>
										<Vietnamese>Năm '+CAST(YEAR(MAX(DocDate)) AS NVARCHAR(26))+'</Vietnamese>
										<English>Year '+CAST(YEAR(MAX(DocDate)) AS NVARCHAR(26))+'</English>
									</Text>
									<Style></Style>
								</Row_1>
							</Rows>
						</'+YearStrTH+N'>
							'
	FROM @_DsCot
	GROUP BY YearStrTH
	ORDER BY MAX(Id)
 
	SET @_LAYOUT_XML=@_LAYOUT_XML +	N'</Cols></Content></DefaultReport>'	

	DELETE FROM #K_BcTmp WHERE ItemNo LIKE N'Zz%' AND ItemLevel = 5 AND ISNULL(Actual, 0) = 0

	IF (SELECT COUNT(*) FROM #K_BcTmp WHERE ItemNo LIKE N'Zz%') = 1
		UPDATE #K_BcTmp SET IsPrint = 0
		WHERE ItemNo LIKE N'Zz%'
	 
	IF ISNULL(@_InsertTable, '') = ''
	BEGIN 
		SELECT *, ItemNo AS _FormulaKey, Formula AS _Formula
		FROM #K_BcTmp
		WHERE IsPrint = 1
		ORDER BY BuiltinOrder ASC 
	END 
	ELSE
	BEGIN 
		EXECUTE usp_sys_Append @_TableSource= '#K_BcTmp',@_TableDestination= @_InsertTable
	END  	

	DROP TABLE IF EXISTS #K_BcTmp
	DROP TABLE IF EXISTS #K_CtTmp
	DROP TABLE IF EXISTS #K_CtTmp0
	DROP TABLE IF EXISTS #Budget
	DROP TABLE IF EXISTS #Kqt
	DROP TABLE IF EXISTS #OpenBalance
	DROP TABLE IF EXISTS #OpenBalanceTmp
	DROP TABLE IF EXISTS #EndBalanceTmp
	DROP TABLE IF EXISTS #OpenBalanceTmpData

	RETURN
END
GO




SET DATEFORMAT DMY

EXEC usp_Kqt_AnalysingDirectCashPlanByTime_test @_DocDate1 = '01/01/2026 00:00:00.000'
                                         , @_DocDate2 = '31/01/2026 00:00:00.000'
                                         , @_Kqt = 'B10KqtCashFlowPlan'
                                         , @_KqtCashFlowPlanId = 'T000000003'
                                         , @_SourceTable = 'B10KqtCashFlowPlan'
                                         , @_Period = '1'
                                         , @_BudgetTypeCode = 'CashFlowBT'
                                         , @_nUserId = 1213
                                         , @_LangId = 0
                                         , @_BranchCode = 'I09'
                                         , @_CurrencyCode0 = 'VND'
                                         , @_TreeView = 0