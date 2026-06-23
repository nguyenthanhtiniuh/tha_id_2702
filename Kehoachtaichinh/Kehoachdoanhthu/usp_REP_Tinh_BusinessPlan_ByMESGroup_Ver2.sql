SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create or ALTER PROCEDURE [dbo].[usp_REP_Tinh_BusinessPlan_ByMESGroup_Ver2]
    @_DocDate1            DATE          = '20260101',
    @_DocDate2            DATE          = '20260131',
    @_DocDatePlan2        DATE          = '20251231',
    @_ProductId           VARCHAR(24)   = '',
    @_BranchCode          NVARCHAR(24)  = 'I09',
    @_Account             NVARCHAR(2000)= '511,521',
    @_NotCrspAccountList  VARCHAR(254)  = '911',
    @_nUserId             INT           = 0,
    @_LangId              INT           = 0,
    @_CurrencyCode0       CHAR(3)       = 'VND',
    @_LAYOUT_XML          NVARCHAR(MAX) = '' OUTPUT,
    @_IsRound             INT           = 0,
    @_DefinitionTableName NVARCHAR(32)  = N'B10BusinessPlanDetail',
    @_tblTmp              NVARCHAR(32)  = '',
    @_RepId1              VARCHAR(16)   = 'I090000001',
    @_RepId2              VARCHAR(16)   = 'I090000003',
    @_BranchReportId      INT           = NULL ,
    @_StrTime             NVARCHAR(128) = NULL OUTPUT
    ,@_IsGetPlan INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- ========================================================
    -- 1. KHỞI TẠO BIẾN VÀ BẢNG TẠM CƠ SỞ
    -- ========================================================
    DECLARE @_Time1 DATETIME = GETDATE(), @_Time2 DATETIME;
    DECLARE @_Num_Round INT = CASE WHEN @_IsRound = 1 THEN 1000000 ELSE 1 END;
    DECLARE @_nl CHAR(1) = CHAR(13) ,@_Key2 VARCHAR(MAX) = ''
    DECLARE @DebugStepTime DATETIME = GETDATE()
           ,@_Step NVARCHAR(2000)
           ,@_DebugMsg NVARCHAR(256) = N'';

	SET @_Key2 = N'	( DocCode IN (''XK'', ''HD'',''HC'',''TL'') )  '
 

    DROP TABLE IF EXISTS #tblTmp1;
    CREATE TABLE #tblTmp1 (
        Id              INT,
        BranchCode      NVARCHAR(3)   DEFAULT '',
        BranchName      NVARCHAR(256) DEFAULT '',
        BranchInfor     NVARCHAR(256) DEFAULT '',
        Key_Where       VARCHAR(4000) DEFAULT '',
        VarValue        VARCHAR(64)   DEFAULT '',
        VarKey          VARCHAR(24)   DEFAULT '',
        BuiltinOrder    INT,
        Description     NVARCHAR(254) DEFAULT '',
        ItemNo          NVARCHAR(3)   DEFAULT '',
        Formula         NVARCHAR(512) DEFAULT '',
        _FormatStyleKey NVARCHAR(254) DEFAULT '',
        BranchCode1     NVARCHAR(3)   DEFAULT '',
        BranchName1     NVARCHAR(256) DEFAULT ''
    );

    DROP TABLE IF EXISTS #tblTmp1_Branch;
    CREATE TABLE #tblTmp1_Branch (
        Id              INT, Key_Where VARCHAR(4000), VarValue VARCHAR(64),
        VarKey VARCHAR(24), BuiltinOrder INT, Description NVARCHAR(254),
        ItemNo NVARCHAR(3), Formula NVARCHAR(512), _FormatStyleKey NVARCHAR(254),
        BranchCode NVARCHAR(3), BranchName NVARCHAR(256), BranchInfor NVARCHAR(256)
    );

    -- ========================================================
    -- 2. XỬ LÝ BỘ LỌC CHI NHÁNH VÀ TÀI KHOẢN
    -- ========================================================
    DECLARE @_Key VARCHAR(MAX) = 'Stt = ''' + @_RepId1 + ''' ';
    DECLARE @_Key_Acc VARCHAR(MAX) = '';

    IF @_Account <> ''
        SET @_Key_Acc = N'((Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + '%''))';

    IF @_NotCrspAccountList <> ''
        SET @_Key_Acc += ' AND ((CrspAccount NOT LIKE ''' + REPLACE(@_NotCrspAccountList, ',', '%''') + '%''))';

    EXEC dbo.usp_sys_CreateTable @_Table = '#tblTmp1', @_BaseTable = @_DefinitionTableName;

    SELECT @_Step = N' Start: Khởi tạo dữ liệu cơ bản & GenKey xong.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                   ,@_DebugStepTime = @DebugStepTime OUTPUT;   

    DROP TABLE IF EXISTS #_DsDvcs;
    SELECT BranchCode, BranchCode AS BranchCode1, DataCode, CAST(0 AS INT) AS _Scan
    INTO #_DsDvcs FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode);

    -- ========================================================
    -- 3. THU THẬP DỮ LIỆU SỔ CÁI (GENERAL LEDGER)
    -- ========================================================
    DROP TABLE IF EXISTS #CtTmpGeneralLedger;
    SELECT TOP 0 CAST(-1 AS INT) AS Id, BranchCode, DocDate, DocCode, 
                 CAST('' AS NVARCHAR(24)) AS Col_DocDate, CAST('' AS NVARCHAR(24)) AS M_DocDate, 
                 CAST('' AS NVARCHAR(24)) AS Y_DocDate, CustomerId0, CustomerId, Amount2, 
                 OriginalAmount2, Stt, RowId,DebitAccount,CreditAccount,Account, CrspAccount, Amount, OriginalAmount, 
                 ItemId, CAST(NULL AS INT) AS ProductId,  
                 CAST('' AS NVARCHAR(128)) AS _FormatStyleKey, DebitAmount, OriginalDebitAmount, 
                 CreditAmount, Quantity, CurrencyCode
    INTO #CtTmpGeneralLedger FROM dbo.B00CtTmp (NOLOCK);

    EXEC dbo.usp_B30GeneralLedger_GetData 
        @_DocDate1 = @_DocDate1, @_DocDate2 = @_DocDate2, @_Key1 = @_Key_Acc, 
        @_Key2 = '', @_CtTmp = N'#CtTmpGeneralLedger', @_nUserId = @_nUserId, @_LangId = @_LangId, 
        @_BranchReportId = @_BranchReportId, @_BranchCode = @_BranchCode, @_CurrencyCode0 = @_CurrencyCode0;
		
    SELECT @_Step = N' Bước 1: Lấy xong dữ liệu Số phát sinh(#CtTmpGeneralLedger).';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                   ,@_DebugStepTime = @DebugStepTime OUTPUT;		   

	DROP TABLE IF EXISTS #CtTmp;
	SELECT TOP (0) CAST(-1 AS INT) AS Id,
		BranchCode, DocDate,DocCode,DocGroup,
		CAST('' AS NVARCHAR(24)) AS Col_DocDate, 
		CAST('' AS NVARCHAR(24))  M_DocDate, CAST('' AS NVARCHAR(24))  AS Y_DocDate,
		CustomerId,	 
		 DebitAccount,CreditAccount,
		Stt, RowId,
		Account,CrspAccount,
		Quantity,		 
		CurrencyCode  ,		 
		ItemId,
		CAST(NULL AS VARCHAR(24)) AS ItemCode,
		CAST(NULL AS TINYINT) AS ItemType,
		CAST(NULL AS INT) AS ProductId,
		CAST(NULL AS NUMERIC(18,0)) AS OriginalAmount,
		CAST(NULL AS NUMERIC(18,0)) AS Amount ,
		--tiền doanh thu trên hóa đơn 
		CAST(NULL AS NUMERIC(18,0)) AS OriginalAmount2,
		CAST(NULL AS NUMERIC(18,0)) AS Amount2,
		CAST('' AS NVARCHAR(128)) AS _FormatStyleKey,
		--Nhóm sản phẩm hợp nhất cấp 1
		CAST(NULL AS INT) AS ProductLevelId,
		--Nhóm sản phẩm hợp nhất cấp 2
		CAST(NULL AS INT) AS ProductClassId,
		--Nhóm sản phẩm 
		CAST(NULL AS INT) AS ProductGroupId,
		--Dòng sản phẩm 
		CAST(NULL AS INT) AS ProductLineId  
	INTO #CtTmp
	FROM dbo.B00CtTmp  

	SELECT @_Key2 = 
	@_Key2 + ' AND  EXISTS ( SELECT Stt FROM #CtTmpGeneralLedger ctt 
	WHERE ctt.RowId = #SFile_B30TheKho_GetData.RowId AND ctt.Stt = #SFile_B30TheKho_GetData.Stt AND ctt.DocCode = #SFile_B30TheKho_GetData.DocCode)  '
 
	--25-03-2026 xử lý lại lấy từ StockLedger
	EXECUTE dbo.usp_B30StockLedger_GetData 
			@_Date1 = @_DocDate1
			,@_Date2 = @_DocDate2
			,@_Key2 = @_Key2
			,@_CtTmp = N'#CtTmp'
			,@_nUserId = @_nUserId
			,@_LangId = @_LangId
			,@_BranchReportId = @_BranchReportId
			,@_BranchCode = @_BranchCode   

    SELECT @_Step = N' Bước 2: Lấy xong dữ liệu Số phát sinh(#CtTmp).';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                   ,@_DebugStepTime = @DebugStepTime OUTPUT;		  

	DELETE #CtTmp WHERE Amount2 =0 AND  OriginalAmount2 = 0

	UPDATE #CtTmp
	SET Amount2 = IIF(DocGroup=1,-Amount2,Amount2)
	,OriginalAmount2 = IIF(DocGroup=1,-OriginalAmount2,OriginalAmount2)
	,Quantity = IIF(DocGroup=1,-Quantity,Quantity)
 
	INSERT INTO #CtTmp (CustomerId,ProductId,ItemId,BranchCode,Amount2,Quantity,Amount,DocDate,CurrencyCode,DebitAccount,CreditAccount)
	SELECT DISTINCT CustomerId0,ProductId,ItemId,BranchCode,ISNULL(-SUM(DebitAmount),0) AS Amount2,SUM(Quantity) AS Quantity,ISNULL(-SUM(Amount),0) AS Amount,(DocDate) ,(CurrencyCode),DebitAccount,CreditAccount
	FROM  #CtTmpGeneralLedger WHERE DebitAmount <> 0   AND DebitAccount LIKE '511%' AND DocCode NOT IN ('HD','TL','XK','HC')
	GROUP BY CustomerId0,ProductId,ItemId,BranchCode,DocDate,CurrencyCode,DebitAccount,CreditAccount
 
    INSERT INTO #CtTmp (CustomerId,ProductId,ItemId,BranchCode,Amount2,Quantity,DocDate,CurrencyCode,DebitAccount,CreditAccount)
	SELECT DISTINCT CustomerId0,ProductId,ItemId,BranchCode,ISNULL(SUM(CreditAmount),0) AS Amount2,SUM(Quantity) AS Quantity,(DocDate) ,(CurrencyCode),DebitAccount,CreditAccount
	FROM  #CtTmpGeneralLedger WHERE CreditAmount <> 0   AND CreditAccount LIKE '511%' AND DocCode NOT IN ('HD','TL','XK','HC')
	GROUP BY CustomerId0,ProductId,ItemId,BranchCode,DocDate,CurrencyCode,DebitAccount,CreditAccount
 
   
  
    DECLARE @_Ma_DvcsFilter NVARCHAR(24) = N'';
    WHILE EXISTS (SELECT 1 FROM #_DsDvcs WHERE _Scan = 0)
    BEGIN
        SELECT TOP 1 @_Ma_DvcsFilter = BranchCode FROM #_DsDvcs WHERE _Scan = 0 ORDER BY BranchCode;
        TRUNCATE TABLE #tblTmp1_Branch;
        EXEC dbo.usp_sys_Append @_TableSource = @_DefinitionTableName, @_TableDestination = '#tblTmp1_Branch', @_Where_TableSource = @_Key;
        UPDATE #tblTmp1_Branch SET BranchCode = @_Ma_DvcsFilter;
        EXEC dbo.usp_sys_Append @_TableSource = '#tblTmp1_Branch', @_TableDestination = '#tblTmp1';
        UPDATE #_DsDvcs SET _Scan = 1 WHERE BranchCode = @_Ma_DvcsFilter;
    END

	--tao bang lay so ke hoach
	DROP TABLE IF EXISTS #FinPlan
	SELECT TOP (0)
		   DocDate
		  ,CAST(NULL AS INT) AS _Year
		  ,CAST(NULL AS INT) AS _Month
		  ,CAST('' AS NVARCHAR(24)) AS Col_DocDate
		  ,CustomerId
		  ,ProfitCenterId
		  ,ItemId
		  ,CAST(NULL AS TINYINT) AS ItemType
		  ,CAST(NULL AS INT) AS ProductId
		  ,CAST(0 AS NUMERIC(18, 0)) AS OriginalUnitCost
		  ,CAST(0 AS NUMERIC(18, 0)) AS Amount
		  ,CAST(0 AS NUMERIC(18, 0)) AS OriginalAmount
		  ,BranchCode,
		--Nhóm sản phẩm hợp nhất cấp 1
		CAST(NULL AS INT) AS ProductLevelId,
		--Nhóm sản phẩm hợp nhất cấp 2
		CAST(NULL AS INT) AS ProductClassId,
		--Nhóm sản phẩm 
		CAST(NULL AS INT) AS ProductGroupId,
		--Dòng sản phẩm 
		CAST(NULL AS INT) AS ProductLineId  ,
        --Phân loại khách hàng
        CAST('' AS VARCHAR(24)) AS MESGroupCode
	INTO #FinPlan
	FROM dbo.B00CtTmp

	EXECUTE dbo.usp_sys_DefaultTable @_Table = '#FinPlan'

    
    if @_IsGetPlan= 1
	EXEC usp_FinPlanDetail_GetData @_CtTmp = '#FinPlan' ,@_BranchCode = @_BranchCode	,   @_PrintExec = 0
  
    
	
    UPDATE a
	SET a.ItemType = item.ItemType
	--Lấy mã hợp nhất cấp 1
		,ProductLevelId = ProductClass.ProductLevelId
	   ,ProductClassId = item.ProductClassId
	   ,ProductGroupId = item.ProductGroupId
	   ,ProductLineId = item.ProductLineId
	   
	FROM #FinPlan a
		INNER JOIN dbo.B20Item item WITH (NOLOCK)
			ON a.ItemId = item.Id
			LEFT JOIN B20ProductClass ProductClass ON item.ProductClassId= ProductClass.Id
 
    -- ========================================================
    -- 4. TẠO HEADER ĐỘNG VÀ THIẾT LẬP CẤU TRÚC GRID 2
    -- ========================================================
    DROP TABLE IF EXISTS #ColList;
    CREATE TABLE #ColList (
        Tt INT, M_DocDate1 INT, M_DocDate2 INT, Y_DocDate INT, ColName NVARCHAR(128),
        UserData0 NVARCHAR(128), Row_0_VN NVARCHAR(256), Row_0_EN NVARCHAR(256),
        UserData1 NVARCHAR(128), Row_1_VN NVARCHAR(256), Row_1_EN NVARCHAR(256),
        _TextAlign NVARCHAR(24) DEFAULT '', _Width NVARCHAR(24) DEFAULT '',
        _Format NVARCHAR(24) DEFAULT '', _ForeColor NVARCHAR(24) DEFAULT '',
        _BackColor NVARCHAR(24) DEFAULT '', Type INT
    );
       
    INSERT INTO #ColList
    EXEC dbo.usp_GenerateReportHeader_ActualPlan @_DocDate1 = @_DocDate1, @_DocDate2 = @_DocDate2, @_LAYOUT_XML = @_LAYOUT_XML OUTPUT;
 
    DROP TABLE IF EXISTS #tblTmp1Grid2 ;
    CREATE TABLE #tblTmp1Grid2  (
        Id INT DEFAULT 0, BranchCode NVARCHAR(24) DEFAULT '', Key_Where VARCHAR(4000) DEFAULT '',
        VarValue VARCHAR(64) DEFAULT '', VarKey VARCHAR(24) DEFAULT '', BuiltinOrder INT, IsPrint int 
    );

    EXEC dbo.usp_sys_CreateTable @_Table = '#tblTmp1Grid2', @_BaseTable = @_DefinitionTableName;
	
    SELECT @_Key = 'Stt = ''' + @_RepId2 + ''' ';
    EXEC dbo.usp_sys_Append @_TableSource = @_DefinitionTableName, @_TableDestination = '#tblTmp1Grid2 ', @_Where_TableSource = @_Key;
 
       	 
	 
       
    
    -- Thêm các cột động vào khung báo cáo
    DECLARE @_AlterCols NVARCHAR(MAX) = N'';
    DECLARE @_AlterColsOriginal NVARCHAR(MAX) = N'';
    SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL', ', ') FROM #ColList;
	  
    DECLARE @_SqlAlterHeaders NVARCHAR(MAX) = 
        N'ALTER TABLE #tblTmp1 ADD ' + @_AlterCols + N';' + @_nl + 
        N'ALTER TABLE #tblTmp1Grid2 ADD ' + @_AlterCols + N';';
    EXEC sys.sp_executesql @_SqlAlterHeaders;
	  
    -- ========================================================
    -- 5. XỬ LÝ DỮ LIỆU THỰC TẾ (SINGLE-PASS AGGREGATION)
    -- ========================================================
    UPDATE #CtTmp SET 
        Col_DocDate = FORMAT(DocDate, 'yyyyMM'), M_DocDate = MONTH(DocDate), 
        Y_DocDate = YEAR(DocDate),  
        Amount2 = ISNULL(Amount2,0), OriginalAmount2 = ISNULL(OriginalAmount2,0);
		 
	UPDATE #CtTmpGeneralLedger SET Amount2 = ISNULL(Amount,0), OriginalAmount2 = ISNULL(OriginalAmount,0);

	UPDATE #CtTmp
	SET ProductLevelId = item.ProductLevelId
	   ,ProductClassId = item.ProductClassId
	   ,ProductGroupId = item.ProductGroupId
	   ,ProductLineId = item.ProductLineId,ItemCode = item.Code
	FROM #CtTmp tmm
		INNER JOIN B20Item item WITH (NOLOCK)
			ON tmm.ItemId = item.Id
 
    DECLARE @_MonthlyAggCols_Reality NVARCHAR(MAX) = N'';
    SELECT @_MonthlyAggCols_Reality=  STRING_AGG(CAST(
        CONCAT('SUM(CASE WHEN YEAR(DocDate) = ', TRIM(STR(Y_DocDate)), ' AND MONTH(DocDate) BETWEEN ', TRIM(STR(M_DocDate1)), ' AND ', TRIM(STR(M_DocDate2)), ' THEN Amount2 ELSE 0 END) / ', TRIM(STR(@_Num_Round)), ' AS ', QUOTENAME(ColName),
               ', SUM(CASE WHEN YEAR(DocDate) = ', TRIM(STR(Y_DocDate)), ' AND MONTH(DocDate) BETWEEN ', TRIM(STR(M_DocDate1)), ' AND ', TRIM(STR(M_DocDate2)), ' THEN OriginalAmount2 ELSE 0 END) / ', TRIM(STR(@_Num_Round)), ' AS ', QUOTENAME('Original' + ColName)) AS VARCHAR(MAX)),
        ', '  ) 
    FROM #ColList 
	WHERE Type = 0;     
	
	DECLARE @_MonthlyAggCols_Plan NVARCHAR(MAX) = N'';
    SELECT @_MonthlyAggCols_Plan=  STRING_AGG(CAST(
        CONCAT('SUM(CASE WHEN YEAR(DocDate) = ', TRIM(STR(Y_DocDate)), ' AND _Month BETWEEN ', TRIM(STR(M_DocDate1)), ' AND ', TRIM(STR(M_DocDate2)), ' THEN Amount ELSE 0 END) / ', TRIM(STR(@_Num_Round)), ' AS ', QUOTENAME(ColName),
               ', SUM(CASE WHEN YEAR(DocDate) = ', TRIM(STR(Y_DocDate)), ' AND _Month BETWEEN ', TRIM(STR(M_DocDate1)), ' AND ', TRIM(STR(M_DocDate2)), ' THEN OriginalAmount ELSE 0 END) / ', TRIM(STR(@_Num_Round)), ' AS ', QUOTENAME('Original' + ColName)) AS VARCHAR(MAX)),
        ', '  ) 
    FROM #ColList 
	WHERE Type = 1;     

    DROP TABLE IF EXISTS #CtTmp1;
	SELECT TOP 0
		   BranchCode,CustomerId,CurrencyCode,CAST('' AS VARCHAR(24)) AS MESGroupCode
		  --Nhóm sản phẩm hợp nhất cấp 1
		  ,ProductLevelId
		  --Nhóm sản phẩm hợp nhất cấp 2
		  ,ProductClassId
		  --Nhóm sản phẩm 
		  ,ProductGroupId
		  --Dòng sản phẩm 
		  ,ProductLineId
	INTO #CtTmp1
	FROM #CtTmp;   
 
	--xu ly cot so thuc te Type = 0
    DECLARE @_ListCols_Reality NVARCHAR(MAX) = '';
    SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL, ' + QUOTENAME('Original' + ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL', ', '),
           @_ListCols_Reality = STRING_AGG(QUOTENAME(ColName) + ',' + QUOTENAME('Original' + ColName), ', ')
    FROM #ColList
	WHERE Type = 0;

    DECLARE @_SqlAlterCtTmp1 NVARCHAR(MAX) = N'ALTER TABLE #CtTmp1 ADD ' + @_AlterCols + N';';
    EXEC sys.sp_executesql @_SqlAlterCtTmp1;

	--xu ly cot so thuc te Type = 1
	DECLARE @_ListCols_Plan NVARCHAR(MAX) = '';
	SELECT @_ListCols_Plan =''
    SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL, ' + QUOTENAME('Original' + ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL', ', '),
           @_ListCols_Plan = STRING_AGG(QUOTENAME(ColName) + ',' + QUOTENAME('Original' + ColName), ', ')
    FROM #ColList
	WHERE Type = 1;
	SELECT @_SqlAlterCtTmp1  = N'ALTER TABLE #CtTmp1 ADD ' + @_AlterCols + N';';
    EXEC sys.sp_executesql @_SqlAlterCtTmp1; 

      
 
    DECLARE @_SqlCreateCtTmp1 NVARCHAR(MAX) = N'
        INSERT INTO #CtTmp1(CustomerId, BranchCode,  CurrencyCode, MESGroupCode,ProductLevelId,ProductClassId,ProductGroupId,ProductLineId, ' + @_ListCols_Reality + N')
        SELECT ct.CustomerId, ct.BranchCode,   ct.CurrencyCode, cus.MESGroupCode,ct.ProductLevelId,ct.ProductClassId,ct.ProductGroupId,ct.ProductLineId, ' + @_MonthlyAggCols_Reality + N'
        FROM #CtTmp ct
        LEFT JOIN dbo.B20Customer cus WITH (NOLOCK) ON ct.CustomerId = cus.Id
        GROUP BY ct.CustomerId, ct.BranchCode,  ct.CurrencyCode, cus.MESGroupCode ,ct.ProductLevelId,ct.ProductClassId,ct.ProductGroupId,ct.ProductLineId
 
		INSERT INTO #CtTmp1(CustomerId, BranchCode,  CurrencyCode, MESGroupCode,ProductLevelId,ProductClassId,ProductGroupId,ProductLineId, ' + @_ListCols_Plan + N')
        SELECT ct.CustomerId, ct.BranchCode,   '''+@_CurrencyCode0+''', cus.MESGroupCode,ct.ProductLevelId,ct.ProductClassId,ct.ProductGroupId,ct.ProductLineId, ' + @_MonthlyAggCols_plan+ N'
        FROM #FinPlan ct
        LEFT JOIN dbo.B20Customer cus WITH (NOLOCK) ON ct.CustomerId  = cus.Id
        GROUP BY ct.CustomerId , ct.BranchCode,  cus.MESGroupCode,ct.ProductLevelId,ct.ProductClassId,ct.ProductGroupId,ct.ProductLineId

        CREATE CLUSTERED INDEX IX_CtTmp1_Main ON #CtTmp1 (BranchCode, MESGroupCode);' ;
	
    EXEC sp_executesql @_SqlCreateCtTmp1;
 
    -- ========================================================
    -- 6. CẬP NHẬT GRID CHÍNH THEO MES GROUP
    -- ========================================================
    DROP TABLE IF EXISTS #AggregatedData;
    DECLARE @_SumActualCols NVARCHAR(MAX) = N'';
    DECLARE @_SumPlanCols NVARCHAR(MAX) = N'';
 
	SELECT @_SumActualCols = STRING_AGG(CONCAT('SUM(', QUOTENAME(ColName), ') AS ', QUOTENAME(ColName), ', SUM(', QUOTENAME('Original' + ColName), ') AS ', QUOTENAME('Original' + ColName)), ', ')
    FROM #ColList   WHERE Type = 0
 
	SELECT @_SumPlanCols = STRING_AGG(CONCAT('SUM(', QUOTENAME(ColName), ') AS ', QUOTENAME(ColName), ', SUM(', QUOTENAME('Original' + ColName), ') AS ', QUOTENAME('Original' + ColName)), ', ')
    FROM #ColList   WHERE Type = 1

	-- Cột chạy cập nhật dữ liệu thì lấy cả số Thực tế, Kế hoạch
    DECLARE @_SetColumns NVARCHAR(MAX) = N'', @_FinalSumColumns NVARCHAR(MAX) = N'';
    SELECT @_SetColumns = STRING_AGG(CONCAT(QUOTENAME(ColName), ' = ISNULL(FinalAgg.', QUOTENAME(ColName), ', 0)'), ', ') FROM #ColList  ;
    SELECT @_FinalSumColumns = STRING_AGG(CONCAT('SUM(ad.', QUOTENAME(ColName), ') AS ', QUOTENAME(ColName)), ', ') FROM #ColList  ;

	DECLARE @_SetCurrencyCols NVARCHAR(MAX) = N'';
    SELECT @_SetCurrencyCols   = N'';
    SELECT @_SetCurrencyCols = STRING_AGG(CONCAT(QUOTENAME(ColName), ' = CASE WHEN TMP.VarValue = ''VND'' THEN ISNULL(Agg.', QUOTENAME(ColName), ', 0) WHEN TMP.VarValue = ''USD'' THEN ISNULL(Agg.', QUOTENAME('Original' + ColName), ', 0) ELSE 0 END'), ', ')
    FROM #ColList  ;
 
    DECLARE @_SqlPreAgg NVARCHAR(MAX) = N'
        SELECT BranchCode, MESGroupCode,CurrencyCode, ' + @_SumActualCols+' , ' + @_SumPlanCols + N' INTO #AggregatedData 
		FROM #CtTmp1 GROUP BY BranchCode, MESGroupCode,CurrencyCode ;
        CREATE CLUSTERED INDEX IX_AggData ON #AggregatedData (BranchCode, MESGroupCode,CurrencyCode);
 
        UPDATE TMP SET ' + @_SetColumns + N' FROM #tblTmp1 TMP 
		CROSS APPLY (SELECT ' + @_FinalSumColumns + N' FROM STRING_SPLIT(TMP.VarValue, '','') s 
		INNER JOIN #AggregatedData ad ON ad.MESGroupCode = TRIM(s.value) 
		AND ad.BranchCode = TMP.BranchCode) FinalAgg WHERE TMP.VarKey = ''MESGroupCode'' AND ISNULL(TMP.VarValue, '''') <> '''';
		
		-- BỔ SUNG: Cập nhật chỉ tiêu CurrencyCode cho Bảng 1
        UPDATE TMP SET ' + @_SetCurrencyCols + N' 
        FROM #tblTmp1 TMP 
        CROSS APPLY (
            SELECT ' + (SELECT STRING_AGG(CONCAT('SUM(', QUOTENAME(v.Col), ') AS ', QUOTENAME(v.Col)), ', ') FROM #ColList c 
			CROSS APPLY (VALUES (c.ColName), (CONCAT('Original', c.ColName))) v(Col)) + N' 
            FROM #AggregatedData ad 
            WHERE ad.CurrencyCode = TMP.VarValue AND ad.BranchCode = TMP.BranchCode
        ) Agg 
        WHERE TMP.VarKey = ''CurrencyCode'' ;

		UPDATE TMP SET ' + @_SetColumns + N' FROM #tblTmp1Grid2 TMP 
		CROSS APPLY (SELECT ' + @_FinalSumColumns + N' FROM STRING_SPLIT(TMP.VarValue, '','') s 
		INNER JOIN #AggregatedData ad ON ad.MESGroupCode = TRIM(s.value)) 
		FinalAgg WHERE TMP.VarKey = ''MESGroupCode'' AND ISNULL(TMP.VarValue, '''') <> '''';'
    EXEC sys.sp_executesql @_SqlPreAgg;
  
    -- ========================================================
    -- 7. XỬ LÝ GRID 2 (PROFIT CENTER & CURRENCY)
    -- ========================================================
    DROP TABLE IF EXISTS #AggGrid2;
    DECLARE @_SumColsGrid2 NVARCHAR(MAX) = N'';
    SELECT @_SumColsGrid2 = STRING_AGG(CONCAT('SUM(', QUOTENAME(ColName), ') AS ', QUOTENAME(ColName), ', SUM(', QUOTENAME('Original' + ColName), ') AS ', QUOTENAME('Original' + ColName)), ', ')
    FROM #ColList 

	DROP TABLE IF EXISTS #AggGrid2;

	SELECT TOP 0  BranchCode,  CurrencyCode INTO #AggGrid2 FROM #CtTmp1
	SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL', ', ') FROM #ColList;
	SELECT @_AlterColsOriginal = STRING_AGG(QUOTENAME('Original'+ColName) + ' NUMERIC(18,2) DEFAULT 0 NOT NULL', ', ') FROM #ColList;
	  
    SELECT @_SqlAlterHeaders  = 
        N'ALTER TABLE #AggGrid2 ADD ' + @_AlterCols + N';' + @_nl + 
        N'ALTER TABLE #AggGrid2 ADD ' + @_AlterColsOriginal + N';' + @_nl         
    EXEC sys.sp_executesql @_SqlAlterHeaders;
 
	DECLARE @_ListColsAggregation NVARCHAR(MAX) = (SELECT STRING_AGG(CONCAT(QUOTENAME(ColName),' , ',QUOTENAME('Original'+ColName)), ' ,') FROM #ColList);
 
    DECLARE @_SqlPreAggGrid2 NVARCHAR(MAX) = N'
        INSERT INTO  #AggGrid2 (BranchCode,  CurrencyCode, '+@_ListColsAggregation+' )
        SELECT BranchCode,  CurrencyCode, ' + @_SumColsGrid2 + N'   FROM #CtTmp1 GROUP BY BranchCode,  CurrencyCode; 
        CREATE CLUSTERED INDEX IX_AggGrid2 ON #AggGrid2 (BranchCode,  CurrencyCode);';	 
	EXEC sys.sp_executesql @_SqlPreAggGrid2; 
 
 
    SELECT @_SetCurrencyCols   = N'';
    SELECT @_SetCurrencyCols = STRING_AGG(CONCAT(QUOTENAME(ColName), ' = CASE WHEN TMP.VarValue = ''VND'' THEN ISNULL(Agg.', QUOTENAME(ColName), ', 0) WHEN TMP.VarValue = ''USD'' THEN ISNULL(Agg.', QUOTENAME('Original' + ColName), ', 0) ELSE 0 END'), ', ')
    FROM #ColList  ;

    DECLARE @_SetPCCols NVARCHAR(MAX) = N'', @_SumPCCols NVARCHAR(MAX) = N'';
    SELECT @_SetPCCols = STRING_AGG(CONCAT(QUOTENAME(ColName), ' = ISNULL(src.', QUOTENAME(ColName), ', 0)'), ', ') FROM #ColList  
    SELECT @_SumPCCols = STRING_AGG(CONCAT('SUM(ad.', QUOTENAME(ColName), ') AS ', QUOTENAME(ColName)), ', ') FROM #ColList  

    DECLARE @_SqlUpdatePC NVARCHAR(MAX) =  @_nl + 
       
	   N'UPDATE TMP SET ' + @_SetCurrencyCols + N' FROM #tblTmp1Grid2 TMP CROSS APPLY (SELECT ' + 
        (SELECT STRING_AGG(CONCAT('SUM(', QUOTENAME(v.Col), ') AS ', QUOTENAME(v.Col)), ', ') FROM #ColList c CROSS APPLY (VALUES (c.ColName), (CONCAT('Original', c.ColName))) v(Col)  ) + 
        N' FROM #AggGrid2 ad WHERE ad.CurrencyCode = TMP.VarValue ) Agg WHERE TMP.VarKey = ''CurrencyCode'';' 
 
    EXEC sys.sp_executesql @_SqlUpdatePC;   

 
	--Dùng VarValue giá trị Id,Code tùy theo người dùng nhập liệu trên form khai báo chỉ tiêu để làm điều kiện join với bảng dữ liệu thô đã dựng cột theo tháng
	SELECT @_SqlUpdatePC = ''
	SELECT @_SqlUpdatePC =	      
	   N';WITH CTE_CleanedSplit AS (SELECT DISTINCT TMP.Id, TRY_CAST(TRIM(s.value) AS INT) AS CleanedPCId FROM 
	   #tblTmp1Grid2 TMP CROSS APPLY STRING_SPLIT(TMP.VarValue, '','') s 
	   WHERE TMP.VarKey = ''ProductLevelId'' AND ISNULL(TMP.VarValue, '''') <> ''''), 
	   CTE_AggregatedResult AS (SELECT cs.Id, ' + @_SumPCCols + N' FROM CTE_CleanedSplit cs 
	   INNER JOIN #CtTmp1 ad ON ad.ProductLevelId = cs.CleanedPCId GROUP BY cs.Id) 
	   UPDATE target SET ' + @_SetPCCols + N' FROM #tblTmp1Grid2 target INNER JOIN CTE_AggregatedResult src ON target.Id = src.Id; 	   
	   ' 	
	EXEC sys.sp_executesql @_SqlUpdatePC;   
	PRINT @_SqlUpdatePC
 
    -- ========================================================
    -- 8. KẾT THÚC VÀ TRẢ DỮ LIỆU
    -- ========================================================
    DECLARE @_CalSum VARCHAR(MAX) = '';
    SELECT @_CalSum = STRING_AGG(ColName, ',') FROM #ColList;
    EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp1Grid2', @_FieldList = @_CalSum, @_FieldKey = 'ItemNo', @_FieldCal = 'Formula', @_FieldBac = 'ItemLevel', @_FieldIn_Ck = 'IsPrint', @_ResetFormula = 1;

    -- Cập nhật thông tin chi nhánh và Layout
    UPDATE #tblTmp1 SET BranchName = br.BranchName, BranchInfor = CONCAT(tmp.BranchCode, '-', br.BranchName) FROM #tblTmp1 tmp 
	INNER JOIN dbo.B00Branch br ON tmp.BranchCode = br.BranchCode;

    DECLARE @_LAYOUT_XML2 NVARCHAR(MAX) = REPLACE(@_LAYOUT_XML, 'Report_0', 'Report_1');
    SET @_LAYOUT_XML = N'<panelReporter>' + @_nl + N'   <Controls> ' + @_nl + N' ' + CONCAT(@_LAYOUT_XML, @_nl, @_LAYOUT_XML2) + @_nl + N'   </Controls> ' + @_nl + N'</panelReporter>' + @_nl;
 
	;
    WITH cteBrConsolidation1
    AS (SELECT BranchCode1
              ,Name AS Name1
              ,Id
              ,ParentId
        FROM B00BrConsolidation
        WHERE isactive = 1
              AND ParentId = -1
              AND BranchCode1 <> '')
        ,cteBrConsolidation
    AS (SELECT BranchCode
              ,Name
              ,Id
              ,ParentId
        FROM B00BrConsolidation
        WHERE isactive = 1
              AND ParentId <> -1
              AND BranchCode <> '')
    UPDATE #tblTmp1
    SET BranchName1 = CONCAT(c.BranchCode1, ' - ', c.Name1)
    FROM #tblTmp1 tbl
        INNER JOIN
        (
            SELECT BrC.BranchCode
                  ,BrC.Name
                  ,BrC1.BranchCode1
                  ,BrC1.Name1
            FROM cteBrConsolidation BrC
                LEFT JOIN cteBrConsolidation1 BrC1
                    ON BrC.ParentId = BrC1.Id
        ) c
            ON c.BranchCode = tbl.BranchCode
 
    SELECT * FROM #tblTmp1 WHERE ISNULL(BranchName1, '') <> '' ORDER BY BranchCode, BuiltinOrder;
    SELECT * FROM #tblTmp1Grid2 where IsPrint = 1 ORDER BY BranchCode, BuiltinOrder;

    SET @_Time2 = GETDATE();
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, @_Time2)));

    DROP TABLE IF EXISTS #ColList, #BranchCode0, #CtTmp, #CtTmp1, #_DsDvcs, #tblTmp1, #tblTmp1Grid2, #AggregatedData, #AggGrid2;
END

GO



set dateformat dmy
exec [usp_REP_Tinh_BusinessPlan_ByMESGroup_Ver2_test] @_DocDate1='01/01/2026 00:00:00.000',@_DocDate2='31/01/2026 00:00:00.000',@_BranchCode='I00',@_nUserId=1213,@_LangId=0,@_CurrencyCode0='VND',@_IsRound=0,@_RepId1='I090000001',@_RepId2='I000000007',@_BranchReportId=17641848,@_StrTime='00:00:07'