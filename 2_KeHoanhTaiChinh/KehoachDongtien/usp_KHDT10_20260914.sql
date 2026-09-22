ALTER PROCEDURE dbo.usp_KHDT10
    @_DocDate1 SMALLDATETIME = '20150601'
  , @_DocDate2 SMALLDATETIME = '20150630'
  , @_DocCode NCHAR(2) = N''
  , @_CashFlowCode NVARCHAR(16) = N''
  , @_DeptCode NVARCHAR(16) = N''
  , @_Account NVARCHAR(1000) = N'111,112,113'
  , @_ReduceAccount NVARCHAR(1000) = N'152,153,155,156,157,159,11,14,33'
  , @_ExclusionAccount NVARCHAR(1000) = N'911'
  , @_KeyExclude NVARCHAR(MAX) = ''
  , @_Kieu_Bc CHAR(1) = '1'
  , @_nUserId AS INT = 0
  , @_LangId INT = 0
  , @_Ma_Dvcs NCHAR(3) = N'A01'
  , @_ConsolCode NVARCHAR(512) = ''
  , @_Not_ConsolCode NVARCHAR(512) = ''
  , @_Not_BranchCode NVARCHAR(512) = ''
  , @_Not_RouteCode NVARCHAR(512) = ''
  , @_BranchCode1 NVARCHAR(512) = ''
  , @_Not_BranchCode1 NVARCHAR(512) = ''
  , @_Not_BranchCode1Detail NVARCHAR(512) = ''
  , @_BranchCode NVARCHAR(3) = ''
  , @_BranchCode2 NVARCHAR(128) = ''
  , @_Test INT = 0
  , @_GetParent INT = 0
  , @_LAYOUT_XML NVARCHAR(MAX) = '' OUTPUT
  , @_StrTime NVARCHAR(128) = '' OUTPUT
  , @tblOutput NVARCHAR(64) = ''
  , @_ChiTiet_DVCS INT = 0
  , @_AddColType1 INT = 1
  , @_AddColType NVARCHAR(16) = 'THANG'
  , @_BranchReportId INT = NULL
AS
BEGIN
    -- Tong hop chi phi theo khoan muc      
    SET NOCOUNT ON;
    DECLARE @_Time1               DATETIME
          , @_Time2               DATETIME
          , @_Msg_KhongCoKhoanMuc NVARCHAR(128) = dbo.ufn_sys_MessageText('KhongCoHDDT', @_LangId)
    SET @_Time1 = GETDATE()
    IF OBJECT_ID('TempDb..#DsDvcsTmp') IS NOT NULL
        DROP TABLE #DsDvcsTmp
    SELECT tb.BranchCode AS Ma_Dvcs
         , tb.BranchCode AS BranchCode1
         , dv.BranchName AS Ten_Dvcs
    INTO #DsDvcsTmp
    FROM dbo.ufn_B00Branch_GetChildTableThaco(
                                                 @_nUserId
                                               , @_Ma_Dvcs
                                               , @_ConsolCode
                                               , @_Not_ConsolCode
                                               , @_Not_BranchCode
                                               , @_Not_RouteCode
                                               , 0
                                             ) AS tb
        LEFT OUTER JOIN B00Branch              AS dv
            ON tb.BranchCode = dv.BranchCode
    DECLARE @_Xml XML
    SET @_Xml = '<BravoLayout></BravoLayout>'
    SELECT @_DocCode          = RTRIM(@_DocCode)
         , @_CashFlowCode     = RTRIM(@_CashFlowCode)
         , @_DeptCode         = RTRIM(@_DeptCode)
         , @_Account          = RTRIM(@_Account)
         , @_ExclusionAccount = RTRIM(@_ExclusionAccount)
    DECLARE @_StrTmp               NVARCHAR(4000)
          , @_Order_By             NVARCHAR(256)
          , @_Group_By             NVARCHAR(256)
          , @_Amount               NUMERIC(18, 2)
          , @_OriginalAmount       NUMERIC(18, 2)
          , @_BudgetAmount         NUMERIC(18, 2)
          , @_OriginalBudgetAmount NUMERIC(18, 2)
          , @_Description          NVARCHAR(256)
          , @_StrTmpN              NVARCHAR(4000)
          , @_StrExec              NVARCHAR(4000)
          , @_Key1                 NVARCHAR(MAX)
          , @_Key2                 NVARCHAR(MAX)
          , @_Key_Kh               NVARCHAR(4000)
          , @_KeyDelLcNb           NVARCHAR(MAX)
          , @_FieldList            VARCHAR(MAX)
          , @_FieldSum             VARCHAR(MAX)
    IF OBJECT_ID('TempDb..#CtTmp') IS NOT NULL
        DROP TABLE #CtTmp
    IF OBJECT_ID('TempDb..#K_CtTmp') IS NOT NULL
        DROP TABLE #K_CtTmp
    IF OBJECT_ID('TempDb..#K_SoTmp') IS NOT NULL
        DROP TABLE #K_SoTmp
    CREATE TABLE #CtTmp
    (
        BranchCode CHAR(8)
            DEFAULT ''
      , BranchCode2 CHAR(160)
            DEFAULT '' -- 20201030 DUYENTTM lấy thêm địa điểm bán      
      , DocCode NVARCHAR(2)
      , DocDate SMALLDATETIME
            DEFAULT ''
      , DocNo NVARCHAR(24)
            DEFAULT ''
      , DeptCode VARCHAR(24)
            DEFAULT ''
      , DeptName NVARCHAR(128)
      , CashFlowId INT
      , CashFlowCode VARCHAR(24)
            DEFAULT ''
      , CashFlowName NVARCHAR(128)
      , Amount NUMERIC(18, 2)
            DEFAULT 0
      , OriginalAmount NUMERIC(18, 2)
            DEFAULT 0
      , RowId NVARCHAR(16)
      , ProfitCenterCode NVARCHAR(24)
      , ProfitCenterName NVARCHAR(256)
      , Account NVARCHAR(16)
      , CrspAccount NVARCHAR(16)
      , CreditAccount NVARCHAR(16)
      , DebitAccount NVARCHAR(16)
      , StageCode NVARCHAR(16)
      , Ma_Dvcs CHAR(8)
            DEFAULT ''
      , Ma_Dvcs1 CHAR(8)
            DEFAULT ''
      , DeptId INT
      , ProfitCenterId INT
      , StageId INT
      , RouteCode NVARCHAR(56)
      , CustomerId0 INT
      , MesGroupCode VARCHAR(24)
    )
    EXECUTE usp_sys_DefaultTable '#CtTmp'
    SET @_Key1
        = N'((Account LIKE N''' + REPLACE(@_Account, N',', N'%'' OR Account LIKE N''')
          + N'%'') AND (CrspAccount NOT LIKE ''' + REPLACE(@_ExclusionAccount, ',', '%'' AND CrspAccount NOT LIKE ''')
          + '%'')) AND DebitAmount<>0'
    SET @_Key2
        = N'((Account LIKE N''' + REPLACE(@_Account, N',', N'%'' OR Account LIKE N''')
          + N'%'') AND (CrspAccount NOT LIKE ''' + REPLACE(@_ExclusionAccount, ',', '%'' AND CrspAccount NOT LIKE ''')
          + '%'')) AND CreditAmount<>0'
    IF @_DocCode <> ''
    BEGIN
        SET @_Key1 = @_Key1 + N' AND (DocCode = N''' + @_DocCode + N''')'
        SET @_Key2 = @_Key2 + N' AND (DocCode = N''' + @_DocCode + N''')'
    END
    IF @_CashFlowCode <> ''
    BEGIN
        SET @_Key1 = @_Key1 + N' AND (CashFlowCode LIKE N''' + RTRIM(@_CashFlowCode) + N'%'')'
        SET @_Key2 = @_Key2 + N' AND (CashFlowCode LIKE N''' + RTRIM(@_CashFlowCode) + N'%'')'
        SET @_Key_Kh = @_Key_Kh + N' AND (CashFlowCode LIKE N''' + RTRIM(@_CashFlowCode) + N'%'')'
    END
    IF @_DeptCode <> ''
    BEGIN
        SET @_Key1 = @_Key1 + N' AND (DeptCode LIKE N''' + RTRIM(@_DeptCode) + N'%'')'
        SET @_Key2 = @_Key2 + N' AND (DeptCode LIKE N''' + RTRIM(@_DeptCode) + N'%'')'
        SET @_Key_Kh = @_Key_Kh + N' AND (DeptCode LIKE N''' + RTRIM(@_DeptCode) + N'%'')'
    END
    IF @_BranchCode2 <> N''
    BEGIN
        SET @_Key1
            = @_Key1 + N' AND (BranchCode2 LIKE N''' + REPLACE(@_BranchCode2, N',', N'%'' OR BranchCode2 LIKE N''')
              + N'%'')'
        SET @_Key2
            = @_Key2 + N' AND (BranchCode2 LIKE N''' + REPLACE(@_BranchCode2, N',', N'%'' OR BranchCode2 LIKE N''')
              + N'%'')'
        SET @_Key_Kh
            = @_Key_Kh + N' AND (BranchCode2 LIKE N''' + REPLACE(@_BranchCode2, N',', N'%'' OR BranchCode2 LIKE N''')
              + N'%'')'
    END
    SELECT @_KeyExclude = ' AND NOT ( Account LIKE ''241%''  AND CrspAccount LIKE ''331%2'' ) '
    SELECT @_Key1 = @_Key1 + @_KeyExclude

    --Lay phan: chi phi phat tang      
    EXEC usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                    , @_DocDate2 = @_DocDate2
                                    , @_Key1 = @_Key1
                                    , @_CtTmp = N'#CtTmp'
                                    , @_nUserId = @_nUserId
                                    , @_LangId = @_LangId
                                    , @_BranchCode = @_Ma_Dvcs
                                    , @_BranchReportId = @_BranchReportId



    --Lay phan: Chi phi giam      
    SELECT TOP 0
           *
    INTO #CtTmp1
    FROM #CtTmp
    EXEC usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                    , @_DocDate2 = @_DocDate2
                                    , @_Key1 = @_Key2
                                    , @_CtTmp = N'#CtTmp1'
                                    , @_nUserId = @_nUserId
                                    , @_LangId = @_LangId
                                    , @_BranchCode = @_Ma_Dvcs
                                    , @_BranchReportId = @_BranchReportId
    UPDATE #CtTmp1
    SET Amount = -Amount
      , OriginalAmount = -OriginalAmount

    INSERT INTO #CtTmp
    SELECT *
    FROM #CtTmp1
    DROP TABLE #CtTmp1

    UPDATE #CtTmp
    SET MesGroupCode = cus.MesGroupCode
    FROM #CtTmp                AS c
        INNER JOIN B20Customer AS cus (READUNCOMMITTED)
            ON c.CustomerId0 = cus.Id

    --quanhp: xu ly chi tiet theo ma dvcs      
    UPDATE #CtTmp
    SET Ma_Dvcs = Tmp.BranchCode
      , Ma_Dvcs1 = Dvcs.BranchCode
    FROM #CtTmp                  AS Tmp
        INNER JOIN dbo.B00Branch AS Dvcs
            ON Tmp.BranchCode = Dvcs.BranchCode
    UPDATE #CtTmp
    SET DeptCode = dept.Code
      , CashFlowCode = expen.Code
      , ProfitCenterCode = pro.Code
    FROM #CtTmp                             AS a
        LEFT OUTER JOIN dbo.B20Dept         AS dept
            ON dept.Id = a.DeptId
        LEFT OUTER JOIN dbo.B20CashFlow     AS expen
            ON expen.Id = a.CashFlowId
        LEFT OUTER JOIN dbo.B20ProfitCenter AS pro
            ON pro.Id = a.ProfitCenterId
    IF @_AddColType = 'THANG'
        UPDATE #CtTmp
        SET BranchCode = 'N' + STR(YEAR(DocDate), 4) + REPLACE(STR(MONTH(DocDate), 2), SPACE(1), '0')
    IF @_Kieu_Bc = '1'
    BEGIN
        UPDATE #CtTmp
        SET DeptCode = ''
        UPDATE #CtTmp
        SET ProfitCenterCode = ''
    END
    IF OBJECT_ID('Tempdb..#K_CtTmp') IS NOT NULL
        DROP TABLE #K_CtTmp
    SELECT BranchCode
         , MAX(RouteCode)            AS BranchCode2
         , DeptCode
         , MAX(DeptName)             AS DeptName
         , CashFlowCode
         , MAX(CashFlowId)           AS CashFlowId
         , MAX(CashFlowName)         AS CashFlowName
         , SUM(Amount)               AS Amount
         , SUM(OriginalAmount)       AS OriginalAmount
         , CAST('' AS VARCHAR(16))   AS Ma_Th
         , CAST('' AS NVARCHAR(128)) AS Ten_Th
         , CAST('' AS VARCHAR(16))   AS Ma_Ct
         , CAST('' AS NVARCHAR(128)) AS Ten_Ct
         , MAX(ProfitCenterCode)     AS ProfitCenterCode
         , MAX(ProfitCenterName)     AS ProfitCenterName
         , MAX(StageCode)            AS StageCode
         , MAX(Ma_Dvcs)              AS Ma_Dvcs
         , MAX(Ma_Dvcs1)             AS Ma_Dvcs1
         , CAST('' AS VARCHAR(16))   AS ClassCode1
         , MesGroupCode
    INTO #K_CtTmp
    FROM #CtTmp
    GROUP BY BranchCode
           , DeptCode
           , CashFlowCode
           , ProfitCenterCode
           , Ma_Dvcs
           , Ma_Dvcs1
           , RouteCode
           , MesGroupCode

    UPDATE #K_CtTmp
    SET CashFlowName = IIF(ISNULL(a.CashFlowCode, '') = '', N'<' + @_Msg_KhongCoKhoanMuc + N'>', expe.Name)
      , ClassCode1 = expe.ClassCode1
    FROM #K_CtTmp                   AS a
        LEFT OUTER JOIN B20CashFlow AS expe
            ON a.CashFlowCode = expe.Code
    UPDATE #K_CtTmp
    SET #K_CtTmp.DeptName = B20Dept.Name
    FROM #K_CtTmp
       , B20Dept
    WHERE #K_CtTmp.DeptCode = B20Dept.Code
    UPDATE #K_CtTmp
    SET #K_CtTmp.ProfitCenterName = B20ProfitCenter.Name
    FROM #K_CtTmp
       , B20ProfitCenter
    WHERE #K_CtTmp.ProfitCenterCode = B20ProfitCenter.Code
    UPDATE #K_CtTmp
    SET CashFlowCode = ''
      , CashFlowName = CASE @_LangId
                           WHEN 1 THEN
                               N'<Unknow category>'
                           ELSE
                               N'<Chưa xác định khoản mục>'
                       END
    WHERE CashFlowCode = ''
    UPDATE #K_CtTmp
    SET DeptCode = ''
      , DeptName = CASE @_LangId
                       WHEN 1 THEN
                           N'<Unknow department>'
                       ELSE
                           N'<Chưa xác định bộ phận>'
                   END
    WHERE DeptCode = ''
    UPDATE #K_CtTmp
    SET ProfitCenterCode = ''
      , ProfitCenterName = CASE @_LangId
                               WHEN 1 THEN
                                   N'<Unknow profitcenter>'
                               ELSE
                                   N'<Chưa xác định mã HĐKD>'
                           END
    WHERE ProfitCenterCode = ''
    IF @_Kieu_Bc = '1'
    BEGIN
        UPDATE #K_CtTmp
        SET Ma_Th = CashFlowCode
          , Ten_Th = RTRIM(CashFlowName)
          , StageCode = '' -- Tín thêm, xóa các stagecode, chỉ group lại theo kmp      
        UPDATE #K_CtTmp
        SET Ten_Ct = Ten_Th
    END
    ELSE IF @_Kieu_Bc = '2' --2: Km, Bp      
    BEGIN
        IF ISNULL(@_GetParent, 0) = 1
        BEGIN
            -- Tín thêm lấy mã bộ phận cấp mẹ      
            ;WITH tbl (DeptCode, ParentCode)
             AS (SELECT a.Code
                      , b.Code
                 FROM B20Dept           AS a
                     INNER JOIN B20Dept AS b
                         ON a.ParentId = b.Id)
            UPDATE #K_CtTmp
            SET DeptCode = a.ParentCode
            FROM tbl                AS a
                INNER JOIN #K_CtTmp AS b
                    ON a.DeptCode = b.DeptCode
        END
        UPDATE #K_CtTmp
        SET Ma_Th = CashFlowCode
          , Ten_Th = RTRIM(CashFlowName)
          , Ma_Ct = DeptCode
          , Ten_Ct = RTRIM(DeptName)
    END
    ELSE IF @_Kieu_Bc = '3' --3: Bp, Km      
        UPDATE #K_CtTmp
        SET Ma_Th = DeptCode
          , Ten_Th = RTRIM(DeptName)
          , Ma_Ct = CashFlowCode
          , Ten_Ct = RTRIM(CashFlowName)
    ELSE
        UPDATE #K_CtTmp --4: km, ma hdkd      
        SET Ma_Th = CashFlowCode
          , Ten_Th = RTRIM(CashFlowName)
          , Ma_Ct = ProfitCenterCode
          , Ten_Ct = RTRIM(ProfitCenterName)
    IF OBJECT_ID('Tempdb..#KQ') IS NOT NULL
        DROP TABLE #KQ
    SELECT TOP 0
           Ma_Th
         , Ten_Th
         , Ma_Ct
         , Ten_Ct
         , DeptCode
         , CashFlowCode
         , CashFlowId
         , ProfitCenterCode
         , StageCode
         , Ma_Dvcs
         , Ma_Dvcs1
         , BranchCode2
         , ClassCode1
         , MesGroupCode
    INTO #KQ
    FROM #K_CtTmp


    DECLARE @_BrowField NVARCHAR(MAX)
    EXEC usp_pivot @query = 'SELECT * FROM #K_CtTmp'
                 , @on_rows = 'Ma_Th,Ten_Th,Ma_Ct,Ten_Ct,DeptCode,CashFlowCode,CashFlowId,ProfitCenterCode,StageCode,Ma_Dvcs,Ma_Dvcs1,BranchCode2,ClassCode1,MesGroupCode' -- Tín bỏ cái StageCode       
                 , @on_cols = 'BranchCode'
                 , @agg_func = 'SUM'
                 , @agg_col = 'Amount'
                 , @bang = '#KQ'
                 , @brow_str = @_BrowField OUTPUT

    ALTER TABLE #KQ ADD ClassCode1Name NVARCHAR(256) DEFAULT '',MesGroupInfo  NVARCHAR(256) DEFAULT ''


    UPDATE #KQ
    SET ClassCode1Name = cl1.Name
    FROM #KQ                         AS a
        LEFT OUTER JOIN dbo.B20Class AS cl1
            ON cl1.Code = a.ClassCode1
               AND cl1.ParentCode = 'IncomeExpenditure'


	  UPDATE #KQ
    SET MesGroupInfo = cl1.Name
    FROM #KQ                         AS a
        LEFT OUTER JOIN dbo.B20Class AS cl1
            ON cl1.Code = a.MesGroupCode
               AND cl1.ParentCode = 'MesGroupCode'

    --: dung cot      
    DECLARE @_DsCot TABLE
    (
        Cot VARCHAR(11)
      , Ma_Cot VARCHAR(32)
      , Ma_Cot2 VARCHAR(32)
      , Ten_Cot VARCHAR(128)
      , Id INT IDENTITY(1, 1)
      , Tag CHAR(1)
            DEFAULT ''
    )
    INSERT INTO @_DsCot
    (
        Ma_Cot
    )
    SELECT BranchCode
    FROM #K_CtTmp
    GROUP BY BranchCode
    IF @_AddColType = 'THANG'
        UPDATE @_DsCot
        SET Ten_Cot = N'Tháng ' + RIGHT(RTRIM(Ma_Cot), 2) + '/' + SUBSTRING(Ma_Cot, 2, 4)
    ELSE
        UPDATE @_DsCot
        SET Ten_Cot = t2.BranchName_English
        FROM @_DsCot                 AS t1
            INNER JOIN dbo.B00Branch AS t2
                ON t1.Ma_Cot = t2.BranchCode
    SET @_LAYOUT_XML = ''
    SELECT @_LAYOUT_XML
        = RTRIM(@_LAYOUT_XML) + N'<Column_' + RTRIM(Ma_Cot) + N'>' + CHAR(13) + N'<Name>' + RTRIM(Ma_Cot) + N'</Name>'
          + CHAR(13) + N'<Width>120</Width>' + CHAR(13) + N'<Format>N0</Format>' + CHAR(13)
          + N'<Rows>      
      <Row_0>'            + CHAR(13) + CASE
                                           WHEN @_AddColType = 'THANG' THEN
                                               CASE
                                                   WHEN Id = 1 THEN
                                                       N'<Text><Vietnamese>Thời gian</Vietnamese></Text>'
                                                   ELSE
                                                       N''
                                               END
                                           ELSE
                                               N'<Text><Vietnamese>' + RTRIM(Ma_Cot) + N'</Vietnamese></Text>'
                                       END + CHAR(13) + CASE
                                                            WHEN @_AddColType = 'THANG' THEN
                                                                N'<Style>UserData:AAA;</Style>'
                                                            ELSE
                                                                N''
                                                        END + CHAR(13)
          + N'  </Row_0>      
                <Row_1>      
                  <Text><Vietnamese>' + RTRIM(Ten_Cot)
          + N'</Vietnamese></Text>      
                </Row_1>      
               </Rows>  ' + CHAR(13) + N'</Column_' + RTRIM(Ma_Cot) + N'>' + CHAR(13)
    FROM @_DsCot
    ORDER BY Ma_Cot
    SET @_LAYOUT_XML = N'<Content><Cols>' + RTRIM(@_LAYOUT_XML) + N'</Cols></Content>'
    SET @_LAYOUT_XML
        = N'<DefaultReport>' + CHAR(13) + RTRIM(@_LAYOUT_XML) + CHAR(13)
          + CASE
                WHEN @_Kieu_Bc <> '1' THEN
                    N'<SubTotals><Ten_Th><Text /></Ten_Th></SubTotals> '
                ELSE
                    N''
            END + CHAR(13) + N'</DefaultReport>'
    DECLARE @_LinkCommand  AS NVARCHAR(2000)
          , @_LinkCommand1 AS NVARCHAR(2000);
    IF ISNULL(@tblOutput, '') <> ''
    BEGIN
        DECLARE @Cmd NVARCHAR(MAX)
        EXEC usp_sys_CreateTable @tblOutput, '#KQ'
        SET @Cmd = ''
        SELECT @Cmd = @Cmd + IIF(@Cmd <> '', ',', '') + Name
        FROM tempdb.Sys.Columns
        WHERE OBJECT_ID = OBJECT_ID('tempdb..' + @tblOutput)
              AND Name IN
                  (
                      SELECT Name
                      FROM tempdb.Sys.Columns
                      WHERE OBJECT_ID = OBJECT_ID('tempdb..#KQ')
                  )
        SET @Cmd = N'INSERT INTO ' + @tblOutput + N'(' + @Cmd + N')' + CHAR(13) + N'SELECT ' + @Cmd + N' FROM #KQ'
        EXEC sp_executesql @Cmd
    END
    ELSE
    BEGIN
        SELECT *
             , @_LinkCommand AS _LinkCommand
        FROM #KQ
        ORDER BY CashFlowCode
    END
    DROP TABLE #KQ
    DROP TABLE #K_CtTmp
    DROP TABLE #CtTmp
    SELECT @_Time2 = GETDATE()
END
GO



SET DATEFORMAT DMY
EXEC usp_KHDT10 @_DocDate1 = '01/08/2026 00:00:00.000'
              , @_DocDate2 = '31/08/2026 00:00:00.000'
              , @_Account = '331'
              , @_ExclusionAccount = '341'
              , @_nUserId = 1213
              , @_LangId = 0
              , @_Ma_Dvcs = 'I22'
              , @_StrTime = ''
              , @tblOutput = NULL