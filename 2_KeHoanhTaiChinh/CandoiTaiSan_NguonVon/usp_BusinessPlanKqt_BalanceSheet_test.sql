SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*BusinessPlan*/
-- Coder: ThangDQ
-- ============================================
-- Description: Bảng cân đối Kế toán (KHTC)
-- ============================================
CREATE OR ALTER PROCEDURE dbo.usp_BusinessPlanKqt_BalanceSheet_test
    @_DocDate1 DATE = '20240101'
  , @_DocDate2 DATE = '20240831'
  , @_Ngay_Dau_Nam DATE = NULL OUTPUT
  , @_Mau_Bc VARCHAR(24) = N''
  , @_ForeignCurrencyOnly SMALLINT = 1
  , @_nUserId AS INT = 0
  , @_LangId INT = 0
  , @_BranchCode VARCHAR(3) = 'A01'
  , @_RepId1 VARCHAR(16) = 'T000000001'
  , @_CurrencyCode0 CHAR(3) = N'VND'
  , @_Kd_Cp_Tam NCHAR(1) = N'K'
  , @_GetIsOutsideAccount TINYINT = 0
  , @_DefinitionTableName VARCHAR(32) = 'B10BusinessPlanKqt01'
  , @_ItemNo NVARCHAR(3) = ''
  , @_TableValue NVARCHAR(MAX) = '' OUTPUT
  , @_TableValueInput NVARCHAR(MAX) = ''
  , @_HTKK_Exp TINYINT = 0               -- 1: Tạo, 0: Không tạo; Hỗ trợ kê khai thuế
  , @_File_XML NVARCHAR(MAX) = '' OUTPUT -- Chuỗi XML kết xuất 
  , @_Filename_XML NVARCHAR(254) = N'' OUTPUT
  , @_WarningUnbalance NVARCHAR(254) = NULL OUTPUT
  , @_IssuedByNo NVARCHAR(32) = ''
  , @_ExchangeRateConvReport TINYINT = 0 -- 1: Báo cáo chuyển đổi sang đồng tiền VNĐ
  , @_LAYOUT_XML NVARCHAR(MAX) = '' OUTPUT
  , @_tblOutput NVARCHAR(64) = ''
--WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    -- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
    SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode)
    SELECT @_WarningUnbalance = NULL
         , @_BranchCode       = RTRIM(@_BranchCode);

    -- Ngày bắt đầu năm tài chính
    SET @_Ngay_Dau_Nam = dbo.ufn_sys_GetOpenDateOfFinanceYear(@_DocDate2, @_BranchCode)

    DECLARE @_FiscalYear                VARCHAR(24) = dbo.ufn_B00FiscalYear_GetName(@_DocDate2, @_BranchCode)
          , @_Xml                       XML
          , @_CommandKey_TongHopTk      NVARCHAR(256)
          , @_CommandKey_ChiTieuTongHop NVARCHAR(MAX)
          , @_CommandKey_BangCanDoiPS   NVARCHAR(256)
          , @_CommandKey_BCDTK_TCTK     NVARCHAR(256)
    DECLARE @_nl CHAR(1) = CHAR(13);
    DECLARE @_Sep NVARCHAR(5) = ',' + @_nl;

    SET @_CommandKey_BangCanDoiPS
        = N'REP07_KCD_CDTK DocDate1=''' + CAST(@_DocDate1 AS VARCHAR(11))
          + ''';DocDate2=''{=@_DocDate2}'';Account=''{=Account}'';'
    SET @_CommandKey_TongHopTk
        = N'REP09_KTH_THPSTK DocDate1=''' + CAST(@_DocDate1 AS VARCHAR(11))
          + ''';DocDate2=''{=@_DocDate2}'';Account=''{=Account}'';'
    SET @_CommandKey_BCDTK_TCTK
        = N'REP13_BCDTK_TCTK DocDate1=''' + CAST(@_DocDate1 AS VARCHAR(11))
          + ''';DocDate2=''{=@_DocDate2}'';Account=''{=Account}'';'

    -- Sửa riêng TT200/2014/TT-BTC
    IF @_IssuedByNo = '200/2014/TT-BTC'
    BEGIN
        SET @_CommandKey_BangCanDoiPS
            = N'REP07_KCD_CDTK DocDate1=''' + CAST(@_DocDate1 AS VARCHAR(11))
              + ''';DocDate2=''{=@_DocDate2}'';Account=''{=Account}'';LongTermAccount={=ISNULL(LongTermAccount,0)};'
        SET @_CommandKey_TongHopTk
            = N'REP09_KTH_THPSTK DocDate1=''' + CAST(@_DocDate1 AS VARCHAR(11))
              + ''';DocDate2=''{=@_DocDate2}'';Account=''{=Account}'';LongTermAccount={=ISNULL(LongTermAccount,0)};'

        IF @_Mau_Bc = ''
        BEGIN
            SET @_CommandKey_ChiTieuTongHop
                = N'REP07_BCDKT200 DocDate1=''{=@_DocDate1}'';DocDate2=''{=@_DocDate2}'';ItemNo=''{=ItemNo}'';IssuedByNo='''
                  + @_IssuedByNo + ''';DefinitionTableName=''' + @_DefinitionTableName + ''';'
                  + N'TableValueInput={=@_TableValue};'

            IF @_ExchangeRateConvReport = 1
                SET @_CommandKey_ChiTieuTongHop
                    = N'REP07_VND_BS DocDate2=''{=@_DocDate2}'';ItemNo=''{=ItemNo}'';IssuedByNo=''' + @_IssuedByNo
                      + ''';DefinitionTableName=''' + @_DefinitionTableName + ''';'
                      + N'TableValueInput={=@_TableValue};ExchangeRateConvReport={=ISNULL(@_ExchangeRateConvReport,0)};'
        END
        ELSE
            SET @_CommandKey_ChiTieuTongHop
                = N'REP07_BCDKT200_TL DocDate2=''{=@_DocDate2}'';ItemNo=''{=ItemNo}'';IssuedByNo=''' + @_IssuedByNo
                  + ''';DefinitionTableName=''' + @_DefinitionTableName + ''';' + N'TableValueInput={=@_TableValue};'
    END
    ELSE
    BEGIN
        IF @_Mau_Bc = ''
        BEGIN
            SET @_CommandKey_ChiTieuTongHop
                = N'REP07_BCDKT200 DocDate2=''{=@_DocDate2}'';ItemNo=''{=ItemNo}'';TableValueInput={=@_TableValue};'

            IF @_ExchangeRateConvReport = 1
                SET @_CommandKey_ChiTieuTongHop
                    = N'REP07_VND_BS DocDate2=''{=@_DocDate2}'';ItemNo=''{=ItemNo}'';TableValueInput={=@_TableValue};ExchangeRateConvReport={=ISNULL(@_ExchangeRateConvReport,0)};'
        END
        ELSE
            SET @_CommandKey_ChiTieuTongHop
                = N'REP07_BCDKT200_TL DocDate2=''{=@_DocDate2}'';Mau_Bc=''' + @_Mau_Bc + ''';ItemNo=''{=ItemNo}'';'
                  + N'TableValueInput={=@_TableValue};IssuedByNo=''' + @_IssuedByNo + ''';'
    END

    IF @_DefinitionTableName = 'B10Kqt01IFRS'
        SELECT @_CommandKey_ChiTieuTongHop = REPLACE(@_CommandKey_ChiTieuTongHop, 'REP07_BCDKT200', 'REP07_IFRS_BCDKT')

    -- Tạo bảng temp từ @_DefinitionTableName
    DROP TABLE IF EXISTS #TKTStmp
    CREATE TABLE #TKTStmp
    (
        Id INT
            DEFAULT 0
      , LongTermAccount TINYINT
      , VNDCloseAmount NUMERIC(20, 2)
      , VNDOpenFiscalYearAmount NUMERIC(20, 2)
      , VNDOpenAmount NUMERIC(20, 2)
      , ThisExchangeRate NUMERIC(20, 6)
      , PrevExchangeRate NUMERIC(20, 6)
      , ExchangeRateConvCode VARCHAR(24)
      , DataType VARCHAR(24)
	  ,MESGroupCode_Lst NVARCHAR(256)
    )

    EXECUTE usp_sys_CreateTable '#TKTStmp', @_DefinitionTableName
 
    DECLARE @_KeyHeader VARCHAR(MAX) = N' Stt = ''' + @_RepId1 + N''' ';
 
    EXECUTE usp_sys_Append @_TableSource= @_DefinitionTableName
                         , @_TableDestination='#TKTStmp'
                         , @_Where_TableSource = @_KeyHeader
						 , @_Print_Exec = 1

    IF @_LangId <> 0
    BEGIN
        DECLARE @_strExec NVARCHAR(MAX)
        SET @_strExec
            = 'UPDATE #TKTStmp SET Description = Description_' + dbo.ufn_sys_MessageText('Language', @_LangId)
        EXECUTE (@_strExec)
    END
	  
    -- Tạo bảng dữ liệu ghi nhận chuyển đổi 
    IF @_ExchangeRateConvReport = 1
    BEGIN
        DROP TABLE IF EXISTS #ExchangeRateConv_CtTmp;

        SELECT TOP 0
               CAST(0 AS TINYINT)        AS IsOpenning
             , DocDate
             , Account
             , CustomerId
             , ProductId
             , DebitAmount
             , CreditAmount
             , DebitAmount               AS VNDDebitAmount
             , CreditAmount              AS VNDCreditAmount
             , CAST(NULL AS INT)         AS ExchangeRateConvId
             , CAST(0 AS NUMERIC(20, 6)) AS ExchangeRate
        INTO #ExchangeRateConv_CtTmp
        FROM B00CtTmp
    END

    DROP TABLE IF EXISTS #ColList;
    SELECT TOP (0)
           Tt
         , M_DocDate1
         , M_DocDate2
         , Y_DocDate
         , ColName
         , UserData0
         , Row_0_VN
         , Row_0_EN
         , UserData1
         , Row_1_VN
         , Row_1_EN
         , _TextAlign
         , _Width
         , _Format
         , _ForeColor
         , _BackColor
         , Type
         , BuiltinOrder1
    INTO #ColList
    FROM dbo.B00ColList;
    INSERT INTO #ColList
    EXEC dbo.usp_GenerateReportHeader_ActualPlan_Final @_DocDate1 = @_DocDate1
                                                     , @_DocDate2 = @_DocDate2
                                                     , @_LAYOUT_XML = @_LAYOUT_XML OUTPUT
                                                     , @_IsGetPlan = 0
 
	UPDATE #ColList SET _Width = 0 WHERE Type = 3
	UPDATE #ColList SET _Width = 0 WHERE Type = 2
	UPDATE #ColList SET _Format = 'N0'
 
    ALTER TABLE #ColList ADD DocDate1 DATE
    ALTER TABLE #ColList ADD DocDate2 DATE
    ALTER TABLE #ColList ADD _Check TINYINT DEFAULT 0

    UPDATE #ColList
    SET DocDate1 = DATEFROMPARTS(Y_DocDate, M_DocDate1, '01')
    UPDATE #ColList
    SET DocDate2 = EOMONTH((DocDate1))
    WHERE Type = 0
          AND Tt <> 0

    DECLARE @_DocDateProcessData1 DATE
    DECLARE @_DocDateProcessData2 DATE
    DECLARE @_ColName NVARCHAR(24) = ''
    DECLARE @_TT INT

    -- Thêm cột động cho #tblTmp
    DECLARE @_AlterCols NVARCHAR(MAX) = N'';
    SELECT @_AlterCols = STRING_AGG(QUOTENAME(ColName) + ' NUMERIC(18,2) DEFAULT 0', ',')
    FROM #ColList;
    DECLARE @_SqlAlter NVARCHAR(MAX) = N'ALTER TABLE #TKTStmp ADD ' + @_AlterCols + ';';
    EXEC sp_executesql @_SqlAlter;

    --13-05-2026 bổ sung đk chỉ chạy lấy dữ liệu cuối kỳ cho các cột dữ liệu số thực tế 
    --Type = 0 AND  (DocDate1 IS NOT NULL  AND DocDate2 IS NOT NULL)
    --SELECT * FROM #ColList WHERE Type = 0 AND  (DocDate1 IS NOT NULL  AND DocDate2 IS NOT NULL) 
    IF ISNULL(@_ItemNo, '') = ''
    BEGIN
        WHILE EXISTS
    (
        SELECT *
        FROM #ColList
        WHERE Type = 0
              AND
              (
                  DocDate1 IS NOT NULL
                  AND DocDate2 IS NOT NULL
              )
              AND ISNULL(_Check, 0) = 0
    )
        BEGIN

            SELECT TOP (1)
                   @_DocDateProcessData1 = DocDate1
                 , @_DocDateProcessData2 = DocDate2
                 , @_ColName             = ColName
                 , @_TT                  = Tt
            FROM #ColList
            WHERE Type = 0
                  AND
                  (
                      DocDate1 IS NOT NULL
                      AND DocDate2 IS NOT NULL
                  )
                  AND ISNULL(_Check, 0) = 0
            ORDER BY Tt ASC

            EXECUTE dbo.usp_Kqt_BalanceSheet_ProcessData_KHTC_test @_DocDate1 = @_DocDateProcessData1
                                                            , @_DocDate2 = @_DocDateProcessData2
                                                            , @_FirstDayOfYear = @_Ngay_Dau_Nam
                                                            , @_tblTKTStmp = N'#TKTStmp'
                                                            , @_ForeignCurrencyOnly = @_ForeignCurrencyOnly
                                                            , @_LangId = @_LangId
                                                            , @_nUserId = @_nUserId
                                                            , @_BranchCode = @_BranchCode
                                                            , @_CurrencyCode0 = @_CurrencyCode0
                                                            , @_Kd_Cp_Tam = @_Kd_Cp_Tam
                                                            , @_IssuedByNo = @_IssuedByNo
                                                            , @_GetIsOutsideAccount = @_GetIsOutsideAccount
                                                            , @_ExchangeRateConvReport = @_ExchangeRateConvReport
                                                            , @_ColName = @_ColName

            UPDATE #ColList
            SET _Check = 1
            WHERE Tt = @_TT
        END
		 
        --13-05-2026 Bổ sung thêm đoạn tính cột Total
        SELECT @_strExec = '
		UPDATE #TKTStmp
		SET ' +
        (
            SELECT QUOTENAME(cl.ColName)FROM #ColList AS cl WHERE cl.Tt = 0
        )                  + ' = ' +
        (
            SELECT STRING_AGG(CONCAT('ISNULL(', QUOTENAME(cl.ColName), ',0)'), '+')
            FROM #ColList AS cl
            WHERE Tt <> 0
        )                  + ' '
        EXEC (@_strExec)

        -- Cảnh báo khi bảng cân đối không cân
        DECLARE @_CloseAmountAssets             NUMERIC(20, 2)
              , @_CloseAmountEquity             NUMERIC(20, 2)
              , @_OpenFiscalYearAmountAssets    NUMERIC(20, 2)
              , @_OpenFiscalYearAmountEquity    NUMERIC(20, 2)
              , @_VNDCloseAmountAssets          NUMERIC(20, 2)
              , @_VNDCloseAmountEquity          NUMERIC(20, 2)
              , @_VNDOpenFiscalYearAmountAssets NUMERIC(20, 2)
              , @_VNDOpenFiscalYearAmountEquity NUMERIC(20, 2)

        SELECT @_CloseAmountAssets             = CloseAmount
             , @_OpenFiscalYearAmountAssets    = OpenFiscalYearAmount
             , @_VNDCloseAmountAssets          = VNDCloseAmount
             , @_VNDOpenFiscalYearAmountAssets = VNDOpenFiscalYearAmount
        FROM #TKTStmp
        WHERE Account = 'TONGTS';

        SELECT @_CloseAmountEquity             = CloseAmount
             , @_OpenFiscalYearAmountEquity    = OpenFiscalYearAmount
             , @_VNDCloseAmountEquity          = VNDCloseAmount
             , @_VNDOpenFiscalYearAmountEquity = VNDOpenFiscalYearAmount
        FROM #TKTStmp
        WHERE Account = 'TONGNV';

 
    END

    IF @_ExchangeRateConvReport = 1
    BEGIN
        -- Đưa các TK theo dõi tính chất vào theo dõi riêng ở báo cáo Bảng cân đối tài khoản theo tính chất ngắn/dài hạn
        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_BCDTK_TCTK
                           + IIF(ISNULL(ThisExchangeRate, 0) <> 0
                               , N'ExchangeRateConvertDesc='''
                                 + dbo.ufn_sys_MessageText(N'ExchangeRateConvert', @_LangId) + ' (' + conv.Code + '): '
                                 + FORMAT(ThisExchangeRate, 'N6') + ''';'
                               , '')
        FROM #TKTStmp                          AS tb
            INNER JOIN dbo.B20ExchangeRateConv AS conv
                ON tb.ExchangeRateConvId = conv.Id
        WHERE ItemLevel = 9
              AND tb.LongTermAccount IS NOT NULL

        -- Thay việc đưa vào công nợ ==> chuyển thành bảng cân đối phát sinh
        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_BangCanDoiPS
                           + IIF(ISNULL(ThisExchangeRate, 0) <> 0
                               , N'ExchangeRateConvertDesc='''
                                 + dbo.ufn_sys_MessageText(N'ExchangeRateConvert', @_LangId) + ' (' + conv.Code + '): '
                                 + FORMAT(ThisExchangeRate, 'N6') + ''';'
                               , '')
        FROM #TKTStmp                          AS tb
            INNER JOIN dbo.B20ExchangeRateConv AS conv
                ON tb.ExchangeRateConvId = conv.Id
        WHERE ItemLevel = 9
              AND ItemType = 'L'
              AND tb.LongTermAccount IS NULL

        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_TongHopTk
                           + IIF(ISNULL(ThisExchangeRate, 0) <> 0
                               , N'ExchangeRateConvertDesc='''
                                 + dbo.ufn_sys_MessageText(N'ExchangeRateConvert', @_LangId) + ' (' + conv.Code + '): '
                                 + FORMAT(ThisExchangeRate, 'N6') + ''';'
                               , '')
        FROM #TKTStmp                          AS tb
            INNER JOIN dbo.B20ExchangeRateConv AS conv
                ON tb.ExchangeRateConvId = conv.Id
        WHERE ItemLevel = 9
              AND ItemSide = 'C'
              AND ItemType <> 'L'
              AND tb.LongTermAccount IS NULL

        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_BangCanDoiPS
                           + IIF(ISNULL(ThisExchangeRate, 0) <> 0
                               , N'ExchangeRateConvertDesc='''
                                 + dbo.ufn_sys_MessageText(N'ExchangeRateConvert', @_LangId) + ' (' + conv.Code + '): '
                                 + FORMAT(ThisExchangeRate, 'N6') + ''';'
                               , '')
        FROM #TKTStmp                          AS tb
            INNER JOIN dbo.B20ChartOfAccount   AS acc
                ON acc.Code = tb.Account
            INNER JOIN dbo.B20ExchangeRateConv AS conv
                ON tb.ExchangeRateConvId = conv.Id
        WHERE tb.ItemLevel = 9
              AND tb.ItemType <> 'L'
              AND CustomerAccount = 1
              AND tb.LongTermAccount IS NULL

        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_TongHopTk
                           + IIF(ISNULL(ThisExchangeRate, 0) <> 0
                               , N'ExchangeRateConvertDesc='''
                                 + dbo.ufn_sys_MessageText(N'ExchangeRateConvert', @_LangId) + ' (' + conv.Code + '): '
                                 + FORMAT(ThisExchangeRate, 'N6') + ''';'
                               , '')
        FROM #TKTStmp                          AS tb
            INNER JOIN dbo.B20ExchangeRateConv AS conv
                ON tb.ExchangeRateConvId = conv.Id
        WHERE ItemLevel = 9
              AND ItemSide = 'N'
              AND ItemType <> 'L'
              AND LongTermAccount IS NULL

        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_ChiTieuTongHop
        WHERE ItemLevel <> 9
              AND Account NOT IN ( 'TONGNV', 'TONGTS' )
              AND ItemLevel <> 0
    END
    ELSE
    BEGIN
        -- Đưa các TK theo dõi tính chất vào theo dõi riêng ở báo cáo Bảng cân đối tài khoản theo tính chất ngắn/dài hạn
        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_BCDTK_TCTK
        FROM #TKTStmp AS tb
        WHERE ItemLevel = 9
              AND LongTermAccount IS NOT NULL

        -- Thay việc đưa vào công nợ ==> chuyển thành bảng cân đối phát sinh
        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_BangCanDoiPS
        FROM #TKTStmp AS tb
        WHERE ItemLevel = 9
              AND ItemType = 'L'
              AND LongTermAccount IS NULL

        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_TongHopTk
        FROM #TKTStmp AS tb
        WHERE ItemLevel = 9
              AND ItemSide = 'C'
              AND ItemType <> 'L'
              AND LongTermAccount IS NULL

        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_BangCanDoiPS
        FROM #TKTStmp                        AS tb
            INNER JOIN dbo.B20ChartOfAccount AS acc
                ON acc.Code = tb.Account
        WHERE tb.ItemLevel = 9
              AND tb.ItemType <> 'L'
              AND CustomerAccount = 1
              AND tb.LongTermAccount IS NULL

        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_TongHopTk
        WHERE ItemLevel = 9
              AND ItemSide = 'N'
              AND ItemType <> 'L'
              AND LongTermAccount IS NULL

        UPDATE #TKTStmp
        SET _LinkCommand = @_CommandKey_ChiTieuTongHop
        WHERE ItemLevel <> 9
              AND Account NOT IN ( 'TONGNV', 'TONGTS' )
              AND ItemLevel <> 0
    END

    IF ISNULL(@_ItemNo, '') <> ''
        UPDATE #TKTStmp
        SET _LinkCommand = NULL
        WHERE ItemNo = @_ItemNo
              AND ItemLevel <> 9

    UPDATE tb
    SET ExchangeRateConvCode = conv.Code
    FROM #TKTStmp                          AS tb
        INNER JOIN dbo.B20ExchangeRateConv AS conv
            ON tb.ExchangeRateConvId = conv.Id


    IF @_Mau_Bc = N''
    BEGIN

        IF ISNULL(@_tblOutput, '') <> ''
        BEGIN
            DECLARE @Cmd NVARCHAR(MAX)

            EXEC usp_sys_CreateTable @_tblOutput, '#TKTStmp'

            SET @Cmd = ''
            SELECT @Cmd = @Cmd + IIF(@Cmd <> '', ',', '') + Name
            FROM tempdb.Sys.Columns
            WHERE OBJECT_ID = OBJECT_ID('tempdb..' + @_tblOutput)
                  AND Name IN
                      (
                          SELECT Name
                          FROM tempdb.Sys.Columns
                          WHERE OBJECT_ID = OBJECT_ID('tempdb..#TKTStmp')
                      )
            SET @Cmd
                = N'INSERT INTO ' + @_tblOutput + N'(' + @Cmd + N')' + CHAR(13) + N'SELECT ' + @Cmd + N' FROM #TKTStmp'
            EXEC sp_executesql @Cmd

        END
        ELSE
        BEGIN
            SELECT A.*
                 , Stt_Order AS _Stt_Order
                 , ItemNo    AS _FormulaKey
                 , Formula   AS _Formula
            FROM #TKTStmp AS A
            WHERE ItemSide = 'C'
                  AND IsOutsideAccount = 0
                  AND IsPrint = 1
            ORDER BY _Stt_Order ASC

            SELECT A.*
                 , Stt_Order AS _Stt_Order
                 , ItemNo    AS _FormulaKey
                 , Formula   AS _Formula
            FROM #TKTStmp AS A
            WHERE ItemSide = 'N'
                  AND IsOutsideAccount = 0
                  AND IsPrint = 1
            ORDER BY _Stt_Order ASC

            --IF ISNULL(@_GetIsOutsideAccount, 0) = 1
            --    SELECT A.*
            --         , Stt_Order AS _Stt_Order
            --         , ItemNo    AS _FormulaKey
            --         , Formula   AS _Formula
            --    FROM #TKTStmp AS A
            --    WHERE ItemSide = 'N'
            --          AND IsOutsideAccount = 1
            --          AND IsPrint = 1

        END

    END

		  SELECT @_LAYOUT_XML = ''
        SELECT @_LAYOUT_XML
            = @_LAYOUT_XML + @_nl + 
N' <' + ISNULL(ColName, '') + '>' + @_nl + 
N' <Width>' + ISNULL(_Width, '')+ '</Width> ' + @_nl + 
N' <Style>TextAlign:' + ISNULL(_TextAlign, '') + ';</Style> ' + @_nl + 
N'   <Format>' + ISNULL(_Format, '')+ '</Format> ' + @_nl + 
N' <Rows> ' + @_nl + 
N'  <Row_0> ' + @_nl + 
N'   <Text> ' + @_nl+ 
N'    <Vietnamese>' + ISNULL(Row_0_VN, '') + '</Vietnamese> ' + @_nl + 
N'    <English>'+ ISNULL(Row_0_EN, '') + '</English> ' + @_nl + 
N'   </Text> ' + @_nl + 
N'   <Style>UserData:'+ ISNULL(UserData0, '') + ';</Style> ' + @_nl + 
N'  </Row_0> ' + @_nl + 
N'  <Row_1> ' + @_nl+ 
N'   <Text> ' + @_nl + 
N'    <Vietnamese>' + ISNULL(Row_1_VN, '') + '</Vietnamese> ' + @_nl+ 
N'    <English>' + ISNULL(Row_1_EN, '') + '</English> ' + @_nl + 
N'   </Text> ' + @_nl+ 
N'   <Style>UserData:' + ISNULL(UserData1, '') + ';WordWrap:True;</Style> ' + @_nl + 
N'  </Row_1> '+ @_nl + 
N' </Rows> ' + @_nl + 
N' </' + ISNULL(ColName, '') + '>' + @_nl
        FROM #ColList
        ORDER BY BuiltinOrder1 ASC 

        SET @_LAYOUT_XML
            = 
N'		<Report_0> ' + @_nl + 
N'			<Content> ' + @_nl + 
N'				<Cols> ' + @_nl + 
N'			'+ @_LAYOUT_XML + @_nl + 
N'				</Cols> ' + @_nl + 
N'			</Content> ' + @_nl+  
N'		</Report_0> '   + @_nl


    DECLARE @_LAYOUT_XML2 NVARCHAR(MAX) = REPLACE(@_LAYOUT_XML, 'Report_0', 'Report_1')
 
    SET @_LAYOUT_XML
        = N'<panelReporter>' + @_nl + N'   <Controls> ' + @_nl + N' ' + CONCAT(@_LAYOUT_XML, @_nl, @_LAYOUT_XML2, @_nl)
          + @_nl + N'   </Controls> ' + @_nl + N'</panelReporter>' + @_nl;

		 

    DROP TABLE IF EXISTS #ExchangeRateConv_CtTmp;
    DROP TABLE IF EXISTS #TKTStmp
    RETURN
END
GO
GO


GO



SET DATEFORMAT DMY
EXEC usp_BusinessPlanKqt_BalanceSheet_test @_DocDate1 = '01/01/2026 00:00:00.000'
                                    , @_DocDate2 = '31/01/2026 00:00:00.000'
                                    , @_Ngay_Dau_Nam = '01/01/2026 00:00:00.000'
                                    , @_LangId = 0
                                    , @_BranchCode = 'I26'
                                    , @_RepId1 = 'I260000005'
                                    , @_CurrencyCode0 = 'VND'
                                    , @_DefinitionTableName = 'B10BusinessPlanKqt01'
                                    , @_TableValue = ''
                                    , @_HTKK_Exp = 0
                                    , @_Filename_XML = ''
                                    , @_IssuedByNo = '200/2014/TT-BTC'