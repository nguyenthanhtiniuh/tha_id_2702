USE [B10THACOIDACC]
GO

/****** Object:  StoredProcedure [dbo].[usp_B30AssetDoc_AccoDeprAsset]    Script Date: 02-03-2026 14:28:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Coder: VuLA
ALTER  PROCEDURE [dbo].[usp_B30AssetDoc_AccoDeprAsset]
	@_DocDate1 AS DATE = 'Oct 1, 2012', 
	@_DocDate2 AS DATE = 'Oct 31, 2012', 
	@_Year AS VARCHAR(24) = '2012', 
	@_AssetAccount AS VARCHAR(24) = '',
	@_AssetId AS VARCHAR(512) = '',
	@_AssetType AS TINYINT = 0,
	@_Round AS TINYINT = 0,
	@_CustomerId AS VARCHAR(512) = '',
	@_TransCode AS VARCHAR(24) = '',
	@_DocNo AS NVARCHAR(32) = '',
	@_DetailByAsset	AS TINYINT = 1, -- Tạo phiếu có chi tiết hay không
	@_BranchCode AS CHAR(3) = 'A02',
	@_nUserId AS INT = 0,
	@_AutoDisposals AS TINYINT = 1,		-- Tự động hạch toán thanh lý TSCĐ
	@_DisposalsTransCode AS VARCHAR(24) = '',
	@_CommandKey VARCHAR(24) = 'AssetDepreciation'
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @_Loai_Ps_Depreciation VARCHAR(24), @_DocCode VARCHAR(4), @_CurrencyCode0 CHAR(3), 
			@_DocStatus TINYINT, @_DienGiaiButToanKhauHao NVARCHAR(192), @_DocGroup CHAR(1), @_BuiltinOrder INT,
			@_DataCode_Branch VARCHAR(8) = (SELECT TOP (1) DataCode FROM dbo.B00Branch WHERE BranchCode = @_BranchCode),
			@_Cmd NVARCHAR(MAX)

	IF @_DisposalsTransCode = ''
		SET @_DisposalsTransCode = @_TransCode
			
	SELECT @_Loai_Ps_Depreciation = N'KHAUHAO', @_DocCode = 'TD',
		@_DocStatus = dbo.ufn_B00DmCt_DocStatusDefault(@_DocCode, @_nUserId, @_BranchCode), 
		@_CurrencyCode0 = dbo.ufn_vB00Config_GetValue('M_Ma_Tte0', @_BranchCode),
		@_DienGiaiButToanKhauHao = dbo.ufn_sys_MessageText(N'DienGiaiButToanKhauHao', 0)

	SELECT TOP 1 @_DocGroup = Nh_Ct FROM dbo.B00DmCt WHERE Ma_Ct = @_DocCode

	DROP TABLE IF EXISTS #CtKtTmp

	-- Danh sách phiếu 
	DECLARE @_Ct TABLE (Id INT, Stt VARCHAR(24), Del Bit DEFAULT 1, DocNo NVARCHAR(20))

	DECLARE @_CtKt TABLE 
			(Id INT, BuiltinOrder Smallint, Stt VARCHAR(24), DocDate DATE, 
			AssetId INT, DebitAccount VARCHAR(24), CreditAccount VARCHAR(24),
			DeptId INT, ExpenseCatgId INT, ProductId INT,
			ProfitCenterId INT, StageId INT, RouteCode VARCHAR(24),TerritoryId INT)

	IF @_AssetType = 1 
		SELECT	@_Loai_Ps_Depreciation = 'CCDC', 
				@_DienGiaiButToanKhauHao = dbo.ufn_sys_MessageText(N'ToolsDescription', 0)	
	ELSE 
	IF @_AssetType = 2	
		SELECT	@_Loai_Ps_Depreciation = 'PendingCost', 
				@_DienGiaiButToanKhauHao = N'Hạch toán chi phí chờ phân bổ'

	INSERT INTO @_Ct (Id, Stt, Del, DocNo)
	SELECT Id, Stt, 1, @_DocNo FROM dbo.B30AccDocAutoEntry 
	WHERE DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND BranchCode = @_BranchCode
		AND Loai_Ps = @_Loai_Ps_Depreciation AND IsActive = 1

	SELECT TOP 0 Id, BranchCode, DocDate, Stt, BuiltinOrder,
		AssetId, DebitAccount, CreditAccount, WorkProcessId, CostCentreId, 
		DeptId, ExpenseCatgId, ProductId, 
		Amount, OriginalAmount, Amount9, OriginalAmount9,
		@_Loai_Ps_Depreciation AS Loai_Ps,
		CAST(0 AS TINYINT) AS _Exists, CustomerId,
		-- 18/03/2024 ĐứcCM: Bổ sung các trường CustomFieldId trên các chứng từ TSCĐ
		CustomFieldId AS CustomFieldId1, CustomFieldId AS CustomFieldId2, CustomFieldId AS CustomFieldId3,
		ProfitCenterId, ItemId AS StageId, RouteCode, CAST(0 AS TINYINT) AS IsDisposals, TerritoryId
	INTO #CtKtTmp
	FROM dbo.B00CtTmp


	-- Lấy giá trị khấu hao trong tháng
	IF @_DetailByAsset = 0 -- Không chi tiết theo tài sản
		UPDATE #CtKtTmp SET AssetId = NULL

	SET @_Cmd = N'
	INSERT INTO #CtKtTmp
		 (
			Id, BranchCode, DocDate, Stt, BuiltinOrder,
			AssetId, DebitAccount, CreditAccount,
			WorkProcessId, StageId,CostCentreId, DeptId,
			ExpenseCatgId, ProductId,
			Amount, OriginalAmount, Amount9, OriginalAmount9,
			Loai_Ps, _Exists, CustomerId,
			CustomFieldId1, CustomFieldId2, CustomFieldId3,
			ProfitCenterId,  RouteCode, TerritoryId 
		)
	SELECT MAX(Id) AS Id, @_BranchCode AS BranchCode, DocDate, 
		CAST('''' AS VARCHAR(24)) AS Stt, CAST(0 AS INT) AS BuiltinOrder,
		AssetId, DeprDebitAccount AS DebitAccount, DeprCreditAccount AS CreditAccount, 
		WorkProcessId, StageId,CostCentreId, DeptId,ExpenseCatgId, ProductId, 
		SUM(Depreciation) AS Amount, CAST(0 AS NUMERIC(18, 2)) AS OriginalAmount,
		CAST(0 AS NUMERIC(18, 2)) AS Amount9, CAST(0 AS NUMERIC(18, 2)) AS OriginalAmount9,
		@_Loai_Ps_Depreciation AS Loai_Ps,
		CAST(0 AS TINYINT) AS _Exists, CustomerId,
		-- 18/03/2024 ĐứcCM: Bổ sung các trường CustomFieldId trên các chứng từ TSCĐ
		CustomFieldId1, CustomFieldId2, CustomFieldId3,
		ProfitCenterId,  RouteCode, TerritoryId
	FROM dbo.B3' + @_DataCode_Branch + N'AssetDoc
	WHERE DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND BranchCode = @_BranchCode
		AND AssetTransType = (N''KHAUHAO'') AND IsActive = 1
		AND AssetId IN (SELECT Id FROM B2' + @_DataCode_Branch + N'Asset WHERE Type = @_AssetType AND IsActive = 1)
	GROUP BY DocDate, AssetId, WorkProcessId, DeprDebitAccount, DeprCreditAccount, CostCentreId, ExpenseCatgId, ProductId, 
		DeptId, CustomerId, CustomFieldId1, CustomFieldId2, CustomFieldId3, ProfitCenterId, StageId, RouteCode, TerritoryId'
	
	EXECUTE sp_executesql @_cmd,
		N'@_DocDate1 DATE, @_DocDate2 DATE, @_AssetType VARCHAR(8), @_BranchCode VARCHAR(8), @_Loai_Ps_Depreciation VARCHAR(24)',
		@_DocDate1,
		@_DocDate2,
		@_AssetType,
		@_BranchCode,
		@_Loai_Ps_Depreciation
	
	-- Duydnp: Đánh dấu CCDC nào khai báo thanh lý trong kỳ
	SET @_Cmd = N'
	UPDATE #CtKtTmp SET IsDisposals = 1
	WHERE AssetId IN (SELECT AssetId FROM B3' + @_DataCode_Branch + N'AssetDoc 
					WHERE DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND BranchCode = @_BranchCode
						AND AssetTransType = (N''GIAMTAISAN'') AND IsActive = 1)'
	EXECUTE sp_executesql @_cmd,
		N'@_DocDate1 DATE, @_DocDate2 DATE, @_AssetType VARCHAR(8), @_BranchCode VARCHAR(8), @_Loai_Ps_Depreciation VARCHAR(24)',
		@_DocDate1,
		@_DocDate2,
		@_AssetType,
		@_BranchCode,
		@_Loai_Ps_Depreciation

	UPDATE #CtKtTmp SET OriginalAmount = Amount, OriginalAmount9 = Amount, Amount9 = Amount

		
	-- Xoa danh sach chung tu:
	DECLARE @_Key_Del NVARCHAR(100), @_Error INT, @_IdTmp Int, @_Stt VARCHAR(24), 
			@_DocDate DATE, @_RowId UniqueKeyType, @_SttListXML NVARCHAR(MAX);

	DECLARE @DateList TABLE (DocDate DATE, Stt VARCHAR(24));

	DROP TABLE IF EXISTS #_SttDeleteLists;
	CREATE TABLE #_SttDeleteLists (Stt VARCHAR(24))

	SET @_cmd = N'
	INSERT #_SttDeleteLists (Stt)
	SELECT Stt FROM B3' + @_DataCode_Branch + N'AccDocAutoEntry 
		WHERE DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND BranchCode = @_BranchCode
		AND Loai_Ps = @_Loai_Ps_Depreciation'

	EXECUTE sp_executesql @_cmd,
		N'@_DocDate1 DATE, @_DocDate2 DATE, @_Loai_Ps_Depreciation VARCHAR(24), @_BranchCode VARCHAR(8)',
		@_DocDate1,
		@_DocDate2,
		@_Loai_Ps_Depreciation,
		@_BranchCode

	WHILE EXISTS(SELECT * FROM #_SttDeleteLists)
	BEGIN
		PRINT N'Deleting ... Stt = [' + @_Stt + ']'

		SELECT TOP 1 @_Stt = Stt FROM #_SttDeleteLists
		DELETE FROM #_SttDeleteLists WHERE Stt = @_Stt

		SET @_Key_Del  = N'(Stt = ''' + @_Stt + ''')'

		-- Xoa chung tu
		EXECUTE @_Error = usp_B30AccDoc_DeleteDocument
			@_Stt = @_Stt, 
			@_Transaction = 0, 
			@_BranchCode = @_BranchCode,
			@_DocCode = @_DocCode

		IF @_Error < 0
		BEGIN
			PRINT N'Error ' + STR(@_Error)
			PRINT N'Có lỗi khi xóa chứng từ Stt = ' + @_Stt

			CONTINUE
		END
	END

	DROP TABLE IF EXISTS #_SttDeleteLists;
	
	IF EXISTS (SELECT * FROM #CtKtTmp)
	BEGIN	
		DROP TABLE IF EXISTS #Ct
		SELECT TOP 0 BranchCode, Stt, DocCode, DocGroup, DocDate, Description, CurrencyCode,
			Amount AS TotalOriginalAmount0, Amount AS TotalOriginalAmount, 			
			Amount AS TotalAmount0, Amount AS TotalAmount,
			CustomerId, DocNo, Loai_Ps, DocStatus, CAST(-1 AS INT) AS CreatedBy, CAST(0 AS TINYINT) AS IsDisposals
		INTO #Ct
		FROM dbo.B00CtTmp WITH (NOLOCK)

		DROP TABLE IF EXISTS #Ct0
		SELECT TOP 0 BranchCode, Stt, RowId, DocDate, DocCode, DocGroup, AssetId, Description, 
			BuiltinOrder, TransCode, CustomerId, DebitAccount, CreditAccount, OriginalAmount, Amount, 
			OriginalAmount9, Amount9, ExpenseCatgId, WorkProcessId,WorkProcessId AS StageId, CostCentreId, 
			DeptId, ProductId, CAST(-1 AS INT) AS CreatedBy,-- 18/03/2024 ĐứcCM: Bổ sung các trường CustomFieldId trên các chứng từ TSCĐ
			CustomFieldId AS CustomFieldId1, CustomFieldId AS CustomFieldId2, CustomFieldId AS CustomFieldId3,
			ProfitCenterId,  RouteCode, CAST(0 AS TINYINT) AS IsDisposals, TerritoryId
		INTO #Ct0
		FROM dbo.B00CtTmp WITH (NOLOCK)

		INSERT INTO #Ct(BranchCode, Stt, DocCode, DocGroup, DocDate, Description, CurrencyCode, 
						CustomerId, DocNo, Loai_Ps, DocStatus, CreatedBy, 
						TotalOriginalAmount0, TotalOriginalAmount, TotalAmount0, TotalAmount, IsDisposals)
		SELECT @_BranchCode, '', @_DocCode, @_DocGroup, DocDate, CASE WHEN IsDisposals=1 THEN N'Thanh lý CCDC' ELSE @_DienGiaiButToanKhauHao END, @_CurrencyCode0, 
			ISNULL(MAX(CustomerId), @_CustomerId), @_DocNo, @_Loai_Ps_Depreciation, @_DocStatus, @_nUserId,
			SUM(OriginalAmount), SUM(OriginalAmount), SUM(Amount), SUM(Amount), IsDisposals
		FROM #CtKtTmp 
		WHERE Stt = '' 
		GROUP BY DocDate, IsDisposals

		DECLARE @_TableHeader sysname = dbo.ufn_sys_TableName('B30AccDocAutoEntry', @_DataCode_Branch),
			@_TableDetail sysname = dbo.ufn_sys_TableName('B30AccDocAutoEntry1', @_DataCode_Branch)

		-- 11/4/2024: HuyTQ tách bảng chứng từ tự động
		-- Tạo sẵn Stt, RowId theo sequence trước khi tạo phiếu và thay đổi cách đổ dữ liệu vào bảng
		EXECUTE dbo.usp_sys_CreateSttBySeq_ForArray
			@_TableName = @_TableHeader,
			@_BranchCode = @_BranchCode,
			@_Ext = '',
			@_OutputTableName = '#Ct',	-- Update thẳng vào bảng temp
			@_OutputColName = 'Stt'

		INSERT INTO #Ct0 (BranchCode, Stt, RowId, DocDate, DocCode, DocGroup, AssetId, Description, BuiltinOrder, TransCode, CustomerId, DebitAccount, 
			CreditAccount, OriginalAmount, Amount, OriginalAmount9, Amount9, ExpenseCatgId, WorkProcessId, StageId, CostCentreId, DeptId, ProductId, CreatedBy,
			-- 18/03/2024 ĐứcCM: Bổ sung các trường CustomFieldId trên các chứng từ TSCĐ
			CustomFieldId1, CustomFieldId2, CustomFieldId3, ProfitCenterId, RouteCode, IsDisposals, TerritoryId)
		SELECT BranchCode, '', '', DocDate, @_DocCode, @_DocGroup, AssetId, CASE WHEN IsDisposals=1 THEN N'Thanh lý CCDC' ELSE @_DienGiaiButToanKhauHao END, ROW_NUMBER() OVER (PARTITION BY DocDate ORDER BY DocDate), @_TransCode, 
			ISNULL(CustomerId, @_CustomerId), DebitAccount, CreditAccount, OriginalAmount, Amount, OriginalAmount9, Amount9, ExpenseCatgId, 
			WorkProcessId,StageId, CostCentreId, DeptId, ProductId, @_nUserId,
			-- 18/03/2024 ĐứcCM: Bổ sung các trường CustomFieldId trên các chứng từ TSCĐ
			CustomFieldId1, CustomFieldId2, CustomFieldId3, ProfitCenterId,  RouteCode, IsDisposals, TerritoryId
		FROM #CtKtTmp

		EXECUTE dbo.usp_sys_CreateSttBySeq_ForArray
			@_TableName = @_TableDetail,
			@_BranchCode = @_BranchCode,
			@_Ext = @_DocCode,
			@_OutputTableName = '#Ct0',	-- Update thẳng vào bảng temp
			@_OutputColName = 'RowId'

		UPDATE #Ct0 
		SET Stt = Ct.Stt
		FROM #Ct0 Ct0
			INNER JOIN #Ct Ct ON Ct.DocDate = Ct0.DocDate AND ISNULL(Ct0.IsDisposals,0) = ISNULL(Ct.IsDisposals,0)
		

		

		DECLARE @_StrExec NVARCHAR(MAX) =
		'INSERT INTO dbo.' + @_TableHeader + 
			' (BranchCode, Stt, DocCode, DocGroup, DocDate, Description, CurrencyCode, CustomerId, DocNo, Loai_Ps, DocStatus, CreatedBy,
			   TotalOriginalAmount0, TotalOriginalAmount, TotalAmount0, TotalAmount)
		SELECT BranchCode, Stt, DocCode, DocGroup, DocDate, Description, CurrencyCode, CustomerId, DocNo, Loai_Ps, DocStatus, CreatedBy,
			  TotalOriginalAmount0, TotalOriginalAmount, TotalAmount0, TotalAmount
		FROM #Ct

		INSERT INTO dbo.' + @_TableDetail + ' (BranchCode, Stt, RowId, DocDate, DocCode, DocGroup, AssetId, Description,
			BuiltinOrder, TransCode, CustomerId, DebitAccount, CreditAccount, OriginalAmount, Amount, OriginalAmount9, Amount9, ExpenseCatgId, 
			WorkProcessId,StageId, CostCentreId, DeptId, ProductId, CreatedBy,
			-- 18/03/2024 ĐứcCM: Bổ sung các trường CustomFieldId trên các chứng từ TSCĐ
			CustomFieldId1, CustomFieldId2, CustomFieldId3, ProfitCenterId,  RouteCode, TerritoryId)
		SELECT BranchCode, Stt, RowId, DocDate, DocCode, DocGroup, AssetId, Description,
			BuiltinOrder, TransCode, CustomerId, DebitAccount, CreditAccount, OriginalAmount, Amount, OriginalAmount9, Amount9, ExpenseCatgId, 
			WorkProcessId,StageId, CostCentreId, DeptId, ProductId, CreatedBy,
			-- 18/03/2024 ĐứcCM: Bổ sung các trường CustomFieldId trên các chứng từ TSCĐ
			CustomFieldId1, CustomFieldId2, CustomFieldId3, ProfitCenterId,  RouteCode, TerritoryId
		FROM #Ct0'
		PRINT @_StrExec
		EXECUTE sys.sp_executesql @_StrExec

		SET @_SttListXML = (SELECT Stt, DocDate, DocCode, DocStatus FROM #Ct FOR XML RAW, ROOT('root'))
		
		EXECUTE dbo.usp_B30AccDoc_Post 
			@_BranchCode = @_BranchCode,
			@_Stt = NULL, @_DocDate = NULL, @_DocCode = NULL,
			@_DocStatus = NULL, 
			@_SttListXML = @_SttListXML,
			@_IsPostWhenSaveNewDoc = 1, 
			@_FiscalYear = @_Year,
			@_nUserId = @_nUserId
		
		DROP TABLE IF EXISTS #Ct
		DROP TABLE IF EXISTS #Ct0
	END

	DROP TABLE #CtKtTmp;

	-- Chức năng tự động tạo chứng từ thanh lý TSCĐ 
	-- Không tạo chứng từ thanh lý với CCDC, Chi phí chờ phân bổ do chi phí còn lại sẽ hạch toán phân bổ hết vào tháng hỏng
	-- Thaco 19/06/25: Đơn vị tự thanh lý = bút toán khác do chưa có giải pháp chung khi thanh lý tài sản/ccdc
	IF @_AutoDisposals = 0 --OR @_AssetType IN (1, 2)
		RETURN;

	DECLARE @_DisposalDescription NVARCHAR(256), 
		@_Tk8111 VARCHAR(24) = dbo.ufn_vB00Config_GetValue('M_Tk_Thanh_Ly_TSCD', @_BranchCode), 
		@_Loai_Ps_Disposal VARCHAR(24) = N'GIAMTAISAN'
	

	



	-- Lay chi tiet thanh ly
	SELECT TOP 0 AssetId, DocDate, DocNo, BuiltinOrder,
		DebitAccount, CreditAccount, Amount, Description,
		CAST(0 AS INT) AS CustomerId, 
		CAST(NULL AS INT) AS ProfitCenterId,
		CAST(NULL AS INT) AS StageId,
		CAST('' AS varchar(24)) AS RouteCode
	INTO #CtTLTmp
	FROM B00Cttmp
	
	-- 27/07/2024 HuyTQ thêm thông tin tài khoản và đối tượng thanh lý
	-- 18/06/2025 Duydnp thêm thông tin HĐKD, RouteCode
	IF @_AssetType = 0	-- Thanh lý TSCĐ
	BEGIN
		SET @_Cmd = N'
		INSERT INTO #CtTLTmp (AssetId, DocDate, DocNo, BuiltinOrder, DebitAccount, CreditAccount, Amount, Description, CustomerId)
		SELECT AssetId, DocDate, MAX(DocNo) AS DocNo, CAST(1 AS INT) AS BuiltinOrder,
			IIF(ISNULL(MAX(DisposalAccount), '''') <> '''', MAX(DisposalAccount), @_Tk8111) AS DebitAccount,
			AssetAccount AS CreditAccount, SUM(NetBookValue) AS Amount,
			MAX(Description) AS Description,
			IIF(ISNULL(MAX(CustomerId), 0) <> 0, MAX(CustomerId), @_CustomerId) AS CustomerId
		FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc_Decrease de
		WHERE DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND BranchCode = @_BranchCode
			AND IsActive = 1 AND IsActiveAsset = 1 AND  AssetType = @_AssetType 
			AND (AssetId = @_AssetId OR ISNULL(@_AssetId, '''') = '''')  
		GROUP BY DocDate, AssetId, AssetAccount
		UNION ALL		-- Gia tri da khau hao TSCD
		SELECT  tb.AssetId, tb.DocDate, MAX(tb.DocNo) AS DocNo, CAST(2 AS INT) AS BuiltinOrder,
				MAX(ad.DeprCreditAccount) AS DebitAccount, tb.AssetAccount AS CreditAccount, 
				SUM(tb.Depreciation) AS Amount, MAX(tb.Description) AS Description, 
				IIF(ISNULL(MAX(CustomerId), 0) <> 0, MAX(CustomerId), @_CustomerId) AS CustomerId
		FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc_Decrease AS tb
			OUTER APPLY 
			(
				SELECT TOP 1 DeprCreditAccount 
				FROM dbo.B3' + @_DataCode_Branch + N'AssetDoc ad 
				WHERE ad.AssetId = tb.AssetId AND ad.DocGroup = ''1''
				ORDER BY DocDate 
			) AS ad
		WHERE tb.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND tb.BranchCode = @_BranchCode
			AND tb.IsActive = 1 AND tb.IsActiveAsset = 1 AND tb.AssetType = @_AssetType
			AND (tb.AssetId = @_AssetId OR ISNULL(@_AssetId, '''') = '''')  
		GROUP BY DocDate, AssetId, AssetAccount'

	EXECUTE sp_executesql @_cmd,
		N'@_DocDate1 DATE, @_DocDate2 DATE, @_AssetId VARCHAR(24), @_AssetType VARCHAR(8), @_BranchCode VARCHAR(8), @_CustomerId INT, @_Tk8111 VARCHAR(24)',
		@_DocDate1,
		@_DocDate2,
		@_AssetId,
		@_AssetType,
		@_BranchCode,
		@_CustomerId,
		@_Tk8111 
	END ELSE	-- Thanh lý CCDC
	BEGIN
		SET @_Cmd = N'
		INSERT INTO #CtTLTmp (AssetId, DocDate, DocNo, BuiltinOrder, DebitAccount, CreditAccount, Amount, Description, CustomerId)
		SELECT  tb.AssetId, tb.DocDate, MAX(tb.DocNo) AS DocNo, CAST(1 AS INT) AS BuiltinOrder,
			IIF(ISNULL(MAX(DisposalAccount), '''') <> '''', MAX(DisposalAccount), @_Tk8111) AS DebitAccount,
			MAX(ad.DeprCreditAccount) AS CreditAccount, SUM(tb.NetBookValue) AS Amount,
			--MAX(tb.Description) AS Description,
			N''Thanh lý CCDC'' AS Description,
			IIF(ISNULL(MAX(CustomerId), 0) <> 0, MAX(CustomerId), @_CustomerId) AS CustomerId
		FROM dbo.vB3' + @_DataCode_Branch + N'AssetDoc_Decrease AS tb
			OUTER APPLY 
				(
					SELECT TOP 1 DeprCreditAccount 
					FROM dbo.B3' + @_DataCode_Branch + N'AssetDoc ad 
					WHERE ad.AssetId = tb.AssetId AND ad.DocGroup = ''1''
					ORDER BY DocDate 
				) AS ad
		WHERE tb.DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND tb.BranchCode = @_BranchCode
			AND tb.IsActive = 1 AND IsActiveAsset = 1 AND tb.AssetType = @_AssetType
			AND (AssetId = @_AssetId OR ISNULL(@_AssetId, '''') = '''')  
		GROUP BY tb.DocDate, tb.AssetId'
		
	EXECUTE sp_executesql @_cmd,
		N'@_DocDate1 DATE, @_DocDate2 DATE, @_AssetId VARCHAR(24), @_AssetType VARCHAR(8), @_BranchCode VARCHAR(8), @_CustomerId INT, @_Tk8111 VARCHAR(24)',
		@_DocDate1,@_DocDate2,@_AssetId,@_AssetType,@_BranchCode,	@_CustomerId,	@_Tk8111 
	END

	-- Xử lý thanh lý tài sản khi thanh lý ngay trong tháng đầu tiên tăng: Xóa các dòng hạch toán không có giá trị
	DELETE #CtTLTmp WHERE Amount = 0

	SELECT TOP 0 tb.*, asset.Code AS AssetCode, 
		ISNULL(tb.Description, '') + N' (' + ISNULL(asset.Code, '') + N')' AS DisposalDescription 
	INTO #CtTLTmp_Tmp
	FROM #CtTLTmp tb
		LEFT OUTER JOIN dbo.B20Asset asset ON tb.AssetId = asset.Id
	
	SET @_Cmd = N'
	INSERT INTO #CtTLTmp_Tmp
	SELECT tb.*, asset.Code AS AssetCode, 
		ISNULL(tb.Description, '''') + N'' ('' + ISNULL(asset.Code, '''') + N'')'' AS DisposalDescription 
	FROM #CtTLTmp tb
		LEFT OUTER JOIN dbo.B2' + @_DataCode_Branch + N'Asset asset ON tb.AssetId = asset.Id
	WHERE (AssetId = @_AssetId OR ISNULL(@_AssetId, '''') = '''')'

	EXECUTE sp_executesql @_cmd, N'@_AssetId VARCHAR(24)', @_AssetId

	IF ISNULL(@_AssetAccount, '') <> ''
	BEGIN
		SET @_Cmd = N'
		DELETE FROM #CtTLTmp_Tmp 
		FROM #CtTLTmp_Tmp tb
			INNER JOIN B2' + @_DataCode_Branch + N'Asset asset ON tb.AssetId = asset.Id
		WHERE asset.AssetAccount NOT LIKE @_AssetAccount + ''%'''
		
		EXECUTE sp_executesql @_cmd, N'@_AssetAccount VARCHAR(24)', @_AssetAccount
	END

	SELECT * FROM #CtTLTmp_Tmp

	DROP TABLE #CtTLTmp_Tmp

	-- Lấy danh sách TSCĐ thanh lý, tạo mỗi TSCĐ một chứng từ riêng
	SELECT AssetId 
	INTO #AssetList 
	FROM #CtTLTmp 
	GROUP BY AssetId


	-- 11/4/2024: HuyTQ tách bảng chứng từ tự động
	-- Xóa các chứng từ cũ
	IF EXISTS (SELECT * FROM #AssetList)
	BEGIN
		SET @_Cmd = N'
		DECLARE @_SttDelete TABLE (Stt VARCHAR(24))
			
		DELETE FROM dbo.B3' + @_DataCode_Branch + N'AccDocAutoEntry OUTPUT DELETED.Stt INTO @_SttDelete
			WHERE BranchCode = @_BranchCode AND DocCode = @_DocCode 
				AND DocDate BETWEEN @_DocDate1 AND @_DocDate2 AND Loai_Ps = @_Loai_Ps_Disposal

		DELETE FROM dbo.B3' + @_DataCode_Branch + N'AccDocAutoEntry1 WHERE Stt IN (SELECT Stt FROM @_SttDelete)'

		EXECUTE sp_executesql @_cmd,
			N'@_DocDate1 DATE, @_DocDate2 DATE, @_Loai_Ps_Disposal VARCHAR(24), @_DocCode VARCHAR(8), @_BranchCode VARCHAR(8)',
			@_DocDate1,@_DocDate2,@_Loai_Ps_Disposal,@_DocCode,@_BranchCode
	END
	
	-- Tạo sẵn Stt, RowId theo sequence trước khi tạo phiếu và thay đổi cách đổ dữ liệu vào bảng
	IF EXISTS (SELECT * FROM #CtTLTmp)
	BEGIN

		DROP TABLE IF EXISTS #CtTl
		SELECT BranchCode, Stt, DocCode, DocGroup, DocDate, DocNo, Description, CurrencyCode,
			Amount AS TotalOriginalAmount0, Amount AS TotalOriginalAmount, 			
			Amount AS TotalAmount0, Amount AS TotalAmount,
			CustomerId, Loai_Ps, DocStatus, AssetId, CAST(-1 AS INT) AS CreatedBy
		INTO #CtTl
		FROM dbo.B00CtTmp

		DROP TABLE IF EXISTS #CtTl0
		SELECT BranchCode, Stt, RowId, DocDate, DocCode, DocGroup, AssetId, Description, 
			BuiltinOrder, TransCode, CustomerId, DebitAccount, CreditAccount, OriginalAmount, Amount, 
			OriginalAmount9, Amount9, CAST(-1 AS INT) AS CreatedBy, ProfitCenterId, WorkProcessId AS StageId, RouteCode
		INTO #CtTl0
		FROM dbo.B00CtTmp
	
		INSERT INTO #CtTl(BranchCode, Stt, DocCode, DocGroup, DocDate, DocNo, Description, CurrencyCode, TotalOriginalAmount0, 
						  TotalOriginalAmount, TotalAmount0, TotalAmount, CustomerId, Loai_Ps, DocStatus, AssetId, CreatedBy)
		SELECT @_BranchCode, '', @_DocCode, @_DocGroup, MAX(DocDate), MAX(DocNo), MAX(Description), @_CurrencyCode0, 
			SUM(Amount), SUM(Amount), SUM(Amount), SUM(Amount), MAX(CustomerId), @_Loai_Ps_Disposal, @_DocStatus, AssetId, @_nUserId
		FROM #CtTLTmp 
		GROUP BY AssetId

		DECLARE @_AssetCode NVARCHAR(24) = N''
		SELECT @_AssetCode = Code FROM dbo.B20Asset WHERE Id = @_AssetId

		SET @_cmd=N'UPDATE a 
					SET Description = LEFT(a.Description +  N'' ('' + b.Code + N'')'', 192)
					FROM #CtTl a INNER JOIN dbo.B2'+@_DataCode_Branch+'Asset b ON a.AssetId = b.Id'
		EXECUTE sp_executesql @_cmd

		-- 11/4/2024: HuyTQ tách bảng chứng từ tự động
		EXECUTE dbo.usp_sys_CreateSttBySeq_ForArray
			@_TableName = @_TableHeader,
			@_BranchCode = @_BranchCode,
			@_Ext = '',
			@_OutputTableName = '#CtTl',
			@_OutputColName = 'Stt'

		INSERT INTO #CtTl0(BranchCode, Stt, RowId, DocDate, DocCode, DocGroup, AssetId, Description, BuiltinOrder, TransCode, 
							CustomerId, DebitAccount, CreditAccount, OriginalAmount, Amount, OriginalAmount9, Amount9, 
							CreatedBy, ProfitCenterId, StageId, RouteCode)
		SELECT @_BranchCode, '' AS Stt, '' AS RowId, DocDate, @_DocCode AS DocCode, @_DocGroup AS DocGroup, 
				AssetId, '' AS Description  , ROW_NUMBER() OVER (PARTITION BY AssetId ORDER BY AssetId) AS BuiltinOrder,
				@_DisposalsTransCode AS TransCode, CustomerId, DebitAccount, CreditAccount, Amount, Amount, Amount, Amount, 
				@_nUserId, ProfitCenterId, StageId,
				ISNULL(RouteCode,'') AS RouteCode
		FROM #CtTLTmp

		EXECUTE dbo.usp_sys_CreateSttBySeq_ForArray
			@_TableName = @_TableDetail,
			@_BranchCode = @_BranchCode,
			@_Ext = @_DocCode,
			@_OutputTableName = '#CtTl0',
			@_OutputColName = 'RowId'

		UPDATE #CtTl0 SET Stt = Ct.Stt, Description = Ct.Description
		FROM #CtTl0 Ct0
			INNER JOIN #CtTl Ct ON Ct.AssetId = Ct0.AssetId

		SET @_StrExec = 
		'INSERT INTO dbo.' + @_TableHeader + 
		' (BranchCode, Stt, DocCode, DocGroup, DocDate, DocNo, Description, 
		   CurrencyCode, CustomerId, Loai_Ps, DocStatus, CreatedBy, TotalOriginalAmount0, 
		   TotalOriginalAmount, TotalAmount0, TotalAmount) 
		SELECT BranchCode, Stt, DocCode, DocGroup, DocDate, DocNo, Description, 
			CurrencyCode, CustomerId, Loai_Ps, DocStatus, CreatedBy, TotalOriginalAmount0, 
			TotalOriginalAmount, TotalAmount0, TotalAmount
		FROM #CtTl

		INSERT INTO dbo.' + @_TableDetail + 
			' (BranchCode, Stt, RowId, BuiltinOrder, DocDate, DocCode, DocGroup, AssetId, Description, 
			   TransCode, CustomerId, DebitAccount, CreditAccount, OriginalAmount, Amount, OriginalAmount9, Amount9, CreatedBy,
			   ProfitCenterId, StageId, RouteCode)
		SELECT BranchCode, Stt, RowId, BuiltinOrder, DocDate, DocCode, DocGroup, AssetId, Description, 
				TransCode, CustomerId, DebitAccount, CreditAccount, OriginalAmount, Amount, OriginalAmount9, Amount9, CreatedBy,
				ProfitCenterId, StageId, RouteCode
		FROM #CtTl0'

		EXECUTE sys.sp_executesql @_StrExec

		SET @_SttListXML = (SELECT Stt, DocDate, DocCode, DocStatus FROM #CtTl FOR XML RAW, ROOT('root'))
		
		EXECUTE dbo.usp_B30AccDoc_Post 
			@_BranchCode = @_BranchCode,
			@_Stt = NULL, @_DocDate = NULL, @_DocCode = NULL,
			@_DocStatus = NULL, 
			@_SttListXML = @_SttListXML,
			@_IsPostWhenSaveNewDoc = 1, 
			@_FiscalYear = @_Year,
			@_nUserId = @_nUserId
	

		DROP TABLE IF EXISTS #CtTl
		DROP TABLE IF EXISTS #CtTl0
	END
	
	DECLARE @ci VARBINARY(128) = ISNULL(CONTEXT_INFO(), 0)
	DECLARE @_LogInfo NVARCHAR(MAX);

	IF @_AssetType = 0
		SET @_LogInfo = 
			N'Hạch toán thanh lý TSCĐ ' + REPLACE(STR(MONTH(@_DocDate2), 2), ' ', '0') + N'/' + STR(YEAR(@_DocDate2), 4)
					+ CASE WHEN @_AssetAccount <> '' THEN N'. Tài khoản ' + LTRIM(@_AssetAccount) ELSE N'' END
					+ CASE WHEN @_AssetId <> '' THEN N'. Tài sản ' + LTRIM(@_AssetId) ELSE N'' END
	ELSE
		SET @_LogInfo = 
			N'Hạch toán thanh lý CCDC ' + REPLACE(STR(MONTH(@_DocDate2), 2), ' ', '0') + N'/' + STR(YEAR(@_DocDate2), 4)
					+ CASE WHEN @_AssetAccount <> '' THEN N'. Tài khoản ' + LTRIM(@_AssetAccount) ELSE N'' END
					+ CASE WHEN @_AssetId <> '' THEN N'. Công cụ dụng cụ ' + LTRIM(@_AssetId) ELSE N'' END

	EXECUTE dbo.usp_sys_WriteLog_Command 
		@_Description= @_LogInfo,
	    @_nUserId = @_nUserId,
	    @_BranchCode = @_BranchCode,
	    @_CommandKey = @_CommandKey

	_AutoDisposalsLast:

	DROP TABLE #AssetList
	DROP TABLE #CtTLTmp
END
GO


