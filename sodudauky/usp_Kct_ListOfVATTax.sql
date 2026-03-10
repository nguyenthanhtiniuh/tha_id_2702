-- Coder: AnhPK

-- ============================================
-- Description: Bảng kê thuế GTGT (Theo mẫu của thông tư 119 ngày 25/08/2014)
-- ============================================
ALTER  PROCEDURE dbo.usp_Kct_ListOfVATTax 
	@_DocDate1 DATE = 'Jan 01 2014',
	@_DocDate2 DATE = 'Jan 31 2015',
	@_KqtMau NVARCHAR(48) = 'B10Kct07',
	@_Account CodeType = N'',
	@_CrspAccount CodeType = N'',
	@_In_Out VARCHAR(2) = '1',
	@_Except_TaxCode NCHAR(1) = 'C', -- Có loại trừ mã thuế điều chỉnh không (V00D, R00D) trên bảng kê
	@_PrintType TINYINT = 0,
	@_nUserId INT = 0,
	@_LangId INT = 0,
	@_BranchCode VARCHAR(3) = N'A02',
	@_DescExcludeBST AS NCHAR(1) = N'K', -- C: sử dụng BST ở diễn giải
	@_Table_Temp AS NVARCHAR(96) = N'',
	@_TotalAmount NUMERIC(18, 2) = 0.00 OUTPUT,
	@_TotalTaxableAmount NUMERIC(18, 2) = 0 OUTPUT,
	@_TotalVAT NUMERIC(18, 2) = 0 OUTPUT,
	@_TaxAgentCode VARCHAR(24) = N'',
	@_TaxAgentName NVARCHAR(128) = N'',
	@_TaxCode VARCHAR(24) = N'',
	@_TaxStaff NVARCHAR(48) = N'',
	@_CertNo NVARCHAR(32) = N'',
	@_HTKK_Exp TINYINT = 0, -- 1: thì tạo, 0-không tạo
	@_isCompare TINYINT = 0, -- 1: insert dữ liệu theo chứng từ, không nhóm theo ngày hóa đơn thuế mục đích để kiểm tra dữ liệu thuế VAT
	@_File_XML NVARCHAR(MAX) = N'' OUTPUT,
	@_Filename_XML NVARCHAR(254) = N'' OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	-- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
	SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
	--SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)

	DECLARE @_Key NVARCHAR(4000), @_Cmd nvarchar(MAX), @_DataCode_Branch VARCHAR(8)
	DECLARE @_BranchList TABLE (BranchCode VARCHAR(3), DataCode_Branch VARCHAR(8))

	SET @_DataCode_Branch = ISNULL((SELECT TOP (1) DataCode FROM dbo.B00Branch WHERE BranchCode = @_BranchCode), '0')

	INSERT INTO @_BranchList (BranchCode, DataCode_Branch)
	SELECT BranchCode, DataCode
	FROM [dbo].[ufn_B00Branch_GetChildTable](@_BranchCode)

	IF @_CrspAccount <> ''
		SET @_Key = N'((DebitAccount3 LIKE ''' + @_Account + '%'' AND CreditAccount3 LIKE ''' + @_CrspAccount + '%'') OR ' +
			N'(CreditAccount3 LIKE ''' + @_Account + '%'' AND DebitAccount3 LIKE ''' + @_CrspAccount + '%''))'
	ELSE
		SET @_Key = N'(DebitAccount3 LIKE ''' + @_Account + '%'' OR CreditAccount3 LIKE ''' + @_Account + '%'')'

	IF @_In_Out = '2'
		SET @_Key = '((' + @_Key + ') OR (DocCode = ''XT'' AND ' + @_Key + '))'
		
	SET @_Key = @_Key + N' AND TaxCode IN (SELECT Code FROM B20Tax WHERE Type = ' + @_In_Out + ')'

	-- Fix lỗi không lên được thuế điếu chỉnh ở tờ khai thuế
	IF @_Except_TaxCode = 'C'
	BEGIN
		DECLARE @_Not_Lst_TaxCode NVARCHAR(128)
		SET @_Not_Lst_TaxCode = dbo.ufn_B10Kqt05Ts_GetData(N'Not_Lst_TaxCode' + @_In_Out)

		IF @_Not_Lst_TaxCode = ''
			SET @_Not_Lst_TaxCode = IIF(@_In_Out = 1, 'V00D', 'R00D')

		SET @_Key = @_Key + N' AND TaxCode NOT IN(''' + REPLACE(@_Not_Lst_TaxCode, ', ', ''', ''') + ''')'
	END

	-- Lấy dữ liệu phát sinh
	DROP TABLE IF EXISTS #K_CtTmp_Kct07
	SELECT TOP 0 CAST(NULL AS INT) AS Id,
		BranchCode, Stt, BuiltinOrder, CurrencyCode, ExchangeRate, DocCode, 
		Address, DocNo, DocDate, DocSerialNo, Description, CustomerId, 
		CustomerName, AtchDocNo, AtchDocDate, AtchDocSerialNo, AtchDocFormNo,
		DebitAccount2, CreditAccount2, Amount2, OriginalAmount2,
		DebitAccount3, CreditAccount3, Amount3, OriginalAmount3,
		DebitAccount5, CreditAccount5, Amount5, OriginalAmount5, Amount6, OriginalAmount6,
		TaxCode, TaxRate, TaxRegNo, TaxRegName, ItemId, CAST('' AS NVARCHAR(512)) AS ItemName,
		Account, CrspAccount, CAST(0 AS INT) AS DueDate, CAST(0 AS TINYINT) AS TotalAmount, 
		CAST('' AS VARCHAR(24)) AS TypeCode, CAST(N'' AS NVARCHAR(256)) AS EInvoiceLink, 
		CAST(N'' AS NVARCHAR(64)) AS EInvoiceKey -- Thêm lên báo cáo Bảng kê HĐ, chứng từ HHDV mua vào kiểm tra
	INTO #K_CtTmp_Kct07
	FROM B00CtTmp

	ALTER TABLE #K_CtTmp_Kct07 ALTER COLUMN TaxRate NUMERIC(5, 2) NULL

	EXECUTE usp_sys_DefaultTable '#K_CtTmp_Kct07'

	-- Lấy dữ liệu theo PA mới trực tiếp từ B30AccDocAtch.
	-- Tuy nhiên cần lưu ý sẽ bị thiếu nếu KH nhập thuế thẳng vào phần hạch toán. Khi đó nên bỏ trống tham số @_TblSource
	EXECUTE [usp_B30GeneralLedger_GetDataVAT]
		@_Date1 = @_DocDate1,
		@_Date2 = @_DocDate2,
		@_Key1 = @_Key,
		@_Key2 = N'',
		@_CtTmp = N'#K_CtTmp_Kct07',
		@_nUserId = @_nUserId,
		@_LangId = @_LangId,
		@_BranchCode = @_BranchCode,
		@_TblSource = 'vB30AccDocAtch_GetDataVAT'
		
	--SELECT * FROM #K_CtTmp_Kct07 WHERE DocNo = 'CL-2601-0004' RETURN 
		--RETURN 
	
	SET @_Cmd =
		'UPDATE #K_CtTmp_Kct07 
			SET EInvoiceKey = ds.TransactionId
		FROM #K_CtTmp_Kct07 as sc
		INNER JOIN dbo.B3' +ISNULL(@_DataCode_Branch,'0')+'AccDocSales (NoLock) as ds ON ds.Stt = sc.Stt AND ds.DocCode = sc.DocCode;'
	EXECUTE(@_Cmd);

	SET @_Cmd =
		'UPDATE #K_CtTmp_Kct07 
			SET  
			EInvoiceLink = ds.EInvoiceLink,
			EInvoiceKey = ds.EInvoiceKey  
		FROM #K_CtTmp_Kct07 as sc
		INNER JOIN dbo.B3' +ISNULL(@_DataCode_Branch,'0')+'AccDocOther (NoLock) as ds ON ds.Stt = sc.Stt AND ds.BuiltinOrder = sc.BuiltinOrder'
	EXECUTE(@_Cmd);

	IF @_In_Out = '2' AND dbo.ufn_vB00Config_GetValue('M_Retail_PubEInvoice', @_BranchCode) IN ('1', '2')
	BEGIN
		DECLARE @_POSList TABLE (PosDocId VARCHAR(16))

		INSERT INTO @_POSList (PosDocId)
		SELECT PosDocId
		FROM dbo.vB30PosDocSalesRetail_EInvoice_GetData
		WHERE EInvoiceDate BETWEEN @_DocDate1 AND @_DocDate2
			AND BranchCode IN (SELECT BranchCode FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode))
			AND ISNULL(TaxCode, '') <> ''
			AND (Amount2 <> 0 OR Amount3 <> 0) -- Loai tru nhung dong hang khuyen mai, qua tang
		GROUP BY PosDocId

		-- Loại trừ những dòng thuế bị trùng nhập cho Hóa đơn tổng hợp bán lẻ
		DELETE #K_CtTmp_Kct07 WHERE Stt IN (SELECT Stt FROM dbo.B30AccDocRelation WHERE SttSourceDoc IN (SELECT PosDocId FROM @_POSList))

		INSERT INTO #K_CtTmp_Kct07 (BranchCode, Stt, DocCode, AtchDocFormNo, DocSerialNo, AtchDocNo, AtchDocDate,
			Amount2, Amount3, TaxCode, TaxRate, TaxRegNo, TaxRegName)
		SELECT ct.BranchCode, ct.PosDocId, '' AS DocCode, ct.FormNo, ct.DocSerialNo, ct.EInvoiceNo, ct.EInvoiceDate,
			ct.Amount2WithoutVAT, ct.Amount3, ct.TaxCode, ct.TaxRate, ct.TaxRegNo, ct.TaxRegName
		FROM dbo.vB30PosDocSalesRetail_EInvoice_GetData AS ct
		WHERE PosDocId IN (SELECT PosDocId FROM @_POSList)

		-- Loại trừ các dòng không có thuế
		DELETE FROM #K_CtTmp_Kct07 WHERE ISNULL(TaxCode, '') = '' AND Amount3 = 0 AND Amount2 = 0
	END

	IF @_In_Out <> '1'
	BEGIN
		UPDATE #K_CtTmp_Kct07 
		SET DueDate = 0

		SELECT @_Cmd=''
		SELECT @_Cmd=@_Cmd + N'
			UPDATE #K_CtTmp_Kct07 
			SET AtchDocFormNo = c.FormNo
			FROM #K_CtTmp_Kct07 tb
				INNER JOIN dbo.vB3'+DataCode_Branch+'AccDoc ct ON ct.Stt = tb.Stt
				INNER JOIN dbo.B20VoucherRegister c ON c.RowId = ct.RowId_VoucherRegister'
		FROM @_BranchList

	END ELSE
	BEGIN
		SELECT @_Cmd=''
		SELECT @_Cmd=@_Cmd + N'
			UPDATE #K_CtTmp_Kct07 
			SET AtchDocFormNo = ct.AtchDocFormNo
			FROM #K_CtTmp_Kct07 tb
				INNER JOIN dbo.vB3'+DataCode_Branch+'AccDocAtch ct ON tb.Stt = ct.Stt AND ct.AtchDocNo = tb.AtchDocNo'
		FROM @_BranchList
	END
	EXEC sp_executesql @_Cmd

	-- Cập nhật ngày chứng từ
	UPDATE #K_CtTmp_Kct07 
	SET AtchDocDate = IIF(AtchDocDate IS NULL, DocDate, AtchDocDate),
		AtchDocNo = IIF(ISNULL(AtchDocNo, '') = '', DocNo, AtchDocNo),
		AtchDocSerialNo = IIF(ISNULL(AtchDocSerialNo, '') = '', DocSerialNo, AtchDocSerialNo)
	
	DROP TABLE IF EXISTS #B10Kct07
	CREATE TABLE #B10Kct07 (Id INT, chk VARCHAR(10) DEFAULT '')

	EXECUTE dbo.usp_sys_CreateTable
		@_Table = N'#B10Kct07',
	    @_BaseTable = @_KqtMau

	DECLARE @_KeyAppend NVARCHAR(MAX) = 'In_Out = ''' + @_In_Out + ''' AND TypeCode <> ''''';

	EXECUTE dbo.usp_sys_Append
		@_TableSource = @_KqtMau,
		@_TableDestination = N'#B10Kct07',
		@_Where_TableSource = @_KeyAppend

	-- Trường hợp V05B, V10B lấy thuế suất bằng cách lấy ActualRate có thuế GTGT
	UPDATE #K_CtTmp_Kct07 
	SET TaxRate = CAST(Dm.ActualRate AS NUMERIC(18, 5)) / 100
	FROM #K_CtTmp_Kct07 Kct, B20Tax Dm
	WHERE Kct.TaxCode <> '' AND Dm.Code = Kct.TaxCode AND Kct.TaxRate = 0 AND ISNUMERIC(Dm.ActualRate) = 1

	DECLARE @_Id SMALLINT, @_TypeCode VARCHAR(24), @_TaxCodeList VARCHAR(254), @_TaxRateTmp NUMERIC(5, 2), 
		@_Default_Ck CHAR(1), @_TotalAmount0 TINYINT

	WHILE EXISTS(SELECT * FROM #B10Kct07 WHERE chk = '')
	BEGIN
		SELECT TOP 1 @_Id = Id, @_TypeCode = TypeCode, @_TaxCodeList = TaxCodeList,
			@_TaxRateTmp = TaxRate, @_Default_Ck = Default_Ck, @_TotalAmount0 = TotalAmount
		FROM #B10Kct07 
		WHERE chk = ''

		IF @_TaxCodeList <> ''
			UPDATE #K_CtTmp_Kct07 
			SET TypeCode = @_TypeCode, TotalAmount = @_TotalAmount0
			WHERE PATINDEX('%,' + TRIM(TaxCode) + ',%', ',' + RTRIM(@_TaxCodeList) + ',') <> 0 -- 30/12/2024: HuyTQ update lại taxcode
		ELSE
			IF @_TaxRateTmp <> 0 -- Cập nhật theo thuế suất
				UPDATE #K_CtTmp_Kct07 
				SET TypeCode = @_TypeCode, TotalAmount = @_TotalAmount0 
				WHERE TaxRate = @_TaxRateTmp
			ELSE IF @_Default_Ck = 1 -- Cập nhật cho mã ngầm định
				UPDATE #K_CtTmp_Kct07 
				SET TypeCode = @_TypeCode, TotalAmount = @_TotalAmount0 
				WHERE ISNULL(TypeCode, '') = N''

		UPDATE #B10Kct07 SET chk = 'x' WHERE Id = @_Id
	END
	
	-- Cập nhật tiền hàng, tiền thuế, tài khoản tiền hàng, thuế
	-- Với chứng từ XT - Xuất trả lại nhà cung cấp (N111, 112, 331 / C152, 156, 1331)
	-- Nếu mã thuế đầu ra: Lên bảng kê đầu ra, số dương
	-- Nếu mã thuế đầu vào: Lên bảng kê đầu vào, số âm
	IF @_In_Out = '1'
	BEGIN
		UPDATE #K_CtTmp_Kct07 
		SET Account = DebitAccount3, CrspAccount = CreditAccount3
		WHERE DebitAccount3 LIKE @_Account + '%' AND DocCode <> 'XT'

		UPDATE #K_CtTmp_Kct07 
		SET Account = CreditAccount3, CrspAccount = DebitAccount3, Amount3 = -Amount3, Amount2 = -Amount2
		WHERE DebitAccount3 NOT LIKE @_Account + '%' AND DocCode <> 'XT'

		UPDATE #K_CtTmp_Kct07 
		SET Account = CreditAccount3, CrspAccount = DebitAccount3, Amount3 = -Amount3, Amount2 = -Amount2
		WHERE DocCode = 'XT'

		UPDATE #K_CtTmp_Kct07 
		SET TaxRate = TaxRate * 100 
		WHERE TaxRate IS NOT NULL
	END ELSE
	BEGIN
		UPDATE #K_CtTmp_Kct07 
		SET Account = CreditAccount3, CrspAccount = DebitAccount3
		WHERE CreditAccount3 LIKE @_Account + '%' AND DocCode <> 'XT'

		UPDATE #K_CtTmp_Kct07 
		SET Account = DebitAccount3, CrspAccount = CreditAccount3, Amount3 = -Amount3, Amount2 = -Amount2
		WHERE CreditAccount3 NOT LIKE @_Account + '%' AND DocCode NOT IN ('XT', '')

		UPDATE #K_CtTmp_Kct07 
		SET Account = CreditAccount3, CrspAccount = DebitAccount3 
		WHERE DocCode = 'XT'
	END
	
	--TuanPT tạm thời rào đoạn này
	---- Xử lý phần diễn giải có ký tự BTS
	--IF @_DescExcludeBST = N'C'
	--	UPDATE #K_CtTmp_Kct07 
	--	SET Amount2 = [dbo].[ufn_sys_GetDsBST](Description, N'BST')
	--	WHERE PATINDEX('%' + N'BST' + '%', Description) > 0

	IF @_PrintType = 0
		UPDATE #K_CtTmp_Kct07
		SET ItemName = Description 
		WHERE ItemName = N''
		
	DROP TABLE IF EXISTS #BcTmp_Kct07
	SELECT TOP 0 CAST('' AS VARCHAR(8)) AS Stt_Order, Id, Stt, DocCode, AtchDocSerialNo, 
		AtchDocFormNo, AtchDocNo, AtchDocDate, TaxCode, CAST('' AS NVARCHAR(256)) AS TaxRegName,
		TaxRegNo, ItemName, DueDate, Amount2, TaxRate, Amount3, Description, DocNo, DocDate, DocSerialNo,
		DebitAccount2, CreditAccount2, DebitAccount3, CreditAccount3, TypeCode, CAST('' AS NVARCHAR(196)) AS TypeName,
		CAST(NULL AS NVARCHAR(128)) AS _FormatStyleKey, CAST(NULL AS NVARCHAR(256)) AS _FormatStyleArgs,
		CAST(NULL AS NVARCHAR(256)) AS _Caption, CAST(NULL AS INT) AS _Status,
		CAST(0 AS TINYINT) AS TotalAmount, EInvoiceLink, EInvoiceKey, CustomerId, CAST('' AS NVARCHAR(256)) AS CustomerCode,
		CAST(-1 AS INT) AS CreatedBy, CAST('' AS NVARCHAR(126)) AS CreatedName
	INTO #BcTmp_Kct07
	FROM #K_CtTmp_Kct07

	EXECUTE usp_sys_DefaultTable @_Table = N'#BcTmp_Kct07'

	DECLARE @_strExec NVARCHAR(4000)
	
	IF @_PrintType = 0
	BEGIN
		INSERT INTO #BcTmp_Kct07
		SELECT CAST(ROW_NUMBER() OVER (PARTITION BY TypeCode ORDER BY AtchDocDate) AS VARCHAR(8)) AS Stt_Order,
			MAX(Id) AS Id, MAX(Stt) AS Stt, MAX(DocCode) AS DocCode, AtchDocSerialNo, AtchDocFormNo, 
			AtchDocNo, AtchDocDate, MAX(TaxCode), MAX(TaxRegName) AS TaxRegName, TaxRegNo, MAX(ItemName) AS ItemName, 
			MAX(DueDate), SUM(Amount2) AS Amount2, TaxRate AS TaxRate, SUM(Amount3) AS Amount3,
			MAX(Description) AS Description, MAX(DocNo) AS DocNo, MAX(DocDate) AS DocDate, MAX(DocSerialNo) AS DocSerialNo,
			MAX(DebitAccount2) AS DebitAccount2, MAX(CreditAccount2) AS CreditAccount2,
			MAX(DebitAccount3) AS DebitAccount3, MAX(CreditAccount3) AS CreditAccount3,
			TypeCode, CAST('' AS NVARCHAR(196)) AS TypeName, NULL AS _FormatStyleKey, NULL AS _FormatStyleArgs,
			NULL AS _Caption, CAST(2 AS INT) AS _Status, TotalAmount, MAX(EInvoiceLink) AS EInvoiceLink, MAX(EInvoiceKey) AS EInvoiceKey,
			MAX(CustomerId) AS CustomerId, CAST('' AS NVARCHAR(256)) AS CustomerCode, CAST(-1 AS INT) AS CreatedBy, CAST('' AS NVARCHAR(126)) AS CreatedName
		FROM #K_CtTmp_Kct07
		GROUP BY AtchDocSerialNo, AtchDocFormNo, AtchDocNo, AtchDocDate, TaxRegNo, TaxCode, TaxRate, TypeCode, TotalAmount, Stt

		INSERT INTO #BcTmp_Kct07
		SELECT '1' AS Stt_Order,
			NULL, REPLICATE('Z', 10) AS Stt, N'' AS DocCode, N'' AS AtchDocSerialNo, N'' AS AtchDocFormNo,
			N'' AS AtchDocNo, NULL AS AtchDocDate, N'' AS TaxCode, N'' AS TaxRegName, N'' AS TaxRegNo, N'' AS ItemName, 
			0 AS DueDate, 0 AS Amount2, TaxRate AS TaxRate, 0 AS Amount3,
			N'' AS Description, N'' AS DocNo, NULL AS DocDate, N'' AS DocSerialNo,
			N'' AS DebitAccount2, N'' AS CreditAccount2, N'' AS DebitAccount3, N'' AS CreditAccount3,
			TypeCode, CAST('' AS NVARCHAR(196)) AS TypeName, NULL AS _FormatStyleKey, NULL AS _FormatStyleArgs,
			NULL AS _Caption, CAST(2 AS INT) AS _Status, TotalAmount, NULL, NULL,'' AS CustomerId, CAST('' AS NVARCHAR(256)) AS CustomerCode, CAST(-1 AS INT) AS CreatedBy, CAST('' AS NVARCHAR(126)) AS CreatedName
		FROM B10Kct07
		WHERE In_Out = @_In_Out AND TypeCode NOT IN (SELECT DISTINCT TypeCode FROM #BcTmp_Kct07)
	END ELSE
		INSERT INTO #BcTmp_Kct07
		SELECT CAST(ROW_NUMBER() OVER (PARTITION BY TypeCode ORDER BY AtchDocDate) AS VARCHAR(8)) AS Stt_Order,
			MAX(Id), Stt, MAX(DocCode) AS DocCode, AtchDocSerialNo, AtchDocFormNo, AtchDocNo, AtchDocDate, MAX(TaxCode) AS TaxCode,
			MAX(TaxRegName) AS TaxRegName,
			TaxRegNo, MAX(ItemName) AS ItemName, MAX(DueDate),
			SUM(Amount2) AS Amount2, TaxRate AS TaxRate, SUM(Amount3) AS Amount3,
			MAX(Description) AS Description,
			MAX(DocNo) AS DocNo, MAX(DocDate) AS DocDate, MAX(DocSerialNo) AS DocSerialNo,
			MAX(DebitAccount2) AS DebitAccount2, MAX(CreditAccount2) AS CreditAccount2,
			MAX(DebitAccount3) AS DebitAccount3, MAX(CreditAccount3) AS CreditAccount3,
			TypeCode, CAST('' AS NVARCHAR(196)) AS TypeName,
			NULL AS _FormatStyleKey,
			NULL AS _FormatStyleArgs,
			NULL AS _Caption,
			CAST(2 AS INT) AS _Status, TotalAmount, MAX(EInvoiceLink) AS EInvoiceLink, MAX(EInvoiceKey) AS EInvoiceKey,
			MAX(CustomerId) AS CustomerId, CAST('' AS NVARCHAR(256)) AS CustomerCode, CAST(-1 AS INT) AS CreatedBy, CAST('' AS NVARCHAR(126)) AS CreatedName
		FROM #K_CtTmp_Kct07
		GROUP BY AtchDocSerialNo, AtchDocFormNo, AtchDocNo, AtchDocDate, Stt, TaxRegNo, TaxRate, TypeCode, TaxCode, TotalAmount, BuiltinOrder

	ALTER TABLE #BcTmp_Kct07 ADD Stt_Sx NVARCHAR(8) NOT NULL DEFAULT ''
	UPDATE #BcTmp_Kct07 SET Stt_Sx = STR(Stt_Order, 8)

	IF ISNULL(@_Table_Temp, N'') <> ''
	BEGIN
		UPDATE #BcTmp_Kct07 SET DocDate = ISNULL(DocDate, ''), AtchDocDate = ISNULL(AtchDocDate, ''), TaxRate = ISNULL(TaxRate, 0)

		IF OBJECT_ID('TempDb..' + LTRIM(@_Table_Temp)) IS NOT NULL
			IF ISNULL(@_isCompare, 0) = 0
				EXECUTE [dbo].[usp_sys_Append]
					@_TableSource = N'#BcTmp_Kct07',
					@_TableDestination = @_Table_Temp
			ELSE
				EXECUTE [dbo].[usp_sys_Append]
					@_TableSource = N'#K_CtTmp_Kct07',
					@_TableDestination = @_Table_Temp
	END ELSE
	BEGIN
		SELECT @_TotalAmount = ISNULL(SUM(Amount2), 0),
			@_TotalTaxableAmount = ISNULL(SUM(Amount2), 0),
			@_TotalVAT = ISNULL(SUM(Amount3), 0)
		FROM #BcTmp_Kct07
		WHERE TypeCode IN ('V01', 'V02', 'R00', 'R05', 'R08', 'R10')		

		INSERT INTO #BcTmp_Kct07 (
			Stt_Sx, DocDate, AtchDocDate, TaxRegName, TaxRate, TypeCode, _FormatStyleKey, _FormatStyleArgs, _Caption, _Status)
		SELECT LEFT(dbo.ufn_sys_BH(TypeName, TypeName_English, N'', TypeName_Japanese, TypeName_Chinese, TypeName_Korean, @_LangId), 7), 
			NULL, NULL, dbo.ufn_sys_BH(TypeName, TypeName_English, N'', TypeName_Japanese, TypeName_Chinese, TypeName_Korean, @_LangId),
			CAST(NULL AS NUMERIC(5, 2)), TypeCode, N'Subtotal0',
			N'Merge:_Caption, Stt_Order, AtchDocNo, AtchDocDate, TaxRegName, TaxRegNo, Amount2, Amount3, Notes;',
			dbo.ufn_sys_BH(TypeName, TypeName_English, N'', TypeName_Japanese, TypeName_Chinese, TypeName_Korean, @_LangId),
			CAST(1 AS INT) AS _Status
		FROM #B10Kct07

		DECLARE @_Msg_Tong NVARCHAR(128) = [dbo].[ufn_sys_MessageText](N'Tong', @_LangId)

		INSERT INTO #BcTmp_Kct07 (
			Stt_Sx, DocDate, AtchDocDate, TaxRegName, TaxRate, Amount2, Amount3,
			TypeCode, _FormatStyleKey, _FormatStyleArgs, _Caption, _Status)
		SELECT @_Msg_Tong,
			CAST(NULL AS SMALLDATETIME) AS DocDate, CAST(NULL AS SMALLDATETIME) AS AtchDocDate,
			dbo.ufn_sys_MessageText('TongCong', @_LangId), CAST(NULL AS NUMERIC(5, 2)), SUM(Amount2) AS Amount2, SUM(Amount3) AS Amount3,
			TypeCode, N'BOLD', N'Merge:_Caption, Stt_Order, AtchDocNo, AtchDocDate, TaxRegName, TaxRegNo;',
			@_Msg_Tong, CAST(3 AS INT) AS _Status
		FROM #BcTmp_Kct07
		GROUP BY TypeCode

		SET @_Cmd=''
		SET @_Cmd=@_Cmd + N'
			UPDATE #BcTmp_Kct07 
			SET CreatedBy = ds.CreatedBy				
		  FROM #BcTmp_Kct07 as sc
		  INNER JOIN dbo.vB3'+ @_DataCode_Branch+'AccDoc (NOLOCK) as ds 
				ON sc.Stt = ds.Stt AND sc.DocCode = ds.DocCode' + NCHAR(13)
		EXEC sp_executesql @_Cmd
		
		UPDATE #BcTmp_Kct07 
		SET TypeName = dm.TypeName, CustomerCode=ISNULL(cus.Code,''), CreatedName=ISNULL(crd.FullName,'')
		FROM #BcTmp_Kct07 AS bc LEFT OUTER JOIN #B10Kct07 AS dm ON bc.TypeCode = dm.TypeCode
		LEFT OUTER JOIN dbo.B20Customer cus ON cus.Id=bc.CustomerId
		LEFT OUTER JOIN dbo.B00UserList as crd ON bc.CreatedBy = crd.Id

		SELECT *, IIF(ISNULL(DueDate, 0) = 0, '', CAST(DueDate AS NVARCHAR(10))) AS Notes,
			N'' AS BlankForHTKK,
			CONVERT(VARCHAR(11), AtchDocDate, 103) AS DocDate_Exp,
			IIF(DocCode <> '', N'EDIT_{=DocCode} PrimaryKeyValue={=Id}', NULL) AS _LinkCommand,
			CAST(Stt_Order AS INT) AS Stt_Order1
		FROM #BcTmp_Kct07
		ORDER BY TypeName, _Status, AtchDocDate, Stt_Order1 
	END

	DROP TABLE IF EXISTS #BcTmp_Kct07
	DROP TABLE IF EXISTS #K_CtTmp_Kct07
	DROP TABLE IF EXISTS #B10Kct07
	RETURN
END 
GO
GO


SET DATEFORMAT DMY 
EXEC 

usp_Kct_ListOfVATTax  @_DocDate1='01/01/2026 00:00:00.000',@_DocDate2='31/01/2026 00:00:00.000',@_KqtMau='B10Kct07',@_Account='133',@_In_Out='1',@_PrintType=0,@_nUserId=1213,@_LangId=0,@_BranchCode='I15',@_DescExcludeBST='C',@_TotalAmount=84280606601.00 ,@_TotalTaxableAmount=84280606601.00 ,@_TotalVAT=7514078720.00 ,@_HTKK_Exp=0,@_Filename_XML='' 
