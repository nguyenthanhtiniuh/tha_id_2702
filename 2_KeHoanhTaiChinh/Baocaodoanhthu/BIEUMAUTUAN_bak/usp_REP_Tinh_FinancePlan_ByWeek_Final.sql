SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================
-- Description: Báo cáo kế hoạch doanh thu theo tuần (sản phẩm)
-- chỉ lấy số thực hiện
--	chủ nhật là ngày đầu tuần
--	->t7 là ngày cuối tuần
--	Author TINNT
--	22-05-2026
-- ============================================

ALTER PROCEDURE dbo.usp_REP_Tinh_FinancePlan_ByWeek_Final_test
    @_DocDate1 DATE = NULL,
    @_DocDate2 DATE = NULL,
    @_DocDatePlan2 DATE = NULL,
    @_ItemId VARCHAR(24) = '',
    @_ProductId VARCHAR(24) = '',
    @_CustomerId VARCHAR(512) = '',
    @_Account NVARCHAR(2000) = '511',
    @_ExcludeCrspAccount VARCHAR(2000) = '911,3332,333301,33381',
    @_CrspAccount VARCHAR(2000) = '',
    @_BranchCode NVARCHAR(24) = '',
    @_nUserId INT = 0,
    @_LangId INT = 0,
    @_CurrencyCode0 CHAR(3) = 'VND',
    @_LAYOUT_XML NVARCHAR(MAX) = '' OUTPUT,
    @_IsRound INT = 0,
    @_DefinitionTableName NVARCHAR(32) = N'B10BusinessPlanPNDetail',
    @_RepId1 VARCHAR(16) = 'I020000005',
    @_RepId2 VARCHAR(16) = 'I240000067',
    @_tblTmp VARCHAR(64) = '',
    @_ListColumn_Ins VARCHAR(MAX) = '',
    @_MESGroupCode_List VARCHAR(24) = N'',
    @_StrTime VARCHAR(MAX) = '' OUTPUT,
    @_SellingExchangeRate NUMERIC(15, 5) = 26000,
    @_IsGetPlan INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @_Time1 DATETIME = GETDATE();
    DECLARE @DebugStepTime DATETIME = GETDATE(),
            @_Step NVARCHAR(2000),
            @_DebugMsg NVARCHAR(256) = N'';
    DECLARE @_KeyRep VARCHAR(MAX) = '',
            @_Key2 VARCHAR(MAX) = '';
    DECLARE @_StrExec NVARCHAR(MAX) = N'',
            @_nl CHAR(1) = CHAR(13),
            @_DataCode VARCHAR(24),
            @_BranchName NVARCHAR(256),
            @_Key_Acc VARCHAR(MAX) = '';
    DECLARE @_MoneyType AS dbo.MoneyType = 0,
            @_QuantityType dbo.QuantityType = 0,
            @_TINYINTType TINYINT = 0,
            @_INTType INT = 0,
            @_CodeType VARCHAR(24) = '',
            @_NameType NVARCHAR(256) = N'',
            @_UnitType NVARCHAR(8) = N'',
            @_BizDocIdType VARCHAR(16) = '';

    SELECT TOP (1)
           @_SellingExchangeRate = SellingExchangeRate
    FROM dbo.B20CurrencyDetail
    WHERE @_BranchCode = 'I00'
    ORDER BY StartDate DESC;

    SELECT @_DocDatePlan2 = ISNULL(@_DocDatePlan2, EOMONTH(@_DocDate2));
    SELECT @_KeyRep = ' Stt = ''' + (@_RepId1) + '''  AND IsPrint = 1 ';
    DROP TABLE IF EXISTS #tblTmp1;
    CREATE TABLE #tblTmp1
    (
        Id INT
            DEFAULT 0,
        BuiltinOrder INT,
        ParentId INT,
        IsGroup INT,
        ItemNo VARCHAR(24),
        Description NVARCHAR(4000),
        Code VARCHAR(24),
        Name NVARCHAR(4000),
        BranchCode NVARCHAR(24),
        BranchName NVARCHAR(256),
        Key_Where NVARCHAR(MAX),
        VarKey VARCHAR(24),
        VarValue VARCHAR(64),
        VarKey_Exclude VARCHAR(24),
        VarValue_Exclude VARCHAR(64),
        GroupCode VARCHAR(64),
        GroupName NVARCHAR(256),
        Formula NVARCHAR(MAX)
    );
    EXECUTE dbo.usp_sys_CreateTable @_Table = '#tblTmp1',
                                    @_BaseTable = @_DefinitionTableName;
    EXECUTE dbo.usp_sys_Append @_TableSource = @_DefinitionTableName,
                               @_TableDestination = '#tblTmp1',
                               @_Where_TableSource = @_KeyRep;

    --#tblTmp2
    SELECT @_KeyRep = ' Stt = ''' + (@_RepId2) + '''  AND IsPrint = 1 ';
    DROP TABLE IF EXISTS #tblTmp2;
    CREATE TABLE #tblTmp2
    (
        Id INT
            DEFAULT 0,
        BuiltinOrder INT,
        ParentId INT,
        IsGroup INT,
        ItemNo VARCHAR(24),
        Description NVARCHAR(4000),
        Code VARCHAR(24),
        Name NVARCHAR(4000),
        BranchCode NVARCHAR(24),
        BranchName NVARCHAR(256),
        Key_Where NVARCHAR(MAX),
        VarKey VARCHAR(24),
        VarValue VARCHAR(64),
        VarKey_Exclude VARCHAR(24),
        VarValue_Exclude VARCHAR(64),
        GroupCode VARCHAR(64),
        GroupName NVARCHAR(256),
        Formula NVARCHAR(MAX)
    );

    EXECUTE dbo.usp_sys_CreateTable @_Table = '#tblTmp2',
                                    @_BaseTable = @_DefinitionTableName;

    SELECT TOP (1)
           @_BranchName = BranchName
    FROM dbo.B00Branch
    WHERE BranchCode = @_BranchCode
    ORDER BY BranchCode ASC;

    EXECUTE dbo.usp_sys_Append @_TableSource = @_DefinitionTableName,
                               @_TableDestination = '#tblTmp2',
                               @_Where_TableSource = @_KeyRep;

    UPDATE #tblTmp1
    SET BranchCode = @_BranchCode,
        BranchName = @_BranchName,
        Code = ItemNo,
        Name = Description;

    DECLARE @_Num_Round INT = 1;
    IF @_IsRound = 1
        SET @_Num_Round = 1000000;

    IF @_Account <> ''
    BEGIN
        SET @_Key_Acc += N'(' + N'(Account LIKE ''' + REPLACE(@_Account, ',', '%'') OR (Account LIKE ''') + N'%'')'
                         + N')';
    END;

    IF @_ExcludeCrspAccount <> ''
    BEGIN
        SET @_Key_Acc += N' AND ' + N'(' + N'(CrspAccount NOT LIKE '''
                         + REPLACE(@_ExcludeCrspAccount, ',', '%'') AND (CrspAccount NOT LIKE ''') + N'%'')' + N')';
    END;

    IF @_CrspAccount <> ''
    BEGIN
        SET @_Key_Acc += N'OR (' + N'  (CrspAccount LIKE '''
                         + REPLACE(@_CrspAccount, ',', '%'') OR (CrspAccount LIKE ''') + N'%'')' + N')';
    END;

    SELECT @_Step = N' Start: Khởi tạo dữ liệu cơ bản & GenKey xong.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                    @_DebugStepTime = @DebugStepTime OUTPUT;
    IF @_ItemId <> ''
        EXECUTE dbo.usp_sys_GenKey @_Code = @_ItemId,
                                   @_ColGen = 'ItemId',
                                   @_ColName = 'Id',
                                   @_TableName = 'B20Item',
                                   @_AndOrKey = 'AND',
                                   @_Key = @_Key2 OUTPUT;
    IF @_ProductId <> N''
        EXECUTE dbo.usp_sys_GenKey @_Code = @_ProductId,
                                   @_ColGen = 'ProductId',
                                   @_ColName = 'Id',
                                   @_TableName = 'B20Product',
                                   @_AndOrKey = 'AND',
                                   @_Key = @_Key2 OUTPUT;
    IF @_CustomerId <> N''
        EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId,
                                   @_ColGen = 'CustomerId',
                                   @_ColName = 'Id',
                                   @_TableName = 'B20Customer',
                                   @_AndOrKey = 'AND',
                                   @_Key = @_Key2 OUTPUT;
    IF LEFT(@_Key2, 5) = N' AND '
        SET @_Key2 = SUBSTRING(@_Key2, 6, LEN(@_Key2) - 5);
    IF LEFT(@_Key_Acc, 5) = N' AND '
        SET @_Key_Acc = SUBSTRING(@_Key_Acc, 6, LEN(@_Key_Acc) - 5);

    -- ========================================================
    -- 4. TẠO HEADER ĐỘNG VÀ THIẾT LẬP CẤU TRÚC GRID 2
    -- ========================================================
    DROP TABLE IF EXISTS #ColList;
    CREATE TABLE #ColList
    (
        Tt INT,
        M_DocDate1 INT,
        M_DocDate2 INT,
        Y_DocDate INT,
        ColName NVARCHAR(128),
        UserData0 NVARCHAR(128),
        Row_0_VN NVARCHAR(256),
        Row_0_EN NVARCHAR(256),
        UserData1 NVARCHAR(128),
        Row_1_VN NVARCHAR(256),
        Row_1_EN NVARCHAR(256),
        UserData2 NVARCHAR(128),
        Row_2_VN NVARCHAR(256),
        Row_2_EN NVARCHAR(256),
        _TextAlign NVARCHAR(24)
            DEFAULT '',
        _Width NVARCHAR(24)
            DEFAULT '',
        _Format NVARCHAR(24)
            DEFAULT '',
        _ForeColor NVARCHAR(24)
            DEFAULT '',
        _BackColor NVARCHAR(24)
            DEFAULT '',
        Type INT,
        StartDate DATE,
        EndDate DATE
    );
    DECLARE @_jsonData NVARCHAR(MAX);
    INSERT INTO #ColList
    EXEC dbo.usp_GenerateReportHeader_ActualPlan_ByWeek @_DocDate1 = @_DocDate1,
                                                        @_DocDate2 = @_DocDate2,
                                                        @_DocDatePlan2 = @_DocDatePlan2,
                                                        @_LAYOUT_XML = @_LAYOUT_XML OUTPUT,
                                                        @_jsonData = @_jsonData OUTPUT;
    UPDATE #ColList
    SET _Format = 'N2',
        _Width = 150;

    --SET DATEFIRST 7 -- Chủ nhật là ngày đầu tuần 
    SET DATEFIRST 1; -- Thứ 2 là ngày đầu tuần 
    DECLARE @table TABLE
    (
        DocDate DATE,
        StartDate DATE,
        EndDate DATE,
        _Year INT,
        _Week INT,
        _Month INT,
        ISO_Week INT,
        W_DocDate_Rep INT,
        M_DocDate INT,
        _Stt INT
    );
    --Tận dụng OPENJSON -> Kế thừa lại bảng @table của store usp_GenerateReportHeader_ActualPlan_ByWeek
    INSERT INTO @table
    (
        DocDate,
        StartDate,
        EndDate,
        _Year,
        _Week,
        _Month,
        ISO_Week,
        W_DocDate_Rep,
        M_DocDate,
        _Stt
    )
    SELECT DocDate,
           StartDate,
           EndDate,
           _Year,
           _Week,
           _Month,
           ISO_Week,
           W_DocDate_Rep,
           M_DocDate,
           _Stt
    FROM
        OPENJSON(@_jsonData)
        WITH
        (
            DocDate DATE,
            StartDate DATE,
            EndDate DATE,
            _Year INT,
            _Week INT,
            _Month INT,
            ISO_Week INT,
            W_DocDate_Rep INT,
            M_DocDate INT,
            _Stt INT
        );
    DROP TABLE IF EXISTS #CtTmpGeneralLedger;
    SELECT TOP (0)
           CAST(NULL AS INT) AS Id,
           vbgl.BranchCode,
           vbgl.DocDate,
           vbgl.DocNo,
           vbgl.Description,
           vbgl.DocGroup,
           vbgl.DocCode,
           vbgl.CustomerId,
           vbgl.CustomerId0,
           vbgl.Stt,
           vbgl.RowId,
           vbgl.CurrencyCode,
           vbgl.Account,
           vbgl.CrspAccount,
           CAST(NULL AS INT) AS ItemId,
           vbgl.OriginalAmount,
           vbgl.Amount,
           @_QuantityType AS Quantity,
           @_MoneyType AS DebitAmount,
           @_MoneyType AS CreditAmount,
           @_MoneyType AS OriginalDebitAmount,
           @_MoneyType AS OriginalCreditAmount,
           @_CodeType AS CreditAccount,
           @_CodeType AS DebitAccount,   --
           @_MoneyType AS No_Co,
           @_MoneyType AS Co_No,         --
           @_MoneyType AS OriginalNo_Co,
           @_MoneyType AS OriginalCo_No, --
           @_TINYINTType AS M_DocDate,
           @_INTType AS Y_DocDate,       --
           @_CodeType AS MESGroupCode,
           @_NameType AS MESGroupInfor,
           @_CodeType AS Type,
           @_CodeType AS Thang,          --
           @_CodeType AS ItemCode,
           @_NameType AS ItemName,
           @_CodeType AS ItemType,
           @_UnitType AS Unit,
           @_CodeType AS CustomerCode,
           @_NameType AS CustomerName,
           @_INTType AS ProductLevelId,
           @_INTType AS _Stt_Week
    INTO #CtTmpGeneralLedger
    FROM dbo.B00CtTmp AS vbgl;
    EXEC dbo.usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1,
                                          @_DocDate2 = @_DocDate2,
                                          @_Key1 = @_Key_Acc,
                                          @_Key2 = '',
                                          @_CtTmp = N'#CtTmpGeneralLedger',
                                          @_nUserId = @_nUserId,
                                          @_LangId = @_LangId,
                                          @_BranchCode = @_BranchCode,
                                          @_CurrencyCode0 = @_CurrencyCode0,
                                          @_PrintExec = 1;
    UPDATE #CtTmpGeneralLedger
    SET CustomerId = CustomerId0,
        Quantity = IIF(DocGroup = 2, Quantity, -Quantity);
    UPDATE #CtTmpGeneralLedger
    SET OriginalCreditAmount = OriginalAmount
    WHERE CreditAccount LIKE '511%';
    UPDATE #CtTmpGeneralLedger
    SET OriginalDebitAmount = -OriginalAmount
    WHERE DebitAccount LIKE '511%';
    UPDATE #CtTmpGeneralLedger
    SET OriginalNo_Co = OriginalDebitAmount - OriginalCreditAmount,
        OriginalCo_No = OriginalCreditAmount - OriginalDebitAmount;
    UPDATE #CtTmpGeneralLedger
    SET Type = 'ACTUAL',
        M_DocDate = MONTH(ge.DocDate),
        Y_DocDate = YEAR(ge.DocDate),
        No_Co = ge.DebitAmount - ge.CreditAmount,
        Co_No = ge.CreditAmount - ge.DebitAmount
    FROM #CtTmpGeneralLedger AS ge;
    UPDATE #CtTmpGeneralLedger
    SET Thang = cl.ColName
    FROM #CtTmpGeneralLedger AS ge
        INNER JOIN #ColList AS cl
            ON ge.M_DocDate = cl.Tt
               AND cl.Type = '0';
    SELECT @_Step = N' Bước 1: Lấy xong dữ liệu sổ cái.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                    @_DebugStepTime = @DebugStepTime OUTPUT;

									--SELECT * FROM #CtTmpGeneralLedger RETURN 
    -- ========================================================
    -- 3. THU THẬP DỮ LIỆU THỰC TẾ Thẻ kho (#CtTmp)
    -- ========================================================
    SET @_Key2 += N'EXISTS (SELECT 1 FROM #CtTmpGeneralLedger ctt WHERE ctt.RowId = #SFile_B30TheKho_GetData.RowId AND ctt.Stt = #SFile_B30TheKho_GetData.Stt)';
    DROP TABLE IF EXISTS #CtTmp;
    SELECT TOP (0)
           Stt,
           RowId,
           ItemId,
           @_QuantityType AS Quantity
    INTO #CtTmp
    FROM dbo.B00CtTmp;
    EXEC dbo.usp_B30StockLedger_GetData @_Date1 = @_DocDate1,
                                        @_Date2 = @_DocDate2,
                                        @_Key2 = @_Key2,
                                        @_CtTmp = N'#CtTmp',
                                        @_BranchCode = @_BranchCode,
                                        @_CurrencyCode0 = @_CurrencyCode0;
    UPDATE gl
    SET gl.ItemId = stock.ItemId
    FROM #CtTmpGeneralLedger AS gl
        INNER JOIN #CtTmp AS stock
            ON gl.Stt = stock.Stt
               AND gl.RowId = stock.RowId;
    SELECT @_Step = N' Bước 2: Lấy xong dữ liệu thẻ kho. Cập nhật ItemId từ (Thẻ kho).';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                    @_DebugStepTime = @DebugStepTime OUTPUT;
    -- ========================================================    
    -- 4. THU THẬP DỮ LIỆU KẾ HOẠCH (#FinPlan)
    -- ========================================================
    DROP TABLE IF EXISTS #FinPlan;
    SELECT TOP (0)
           DocDate,
           DocDate00,
           DocNo,
           CAST(NULL AS INT) AS Year,
           CAST(NULL AS INT) AS _Month,
           CustomerId,
           ItemId,
           ProfitCenterId,
           CurrencyCode,
           CAST(NULL AS TINYINT) AS ItemType,
           CAST(NULL AS INT) AS ProductId,
           @_MoneyType AS OriginalUnitCost,
           @_MoneyType AS Amount,
           @_QuantityType AS Quantity,
           @_QuantityType AS Quantity_W1,
           @_QuantityType AS Quantity_W2,
           @_QuantityType AS Quantity_W3,
           @_QuantityType AS Quantity_W4,
           @_QuantityType AS Quantity_W5,
           @_QuantityType AS Quantity_W6,
           @_MoneyType AS OriginalAmount,
           BranchCode,
           @_CodeType AS MESGroupCode, --
           @_CodeType AS Type,
           @_TINYINTType AS M_DocDate,
           @_INTType AS Y_DocDate,
           @_CodeType AS Thang,
           @_BizDocIdType AS BizDocId
    INTO #FinPlan
    FROM dbo.vB30FinPlanDetail_GetData;
    IF @_IsGetPlan = 1
        EXEC dbo.usp_FinPlanDetail_GetData @_DocDate1 = @_DocDate1,
                                           @_DocDate2 = @_DocDatePlan2,
                                           @_UsingDateKey = 1,
                                           @_CtTmp = '#FinPlan',
                                           @_BranchCode = @_BranchCode,
                                           @_PrintExec = 0;
    UPDATE fi
    SET fi.Type = 'PLAN',
        fi.M_DocDate = MONTH(fi.DocDate),
        fi.Y_DocDate = YEAR(fi.DocDate)
    FROM #FinPlan AS fi;
    UPDATE FI
    SET FI.Thang = cl.ColName
    FROM #FinPlan AS FI
        INNER JOIN #ColList AS cl
            ON FI.M_DocDate = cl.Tt
               AND cl.Type = '1';
    DELETE #FinPlan
    WHERE (DocDate00 < @_DocDate1);
    DROP TABLE IF EXISTS #FinPlan_ByWeek;
    SELECT fp.DocDate,
           fp.DocDate00,
           fp.DocNo,
           fp.Year,
           fp._Month,
           fp.CustomerId,
           fp.ItemId,
           fp.ProfitCenterId,
           fp.ItemType,
           fp.ProductId,
           fp.OriginalUnitCost,
           fp.Quantity_W1 AS Quantity,
           fp.Quantity_W1 * fp.OriginalUnitCost AS Amount,
           fp.BranchCode,
           fp.MESGroupCode,
           fp.Type,
           fp.M_DocDate,
           fp.Y_DocDate,
           fp.Thang,
           fp.BizDocId,
           '1' AS TypeQuantity
    INTO #FinPlan_ByWeek
    FROM #FinPlan AS fp
    WHERE fp.Quantity_W1 <> 0
          AND fp.OriginalUnitCost <> 0
    UNION
    SELECT fp.DocDate,
           fp.DocDate00,
           fp.DocNo,
           fp.Year,
           fp._Month,
           fp.CustomerId,
           fp.ItemId,
           fp.ProfitCenterId,
           fp.ItemType,
           fp.ProductId,
           fp.OriginalUnitCost,
           fp.Quantity_W2 AS Quantity,
           fp.Quantity_W2 * fp.OriginalUnitCost AS Amount,
           fp.BranchCode,
           fp.MESGroupCode,
           fp.Type,
           fp.M_DocDate,
           fp.Y_DocDate,
           fp.Thang,
           fp.BizDocId,
           '2' AS TypeQuantity
    FROM #FinPlan AS fp
    WHERE fp.Quantity_W2 <> 0
          AND fp.OriginalUnitCost <> 0
    UNION
    SELECT fp.DocDate,
           fp.DocDate00,
           fp.DocNo,
           fp.Year,
           fp._Month,
           fp.CustomerId,
           fp.ItemId,
           fp.ProfitCenterId,
           fp.ItemType,
           fp.ProductId,
           fp.OriginalUnitCost,
           fp.Quantity_W3 AS Quantity,
           fp.Quantity_W3 * fp.OriginalUnitCost AS Amount,
           fp.BranchCode,
           fp.MESGroupCode,
           fp.Type,
           fp.M_DocDate,
           fp.Y_DocDate,
           fp.Thang,
           fp.BizDocId,
           '3' AS TypeQuantity
    FROM #FinPlan AS fp
    WHERE fp.Quantity_W3 <> 0
          AND fp.OriginalUnitCost <> 0
    UNION
    SELECT fp.DocDate,
           fp.DocDate00,
           fp.DocNo,
           fp.Year,
           fp._Month,
           fp.CustomerId,
           fp.ItemId,
           fp.ProfitCenterId,
           fp.ItemType,
           fp.ProductId,
           fp.OriginalUnitCost,
           fp.Quantity_W4 AS Quantity,
           fp.Quantity_W4 * fp.OriginalUnitCost AS Amount,
           fp.BranchCode,
           fp.MESGroupCode,
           fp.Type,
           fp.M_DocDate,
           fp.Y_DocDate,
           fp.Thang,
           fp.BizDocId,
           '4' AS TypeQuantity
    FROM #FinPlan AS fp
    WHERE fp.Quantity_W4 <> 0
          AND fp.OriginalUnitCost <> 0
    UNION
    SELECT fp.DocDate,
           fp.DocDate00,
           fp.DocNo,
           fp.Year,
           fp._Month,
           fp.CustomerId,
           fp.ItemId,
           fp.ProfitCenterId,
           fp.ItemType,
           fp.ProductId,
           fp.OriginalUnitCost,
           fp.Quantity_W5 AS Quantity,
           fp.Quantity_W5 * fp.OriginalUnitCost AS Amount,
           fp.BranchCode,
           fp.MESGroupCode,
           fp.Type,
           fp.M_DocDate,
           fp.Y_DocDate,
           fp.Thang,
           fp.BizDocId,
           '5' AS TypeQuantity
    FROM #FinPlan AS fp
    WHERE fp.Quantity_W5 <> 0
          AND fp.OriginalUnitCost <> 0
    UNION
    SELECT fp.DocDate,
           fp.DocDate00,
           fp.DocNo,
           fp.Year,
           fp._Month,
           fp.CustomerId,
           fp.ItemId,
           fp.ProfitCenterId,
           fp.ItemType,
           fp.ProductId,
           fp.OriginalUnitCost,
           fp.Quantity_W6 AS Quantity,
           fp.Quantity_W6 * fp.OriginalUnitCost AS Amount,
           fp.BranchCode,
           fp.MESGroupCode,
           fp.Type,
           fp.M_DocDate,
           fp.Y_DocDate,
           fp.Thang,
           fp.BizDocId,
           '6' AS TypeQuantity
    FROM #FinPlan AS fp
    WHERE fp.Quantity_W6 <> 0
          AND fp.OriginalUnitCost <> 0;
    UPDATE #FinPlan_ByWeek
    SET Thang = tbl.ColName,
        DocDate00 = tbl.StartDate
    FROM #FinPlan_ByWeek AS t
        INNER JOIN
        (
            SELECT tbl.StartDate,
                   tbl.EndDate,
                   cl.ColName,
                   tbl._Month,
                   tbl.W_DocDate_Rep
            FROM @table AS tbl
                LEFT JOIN #ColList AS cl
                    ON tbl._Stt = cl.Tt
        ) AS tbl
            ON t._Month = tbl._Month
               AND t.TypeQuantity = tbl.W_DocDate_Rep;
    --xóa dữ liệu số dữ kiến trước ngày @_DocDate2
    DELETE #FinPlan_ByWeek
    WHERE (DocDate00 < @_DocDate2);
    --cập nhật cột tuần tháng thực hiện để pivot dữ liệu 
    UPDATE #CtTmpGeneralLedger
    SET Thang = tbl.ColName
    FROM #CtTmpGeneralLedger AS t
        INNER JOIN
        (
            SELECT tbl.StartDate,
                   tbl.EndDate,
                   cl.ColName
            FROM @table AS tbl
                INNER JOIN #ColList AS cl
                    ON tbl._Stt = cl.Tt
        ) AS tbl
            ON t.DocDate
               BETWEEN tbl.StartDate AND tbl.EndDate;
    INSERT INTO #CtTmpGeneralLedger
    (
        DocDate,
        CustomerId,
        MESGroupCode,
        ItemId,
        Thang,
        CurrencyCode,
        Co_No,
        Account,
        BranchCode,
        Type
    )
    SELECT DocDate00,
           CustomerId,
           MESGroupCode,
           ItemId,
           Thang,
           'VND',
           Amount,
           '511',
           BranchCode,
           Type
    FROM #FinPlan_ByWeek;
    IF @_Num_Round <> 1
        UPDATE #CtTmpGeneralLedger
        SET Co_No = Co_No / @_Num_Round;
    SELECT @_Step = N' Bước 3. Lấy xong dữ liệu kế hoạch (#FinPlan)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                    @_DebugStepTime = @DebugStepTime OUTPUT;
    -- ========================================================    
    -- 4. Update các trường Code,Name theo danh mục cho bảng #CtTmpGeneralLedger
    -- ========================================================	
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#CtTmpGeneralLedger',
                                             @_List_Cats = 'Customer',
                                             @_SetString_Other = ',kq.MESGroupCode = Customer.MESGroupCode';
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#CtTmpGeneralLedger',
                                             @_List_Cats = 'Item',
                                             @_SetString_Other = ',kq.Unit = Item.Unit';

    UPDATE #CtTmpGeneralLedger
    SET MESGroupInfor = CONCAT(MESGroupCode, ' : ', cl.Name)
    FROM #CtTmpGeneralLedger AS kq
        INNER JOIN b20class AS cl
            ON kq.MESGroupCode = cl.Code
               AND cl.parentcode = 'MESGroupCode'

    SELECT @_Step = N' Bước 4. Xong Update các trường Code,Name theo danh mục cho bảng #CtTmpGeneralLedger';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                    @_DebugStepTime = @DebugStepTime OUTPUT;
    -- ========================================================    
    -- 4. XỬ LÝ PIVOT BẢNG KẾT QUẢ (#kq_DoanhThu)
    -- ========================================================
    DECLARE @_BrowField NVARCHAR(MAX) = N'',
            @_query NVARCHAR(MAX) = N'',
            @_bang VARCHAR(256),
            @_agg_col VARCHAR(256),
            @_on_rows VARCHAR(256);
    DECLARE @_query_ColList NVARCHAR(MAX) = N' SELECT  ColName FROM #ColList  ';
    DECLARE @_on_cols_ColList NVARCHAR(MAX) = N'ColName';
    DECLARE @_ColName_Total NVARCHAR(128) =
            (
                SELECT TOP (1) ColName FROM #ColList WHERE Tt = 0 ORDER BY Tt ASC
            );
    SELECT @_query = N'SELECT * FROM #CtTmpGeneralLedger    ';
    SELECT @_agg_col = 'ISNULL(Co_No,0)',
           @_bang = '#kq_DoanhThu ',
           @_on_rows
               = 'BranchCode,CustomerId,CustomerCode,CustomerName,MESGroupCode,MESGroupInfor,ItemId,ItemCode,ITemName,Unit,CurrencyCode';
    DROP TABLE IF EXISTS #kq_DoanhThu;
    CREATE TABLE #kq_DoanhThu
    (
        Id INT,
        CustomerId INT,
        ItemId INT,
        Unit NVARCHAR(8),
        ItemCode VARCHAR(24),
        ItemName NVARCHAR(512),
        CustomerCode VARCHAR(24),
        CurrencyCode VARCHAR(24),
        BranchCode VARCHAR(3)
            DEFAULT '',
        CustomerName NVARCHAR(512),
        MESGroupCode VARCHAR(24),
        MESGroupName NVARCHAR(256),
        MESGroupInfor NVARCHAR(256),
        ParentId INT,
        IsGroup INT,
        IsPrint INT
            DEFAULT 1,
        --cột dựng cây
        Id_Tree INT IDENTITY,
        ParentId_Tree INT,
        IsGroup_Tree INT
            DEFAULT 0,
        --cột kế thừa từ bảng khai bao B10
        Id_Rep INT,
        ParentId_Rep INT,
        _GroupOrder NVARCHAR(128),
        --
        ItemNo VARCHAR(24),
        Formula NVARCHAR(MAX),
        ItemLevel INT
            DEFAULT 9
    );
    EXEC dbo.usp_pivot_KHTC @query_ColList = @_query_ColList,
                            @on_cols_ColList = @_on_cols_ColList,
                            @_ColName_Total = @_ColName_Total,
                            @query = @_query,
                            @on_rows = @_on_rows,
                            @on_cols = 'Thang',
                            @agg_func = 'SUM',
                            @agg_col = @_agg_col,
                            @bang = @_bang,
                            @brow_str = @_BrowField;

							--SELECT * FROM #kq_DoanhThu RETURN 

    SELECT @_Step = N' Bước 5. Xử lý xong dữ liệu bảng (#kq_DoanhThu)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                    @_DebugStepTime = @DebugStepTime OUTPUT;
    -- ========================================================    
    -- 4.1 XỬ LÝ PIVOT BẢNG KẾT QUẢ (#kq_DoanhThu_USD)  
    -- ========================================================
    SELECT @_query_ColList = N' SELECT  ColName FROM #ColList  ';
    SELECT @_on_cols_ColList = N'ColName';
    SELECT @_ColName_Total =
    (
        SELECT TOP (1) ColName FROM #ColList WHERE Tt = 0 ORDER BY Tt ASC
    );
    SELECT @_query = N'SELECT * FROM #CtTmpGeneralLedger WHERE CurrencyCode = ''USD''    ';
    SELECT @_agg_col = 'ISNULL(OriginalCo_No,0)',
           @_bang = ' #kq_DoanhThu_USD ',
           @_on_rows
               = 'BranchCode,CustomerId,CustomerCode,CustomerName,MESGroupCode,MESGroupInfor,ItemId,ItemCode,ITemName,Unit,CurrencyCode';
    DROP TABLE IF EXISTS #kq_DoanhThu_USD;
    CREATE TABLE #kq_DoanhThu_USD
    (
        Id INT,
        CustomerId INT,
        ItemId INT,
        Unit NVARCHAR(8),
        ItemCode VARCHAR(24),
        ItemName NVARCHAR(512),
        CustomerCode VARCHAR(24),
        CurrencyCode VARCHAR(24),
        BranchCode VARCHAR(3)
            DEFAULT '',
        CustomerName NVARCHAR(512),
        MESGroupCode VARCHAR(24),
        MESGroupName NVARCHAR(256),
        MESGroupInfor NVARCHAR(256),
        ParentId INT,
        IsGroup INT,
        IsPrint INT
            DEFAULT 1,
        --cột dựng cây
        Id_Tree INT IDENTITY,
        ParentId_Tree INT,
        IsGroup_Tree INT
            DEFAULT 0,
        Id_Rep INT,
        ParentId_Rep INT,
        _GroupOrder NVARCHAR(128),
        --
        ItemNo VARCHAR(24),
        Formula NVARCHAR(MAX),
        ItemLevel INT
            DEFAULT 9
    );
    EXEC dbo.usp_pivot_KHTC @query_ColList = @_query_ColList,
                            @on_cols_ColList = @_on_cols_ColList,
                            @_ColName_Total = @_ColName_Total,
                            @query = @_query,
                            @on_rows = @_on_rows,
                            @on_cols = 'Thang',
                            @agg_func = 'SUM',
                            @agg_col = @_agg_col,
                            @bang = @_bang,
                            @brow_str = @_BrowField;
    SELECT @_Step = N' Bước 5. Xử lý xong dữ liệu bảng (#kq_DoanhThu_USD)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                    @_DebugStepTime = @DebugStepTime OUTPUT;
									
    -- ========================================================    
    -- 4.1 XỬ LÝ PIVOT BẢNG KẾT QUẢ (#kq_DoanhThu_USD2)  
    -- ========================================================
    SELECT @_query_ColList = N' SELECT  ColName FROM #ColList  ';
    SELECT @_on_cols_ColList = N'ColName';
    SELECT @_ColName_Total =
    (
        SELECT TOP (1) ColName FROM #ColList WHERE Tt = 0 ORDER BY Tt ASC
    );
    SELECT @_query = N'SELECT * FROM #CtTmpGeneralLedger WHERE CurrencyCode = ''USD''    ';
    SELECT @_agg_col = 'ISNULL(Co_No,0)',
           @_bang = '#kq_DoanhThu_USD2 ',
           @_on_rows
               = 'BranchCode,CustomerId,CustomerCode,CustomerName,MESGroupCode,MESGroupInfor,ItemId,ItemCode,ITemName,Unit,CurrencyCode';
    DROP TABLE IF EXISTS #kq_DoanhThu_USD2;
    CREATE TABLE #kq_DoanhThu_USD2
    (
        Id INT,
        CustomerId INT,
        ItemId INT,
        Unit NVARCHAR(8),
        ItemCode VARCHAR(24),
        ItemName NVARCHAR(512),
        CustomerCode VARCHAR(24),
        CurrencyCode VARCHAR(24),
        BranchCode VARCHAR(3)
            DEFAULT '',
        CustomerName NVARCHAR(512),
        MESGroupCode VARCHAR(24),
        MESGroupName NVARCHAR(256),
        MESGroupInfor NVARCHAR(256),
        ParentId INT,
        IsGroup INT,
        IsPrint INT
            DEFAULT 1,
        --cột dựng cây
        Id_Tree INT IDENTITY,
        ParentId_Tree INT,
        IsGroup_Tree INT
            DEFAULT 0,
        Id_Rep INT,
        ParentId_Rep INT,
        _GroupOrder NVARCHAR(128),
        --
        ItemNo VARCHAR(24),
        Formula NVARCHAR(MAX),
        ItemLevel INT
            DEFAULT 9
    );
    EXEC dbo.usp_pivot_KHTC @query_ColList = @_query_ColList,
                            @on_cols_ColList = @_on_cols_ColList,
                            @_ColName_Total = @_ColName_Total,
                            @query = @_query,
                            @on_rows = @_on_rows,
                            @on_cols = 'Thang',
                            @agg_func = 'SUM',
                            @agg_col = @_agg_col,
                            @bang = @_bang,
                            @brow_str = @_BrowField;
    SELECT @_Step = N' Bước 5. Xử lý xong dữ liệu bảng (#kq_DoanhThu_USD2)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                    @_DebugStepTime = @DebugStepTime OUTPUT;
									--SELECT * FROM #kq_DoanhThu_USD2 RETURN 
    -- ========================================================    
    -- 7. XỬ LÝ dựng cây cho bảng (#kq_DoanhThu)
    -- ========================================================		
    BEGIN
        DECLARE @tabl TABLE
        (
            Id_Tree INT,
            ParentId_Tree INT,
            IsGroup_Tree INT,
            --rep
            Id_Rep INT,
            ParentId_Rep INT,
            ItemNo VARCHAR(128)
                DEFAULT '',
            BranchCode VARCHAR(3)
        );
        INSERT INTO #kq_DoanhThu
        (
            IsGroup,
            ParentId_Tree,
            IsGroup_Tree,
            Id_Rep,
            ParentId_Rep,
            ItemName,
            CurrencyCode,
            IsPrint,
            ItemNo,
            Formula,
            ItemLevel,
            BranchCode
        )
        OUTPUT Inserted.Id_Tree,
               Inserted.ParentId_Tree,
               Inserted.IsGroup_Tree,
               Inserted.Id_Rep,
               Inserted.ParentId_Rep,
               Inserted.ItemNo,
               Inserted.BranchCode
        INTO @tabl
        (
            Id_Tree,
            ParentId_Tree,
            IsGroup_Tree,
            Id_Rep,
            ParentId_Rep,
            ItemNo,
            BranchCode
        )
        SELECT 1,
               -1,
               1,
               t.Id AS Id_Rep,
               t.ParentId AS ParentId_Rep,
               t.Description,
               IIF(t.VarValue_Exclude <> 'VND', 'VND', 'USD'),
               IsPrint,
               t.ItemNo,
               Formula,
               ItemLevel,
               t.BranchCode
        FROM #tblTmp1 AS t
        ORDER BY t.BuiltinOrder ASC;

        UPDATE #kq_DoanhThu
        SET ParentId_Tree = t.Id_Tree
        FROM #kq_DoanhThu AS k
            INNER JOIN @tabl AS t
                ON k.ParentId_Rep = t.Id_Rep
        WHERE IsGroup = 1;

        UPDATE ctt
        SET ctt.ParentId_Tree = IIF(ISNULL(ctt.ParentId_Tree, 0) <> -1, tblcus.Id_Tree, ctt.ParentId_Tree)
        FROM #kq_DoanhThu AS ctt
            INNER JOIN
            (
                SELECT c.Id_Tree,
                       t.VarKey,
                       t.VarValue, --
                       t.VarKey_Exclude,
                       t.VarValue_Exclude
                FROM #tblTmp1 AS t
                    INNER JOIN @tabl AS c
                        ON c.Id_Rep IS NOT NULL
                           AND t.Id = c.Id_Rep
                           AND t.VarKey = 'MESGroupCode'
            ) AS tblcus
                ON tblcus.VarKey = 'MESGroupCode'
                   AND PATINDEX('%,' + TRIM(STR(ctt.MESGroupCode)) + ',%', ',' + tblcus.VarValue + ',') <> 0;

        EXEC dbo.usp_sys_Update_GroupOrder @_TableName = '#kq_DoanhThu',
                                           @_PrintExec = 0;

        SELECT @_Step = N' Bước 7. Xử lý dựng cây cho bảng (#kq_DoanhThu)';

        EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                        @_DebugStepTime = @DebugStepTime OUTPUT;


        UPDATE #kq_DoanhThu
        SET Id = Id_Tree,
            ParentId = ParentId_Tree;
    END;
    -- ========================================================    
    -- 7.1 XỬ LÝ dựng cây cho bảng (#kq_DoanhThu_USD)
    -- ========================================================		
    BEGIN
        DECLARE @tabl2 TABLE
        (
            Id_Tree INT,
            ParentId_Tree INT,
            IsGroup_Tree INT,
            Id_Rep INT,
            ParentId_Rep INT,
            ItemNo VARCHAR(128)
                DEFAULT '',
            BranchCode VARCHAR(3)
        );
        INSERT INTO #kq_DoanhThu_USD
        (
            IsGroup,
            ParentId_Tree,
            IsGroup_Tree,
            Id_Rep,
            ParentId_Rep,
            ItemName,
            CurrencyCode,
            IsPrint,
            ItemNo,
            Formula,
            ItemLevel,
            BranchCode
        )
        OUTPUT Inserted.Id_Tree,
               Inserted.ParentId_Tree,
               Inserted.IsGroup_Tree,
               Inserted.Id_Rep,
               Inserted.ParentId_Rep,
               Inserted.ItemNo,
               Inserted.BranchCode
        INTO @tabl2
        (
            Id_Tree,
            ParentId_Tree,
            IsGroup_Tree,
            Id_Rep,
            ParentId_Rep,
            ItemNo,
            BranchCode
        )
        SELECT 1,
               -1,
               1,
               t.Id AS Id_Rep,
               ParentId AS ParentId_Rep,
               t.Description,
               t.VarValue_Exclude,
               t.IsPrint,
               t.ItemNo,
               Formula,
               t.ItemLevel,
               t.BranchCode
        FROM #tblTmp2 AS t
        ORDER BY t.BuiltinOrder ASC;
        UPDATE #kq_DoanhThu_USD
        SET ParentId_Tree = t.Id_Tree
        FROM #kq_DoanhThu_USD AS k
            INNER JOIN @tabl2 AS t
                ON k.ParentId_Rep = t.Id_Rep
        WHERE IsGroup = 1;
        UPDATE ctt
        SET ctt.ParentId_Tree = IIF(ISNULL(ctt.ParentId_Tree, 0) <> -1, tblcus.Id_Tree, ctt.ParentId_Tree)
        FROM #kq_DoanhThu_USD AS ctt
            INNER JOIN
            (
                SELECT c.Id_Tree,
                       t.VarKey,
                       t.VarValue, --
                       t.VarKey_Exclude,
                       t.VarValue_Exclude
                FROM #tblTmp2 AS t
                    INNER JOIN @tabl2 AS c
                        ON c.Id_Rep IS NOT NULL
                           AND t.Id = c.Id_Rep
                           AND t.VarKey = 'MESGroupCode'
            ) AS tblcus
                ON tblcus.VarKey = 'MESGroupCode'
                   AND PATINDEX('%,' + TRIM(STR(ctt.MESGroupCode)) + ',%', ',' + tblcus.VarValue + ',') <> 0;
        EXEC dbo.usp_sys_Update_GroupOrder @_TableName = '#kq_DoanhThu_USD',
                                           @_PrintExec = 0;
        SELECT @_Step = N' Bước 7. Xử lý dựng cây cho bảng (#kq_DoanhThu_USD)';
        EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                        @_DebugStepTime = @DebugStepTime OUTPUT;
        UPDATE #kq_DoanhThu_USD
        SET Id = Id_Tree;
    END;

    -- ========================================================    
    -- 7.2 XỬ LÝ dựng cây cho bảng (#kq_DoanhThu_USD)
    -- ========================================================		
    BEGIN
        DECLARE @tabl3 TABLE
        (
            Id_Tree INT,
            ParentId_Tree INT,
            IsGroup_Tree INT,
            Id_Rep INT,
            ParentId_Rep INT,
            ItemNo VARCHAR(128)
                DEFAULT '',
            BranchCode VARCHAR(3)
        );
        INSERT INTO #kq_DoanhThu_USD2
        (
            IsGroup,
            ParentId_Tree,
            IsGroup_Tree,
            Id_Rep,
            ParentId_Rep,
            ItemName,
            CurrencyCode,
            IsPrint,
            ItemNo,
            Formula,
            ItemLevel,
            BranchCode
        )
        OUTPUT Inserted.Id_Tree,
               Inserted.ParentId_Tree,
               Inserted.IsGroup_Tree,
               Inserted.Id_Rep,
               Inserted.ParentId_Rep,
               Inserted.ItemNo,
               Inserted.BranchCode
        INTO @tabl3
        (
            Id_Tree,
            ParentId_Tree,
            IsGroup_Tree,
            Id_Rep,
            ParentId_Rep,
            ItemNo,
            BranchCode
        )
        SELECT 1,
               -1,
               1,
               t.Id AS Id_Rep,
               ParentId AS ParentId_Rep,
               t.Description,
               t.VarValue_Exclude,
               t.IsPrint,
               t.ItemNo,
               Formula,
               t.ItemLevel,
               t.BranchCode
        FROM #tblTmp2 AS t
        ORDER BY t.BuiltinOrder ASC;
        UPDATE #kq_DoanhThu_USD2
        SET ParentId_Tree = t.Id_Tree
        FROM #kq_DoanhThu_USD2 AS k
            INNER JOIN @tabl3 AS t
                ON k.ParentId_Rep = t.Id_Rep
        WHERE IsGroup = 1;
        UPDATE ctt
        SET ctt.ParentId_Tree = IIF(ISNULL(ctt.ParentId_Tree, 0) <> -1, tblcus.Id_Tree, ctt.ParentId_Tree)
        FROM #kq_DoanhThu_USD2 AS ctt
            INNER JOIN
            (
                SELECT c.Id_Tree,
                       t.VarKey,
                       t.VarValue, --
                       t.VarKey_Exclude,
                       t.VarValue_Exclude
                FROM #tblTmp2 AS t
                    INNER JOIN @tabl3 AS c
                        ON c.Id_Rep IS NOT NULL
                           AND t.Id = c.Id_Rep
                           AND t.VarKey = 'MESGroupCode'
            ) AS tblcus
                ON tblcus.VarKey = 'MESGroupCode'
                   AND PATINDEX('%,' + TRIM(STR(ctt.MESGroupCode)) + ',%', ',' + tblcus.VarValue + ',') <> 0;
        EXEC dbo.usp_sys_Update_GroupOrder @_TableName = '#kq_DoanhThu_USD2',
                                           @_PrintExec = 0;
        SELECT @_Step = N' Bước 7. Xử lý dựng cây cho bảng (#kq_DoanhThu_USD)';
        EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step,
                                        @_DebugStepTime = @DebugStepTime OUTPUT;
        UPDATE #kq_DoanhThu_USD
        SET Id = Id_Tree;
    END;

    SET @_LAYOUT_XML = '';
    SELECT @_LAYOUT_XML
        = @_LAYOUT_XML + @_nl + N'<' + ISNULL(ColName, '') + '>' + @_nl + N'	<Width>' + ISNULL(_Width, '')
          + '</Width> ' + @_nl + N'	<Rows> ' + @_nl + N'		<Row_0> ' + @_nl + N'			<Text> ' + @_nl
          + N'				<Vietnamese>'   + ISNULL(Row_0_VN, '') + '</Vietnamese> ' + @_nl + N'				<English>'
          + ISNULL(Row_0_EN, '') + '</English> ' + @_nl + N'			</Text> ' + @_nl + N'			<Style>UserData:'
          + ISNULL(UserData0, '') + ';</Style> ' + @_nl + N'		</Row_0> ' + @_nl + N'		<Row_1> ' + @_nl
          + N'			<Text> '  + @_nl + N'				<Vietnamese>'  + ISNULL(Row_1_VN, '') + '</Vietnamese> '
          + @_nl + N'				<English>' + ISNULL(Row_1_EN, '') + '</English> ' + @_nl + N'			</Text> '
          + @_nl + N'			<Style>UserData:' + ISNULL(UserData1, '') + ';WordWrap:True;</Style> ' + @_nl
          + N'		</Row_1> ' + @_nl + N'		<Row_2> ' + @_nl + N'			<Text> ' + @_nl + N'				<Vietnamese>'
          + ISNULL(Row_2_VN, '') + '</Vietnamese> ' + @_nl + N'				<English>' + ISNULL(Row_2_EN, '')
          + '</English> ' + @_nl + N'			</Text> ' + @_nl + N'			<Style>UserData:'
          + ISNULL(UserData2, '') + ';WordWrap:True;</Style> ' + @_nl + N'		</Row_2> ' + @_nl + N'	</Rows> '
          + @_nl + N'</' + ISNULL(ColName, '') + '>' + @_nl
    FROM #ColList
    ORDER BY Y_DocDate,
             Tt,
             Type;
    DECLARE @_LAYOUT_XML2 NVARCHAR(MAX) = (@_LAYOUT_XML);
    DECLARE @_LAYOUT_XML3 NVARCHAR(MAX) = (@_LAYOUT_XML);
    SELECT @_LAYOUT_XML
        = N'		<Report_0> ' + @_nl + N'			<Content> ' + @_nl + N'				<Cols> ' + @_nl + N'			'
          + @_LAYOUT_XML + @_nl + N'				</Cols> ' + @_nl + N'			</Content> ' + @_nl
          + N'		</Report_0> '   + @_nl;
    SELECT @_LAYOUT_XML2
        = N'		<Report_1> ' + @_nl + N'			<Content> ' + @_nl + N'				<Cols> ' + @_nl + N'			'
          + @_LAYOUT_XML2 + @_nl + N'				</Cols> ' + @_nl + N'			</Content> ' + @_nl
          + N'		</Report_1> '   + @_nl;
    SELECT @_LAYOUT_XML3
        = N'		<Report_2> ' + @_nl + N'			<Content> ' + @_nl + N'				<Cols> ' + @_nl + N'			'
          + @_LAYOUT_XML3 + @_nl + N'				</Cols> ' + @_nl + N'			</Content> ' + @_nl
          + N'		</Report_2> '   + @_nl;
    SELECT @_LAYOUT_XML
        = N'<panelReporter>' + @_nl + N'   <Controls> ' + @_nl + @_LAYOUT_XML + @_LAYOUT_XML2 + @_LAYOUT_XML3
          + N'   </Controls> ' + @_nl + N'</panelReporter>' + @_nl;
    DECLARE @_CalSum VARCHAR(MAX) = '';
    SELECT *,
           IIF(IsGroup_Tree = 1, 'Subtotal0', '') AS _FormatStyleKey
    FROM #kq_DoanhThu
    ORDER BY _GroupOrder ASC;
    SELECT *,
           IIF(IsGroup_Tree = 1, 'Subtotal0', '') AS _FormatStyleKey
    FROM #kq_DoanhThu_USD
    ORDER BY _GroupOrder ASC;

    SELECT *,
           IIF(IsGroup_Tree = 1, 'Subtotal0', '') AS _FormatStyleKey
    FROM #kq_DoanhThu_USD2
    ORDER BY _GroupOrder ASC;

    ALTER TABLE #FinPlan_ByWeek
    ADD CustomerCode VARCHAR(24),
        CustomerName NVARCHAR(256),
        MESGroupInfo NVARCHAR(256);
    ALTER TABLE #FinPlan_ByWeek
    ADD ItemCode VARCHAR(24),
        ItemName NVARCHAR(256),
        Unit NVARCHAR(24);
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#FinPlan_ByWeek',
                                             @_List_Cats = 'Customer',
                                             @_SetString_Other = ',kq.MESGroupCode = Customer.MESGroupCode';
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#FinPlan_ByWeek',
                                             @_List_Cats = 'Item',
                                             @_SetString_Other = ',kq.Unit = Item.Unit';
    UPDATE #FinPlan_ByWeek
    SET MESGroupInfo = CONCAT(bw.MESGroupCode, ' : ', cl.Name)
    FROM #FinPlan_ByWeek AS bw
        INNER JOIN B10THACOID_Data.dbo.B20Class AS cl
            ON bw.MESGroupCode = cl.Code
               AND cl.ParentCode = 'MESGroupCode';
    SELECT *
    FROM #FinPlan_ByWeek AS fpbw
    ORDER BY fpbw.DocDate00,
             CustomerCode ASC,
             ItemCode ASC;
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, GETDATE())));
    SET @_DebugMsg
        = N'--- TỔNG THỜI GIAN CHẠY SP: ' + CAST(DATEDIFF(ms, @_Time1, GETDATE()) AS VARCHAR) + N' ms ---' + @_nl
          + N'--- TỔNG THỜI GIAN CHẠY SP: ' + CAST(DATEDIFF(ss, @_Time1, GETDATE()) AS VARCHAR) + N' ss ---';
    DROP TABLE IF EXISTS #FinPlan,
                         #ColList,
                         #CtTmp,
                         #CtTmpGeneralLedger,
                         #FinPlan_ByWeek,
                         #kq_DoanhThu,
                         #tblTmp1,
                         #kq_DoanhThu_USD;
END;
GO


SET DATEFORMAT DMY
EXEC usp_REP_Tinh_FinancePlan_ByWeek_Final_test @_DocDate1 = '01/08/2026 00:00:00.000',
                                           @_DocDate2 = '27/08/2026 00:00:00.000',
                                           @_DocDatePlan2 = '30/09/2026 00:00:00.000',
                                           @_Account = '511',
                                           @_ExcludeCrspAccount = '911,3332,333301,33381',
                                           @_CrspAccount = '',
                                           @_BranchCode = 'I24',
                                           @_nUserId = 1213,
                                           @_LangId = 0,
                                           @_CurrencyCode0 = 'VND',
                                           @_IsRound = 0,
                                           @_RepId1 = 'I020000005',
                                           @_RepId2 = 'I240000067',
                                           @_StrTime = '00:00:00',
                                           @_IsGetPlan = 0