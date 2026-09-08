SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Coder: KhuongNV
-- ============================================
-- Description: Bảng kê chứng từ
-- ============================================
ALTER PROCEDURE [dbo].[usp_Kct_TransactionListing_Ext] 
	@_DocDate1 DATE	= '20250401',
	@_DocDate2 DATE	= '20250430',
	@_Kieu_Bc VARCHAR(1) = '1',
	@_DocCode VARCHAR(96) = '',
	@_Description NVARCHAR(256)	= '',
	@_DocNo1 NVARCHAR(20) = '',
	@_DocNo2 NVARCHAR(20) = '',
	@_DocBookingId VARCHAR(256) = '',
	@_CustomerId0 VARCHAR(512) = '',
	@_IsAmount BIT =0,
	@_No_Co VARCHAR(1) = '',
	@_Account NVARCHAR(2000) = '',
	@_CrspAccount VARCHAR(1000) = '',
	@_CrspCustomerId VARCHAR(1000) = '',
	@_BizDocId_PO2 VARCHAR(24) = '', -- HĐ mua
	@_BizDocId_SO2 VARCHAR(24) = '', -- HĐ bán
	@_BizDocId_PO VARCHAR(24) = '',
	@_BizDocId_SO VARCHAR(24) = '',
	@_BizDocId_LC VARCHAR(24) = '',
	@_BizDocId_DA VARCHAR(24) = '',
	@_CustomerId VARCHAR(512) = '',
	@_ExpenseCatgId VARCHAR(512) = '',
	@_CashFlowId VARCHAR(512) = '', -- Thêm khoản mục dòng tiền
	@_ProductId VARCHAR(24) = '',
	@_BankAccId VARCHAR(24) = '',
	@_DeptId VARCHAR(256) = '',
	@_CostCentreId VARCHAR(24) = '',
	@_WorkProcessId VARCHAR(24) = '',
	@_StageId VARCHAR(24) = '',
	@_EmployeeId VARCHAR(24) = '',
	@_CurrencyCode CHAR(3) = '',
	@_JobId VARCHAR(24) = '',
	@_NoteFactorId VARCHAR(512) = '',
	@_SalesChannelId VARCHAR(512) = '',
	@_TerritoryId VARCHAR(512) = '',
	@_CustomFieldId1 VARCHAR(512) = '', -- Thêm 3 Danh mục CustomField
	@_CustomFieldId2 VARCHAR(512) = '',
	@_CustomFieldId3 VARCHAR(512) = '',
	@_OriginalAmount1 NUMERIC(18, 2) = NULL,
	@_OriginalAmount2 NUMERIC(18, 2) = NULL,
	@_DebitAccountList VARCHAR(MAX)	= '',
	@_CreditAccountList VARCHAR(MAX) = '',
	@_Not_DebitAccountList VARCHAR(MAX) = '',
	@_Not_CreditAccountList VARCHAR(MAX) = '',
	@_ExpenseCatgIdList VARCHAR(MAX) = '',
	@_NoteFactorIdList VARCHAR(MAX) = '',
	@_Not_NoteFactorIdList VARCHAR(MAX) = '',
	@_ProfitCenterId VARCHAR(512) = '',
	@_ForeignCurrencyOnly TINYINT = 0,
	@_nUserId INT = 0,
	@_LangId INT = 0,
	@_CurrencyCode0 CHAR(3) = 'VND',
	@_BranchCode VARCHAR(3) = 'A01',
	@_Other_Key1 NVARCHAR(MAX) = '',		-- Dùng cho các báo cáo khác Enter chi tiết được của điều kiện Key1
	@_Other_Key2 NVARCHAR(MAX) = '',		-- Dùng cho các báo cáo khác Enter chi tiết được của điều kiện Key2
	@_FilterByEntryNo TINYINT = 1,			-- Kèm theo điều kiện lọc theo EntryNo
	@_ExchangeRateConvertDesc NVARCHAR(1000) = NULL OUTPUT,	-- Chuỗi hiển thị tỷ giá chuyển đổi khi enter chi tiết từ các báo cáo tài chính chuyển đổi VND 
	@_LAYOUT_XML NVARCHAR(MAX)	= '' OUTPUT,
	@_BranchReportId INT = 0,		-- VũLA xử lý báo báo IAS/IFRS
	@_ChassisNo VARCHAR(512) = '',
	@_EntityAssetId VARCHAR(512) = '',
	@_ExcludeCrspAccount VARCHAR(2000) = '',
	@_ItemId VARCHAR(256)=''
AS
BEGIN
	SET NOCOUNT ON;
	--SET ANSI_NULLS ON;
	--SET ANSI_WARNINGS ON;

	-- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)
	
	-- Trường hợp nhập điều kiện lọc chứa ký tự phẩy trên
	SELECT @_Description = REPLACE(@_Description, CHAR(39), CHAR(39) + CHAR(39)),
		@_DocNo1 = REPLACE(@_DocNo1, CHAR(39), CHAR(39) + CHAR(39)), 
		@_DocNo2 = REPLACE(@_DocNo2, CHAR(39), CHAR(39) + CHAR(39))
	
	DECLARE @_StrTmp NVARCHAR(4000),
			@_Key2 NVARCHAR(MAX), 
			@_KeyAmount NVARCHAR(MAX), 
			@_KeyTmp NVARCHAR(MAX),
			@_DataCode_Branch VARCHAR(8);
			
	SET @_DataCode_Branch = ISNULL((SELECT TOP (1) DataCode FROM dbo.B00Branch WHERE BranchCode = @_BranchCode), '0')

	-- Xử lý key cho phiên bản R2:
	DECLARE @_FilterDebitRow NVARCHAR(128) -- Fix thêm xử lý EntryNo
		
	SET @_FilterDebitRow = ''
			
	SET @_Key2 = ''
	IF @_Account <> ''
	BEGIN
		--SET @_Key2 = '(Account LIKE ''' + @_Account + '%'')'
		SET @_Key2 = N'((Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + '%''))'
		
		IF @_CrspAccount <> ''
		BEGIN
			--SET @_Key2 = @_Key2 + N' AND (CrspAccount LIKE ''' + @_CrspAccount + '%'')'
			SET @_Key2 = @_Key2 + N' AND (CrspAccount LIKE ''' + REPLACE(@_CrspAccount, ',', '%'') OR (CrspAccount LIKE ''') + '%'')'
			
			IF @_FilterByEntryNo = 1
			BEGIN
				IF @_CrspAccount LIKE @_Account + '%'
				BEGIN
					-- Nếu chọn 1 trong các điều kiện Filter thì hiển thị cả Entry A và Entry B trong tình huống phiếu BT
					-- Thêm loại khoản mục dòng tiền
					IF (ISNULL(@_BizDocId_LC, '') <> '' OR ISNULL(@_ExpenseCatgId, '') <> '' OR ISNULL(@_CashFlowId, '') <> '' OR
						ISNULL(@_ProductId, '') <> '' OR ISNULL(@_CostCentreId, '') <> '' OR ISNULL(@_WorkProcessId, '') <> '' OR 
						ISNULL(@_JobId, '') <> '' OR ISNULL(@_BizDocId_PO2, '') <> '' OR ISNULL(@_BizDocId_SO2, '') <> ''
							OR ISNULL(@_BizDocId_PO, '') <> '' OR ISNULL(@_BizDocId_PO, '') <> '')
						SET @_FilterDebitRow = ' AND (EntryNo LIKE ''%A'' OR DocCode = ''BT'')'
					ELSE	
						SET @_FilterDebitRow = ' AND (EntryNo LIKE ''%A'')'
			
				END
				ELSE IF @_Account LIKE @_CrspAccount + '%' 
				BEGIN
					-- Nếu chọn 1 trong các điều kiện Filter thì hiển thị cả Entry A và Entry B trong tình huống phiếu BT
					-- Thêm loại khoản mục dòng tiền
					IF (ISNULL(@_BizDocId_LC, '') <> '' OR ISNULL(@_ExpenseCatgId, '') <> '' OR ISNULL(@_CashFlowId, '') <> '' OR 
						ISNULL(@_ProductId, '') <> '' OR ISNULL(@_CostCentreId, '') <> '' OR ISNULL(@_WorkProcessId, '') <> '' OR 
						ISNULL(@_JobId, '') <> '' OR ISNULL(@_BizDocId_PO2, '') <> '' OR ISNULL(@_BizDocId_SO2, '') <> ''
							OR ISNULL(@_BizDocId_PO, '') <> '' OR ISNULL(@_BizDocId_PO, '') <> '')
						SET @_FilterDebitRow = ' AND (EntryNo LIKE ''%B'' OR DocCode = ''BT'')'
					ELSE	
						SET @_FilterDebitRow = ' AND (EntryNo LIKE ''%B'')'
				END
			END
		END 
	END ELSE
	BEGIN
		IF @_FilterByEntryNo = 1
		BEGIN
			-- Nếu chọn 1 trong các điều kiện Filter thì hiển thị cả Entry A và Entry B
			IF (ISNULL(@_BizDocId_LC, '') <> '' OR ISNULL(@_ExpenseCatgId, '') <> '' OR ISNULL(@_CashFlowId, '') <> '' OR 
				ISNULL(@_ProductId, '') <> '' OR ISNULL(@_CostCentreId, '') <> '' OR ISNULL(@_WorkProcessId, '') <> '' OR 
				ISNULL(@_JobId, '') <> '' OR ISNULL(@_BizDocId_PO2, '') <> '' OR ISNULL(@_BizDocId_SO2, '') <> ''
					OR ISNULL(@_BizDocId_PO, '') <> '' OR ISNULL(@_BizDocId_PO, '') <> '')
				SET @_FilterDebitRow = ' AND (EntryNo LIKE ''%A'' OR DocCode = ''BT'')'
			ELSE
				-- Lấy vế nợ
				SET @_FilterDebitRow = ' AND (EntryNo LIKE ''%A'')'
		END
	END

	IF @_CustomerId <> ''
	BEGIN
		EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId, @_ColGen = 'CustomerId', 
			@_ColName = 'Id', @_TableName = 'B20Customer', 
			@_AndOrKey = 'AND (', @_Key = @_Key2 OUTPUT
		
		IF @_CrspCustomerId <> ''
			BEGIN
				EXECUTE dbo.usp_sys_GenKey @_Code = @_CrspCustomerId, @_ColGen = 'CrspCustomerId', 
					@_ColName = 'Id', @_TableName = 'B20Customer', 
					@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

				SET @_Key2 = @_Key2 + ')'
			END
		ELSE
		BEGIN
				EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId, @_ColGen = 'CrspCustomerId', 
					@_ColName = 'Id', @_TableName = 'B20Customer', 
					@_AndOrKey = 'OR', @_Key = @_Key2 OUTPUT
				SET @_Key2 = @_Key2 + ')'
		END		
	END

	IF @_ProfitCenterId <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_ProfitCenterId, @_ColGen = 'ProfitCenterId', 
			@_ColName = 'Id', @_TableName = 'B20ProfitCenter', 
			@_AndOrKey = 'AND ', @_Key = @_Key2 OUTPUT	

	IF @_ProductId <> ''
		SET @_Key2 = @_Key2 + N' AND (ProductId = ''' + @_ProductId + ''' OR CrspProductId = ''' + @_ProductId + ''')'	
	
	IF @_BankAccId <> ''
		SET @_Key2 = @_Key2 + N' AND (BankAccId = ''' + @_BankAccId + ''' OR CrspBankAccId = ''' + @_BankAccId + ''')'	

	IF ISNULL(@_DebitAccountList, '') <> ''	-- Trung 13/10/2010 thêm điều kiệu khi gọi từ báo cáo khác (lưu chuyển tiền tệ)
		SET @_Key2 = @_Key2 + N' AND (DebitAccount LIKE ''' + REPLACE(@_DebitAccountList, N',', '%'' OR DebitAccount LIKE ''') + '%'')'

	IF ISNULL(@_CreditAccountList, '') <> ''
		SET @_Key2 = @_Key2 + N' AND (CreditAccount LIKE ''' + REPLACE(@_CreditAccountList, N',', '%'' OR CreditAccount LIKE ''') + N'%'')'
	
	IF ISNULL(@_Not_DebitAccountList, '') <> ''
		SET @_Key2 = @_Key2 + N' AND NOT (DebitAccount LIKE ''' + REPLACE(@_Not_DebitAccountList, N',', '%'' OR DebitAccount LIKE ''') + N'%'')'

	IF ISNULL(@_Not_CreditAccountList, '') <> ''
		SET @_Key2 = @_Key2 + N' AND NOT (CreditAccount LIKE ''' + REPLACE(@_Not_CreditAccountList, N',', '%'' OR CreditAccount LIKE ''') + N'%'')'
	
	IF ISNULL(@_ExpenseCatgIdList, '') <> ''
		SET @_Key2 = @_Key2 + N' AND (ExpenseCatgId IN (' + @_ExpenseCatgIdList + '))'

	IF ISNULL(@_NoteFactorIdList, '') <> ''
		SET @_Key2 = @_Key2 + N' AND (NoteFactorId IN (' + @_NoteFactorIdList + '))'

	IF ISNULL(@_Not_NoteFactorIdList, '') <> ''
		SET @_Key2 = @_Key2 + N' AND (NoteFactorId NOT IN (' + @_Not_NoteFactorIdList + ') OR NoteFactorId IS NULL)'

	IF @_FilterByEntryNo = 1
	BEGIN
		IF @_No_Co = 'C'
		BEGIN
			SET @_FilterDebitRow = ' AND (EntryNo LIKE ''%B'')'
		END ELSE IF @_No_Co = 'N'
		BEGIN
			SET @_FilterDebitRow = ' AND (EntryNo LIKE ''%A'')'	
		END
	END

	DECLARE @_FilterDebitRowTmp NVARCHAR(128) = @_FilterDebitRow
	
	-- Xử lý NC sau đoạn GetData
	IF ISNULL(@_No_Co, '') = ''
		SET @_FilterDebitRow = ''

	SET @_Key2 = @_Key2 + @_FilterDebitRow
	
	IF @_DocCode <> '' SET @_Key2 = @_Key2 + N' AND DocCode IN (''' + REPLACE(@_DocCode, ',', ''',''') + ''')'
		
	IF @_Description <> ''
		SET @_Key2 = @_Key2 + N' AND (Description LIKE N''%' + @_Description + N'%'')'

	IF @_DocNo1 = N'0' SET @_DocNo1 = ''
	IF @_DocNo2 = N'0' SET @_DocNo2 = ''

	IF @_DocNo1 <> '' AND @_DocNo2 <> ''
		SET @_Key2 = @_Key2 + N' AND DocNo BETWEEN N''' + @_DocNo1 + ''' AND N''' + @_DocNo2 + NCHAR(39)
	ELSE
	BEGIN
		IF @_DocNo1 <> ''
			SET @_Key2 = @_Key2 + N' AND DocNo >= N''' + @_DocNo1 + NCHAR(39)
		
		IF @_DocNo2 <> ''
			SET @_Key2 = @_Key2 + N' AND DocNo <= N''' + @_DocNo2 + NCHAR(39)
	END

	IF RTRIM(@_DocBookingId) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_DocBookingId, @_ColGen = 'DocBookingId', 
			@_ColName = 'Id', @_TableName = 'B20DocBooking', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	-- Sửa lại key lọc điều kiện mã
	IF @_CustomerId0 <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId0, @_ColGen = 'CustomerId0', 
			@_ColName = 'Id', @_TableName = 'B20Customer', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF @_BizDocId_PO2 <> ''
		SET @_Key2 = @_Key2 + N' AND (BizDocId_PO = ''' + @_BizDocId_PO2 + ''')'

	IF @_BizDocId_SO2 <> ''
		SET @_Key2 = @_Key2 + N' AND (BizDocId_C2 = ''' + @_BizDocId_SO2 + ''')'

	IF @_BizDocId_LC <> ''
		SET @_Key2 = @_Key2 + N' AND (BizDocId_LC = ''' + @_BizDocId_LC + ''')'

	IF @_BizDocId_DA <> ''
		SET @_Key2 = @_Key2 + N' AND (BizDocId_DA = ''' + @_BizDocId_DA + ''')'

	IF @_BizDocId_PO <> ''
		SET @_Key2 = @_Key2 + N' AND (BizDocId_PO = ''' + @_BizDocId_PO + ''')'

	IF @_BizDocId_SO <> ''
		SET @_Key2 = @_Key2 + N' AND (BizDocId_SO = ''' + @_BizDocId_SO + ''')'

	IF ISNULL(@_ChassisNo, '') <> ''	
		SET @_Key2 = @_Key2 + N' AND (ChassisNo LIKE ''' + REPLACE(@_ChassisNo, N',', '%'' OR ChassisNo LIKE ''') + '%'')'

	-- Thêm loại khoản mục dòng tiền
	-- Thêm post sổ cái Khoản mục dòng tiền
	IF RTRIM(@_CashFlowId) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_CashFlowId, @_ColGen = 'CashFlowId', 
			@_ColName = 'Id', @_TableName = 'B20CashFlow', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	-- Sửa lại key lọc điều kiện mã
	IF RTRIM(@_ExpenseCatgId) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_ExpenseCatgId, @_ColGen = 'ExpenseCatgId', 
			@_ColName = 'Id', @_TableName = 'B20ExpenseCatg', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF RTRIM(@_DeptId) <> ''
	SET @_Key2 = @_Key2 + N' DeptId IN (' + REPLACE(@_DeptId, ',', ''',''') + ')'
		--EXECUTE dbo.usp_sys_GenKey @_Code = @_DeptId, @_ColGen = 'DeptId', 
		--	@_ColName = 'Id', @_TableName = 'B20Dept', 
		--	@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF RTRIM(@_ItemId) <> ''
	SET @_Key2 = @_Key2 + N' AND ItemId IN (' + REPLACE(@_ItemId, ',', ''',''') + ')'
		--EXECUTE dbo.usp_sys_GenKey @_Code = @_DeptId, @_ColGen = 'DeptId', 
		--	@_ColName = 'Id', @_TableName = 'B20Dept', 
		--	@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT


	IF RTRIM(@_CostCentreId) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_CostCentreId, @_ColGen = 'CostCentreId', 
			@_ColName = 'Id', @_TableName = 'B20CostCentre', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	--IF RTRIM(@_WorkProcessId) <> ''
	--	EXECUTE dbo.usp_sys_GenKey @_Code = @_WorkProcessId, @_ColGen = 'WorkProcessId', 
	--		@_ColName = 'Id', @_TableName = 'B20WorkProcess', 
	--		@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT
 
	--IF RTRIM(@_StageId) <> ''
	--	EXECUTE dbo.usp_sys_GenKey @_Code = @_StageId, @_ColGen = 'StageId', 
	--		@_ColName = 'Id', @_TableName = 'B20ZStage', 
	--		@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT


	IF @_StageId <> N''
	BEGIN 
		SET @_Key2+=' AND StageId = '+QUOTENAME(@_StageId,CHAR(39))
	END


	IF RTRIM(@_EmployeeId) <> '' 
	BEGIN
		IF @_No_Co <> ''
		BEGIN
			EXECUTE dbo.usp_sys_GenKey @_Code = @_EmployeeId, @_ColGen = 'EmployeeId', 
				@_ColName = 'Id', @_TableName = 'B20Employee', 
				@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT
		END ELSE 
		BEGIN
			SET @_KeyTmp = ''

			EXECUTE dbo.usp_sys_GenKey @_Code = @_EmployeeId, @_ColGen = 'EmployeeId', 
				@_ColName = 'Id', @_TableName = 'B20Employee', 
				@_AndOrKey = '', @_Key = @_KeyTmp OUTPUT

			SET @_Key2 = @_Key2 + N' AND (' + @_KeyTmp

			SELECT @_Key2 = @_Key2 + ' OR (RowId IN (SELECT RowId FROM ' + IIF(DBPartitioned = 1 AND DBNamePartitioned <> '', DBNamePartitioned + '.', '') + 'dbo.B30GeneralLedger' + IIF(DBPartitioned = 1 AND DBNamePartitioned <> '', '', DataCode) + N'
				WHERE ' + @_KeyTmp + ' AND EntryNo LIKE ''%B''))'
			FROM B00FiscalYear 
			WHERE BranchCode IN (SELECT BranchCode FROM [dbo].[ufn_B00Branch_GetChildTable](BranchCode)) 
			GROUP BY BranchCode, DataCode, DBPartitioned, DBNamePartitioned; 

			SET @_Key2 = @_Key2 + ')'
		END
	END 			

	IF RTRIM(@_CurrencyCode) <> ''
		SET @_Key2 = @_Key2 + N' AND (CurrencyCode = ''' + RTRIM(@_CurrencyCode) + N''')'

	IF RTRIM(@_JobId) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_JobId, @_ColGen = 'JobId', 
			@_ColName = 'Id', @_TableName = 'B20Job', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF RTRIM(@_EntityAssetId) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_EntityAssetId, @_ColGen = 'EntityAssetId', 
			@_ColName = 'Id', @_TableName = 'B20EntityAsset', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF @_NoteFactorId <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_NoteFactorId, @_ColGen = 'NoteFactorId', 
			@_ColName = 'Id', @_TableName = 'B20NoteFactor', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF @_SalesChannelId <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_SalesChannelId, @_ColGen = 'SalesChannelId', 
			@_ColName = 'Id', @_TableName = 'B20SalesChannel', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF @_TerritoryId <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_TerritoryId, @_ColGen = 'TerritoryId', 
			@_ColName = 'Id', @_TableName = 'B20Territory', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF RTRIM(@_CustomFieldId1) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomFieldId1, @_ColGen = 'CustomFieldId1', 
			@_ColName = 'Id', @_TableName = 'B20CustomField1', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF RTRIM(@_CustomFieldId2) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomFieldId2, @_ColGen = 'CustomFieldId2', 
			@_ColName = 'Id', @_TableName = 'B20CustomField2', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF RTRIM(@_CustomFieldId3) <> ''
		EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomFieldId3, @_ColGen = 'CustomFieldId3', 
			@_ColName = 'Id', @_TableName = 'B20CustomField3', 
			@_AndOrKey = 'AND', @_Key = @_Key2 OUTPUT

	IF @_ExcludeCrspAccount<>''
	BEGIN
		SET @_Key2+=' AND '+'('+'(CrspAccount NOT LIKE '''+REPLACE(@_ExcludeCrspAccount,',','%'') AND (CrspAccount NOT LIKE ''') +'%'')' +')'
	END

	SET @_KeyAmount = ''
	IF (@_OriginalAmount1 <> 0) AND (@_CurrencyCode = @_CurrencyCode0 OR @_CurrencyCode = '') AND (@_Kieu_Bc <> N'6')
		SET @_KeyAmount = @_KeyAmount + N' AND (Amount >= ' + CAST(@_OriginalAmount1 AS NVARCHAR(18)) + N')'
	ELSE IF (@_OriginalAmount1 <> 0) AND (@_CurrencyCode <> @_CurrencyCode0) AND (@_Kieu_Bc <> N'6')
		SET @_KeyAmount = @_KeyAmount + N' AND (OriginalAmount >= ' + CAST(@_OriginalAmount1 AS NVARCHAR(18)) + N')'
	
	IF (@_OriginalAmount2 <> 0) AND (@_CurrencyCode = @_CurrencyCode0 OR @_CurrencyCode = '') AND (@_Kieu_Bc <> N'6')
		SET @_KeyAmount = @_KeyAmount + N' AND (Amount <= ' + CAST(@_OriginalAmount2 AS NVARCHAR(18)) + N')'
	ELSE IF (@_OriginalAmount2 <> 0) AND (@_CurrencyCode <> @_CurrencyCode0) AND (@_Kieu_Bc <> N'6')
		SET @_KeyAmount = @_KeyAmount + N' AND (OriginalAmount <= ' + CAST(@_OriginalAmount2 AS NVARCHAR(18)) + N')'

	IF @_Other_Key1 <> ''
		SET @_Key2 = @_Key2 + ' AND (' + @_Other_Key1 + ')'

	IF @_Other_Key2 <> ''
		SET @_Key2 = @_Key2 + ' AND (' + @_Other_Key2 + ')'

	-- Không lấy giá trị = 0
	IF @_IsAmount =1
		SET @_Key2 = @_Key2 + ' AND ((Amount <> 0 OR OriginalAmount <> 0))' --and Quantity <> 0
	
	IF LEFT(@_Key2, 5) = N' AND ' SET @_Key2 = SUBSTRING(@_Key2, 6, LEN(@_Key2) - 5)

	IF LEFT(@_KeyAmount, 5) <> '' SET @_KeyAmount = STUFF(@_KeyAmount, 1, 5, '')

	DROP TABLE IF EXISTS #CtTmp;
	SELECT TOP 0 CAST(-1 AS INT) AS Id,
	/* =====================================================
	   1. Thông tin chứng từ
	===================================================== */
		BranchCode,
		Stt,
		RowId,
		DocGroup,
		DocCode,
		DocNo, CAST('' AS NVARCHAR(64)) AS DocNo2,
		DocDate,
		DocBookingId,
		TransCode,
		CAST('' AS NVARCHAR(MAX)) AS Description,
		EntryNo,
		ExchangeRate,
		CurrencyCode,
		DebitAccount,
		CreditAccount,
		Account,
		CrspAccount,
		DocNo AS DocBookingNo,
		DocDate AS DocBookingDate,
		
	/* =====================================================
	   2. Khách hàng
	===================================================== */
		CustomerId AS CustomerId0,
		CustomerId AS CustomerId00,
		CustomerId,
		CustomerId AS CrspCustomerId,
		CustomerCode AS CustomerCode0,
		CustomerCode,
		CustomerName,
		Person,
		CAST(-1 AS INT) AS DebitCustomerId,
		CAST('' AS VARCHAR(32)) AS DebitCustomerCode,
		CAST(-1 AS INT) AS CreditCustomerId,
		CAST('' AS VARCHAR(32)) AS CreditCustomerCode,

	/* =====================================================
	   3. Sản phẩm / Hàng hóa
	===================================================== */
		ProductId, CAST(NULL AS INT) AS ProductId0,
		ProductId AS CrspProductId,
		ProductCode,
		CAST(-1 AS INT) AS DebitProductId,
		CAST('' AS VARCHAR(32)) AS DebitProductCode,
		CAST(-1 AS INT) AS CreditProductId,
		CAST('' AS VARCHAR(32)) AS CreditProductCode,
		CAST(-1 AS INT) AS ProductCatgId,
		CAST('' AS VARCHAR(32)) AS ProductCatgCode,

	/* =====================================================
	   4. Item / Kho
	===================================================== */
		CAST(-1 AS INT) AS ItemId,
		CAST('' AS VARCHAR(32)) AS ItemCode,
		CAST('' AS NVARCHAR(512)) AS ItemName,
		CAST('' AS NVARCHAR(32)) AS ItemType,
		CAST(-1 AS INT) AS WarehouseId,
		CAST('' AS VARCHAR(32)) AS WarehouseCode,
		CAST(-1 AS INT) AS ReceiptWarehouseId,
		CAST('' AS VARCHAR(32)) AS ReceiptWarehouseCode,
		CAST(NULL AS INT) AS DeliveryWarehouseId,		
		CAST('' AS NVARCHAR(384)) AS DeliveryWarehouseCode,

	/* =====================================================
	   5. Số tiền
	===================================================== */
		Amount,
		OriginalAmount,
		DebitAmount,
		OriginalDebitAmount,
		CreditAmount,
		OriginalCreditAmount,
		CAST(0 AS NUMERIC(18,5)) AS Quantity,

	/* =====================================================
	   6. BizDoc liên quan
	===================================================== */
		BizDocId,
		BizDocId AS BizDocId_PO,
		DocNo AS BizDocInfo_PO,
		BizDocId AS BizDocId_SO,
		DocNo AS BizDocInfo_SO,
		BizDocId AS BizDocId_LC,
		DocNo AS BizDocInfo_LC,
		BizDocId AS BizDocId_DA,
		DocNo AS BizDocInfo_DA,
		BizDocId AS BizDocId_C1,
		DocNo AS BizDocInfo_C1,
		BizDocId AS BizDocId_C2,
		DocNo AS BizDocInfo_C2,
		CAST('' AS VARCHAR(32)) AS DebitBizDocId_C1,
		CAST('' AS VARCHAR(32)) AS DebitBizDocInfo_C1,
		CAST('' AS VARCHAR(32)) AS CreditBizDocId_C1,
		CAST('' AS VARCHAR(32)) AS CreditBizDocInfo_C1,
		CAST('' AS VARCHAR(32)) AS DebitBizDocId_C2,
		CAST('' AS VARCHAR(32)) AS DebitBizDocInfo_C2,
		CAST('' AS VARCHAR(32)) AS CreditBizDocId_C2,
		CAST('' AS VARCHAR(32)) AS CreditBizDocInfo_C2,

	/* =====================================================
	   7. Tổ chức / Bộ phận
	===================================================== */
		DeptId,
		DeptCode,
		CAST('' AS NVARCHAR(1000)) AS DeptCode0,
		TerritoryId,
		TerritoryCode,
		CostCentreId,
		CostCentreCode,
		ExpenseCatgId,
		Code AS ExpenseCatgCode,
		CAST('' AS NVARCHAR(1000)) AS ExpenseCatgName,
		CAST(0 AS INT) AS ProfitCenterId,
		CAST('' AS VARCHAR(32)) AS ProfitCenterCode,

	/* =====================================================
	   8. Ngân hàng
	===================================================== */
		BankAccId,
		BankAccId AS CrspBankAccId,
		CAST('' AS VARCHAR(64)) AS BankCode,
		CAST('' AS VARCHAR(64)) AS BankAccountNo,
		CAST('' AS NVARCHAR(364)) AS BankName,

	/* =====================================================
	   9. Nhân viên
	===================================================== */
		EmployeeId,
		EmployeeCode,
		CAST('' AS NVARCHAR(1000)) AS EmployeeName,

	/* =====================================================
	   10. Thông tin xe / RO
	===================================================== */
		CAST('' AS NVARCHAR(64)) AS ChassisNo,
		CAST('' AS NVARCHAR(64)) AS EngineNo,
		CAST('' AS VARCHAR(32)) AS ProductCostId,
		CAST('' AS VARCHAR(32)) AS ProductCostId0,

	/* =====================================================
	   11. Thuế / Đính kèm
	===================================================== */
		TaxCode,
		AtchDocNo,
		AtchDocDate,
		CAST('' AS NVARCHAR(1024)) AS DeclarationNo,
		CAST(NULL AS DATE) DeclarationDate,

	/* =====================================================
	   12. Invoice / Services
	===================================================== */
		CAST('' AS VARCHAR(32)) AS InvoiceType,
		CAST('' AS NVARCHAR(64)) AS InvoiceTypeName,
		CAST('' AS VARCHAR(32)) AS ServicesType,
		CAST('' AS NVARCHAR(64)) AS ServicesTypeName,

	/* =====================================================
	   13. Metadata
	===================================================== */
		CAST(NULL AS DATETIME) AS CreatedAt,
		CAST(-1 AS INT) AS CreatedBy,
		CAST('' AS NVARCHAR(64)) AS CreatedName,
		CAST(NULL AS DATETIME) ModifiedAt,
		CAST(-1 AS INT) AS ModifiedBy,
		CAST('' AS NVARCHAR(64)) AS ModifiedName,
		CAST(0 AS TINYINT) AS IsDisbursement,
		CAST('' AS CHAR(1)) AS IsDisbursements,
		CAST(-1 AS INT) AS StageId,
		CAST('' AS NVARCHAR(64)) AS StageCode,
		CAST('' AS NVARCHAR(64)) AS DocNo_RO_Acc,
		CAST(-1 AS INT) AS DueDate,

	/* =====================================================
	   14. Khác
	===================================================== */
		CAST(0 AS INT) AS NoteFactorId,
		Code AS NoteFactorCode,
		Name AS NoteFactorName,
		CAST('' AS NVARCHAR(48)) AS Nhom,
		CAST('' AS NVARCHAR(1000)) AS Ten_Nhom,
		CAST('' AS NVARCHAR(128)) AS _FormatStyleKey,
		CAST(0 AS INT) AS CashFlowId,
		Code AS CashFlowCode,
        CAST('' AS NVARCHAR(1000)) AS CashFlowName,
		CAST('' AS VARCHAR(32)) AS AssetCode,
		CAST('' AS NVARCHAR(1000)) AS AssetName,
		CAST('' AS NVARCHAR(1000)) AS BranchName,
		CAST('' AS VARCHAR(8)) AS EntryNoTmp, 
		CAST('' AS VARCHAR(8)) AS EntryNoTmp1,

		CAST(NULL AS INT)			AS JobId,
        CAST('' AS VARCHAR(24))		AS JobCode,
		CAST('' AS NVARCHAR(1000))	AS JobName,

        CAST(NULL AS INT) AS EntityAssetId,
        CAST('' AS VARCHAR(24)) AS EntityAssetCode,
		CAST('' AS NVARCHAR(1000)) AS EntityAssetName 
	INTO #CtTmp
	FROM B00CtTmp (NOLOCK);



	EXECUTE usp_B30GeneralLedger_GetData
		@_DocDate1 = @_DocDate1, 
		@_DocDate2 = @_DocDate2, 
		@_Key1 = @_Key2, 
		@_Key2 = '', 
		@_CtTmp	= N'#CtTmp', 
		@_nUserId = @_nUserId, 
		@_LangId = @_LangId, 
		@_BranchCode = @_BranchCode,
		@_CurrencyCode0	= @_CurrencyCode0,
		@_BranchReportId = @_BranchReportId
		 
 

	-- 29/05/2024 ThắngĐQ: Xử lý báo cáo 2 dòng khi không chọn nợ có
	UPDATE #CtTmp 
	SET ProductCostId = ProductCostId0 
	WHERE ProductCostId = '' AND ProductCostId0 <> '';

	-- 29/05/2024 ThắngĐQ: Xử lý báo cáo 2 dòng khi không chọn nợ có
	IF ISNULL(@_No_Co, '') = ''
	BEGIN
		UPDATE #CtTmp 
		SET EntryNoTmp = RIGHT(EntryNo, 1), EntryNoTmp1 = LEFT(EntryNo, LEN(EntryNo) - 1)

		DROP TABLE IF EXISTS #CtTmp_EntryB
		SELECT RowId, CustomerId, BankAccId, ProductId, DebitAccount, CreditAccount, EntryNoTmp, EntryNoTmp1
		INTO #CtTmp_EntryB
		FROM #CtTmp tb
		WHERE EntryNoTmp = 'B' AND EXISTS(SELECT * FROM #CtTmp AS tb1 WHERE tb1.RowId = tb.RowId AND tb1.EntryNoTmp = 'A')

		DELETE FROM tb 
		FROM #CtTmp AS tb
			INNER JOIN #CtTmp_EntryB AS tb1 ON tb.RowId = tb1.RowId AND tb.EntryNoTmp1 = tb.EntryNoTmp1
		WHERE tb.EntryNoTmp = 'B'

		UPDATE tb
		SET CrspCustomerId = tb1.CustomerId, CrspProductId = tb1.ProductId, CrspBankAccId = tb1.BankAccId
		FROM #CtTmp tb
			INNER JOIN #CtTmp_EntryB tb1 ON tb.RowId = tb1.RowId AND 
				tb.DebitAccount = tb1.DebitAccount AND tb.CreditAccount = tb1.CreditAccount AND
				tb.EntryNoTmp1 = tb1.EntryNoTmp1

		DROP TABLE #CtTmp_EntryB

		--DROP TABLE IF EXISTS #_CtTmpOther;
		--SELECT Stt, DebitAccount, CreditAccount, RowId, ProductId, CustomerId
		--INTO #_CtTmpOther
		--FROM #CtTmp
		--WHERE EntryNo LIKE '%B' AND (ProductId IS NOT NULL OR CustomerId IS NOT NULL)

		--IF ISNULL(@_FilterDebitRowTmp, '') <> ''
		--	DELETE FROM #CtTmp WHERE EntryNo LIKE '%B'		

		--UPDATE #CtTmp
		--SET ProductId = tb1.ProductId
		--FROM #CtTmp tb
		--	INNER JOIN #_CtTmpOther tb1 ON tb.Stt = tb1.Stt AND tb.RowId = tb1.RowId AND
		--		tb.CreditAccount = tb1.CreditAccount AND tb.DebitAccount = tb1.DebitAccount
		--	INNER JOIN dbo.B20ChartOfAccount acc ON acc.Code = tb1.CreditAccount AND acc.ProductAccount = 1
		--WHERE tb.ProductId IS NULL
		
		--UPDATE #CtTmp 
		--SET CustomerId = tb1.CustomerId
		--FROM #CtTmp tb
		--	INNER JOIN #_CtTmpOther tb1 ON tb.Stt = tb1.Stt AND tb.RowId = tb1.RowId AND
		--		tb.CreditAccount = tb1.CreditAccount AND tb.DebitAccount = tb1.DebitAccount
		--	INNER JOIN dbo.B20ChartOfAccount acc ON acc.Code = tb1.CreditAccount AND acc.CustomerAccount = 1
		--WHERE tb.CustomerId IS NULL

		--DROP TABLE #_CtTmpOther;
	END

	UPDATE #CtTmp 
	SET CustomerId = CrspCustomerId 
	WHERE CustomerId IS NULL AND CrspCustomerId IS NOT NULL

	-- THANGNH lấy theo CrspProductId nếu nằm ở vế Có
	UPDATE #CtTmp 
	SET ProductId = CrspProductId 
	WHERE ProductId IS NULL AND CrspProductId IS NOT NULL

	--AccDoc
	DROP TABLE IF EXISTS #AccDoc
	SELECT TOP (0) Stt, DocCode, InvoiceType, ReceiptWarehouseId, DeclarationNo, DeclarationDate, CreatedAt, CreatedBy, ModifiedAt, ModifiedBy
		INTO #AccDoc
		FROM dbo.vB30AccDoc WITH (NOLOCK);
	CREATE INDEX IX_AccDoc ON #AccDoc(Stt, DocCode);

	--AccDocOther
	DROP TABLE IF EXISTS #AccDocOther
	SELECT TOP (0) Stt, DocCode, RowId, DebitCustomerId, CreditCustomerId, DebitProductId,
			CreditProductId, DebitBizDocId_C1, CreditBizDocId_C1, DebitBizDocId_C2, CreditBizDocId_C2
		INTO #AccDocOther
		FROM dbo.B30AccDocOther WITH (NOLOCK);
	CREATE INDEX IX_AccDocOther ON #AccDocOther(Stt, DocCode, ROWID);

	--#BizDoc
	DROP TABLE IF EXISTS #BizDoc
	SELECT BizDocId, DocNo
		INTO #BizDoc
		FROM dbo.B30BizDoc WITH (NOLOCK);
	CREATE INDEX IX_BizDoc ON #BizDoc(BizDocId);

	--#StockLedger
	DROP TABLE IF EXISTS #StockLedger
	SELECT DocCode, Stt, RowId, WarehouseId, ReceiptWarehouseId, ItemId,CAST(0 AS INT) AS DocGroup
		INTO #StockLedger
		FROM dbo.B30StockLedger WITH (NOLOCK);
	CREATE INDEX IX_StockLedger ON #StockLedger(DocCode, Stt, ROWID);
	
	SET @_StrTmp = N'
		INSERT INTO #AccDoc(Stt, DocCode, InvoiceType, ReceiptWarehouseId, DeclarationNo, DeclarationDate, CreatedAt, CreatedBy, ModifiedAt, ModifiedBy)
		SELECT Stt, DocCode, InvoiceType, ReceiptWarehouseId, DeclarationNo, DeclarationDate, CreatedAt, CreatedBy, ModifiedAt, ModifiedBy
			FROM dbo.vB3'+ @_DataCode_Branch+'AccDoc (NOLOCK) as acc
			WHERE EXISTS(SELECT Stt FROM #CtTmp WHERE Stt = acc.Stt AND DocCode = acc.DocCode) AND IsActive =1;
			
		INSERT INTO #AccDocOther
		(
			Stt, DocCode, RowId, DebitCustomerId, CreditCustomerId, DebitProductId,
			CreditProductId, DebitBizDocId_C1, CreditBizDocId_C1, DebitBizDocId_C2, CreditBizDocId_C2
		)
		SELECT Stt, DocCode, RowId, DebitCustomerId, CreditCustomerId, DebitProductId,
			CreditProductId, DebitBizDocId_C1, CreditBizDocId_C1, DebitBizDocId_C2, CreditBizDocId_C2
			FROM dbo.B3'+ @_DataCode_Branch+'AccDocOther (NOLOCK) as oth 
			WHERE EXISTS(SELECT Stt FROM #CtTmp WHERE RowId = oth.RowId AND Stt = oth.Stt AND DocCode = oth.DocCode) AND IsActive =1;
			
		INSERT INTO #BizDoc(BizDocId, DocNo)
		SELECT BizDocId, DocNo
			FROM dbo.B3'+ @_DataCode_Branch+'BizDoc(NOLOCK) as biz
			WHERE EXISTS(SELECT Stt FROM #CtTmp 
							WHERE BizDocId_C1 = biz.BizDocId OR DebitBizDocId_C1 = biz.BizDocId OR CreditBizDocId_C1 = biz.BizDocId 
							  OR BizDocId_C2 = biz.BizDocId OR DebitBizDocId_C2 = biz.BizDocId OR CreditBizDocId_C2 = biz.BizDocId
							  OR BizDocId_LC = biz.BizDocId 
							) AND IsActive =1;

		INSERT INTO #BizDoc(BizDocId, DocNo)
		SELECT BizDocId, DocNo
			FROM dbo.B3'+ @_DataCode_Branch+'BizDocSO(NOLOCK) as biz
			WHERE EXISTS(SELECT Stt FROM #CtTmp 
							WHERE BizDocId_C2 = biz.BizDocId OR DebitBizDocId_C2 = biz.BizDocId OR CreditBizDocId_C2 = biz.BizDocId
							) AND IsActive =1;
							
		INSERT INTO #StockLedger
		(
			DocCode, Stt, RowId, WarehouseId, ReceiptWarehouseId, ItemId, DocGroup
		)
		SELECT DocCode, Stt, RowId, WarehouseId, ReceiptWarehouseId, ItemId , DocGroup
			FROM dbo.B3'+ @_DataCode_Branch+'StockLedger (NOLOCK) as sl 
			WHERE EXISTS(SELECT Stt FROM #CtTmp WHERE RowId = sl.RowId AND Stt = sl.Stt AND DocCode = sl.DocCode) AND IsActive =1;'
	EXECUTE(@_StrTmp);
	

	UPDATE t
		SET
			-- PO/SO/LC/DA
			BizDocInfo_PO = ISNULL(po.DocNo,''),
			BizDocInfo_SO = ISNULL(so.DocNo,''),
			BizDocInfo_LC = ISNULL(lc.DocNo,''),
			BizDocInfo_DA = ISNULL(da.DocNo,''),

			-- AccDoc
			InvoiceType = ad.InvoiceType,
			CreatedAt = ad.CreatedAt,
			CreatedBy = ad.CreatedBy,
			ModifiedAt = ad.ModifiedAt,
			ModifiedBy = ad.ModifiedBy,
			DeclarationNo = ad.DeclarationNo,
			DeclarationDate = ad.DeclarationDate,

			-- AccDocOther
			DebitCustomerId = ado.DebitCustomerId,
			CreditCustomerId = ado.CreditCustomerId,
			DebitProductId = ado.DebitProductId,
			CreditProductId = ado.CreditProductId,
			DebitBizDocId_C1 = ado.DebitBizDocId_C1,
			CreditBizDocId_C1 = ado.CreditBizDocId_C1,
			DebitBizDocId_C2 = ado.DebitBizDocId_C2,
			CreditBizDocId_C2 = ado.CreditBizDocId_C2,

			-- BizDoc C1 C2
			BizDocInfo_C1 = ISNULL(c1.DocNo,''),
			DebitBizDocInfo_C1 = ISNULL(dbC1.DocNo,''),
			CreditBizDocInfo_C1 = ISNULL(cdC1.DocNo,''),
			BizDocInfo_C2 = ISNULL(c2.DocNo,''),
			DebitBizDocInfo_C2 = ISNULL(dbC2.DocNo,''),
			CreditBizDocInfo_C2 = ISNULL(cdC2.DocNo,''),

			-- Stock
			ItemId = stl.ItemId,
			DeliveryWarehouseId = stl.DeliveryWarehouseId,
			ReceiptWarehouseId = stl.ReceiptWarehouseId,

            EntityAssetCode = EntityAsset.Code,
            EntityAssetName = EntityAsset.Name,

			t.JobCode = Job.Code,
			t.JobName = Job.Name
 
		FROM #CtTmp t

		LEFT JOIN #AccDoc ad ON t.Stt = ad.Stt AND t.DocCode = ad.DocCode

		LEFT JOIN #AccDocOther ado ON t.RowId = ado.RowId AND t.Stt = ado.Stt AND t.DocCode = ado.DocCode 

		LEFT JOIN #BizDoc po ON t.BizDocId_PO = po.BizDocId
		LEFT JOIN #BizDoc so ON t.BizDocId_SO = so.BizDocId
		LEFT JOIN #BizDoc lc ON t.BizDocId_LC = lc.BizDocId
		LEFT JOIN #BizDoc da ON t.BizDocId_DA = da.BizDocId

		LEFT JOIN #BizDoc c1 ON t.BizDocId_C1 = c1.BizDocId
		LEFT JOIN #BizDoc dbC1 ON t.DebitBizDocId_C1 = dbC1.BizDocId
		LEFT JOIN #BizDoc cdC1 ON t.CreditBizDocId_C1 = cdC1.BizDocId

		LEFT JOIN #BizDoc c2 ON t.BizDocId_C2 = c2.BizDocId
		LEFT JOIN #BizDoc dbC2 ON t.DebitBizDocId_C2 = dbC2.BizDocId
		LEFT JOIN #BizDoc cdC2 ON t.CreditBizDocId_C2 = cdC2.BizDocId
		LEFT JOIN B20EntityAsset EntityAsset ON t.EntityAssetId = EntityAsset.Id
		LEFT JOIN B20Job Job ON t.JobId = Job.Id

		LEFT JOIN
		(
			SELECT DocCode, Stt, RowId, ItemId,
				MAX(IIF(DocGroup ='2', WarehouseId, NULL)) AS DeliveryWarehouseId,
				MAX(IIF(DocGroup ='1' AND DocCode <> 'DC', WarehouseId, ReceiptWarehouseId)) AS ReceiptWarehouseId
			 FROM #StockLedger 
			 GROUP BY  DocCode, Stt, RowId, ItemId
		)stl ON t.DocCode = stl.DocCode AND t.Stt = stl.Stt AND t.RowId = stl.RowId
		--LEFT JOIN #StockLedger stl2 ON t.DocCode = stl2.DocCode AND t.Stt = stl2.Stt AND t.RowId = stl2.RowId AND stl2.DocGroup = 2

		--	IF HOST_NAME() = 'TINNT-BSG'
		--BEGIN 
		
		--	--SELECT stt,ct.RowId, ct.WarehouseId,ct.ReceiptWarehouseId,* FROM #CtTmp AS ct 		
		--	--SELECT * FROM #StockLedger AS sl WHERE stt = 'I260011731DC' 
		--	--SELECT * FROM #StockLedger AS sl WHERE stt = 'I260011731DC'  AND stl.DocGroup = 2

		--	--SELECT ct.WarehouseId FROM #CtTmp AS ct
		--END 

	DROP TABLE IF EXISTS #AccDoc
	DROP TABLE IF EXISTS #AccDocOther
	DROP TABLE IF EXISTS #BizDoc
	DROP TABLE IF EXISTS #StockLedger	
	
	--Riêng
	SET @_StrTmp= 
		N'UPDATE #CtTmp 
			SET AssetCode=ISNULL(dm.Code,'''') 
				, AssetName = ISNULL(dm.Name,'''')
			FROM #CtTmp A 
				INNER JOIN dbo.B3'+@_DataCode_Branch+N'AccDocAutoEntry1 B WITH(NOLOCK) ON A.RowId=B.RowId
				LEFT OUTER JOIN B2'+@_DataCode_Branch+N'Asset dm ON dm.Id = b.AssetId;' + NCHAR(13) +

		N'UPDATE Ct SET DocNo2 = sl.DocNo2
		  FROM #CtTmp Ct
			INNER JOIN dbo.vB3'+@_DataCode_Branch+N'StockLedger_DataApi as sl WITH(NOLOCK) 
				ON Ct.Stt = sl.Stt AND Ct.DocCode = sl.DocCode'
	 EXECUTE(@_StrTmp); IF (@@ERROR <> 0) PRINT @_StrTmp
	 
	--Xử lý thuế
	DROP TABLE IF EXISTS #AtchDocTmp;
	SELECT TOP (0) Stt, RowId, RowId_SourceDoc, TaxCode, AtchDocNo, AtchDocDate
		INTO #AtchDocTmp
		FROM dbo.vB30AccDocAtch_GetDataVAT WITH (NOLOCK)

	SET @_StrTmp = N'
		INSERT INTO #AtchDocTmp(Stt, RowId, RowId_SourceDoc, TaxCode, AtchDocNo, AtchDocDate)
		SELECT Stt, RowId, RowId_SourceDoc, TaxCode, AtchDocNo, AtchDocDate
			FROM dbo.vB3' + @_DataCode_Branch + 'AccDocAtch_GetDataVAT WITH (NOLOCK)
			WHERE ISNULL(TaxCode,'''') <> '''';';
	EXEC (@_StrTmp);
	
	CREATE NONCLUSTERED INDEX IX_CtTmp_Stt_RowId ON #CtTmp (Stt, RowId);

	UPDATE ct
	SET 
		TaxCode     = ISNULL(a.TaxCode, ct.TaxCode),
		AtchDocNo   = ISNULL(a.AtchDocNo, ct.AtchDocNo),
		AtchDocDate = ISNULL(a.AtchDocDate, ct.AtchDocDate)
	FROM #CtTmp ct
	OUTER APPLY
	(
		SELECT TOP 1 *
			FROM #AtchDocTmp a
			WHERE a.Stt = ct.Stt
			  AND (
					a.RowId_SourceDoc = ct.RowId
				 OR a.RowId_SourceDoc = ''
				 OR a.RowId = ct.RowId
				  )
			ORDER BY 
				CASE 
					WHEN a.RowId_SourceDoc = ct.RowId THEN 1
					WHEN a.RowId_SourceDoc = '' THEN 2
					WHEN a.RowId = ct.RowId THEN 3
					ELSE 4
				END
	) a;
	DROP TABLE IF EXISTS #AtchDocTmp;
	
	CREATE CLUSTERED INDEX IX_CtTmp_Id ON #CtTmp(Id);
	CREATE NONCLUSTERED INDEX IX_CtTmp_FK ON #CtTmp
	(
		CustomerId,
		EmployeeId,
		ProductId,
		BankAccId,
		StageId
	);
		SET @_StrTmp = N'
		UPDATE T
		SET TerritoryId = COALESCE(A.TerritoryId, B.TerritoryId)
		FROM #CtTmp T
			LEFT JOIN dbo.vB3' + @_DataCode_Branch + 'AccDoc AS A 
				ON T.Stt = A.Stt
			LEFT JOIN dbo.vB3' + @_DataCode_Branch + 'AccDoc_GetDataSub AS B 
				ON T.RowId = B.RowId
	';

	EXEC (@_StrTmp);

	UPDATE t
		SET 
			-- Customer
			CustomerCode0      = ISNULL(cus0.Code, ''),
			CustomerCode       = ISNULL(cus.Code, ''),
			CustomerName       = ISNULL(cus.Name, ''),
			DebitCustomerCode  = dbcs.Code,
			CreditCustomerCode = cdcs.Code,

			-- Employee
			EmployeeCode  = ISNULL(emp.Code, ''),
			DeptCode0     = ISNULL(emp.DeptCode0, ''),
			EmployeeName  = ISNULL(emp.NAME, ''),
			DeptCode      = ISNULL(dept.Code, ''),

			-- Expense / Product
			ExpenseCatgCode = ISNULL(ex.Code, ''),
			ExpenseCatgName = ISNULL(ex.Name, ''),
			ProductCode     = ISNULL(pro.Code, ''),
			DebitProductCode  = ISNULL(dbpr.Code, ''),
			CreditProductCode = ISNULL(cdpr.Code, ''),
			ProductCatgCode   = ISNULL(pdc.Code, ''),

			-- Cash / Bank
			CashFlowCode = ISNULL(cs.Code, ''),
			CashFlowName = ISNULL(cs.Name, ''),
			BankCode     = CASE WHEN t.DocGroup = 1 THEN bank.BankCode ELSE bank2.BankCode END,
			BankAccountNo= CASE WHEN t.DocGroup = 1 THEN bank.BankAccountNo ELSE bank2.BankAccountNo END,
			BankName     = CASE WHEN t.DocGroup = 1 THEN bank.Description ELSE bank2.Description END,

			-- Cost / Territory / Job
			CostCentreCode = ISNULL(cc.Code, ''),
			TerritoryCode  = ISNULL(ter.Code, ''),
			ProfitCenterCode = ISNULL(pfc.Code, ''),

			-- Work / Stage
			StageCode       = ISNULL(stg.Code, ''),

			-- Class
			InvoiceTypeName  = ISNULL(cliv.Name,''),
			ServicesTypeName = ISNULL(clsv.Name,''),

			-- Item
			ItemCode  = ISNULL(it.Code,''),
			ItemName  = it.Name,
			ItemType  = CONVERT(VARCHAR(10), it.ItemType) + ' - ' + clit.Name,

			-- Warehouse
			ReceiptWarehouseCode = ISNULL(rwh.Code, ''),
			DeliveryWarehouseCode   = ISNULL(dwh.Code,''),

			-- User
			CreatedName  = crd.FullName,
			ModifiedName = mdf.FullName,

			-- Chassis
			EngineNo = Chassis.EngineNo,
 
            EntityAssetCode = EntityAsset.Code,
            EntityAssetName = EntityAsset.Name
		FROM #CtTmp t

		-- Customer
		LEFT JOIN dbo.B20Customer cus0 ON t.CustomerId0 = cus0.Id
		LEFT JOIN dbo.B20Customer cus  ON t.CustomerId  = cus.Id
		LEFT JOIN dbo.B20Customer dbcs ON t.DebitCustomerId  = dbcs.Id
		LEFT JOIN dbo.B20Customer cdcs ON t.CreditCustomerId = cdcs.Id

		-- Employee
		LEFT JOIN dbo.vB20HrmEmployee emp ON t.EmployeeId = emp.Id
		LEFT JOIN dbo.B20Dept dept ON t.DeptId = dept.Id

		-- Expense / Product
		LEFT JOIN dbo.B20ExpenseCatg ex ON t.ExpenseCatgId = ex.Id
		LEFT JOIN dbo.B20Product pro ON t.ProductId0 = pro.Id
		LEFT JOIN dbo.B20Product dbpr ON t.DebitProductId = dbpr.Id
		LEFT JOIN dbo.B20Product cdpr ON t.CreditProductId = cdpr.Id
		LEFT JOIN dbo.B20ProductCatg pdc ON t.ProductCatgId = pdc.Id

		-- Cash / Bank
		LEFT JOIN dbo.B20CashFlow cs ON t.CashFlowId = cs.Id
		LEFT JOIN dbo.B20BankAccount bank  ON t.BankAccId = bank.Id
		LEFT JOIN dbo.B20BankAccount bank2 ON t.CrspBankAccId = bank2.Id

		-- Cost / Territory / Job
		LEFT JOIN dbo.B20CostCentre cc ON t.CostCentreId = cc.Id
		LEFT JOIN dbo.B20Territory ter ON t.TerritoryId = ter.Id
		LEFT JOIN dbo.B20ProfitCenter pfc ON t.ProfitCenterId = pfc.Id

		-- Work / Stage
		LEFT JOIN dbo.B20ZStage stg ON t.StageId = stg.Id

		-- Class
		LEFT JOIN dbo.B20Class cliv ON t.InvoiceType = cliv.Code AND cliv.ParentCode ='InvoiceType'
		LEFT JOIN dbo.B20Class clsv ON t.ServicesType = clsv.Code AND clsv.ParentCode ='ServicesType'
		LEFT JOIN dbo.B20Item it ON t.ItemId = it.Id
		LEFT JOIN dbo.B20Class clit ON it.ItemType = clit.Code AND clit.ParentCode ='DMVT_Loai_Vt'

		-- Warehouse
		LEFT JOIN dbo.B20Warehouse rwh ON t.ReceiptWarehouseId = rwh.Id
		LEFT JOIN dbo.B20Warehouse dwh WITH (NOLOCK) ON t.DeliveryWarehouseId = dwh.Id

		-- User
		LEFT JOIN dbo.B00UserList crd ON t.CreatedBy = crd.Id
		LEFT JOIN dbo.B00UserList mdf ON t.ModifiedBy = mdf.Id

		-- Chassis
		LEFT JOIN dbo.B20Chassis Chassis ON t.ChassisNo = Chassis.ChassisNo 
	    
		LEFT JOIN B20EntityAsset EntityAsset ON t.EntityAssetId = EntityAsset.Id;

	UPDATE ct
	SET BranchName = br.BranchName
	FROM #CtTmp AS ct 
		INNER JOIN dbo.B00Branch AS br ON br.BranchCode = ct.BranchCode;
	--Ynq:

	UPDATE ct
	SET DocBookingNo = db.Code, 
		DocBookingDate = db.DocBookingDate
	FROM #CtTmp AS ct 
		LEFT OUTER JOIN dbo.B20DocBooking db ON ct.DocBookingId = db.Id
	WHERE ISNULL(ct.DocBookingId, 0) <> 0

	-- Do chỉ lấy bên vế nợ nên có thể mã sản phẩm nằm ở bên vế có
	IF @_ProductId <> ''
		UPDATE #CtTmp SET ProductId = @_ProductId
	ELSE
	BEGIN
		-- Kiểu báo cáo nhóm theo sản phẩm
		IF @_No_Co = '' AND @_Kieu_Bc = N'5'
			UPDATE #CtTmp SET ProductId = CrspProductId WHERE ISNULL(ProductId, 0) = 0
	END
	
	-- Do chỉ lấy bên vế nợ nên có thể số tknh nằm ở bên vế có
	IF @_BankAccId <> ''
		UPDATE #CtTmp SET BankAccId = @_BankAccId
	ELSE
	BEGIN
		-- Kiểu báo cáo nhóm theo sản phẩm
		IF @_No_Co = '' AND @_Kieu_Bc = N'h'
			UPDATE #CtTmp SET BankAccId = CrspBankAccId WHERE ISNULL(BankAccId, 0) = 0
	END
	
	UPDATE #CtTmp SET BizDocId = CASE WHEN BizDocId_SO > '' THEN BizDocId_SO ELSE BizDocId_PO END

	-- Báo cáo nhóm theo hợp đồng
	IF @_Kieu_Bc = '2'
	BEGIN
		ALTER TABLE #CtTmp ADD OrderTypeId TINYINT NULL;

		-- Lấy dữ liệu loại HĐ
		-- Đổi bảng dữ liệu đầu phiếu PO, SO
		SET @_StrTmp =
			N'UPDATE tb
				SET OrderTypeId = biz.OrderTypeId
				FROM #CtTmp AS tb 
					INNER JOIN dbo.B3'+ @_DataCode_Branch+'BizDocSO biz ON biz.BizDocId = tb.BizDocId
				WHERE tb.BizDocId IS NOT NULL AND tb.BizDocId <> '''' AND biz.OrderTypeId = 2;' + NCHAR(13) +
			N'UPDATE tb 
				SET OrderTypeId = biz.OrderTypeId
				FROM #CtTmp AS tb INNER JOIN dbo.B3'+ @_DataCode_Branch+'BizDocPO biz ON biz.BizDocId = tb.BizDocId
				WHERE tb.BizDocId IS NOT NULL AND tb.BizDocId <> '''' AND biz.OrderTypeId = 2;'
		EXECUTE(@_StrTmp);
		-- Xóa dữ liệu đơn hàng (Nếu có)
		UPDATE #CtTmp SET BizDocId = '' WHERE OrderTypeId IS NULL
	END



	UPDATE ct 
	SET ct.NoteFactorCode = dm.Code,
		ct.NoteFactorName = dm.Name
	FROM #CtTmp AS ct 
		INNER JOIN dbo.B20NoteFactor AS dm ON ct.NoteFactorId = dm.Id
	WHERE ct.NoteFactorId IS NOT NULL


	DECLARE @_ValueCol NVARCHAR(48), @_DocNoCol NVARCHAR(48), @_CodeCol NVARCHAR(48), 
		@_NameCol NVARCHAR(48), @_TableName NVARCHAR(64), 
		@_FilterExpr NVARCHAR(256), @_ValueExpr NVARCHAR(256), @_SqlTmp NVARCHAR(4000)

	SELECT TOP 1 @_ValueCol = ValueCol, @_DocNoCol = DocNoCol, @_CodeCol = CodeCol, 
		@_NameCol = NameCol, @_TableName = TableName, @_FilterExpr = FilterExpr, @_ValueExpr = ValueExpr
	FROM B20Class
	WHERE ParentCode = 'REP09_BKCT' AND Code = @_Kieu_Bc;


	IF ISNULL(@_ValueExpr, '') <> ''
		SET @_SqlTmp = 'UPDATE #CtTmp SET Nhom = ' + @_ValueExpr + ',' + CHAR(13) +
							'Ten_Nhom = ' + @_ValueExpr
	ELSE IF ISNULL(@_DocNoCol, '') <> ''
		SET @_SqlTmp = 'UPDATE #CtTmp SET Nhom = dm.' + @_DocNoCol + ',' + CHAR(13) +
						'Ten_Nhom = RTRIM(dm.' + @_DocNoCol + ') + '' - '' + ISNULL(dm.' + @_NameCol + ', N'''')' + CHAR(13) +
						'FROM #CtTmp AS bc' + CHAR(13) +
						'LEFT OUTER JOIN ' + @_TableName + ' AS dm ON bc.' + @_ValueCol + ' = dm.' + @_CodeCol
	ELSE IF ISNULL(@_TableName, '') <> ''
		SET @_SqlTmp = 'UPDATE #CtTmp SET Nhom = dm.' + IIF(@_CodeCol = 'Id', 'Code', @_CodeCol) + ',' + CHAR(13) +
						'Ten_Nhom = RTRIM(dm.' + IIF(@_CodeCol = 'Id', 'Code', @_CodeCol) + ') + '' - '' + ISNULL(dm.' + @_NameCol + ', N'''')' + CHAR(13) +
						'FROM #CtTmp AS bc' + CHAR(13) +
						'LEFT OUTER JOIN ' + @_TableName + ' AS dm ON bc.' + @_ValueCol + ' = dm.' + @_CodeCol

	DECLARE @_Msg_KhongNhom NVARCHAR(128) = dbo.ufn_sys_MessageText(N'KhongNhom', @_LangId)

	IF (@_Kieu_Bc <> '1')	
	BEGIN
		EXECUTE (@_SqlTmp);
		
		UPDATE #CtTmp 
		SET Nhom = @_Msg_KhongNhom, Ten_Nhom = @_Msg_KhongNhom
		WHERE ISNULL(Nhom, '') = '' 
	END	

	SET @_KeyAmount = CASE WHEN @_KeyAmount <> '' THEN 'WHERE ' + @_KeyAmount ELSE '' END

	UPDATE #CtTmp SET IsDisbursements = 'x' WHERE IsDisbursement =1
 
	IF (@_Kieu_Bc = '6')
	BEGIN
		SET @_StrTmp =
			N'UPDATE #CtTmp 
				SET Description = ISNULL(ct.Description,'''')
				FROM #CtTmp AS bc 
				LEFT OUTER JOIN dbo.B3'+ @_DataCode_Branch+'AccDoc AS ct ON bc.Stt = ct.Stt;'
		EXECUTE(@_StrTmp);

		-- Bỏ các cột không cần
		SELECT MAX(Id) AS Id, MAX(DocCode) AS DocCode, MAX(DocGroup) AS DocGroup, MAX(DocDate) AS DocDate, MAX(DocNo) AS DocNo, 
			MAX(TransCode) AS TransCode, MAX(CustomerCode0) AS CustomerCode0, MAX(CustomerCode) AS CustomerCode,
			MAX(CustomerName) AS CustomerName, MAX(Description) AS Description, 
			MAX(BizDocInfo_PO) AS BizDocInfo_PO, MAX(BizDocInfo_SO) AS BizDocInfo_SO,
			MAX(BizDocInfo_LC) AS BizDocInfo_LC, MAX(BizDocInfo_DA) AS BizDocInfo_DA,
			MAX(ExpenseCatgCode) AS ExpenseCatgCode, MAX(BankCode) AS BankCode, MAX(BankAccountNo) AS BankAccountNo, MAX(BankName) AS BankName,
			MAX(DeptCode) AS DeptCode, MAX(EmployeeId) AS EmployeeId, MAX(EmployeeCode) AS EmployeeCode,
			MAX(CostCentreCode) AS CostCentreCode, MAX(TaxCode) AS TaxCode, MAX(ExchangeRate) AS ExchangeRate, MAX(CurrencyCode) AS CurrencyCode,
			MAX(CashFlowId) AS CashFlowId, MAX(CashFlowCode) AS CashFlowCode, MAX(NoteFactorCode) AS NoteFactorCode,MAX(TerritoryCode) AS TerritoryCode,
			'' AS DebitAccount, SUM(DebitAmount) AS DebitAmount, SUM(CreditAmount) AS CreditAmount, '' AS CreditAccount,
			MAX(Account) AS Account, MAX(CrspAccount) AS CrspAccount,
			SUM(Amount) AS Amount, SUM(OriginalAmount) AS OriginalAmount, SUM(Quantity) AS Quantity,
			MAX(Nhom) AS Nhom, '' AS Ten_Nhom, 
			CAST('' AS NVARCHAR(128)) AS _FormatStyleKey,
			MAX(DocBookingNo) AS DocBookingNo,
			MAX(DocBookingDate) AS DocBookingDate, MAX(ProductCode) AS ProductCode,
			MAX(ProfitCenterCode) AS ProfitCenterCode,
			MAX(ProfitCenterId) AS ProfitCenterId,
			MAX(ChassisNo) AS ChassisNo, MAX(EngineNo) AS EngineNo,
			MAX(ProductCostId) AS ProductCostId, 
			MAX(InvoiceType) AS InvoiceType, MAX(InvoiceTypeName) AS InvoiceTypeName,
			MAX(ServicesType) AS ServicesType, MAX(ServicesTypeName) AS ServicesTypeName,
			MAX(DebitCustomerCode) AS DebitCustomerCode, MAX(CreditCustomerCode) AS CreditCustomerCode,
			MAX(AtchDocNo) AS AtchDocNo, MAX(AtchDocDate) AS AtchDocDate, 
			MAX(ProductCatgId) AS ProductCatgId, MAX(ProductCatgCode) AS ProductCatgCode,
			MAX(BizDocId_C1) AS BizDocId_C1, MAX(BizDocInfo_C1) AS BizDocInfo_C1, 
			MAX(BizDocId_C2) AS BizDocId_C2, MAX(BizDocInfo_C2) AS BizDocInfo_C2,
			MAX(CreatedAt) AS CreatedAt, MAX(CreatedName) AS CreatedName, 
			MAX(ModifiedAt) AS ModifiedAt, MAX(ModifiedName) AS ModifiedName,
			MAX(IsDisbursement) AS IsDisbursement, MAX(IsDisbursements) AS IsDisbursements, MAX(StageCode) AS StageCode, 
			MAX(DeptCode0) AS DeptCode0,
			MAX(Stt) AS Stt, MAX(RowId) AS RowId, MAX(ItemCode) AS ItemCode, MAX(ItemName) AS ItemName,
			MAX(ItemType) AS ItemType, MAX(WarehouseCode) AS WarehouseCode, 
			MAX(ReceiptWarehouseCode) AS ReceiptWarehouseCode, MAX(DueDate) AS DueDate,
			MAX(EmployeeName) AS EmployeeName, MAX(ExpenseCatgName) AS ExpenseCatgName,
			MAX(DebitProductCode) AS DebitProductCode, MAX(CreditProductCode) AS CreditProductCode,
			MAX(DebitBizDocInfo_C1) AS DebitBizDocInfo_C1, MAX(CreditBizDocInfo_C1) AS CreditBizDocInfo_C1,
			MAX(DebitBizDocInfo_C2) AS DebitBizDocInfo_C2, MAX(CreditBizDocInfo_C2) AS CreditBizDocInfo_C2,
			MAX(AssetCode) AS AssetCode, MAX(AssetName) AS AssetName,
			MAX(BranchCode) AS BranchCode,MAX(BranchName) AS BranchName
		FROM #CtTmp
		GROUP BY Stt
	END 
	ELSE IF (@_Kieu_Bc = '1')
	BEGIN

		EXECUTE ('SELECT Id, DocCode, DocGroup, DocDate, DocNo, CustomerCode0, CustomerCode, CustomerName,
				TransCode, Description, BizDocInfo_PO, BizDocInfo_SO, BizDocInfo_LC, BizDocInfo_DA,
				ExpenseCatgCode, BankCode, BankAccountNo, BankName, DeptCode, EmployeeCode, CostCentreCode, TerritoryCode, 
				TaxCode, ExchangeRate, CurrencyCode, 
				CashFlowId, CashFlowCode,CashFlowName, NoteFactorCode, 
				DebitAccount, DebitAmount, CreditAmount, CreditAccount, 
				Account, CrspAccount, Amount, OriginalAmount, Quantity,
				Nhom, Ten_Nhom, _FormatStyleKey, DocBookingNo, DocBookingDate, EntryNo, ProductCode,
				ProfitCenterCode,ProfitCenterId, ChassisNo, EngineNo,ProductCostId,  
				InvoiceType, InvoiceTypeName, ServicesType, ServicesTypeName,
				DebitCustomerCode, CreditCustomerCode,
				AtchDocNo, AtchDocDate, ProductCatgId, ProductCatgCode,
				BizDocId_C1, BizDocInfo_C1, BizDocId_C2, BizDocInfo_C2,
				CreatedAt, CreatedName, ModifiedAt, ModifiedName,
				IsDisbursement,IsDisbursements, StageCode, DeptCode0,
				Stt, RowId, ItemCode, ItemName, ItemType, WarehouseCode, DeliveryWarehouseCode, ReceiptWarehouseCode, DueDate,
				EmployeeName, ExpenseCatgName, DebitProductCode, CreditProductCode,
				DebitBizDocInfo_C1, CreditBizDocInfo_C1, DebitBizDocInfo_C2, CreditBizDocInfo_C2,
				AssetCode, AssetName, BranchCode, BranchName, DocNo2,
				EntityAssetCode  ,EntityAssetName  ,
				JobCode  ,JobName  
			FROM #CtTmp
			' + @_KeyAmount + N'
			ORDER BY DocDate, DocGroup, DocNo, EntryNo')
		
		SET @_LAYOUT_XML = N'
			<DefaultReport><Content>	
					<bGroupInColumn>False</bGroupInColumn>
					<Groups>
						<DocDate>
							<Text>
								<Vietnamese>Ngày: </Vietnamese>
								<English>Date: </English>
								<Chinese>日期: </Chinese>
								<Japanese>日付: </Japanese>
								<Korean>날짜: </Korean>
							</Text>
						</DocDate>
					</Groups>
			</Content></DefaultReport>'	
	END ELSE
	BEGIN
		EXECUTE ('SELECT Id, DocCode, DocGroup, DocDate, DocNo, CustomerCode0, CustomerCode, CustomerName,
				TransCode, Description, BizDocInfo_PO, BizDocInfo_SO, BizDocInfo_LC, BizDocInfo_DA,
				ExpenseCatgCode, BankCode, BankAccountNo, BankName, DeptCode, EmployeeCode, CostCentreCode, TerritoryCode, 
				TaxCode, ExchangeRate, CurrencyCode, 
				CashFlowId, CashFlowCode,CashFlowName, NoteFactorCode, 
				DebitAccount, DebitAmount, CreditAmount, CreditAccount, 
				Account, CrspAccount, Amount, OriginalAmount, Quantity,
				Nhom, Ten_Nhom, _FormatStyleKey, DocBookingNo, DocBookingDate, EntryNo, ProductCode,
				ProfitCenterCode,ProfitCenterId, ChassisNo, EngineNo,ProductCostId,
				InvoiceType, InvoiceTypeName, ServicesType, ServicesTypeName,
				DebitCustomerCode, CreditCustomerCode,
				AtchDocNo, AtchDocDate, ProductCatgId, ProductCatgCode,
				BizDocId_C1, BizDocInfo_C1, BizDocId_C2, BizDocInfo_C2,
				CreatedAt, CreatedName, ModifiedAt, ModifiedName,
				IsDisbursement,IsDisbursements, StageCode, DeptCode0,
				Stt, RowId, ItemCode, ItemName, ItemType, WarehouseCode, DeliveryWarehouseCode, ReceiptWarehouseCode, DueDate,
				EmployeeName, ExpenseCatgName, DebitProductCode, CreditProductCode,
				DebitBizDocInfo_C1, CreditBizDocInfo_C1, DebitBizDocInfo_C2, CreditBizDocInfo_C2,
				AssetCode, AssetName, BranchCode, BranchName, DocNo2,JobCode  ,JobName  
			FROM #CtTmp
			' + @_KeyAmount + N'
			ORDER BY Nhom, _FormatStyleKey DESC, DocDate, DocGroup, DocNo, EntryNo ') 

		SELECT ISNULL(MAX(Nhom), '') AS Nhom, ISNULL(MAX(Ten_Nhom), '') AS Ten_Nhom 
		FROM #CtTmp
		GROUP BY Nhom

		SET @_LAYOUT_XML = N'
			<DefaultReport><Content>	
					<Groups>
						<Ten_Nhom>
							<Text>
								<Vietnamese/>
								<English/>
							</Text>
						</Ten_Nhom>
					</Groups>
			</Content></DefaultReport>'	
	END

	
	DROP TABLE #CtTmp;
	SET NOCOUNT OFF;
END
GO
