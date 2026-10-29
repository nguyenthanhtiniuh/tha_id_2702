SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/*
-- Description:	DETAILED REPORT ON OUTSTANDING LOANS
--BÁO CÁO CHI TIẾT DƯ NỢ VAY
--Tinnt
--02-06-2026
*/
ALTER   PROCEDURE dbo.usp_detailed_report_on_outstanding_loans_test
    @_DocDate1 DATE = NULL
  , @_DocDate2 DATE = NULL
  --Thông tin CR-Hợp đồng tín dụng
  , @_DocType_CR NVARCHAR(16) = NULL
  , @_Account VARCHAR(MAX) = ''
  , @_Account635 VARCHAR(MAX) = '635,1388'
  , @_CustomerId VARCHAR(512) = ''
  , @_BizDocId_LC VARCHAR(512) = ''
  , @_nUserId INT = 0
  , @_LangId INT = 1
  , @_BranchCode VARCHAR(3) = ''
  , @_CurrencyCode0 CHAR(3) = 'VND'
  , @_DocCode NVARCHAR(24) = NULL
  , @_BranchReportId INT = NULL
  , @_AccountLevel INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    -- ========================================================
    -- 1. KHỞI TẠO BIẾN VÀ CẤU TRÚC BÁO CÁO
    -- ========================================================
    -- Tự động lấy thông tin theo AppName khi thực hiện trong chương trình, không theo tham số truyền vào
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId);
    SET @_BranchCode = dbo.ufn_sys_GetValueFromAppName('BranchCode', @_BranchCode);
    DECLARE @_Key2         NVARCHAR(MAX) = N''
          , @_Key          NVARCHAR(MAX) = N''
          , @_KeyCd        NVARCHAR(MAX) = N''
          , @_Key_Interest NVARCHAR(MAX) = N'';
    DECLARE @_Time1 DATETIME = GETDATE()
          , @_nl    CHAR(1)  = CHAR(13);
    DECLARE @_DebugStepTime DATETIME      = GETDATE()
          , @_Step          NVARCHAR(2000)
          , @_DebugMsg      NVARCHAR(256) = N'';

    DECLARE @_Key_BizDoc NVARCHAR(MAX) = '';

    IF ISNULL(@_Account, '') <> ''
    BEGIN
        SET @_Key
            = @_Key + N' AND ((Account LIKE N''' + REPLACE(@_Account, N',', '%'') OR (Account LIKE N' + NCHAR(39))
              + N'%''))';

        SELECT @_Key2       = @_Key
             , @_KeyCd      = @_Key
             , @_Key_BizDoc = @_Key;

        SELECT @_Key_BizDoc = @_Key_BizDoc + ' OR ( PATINDEX( N''%' + @_Account + '%'',Lst_Account ) <> 0 ) ';
    END;

    IF @_Account635 <> N''
    BEGIN
        --SET @_Key_Interest = @_Key_Interest + N' AND Account LIKE ''' + RTRIM(@_Account635) + N'%''';
        SET @_Key_Interest
            = @_Key_Interest + N' AND ((Account  LIKE N'''
              + REPLACE(@_Account635, N',', '%'') OR (Account LIKE N' + NCHAR(39)) + N'%''))';

    END;

    SET @_KeyCd = N' AND (BizDocId <> '''') ';

    IF ISNULL(@_DocCode, '') <> ''
    BEGIN
        SET @_Key = @_Key + N' AND DocCode =''' + RTRIM(@_DocCode) + N'''';
        SET @_Key_BizDoc = @_Key_BizDoc + N' AND DocCode =''' + RTRIM(@_DocCode) + N'''';
    END;

    IF @_BizDocId_LC <> ''
    BEGIN
        SET @_Key
            = @_Key + N' AND ((BizDocId  = N''' + REPLACE(@_BizDocId_LC, N',', ''') OR (BizDocId = N' + NCHAR(39))
              + N'''))';
        SET @_Key2
            = @_Key2 + N' AND ((BizDocId_LC = N'''
              + REPLACE(@_BizDocId_LC, ',', ''') OR (BizDocId_LC  = N' + NCHAR(39)) + N'''))';
        SET @_KeyCd
            = @_KeyCd + N' AND ((BizDocId  = N''' + REPLACE(@_BizDocId_LC, ',', ''') OR (BizDocId = N' + NCHAR(39))
              + N'''))';

        SET @_Key_Interest
            = @_Key_Interest + N' AND ((BizDocId_LC  = N'''
              + REPLACE(@_BizDocId_LC, ',', ''') OR (BizDocId_LC = N' + NCHAR(39)) + N'''))';

        SET @_Key_BizDoc
            = @_Key_BizDoc + N' AND ((BizDocId  = N'''
              + REPLACE(@_BizDocId_LC, ',', ''') OR (BizDocId = N' + NCHAR(39)) + N'''))';
    END;
    ELSE
    BEGIN
        SELECT @_Key2 = @_Key2 + N' AND BizDocId_LC IN (SELECT BizDocId_LC FROM #BizDoc ) AND (BizDocId_LC <> '''') ';
    END;
    IF @_CustomerId <> ''
    BEGIN
        EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId
                                 , @_ColGen = 'CustomerId'
                                 , @_ColName = 'Id'
                                 , @_TableName = 'B20Customer'
                                 , @_AndOrKey = 'AND'
                                 , @_Key = @_Key OUTPUT;
        EXECUTE dbo.usp_sys_GenKey @_Code = @_CustomerId
                                 , @_ColGen = 'CustomerId'
                                 , @_ColName = 'Id'
                                 , @_TableName = 'B20Customer'
                                 , @_AndOrKey = 'AND'
                                 , @_Key = @_KeyCd OUTPUT;
    END;

    IF ISNULL(@_DocType_CR, '') <> ''
    BEGIN
        SET @_Key_BizDoc = @_Key_BizDoc + N' AND DocType_CR =''' + RTRIM(@_DocType_CR) + N'''';
    END;
    ELSE
        SET @_Key_BizDoc = @_Key_BizDoc;

    IF @_Key <> N''
        SET @_Key = SUBSTRING(@_Key, 6, LEN(@_Key) - 5);
    IF @_Key2 <> N''
        SET @_Key2 = SUBSTRING(@_Key2, 6, LEN(@_Key2) - 5);
    IF @_Key_Interest <> N''
        SET @_Key_Interest = SUBSTRING(@_Key_Interest, 6, LEN(@_Key_Interest) - 5);
    IF @_Key_BizDoc <> N''
        SET @_Key_BizDoc = SUBSTRING(@_Key_BizDoc, 6, LEN(@_Key_BizDoc) - 5);




    SELECT @_Step = N' Start: Khởi tạo dữ liệu cơ bản & GenKey xong.';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;
    -- ========================================================
    -- 1. thu thập dữ liệu Khế ước vay  (#BizDoc)
    -- ========================================================
    DROP TABLE IF EXISTS #BizDoc;
    SELECT TOP (0)
           CtTmp.BranchCode
         , CtTmp.Description          AS BranchName
         , CtTmp.Description          AS BranchInfo              --CR
         , CtTmp.BizDocId             AS BizDocId_CR
         , CtTmp.Amount               AS AmountPayment_CR
         , CtTmp.DocNo                AS DocNo_CR
         , @_DocType_CR               AS DocType_CR
         , CtTmp.Description          AS DocType_CR_Info         --LC
         , CtTmp.Id
         , CtTmp.BizDocId
         , CAST(0 AS INT)             AS IsDebt
         , CtTmp.DocCode
         , CtTmp.DocNo
         , CtTmp.DocDate
         , CtTmp.DocDate              AS DateDue
         , CAST(0 AS INT)             AS DueDate
         , CtTmp.Description
         , CtTmp.CustomerId
         , CAST('' AS NVARCHAR(32))   AS CustomerCode
         , CAST('' AS NVARCHAR(192))  AS CustomerName
         , CtTmp.Amount               AS LoanOriginalAmount      --VND
         , CAST(0 AS NUMERIC(18, 2))  AS DebitBiz1
         , CAST(0 AS NUMERIC(18, 2))  AS CreditBiz1
         , CtTmp.DebitAmount
         , CtTmp.CreditAmount
         , CAST(0 AS NUMERIC(18, 2))  AS DebitBiz2
         , CAST(0 AS NUMERIC(18, 2))  AS CreditBiz2              --Original
         , CAST(0 AS NUMERIC(18, 2))  AS OriginalDebitBiz1
         , CAST(0 AS NUMERIC(18, 2))  AS OriginalCreditBiz1
         , CtTmp.OriginalDebitAmount
         , CtTmp.OriginalCreditAmount
         , CAST(0 AS NUMERIC(18, 2))  AS OriginalDebitBiz2
         , CAST(0 AS NUMERIC(18, 2))  AS OriginalCreditBiz2      --Chi tiết Lãi suất
         , CAST(0 AS NUMERIC(15, 10)) AS InterestRate
         , CAST(0 AS NUMERIC(15, 10)) AS InterestRate_ByDate     --Ngày trả nợ
         , CAST('' AS NVARCHAR(256))         AS RepaymentDate           --Ngày trả nợ
         , CtTmp.Amount               AS Interest_Payment        --Tiền lãi trong kỳ
         , CtTmp.Amount               AS InterestDuringThePeriod --
                                                                 --Detail LẤY TK theo dõi có Hiệu liệu lực sớm nhất
                                                                 --Đa số là tk theo dõi Dài hạn
         , CtTmp.Account
         , CAST('' AS NVARCHAR(256))  AS AccountName
         , CAST('' AS NVARCHAR(24))   AS LoanAccountNo
         , CtTmp.DocDate              AS EffectiveDate_Account
         , CAST(0 AS INT)             AS _RN
    INTO #BizDoc
    FROM dbo.B00CtTmp AS CtTmp;





    EXECUTE dbo.usp_sys_DefaultTable @_Table = '#BizDoc';
    EXECUTE dbo.usp_BizDoc_GetData @_DocDate1 = @_DocDate1
                                 , @_DocDate2 = @_DocDate2
                                 , @_Key = @_Key_BizDoc
                                 , @_CtTmp = N'#BizDoc'
                                 , @_nUserId = @_nUserId
                                 , @_LangId = @_LangId
                                 , @_BizDocName = 'dbo.vB30BizDoc_GetData_LC'
                                 , @_BranchCode = @_BranchCode
                                 , @_BranchReportId = @_BranchReportId
                                 , @_PrintExec = 1;



    SELECT @_Step = N' Bước 1: Lấy xong dữ liệu Khế ước vay(#BizDoc).';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;

    -- ========================================================
    -- 1.1. thu thập dữ liệu Hợp đồng tín dụng  (#BizDocCR)
    -- ========================================================
    DROP TABLE IF EXISTS #BizDocCR;
    SELECT TOP (0)
           BizDocId
         , DocNo
         , DocCode
         , DocDate
         , DocDate           AS DateDue
         , Amount            AS AmountPayment
         , CAST(NULL AS INT) AS DueDate
    INTO #BizDocCR
    FROM dbo.B00CtTmp;

    SELECT @_Key_BizDoc = N'   EXISTS (SELECT * FROM #BizDoc B WHERE B.BizDocId_CR = sc.BizDocId	) ';
    EXECUTE dbo.usp_BizDoc_GetData @_Key = @_Key_BizDoc
                                 , @_CtTmp = N'#BizDocCR'
                                 , @_nUserId = @_nUserId
                                 , @_LangId = @_LangId
                                 , @_BranchCode = @_BranchCode
                                 , @_PrintExec = 0
                                 , @_BranchReportId = @_BranchReportId
                                 , @_UsingDateKey = 0;
    UPDATE biz
    SET biz.DocNo_CR = bdc.DocNo
      , biz.AmountPayment_CR = bdc.AmountPayment
      , biz.DateDue = DATEADD(DAY, biz.DueDate, biz.DocDate)
      , biz.DocType_CR_Info = CONCAT(cl.Code, ' : ', cl.Name)
    FROM #BizDoc               AS biz
        INNER JOIN #BizDocCR   AS bdc
            ON biz.BizDocId_CR = bdc.BizDocId
        LEFT JOIN dbo.B20Class AS cl
            ON biz.DocType_CR = cl.Code
               AND cl.ParentCode = 'TYPELC';
    SELECT @_Step = N' Bước 1.1: Lấy xong dữ liệu  Hợp đồng tín dụng  (#BizDocCR)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;
    -- ========================================================
    -- 1.2. thu thập dữ liệu chi tiết lãi suất  (#BizDocInterestRate)
    -- ========================================================
    DROP TABLE IF EXISTS #BizDocInterestRate;
    SELECT TOP (0)
           BizDocId
         , EffectiveDate
         , InterestRate
    --,InterestRate AS InterestRate_ByDate
    INTO #BizDocInterestRate
    FROM dbo.B30BizDocInterestRate;
    SELECT @_Key_BizDoc = N'   EXISTS (SELECT * FROM #BizDoc B WHERE B.BizDocId  = sc.BizDocId	) ';
    EXECUTE dbo.usp_BizDoc_GetData @_Key = @_Key_BizDoc
                                 , @_CtTmp = N'#BizDocInterestRate'
                                 , @_nUserId = @_nUserId
                                 , @_LangId = @_LangId
                                 , @_BizDocName = 'dbo.vB30BizDocInterestRate_GetData'
                                 , @_BranchCode = @_BranchCode
                                 , @_BranchReportId = @_BranchReportId
                                 , @_PrintExec = 0
                                 , @_UsingDateKey = 0;
    UPDATE bd
    SET bd.InterestRate = bdir.InterestRate
    FROM #BizDoc AS bd
        OUTER APPLY
    (
        SELECT TOP (1)
               *
        FROM #BizDocInterestRate AS bdir
        WHERE bdir.BizDocId = bd.BizDocId
        ORDER BY EffectiveDate DESC
    )            AS bdir;
    SELECT @_Step = N' Bước 1.2: Lấy xong dữ liệu  chi tiết lãi suất  (#BizDocInterestRate)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;

    -- ========================================================
    -- 1.3. thu thập dữ liệu chi tiết tài khoản  (#BizDocSubAccount)
    -- ========================================================
    DROP TABLE IF EXISTS #BizDocSubAccount;
    SELECT TOP (0)
           BizDocId
         , BizDocId_CR
         , EffectiveDate
         , Account
         , CustomerId
         , BranchCode
         , DocNo
         , DocDate
    --,InterestRate AS InterestRate_ByDate
    INTO #BizDocSubAccount
    FROM dbo.vB30BizDocSubAccount;


    SELECT @_Key = @_Key + N' AND  EXISTS (SELECT * FROM #BizDoc B WHERE B.BizDocId  = sc.BizDocId	) ';
    EXECUTE dbo.usp_BizDoc_GetData @_Key = @_Key
                                 , @_CtTmp = N'#BizDocSubAccount'
                                 , @_nUserId = @_nUserId
                                 , @_LangId = @_LangId
                                 , @_BizDocName = 'dbo.vB30BizDocSubAccount'
                                 , @_BranchCode = @_BranchCode
                                 , @_BranchReportId = @_BranchReportId
                                 , @_PrintExec = 1
                                 , @_UsingDateKey = 0;

    IF @_AccountLevel = 0
        INSERT INTO #BizDoc
        (
            BizDocId
          , EffectiveDate_Account
          , Account
          , CustomerId
          , BranchCode
          , BizDocId_CR
          , DocNo
          , DocDate
        )
        SELECT BizDocId
             , EffectiveDate
             , Account
             , CustomerId
             , BranchCode
             , BizDocId_CR
             , DocNo
             , DocDate
        FROM #BizDocSubAccount AS acc
        WHERE EXISTS
        (
            SELECT *
            FROM #BizDoc AS b
            WHERE acc.Account <> b.Account
                  AND acc.BizDocId = b.BizDocId
        );
        -------------
        ;
    WITH cte
        AS (SELECT BizDocId
                 , Account
                 , EffectiveDate_Account
            FROM #BizDoc)
       , cte_rn
        AS (SELECT cte.BizDocId
                 , cte.Account
                 , cte.EffectiveDate_Account
                 , ROW_NUMBER() OVER (PARTITION BY cte.BizDocId
                                      ORDER BY cte.EffectiveDate_Account ASC
                                             , cte.Account ASC
                                     ) AS _RN
            FROM cte)
    UPDATE b
    SET b._RN = c._RN
    FROM #BizDoc          AS b
        INNER JOIN cte_rn AS c
            ON b.BizDocId = c.BizDocId
               AND b.Account = c.Account
               AND b.EffectiveDate_Account = c.EffectiveDate_Account;

    IF @_AccountLevel = 1
        UPDATE #BizDoc
        SET Account = LEFT(Account, 3);

    SELECT @_Step = N' Bước 1.2: Lấy xong dữ liệu  chi tiết lãi suất  (#BizDocSubAccount)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;

    -- ========================================================
    -- 2. thu thập dữ liệu Đầu kỳ Công nợ theo Khế ước vay #OpenBiz
    -- ========================================================
    DROP TABLE IF EXISTS #OpenBiz;
    SELECT TOP (0)
           Account
         , CustomerId
         , CustomerId0
         , BizDocId
         , DocCode
         , BizDocId       AS BizDocId_LC
         , BizDocId       AS BizDocId_CR
         , BizDocId       AS BizDocId_C1
         , BizDocId       AS BizDocId_C2
         , BizDocId       AS BizDocId_DA
         , BranchCode
         , Amount         AS DebitBiz1
         , Amount         AS CreditBiz1
         , OriginalAmount AS OriginalDebitBiz1
         , OriginalAmount AS OriginalCreditBiz1
         , Stt
         , RowId
         , ProductId
         , ProductCatgId
    INTO #OpenBiz
    FROM dbo.B00CtTmp;
    EXECUTE dbo.usp_sys_DefaultTable @_Table = '#OpenBiz';
    EXECUTE dbo.usp_B30OpenBizDoc_GetData @_DocDate0 = @_DocDate1
                                        , @_Key = @_KeyCd
                                        , @_Key2 = @_Key2
                                        , @_CtTmp = N'#OpenBiz'
                                        , @_nUserId = @_nUserId
                                        , @_LangId = @_LangId
                                        , @_BranchCode = @_BranchCode
                                        , @_CurrencyCode0 = @_CurrencyCode0
                                        , @_BranchReportId = @_BranchReportId
                                        , @_PrintExec = 0;

    IF @_AccountLevel = 1
        UPDATE #OpenBiz
        SET Account = LEFT(Account, 3);
    SELECT @_Step = N' Bước 2: Lấy xong dữ liệu Đầu kỳ Công nợ theo Khế ước vay (#OpenBiz)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;

    -- ========================================================
    -- 3. thu thập dữ liệu Phát sinh Công nợ theo Khế ước vay #K_CtTmp
    -- ========================================================
    DROP TABLE IF EXISTS #K_CtTmp;
    SELECT TOP (0)
           bct.Account
         , bct.DebitAccount
         , bct.CreditAccount
         , bct.CustomerId
         , CAST(NULL AS INT)         AS CustomerId0
         , bct.BranchCode
         , bct.DocCode
         , bct.DocDate
         , bct.DocNo
         , bct.BizDocId
         , bct.BizDocId              AS BizDocId_LC
         , bct.BizDocId              AS BizDocId_C1
         , bct.BizDocId_C2
         , bct.BizDocId              AS BizDocId_DA
         --VND
         , CAST(0 AS NUMERIC(18, 2)) AS DebitBiz1
         , CAST(0 AS NUMERIC(18, 2)) AS CreditBiz1
         , CAST(0 AS NUMERIC(18, 2)) AS DebitAmount
         , CAST(0 AS NUMERIC(18, 2)) AS CreditAmount
         , CAST(0 AS NUMERIC(18, 2)) AS DebitBiz2
         , CAST(0 AS NUMERIC(18, 2)) AS CreditBiz2
         --Original
         , CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitBiz1
         , CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditBiz1
         , CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitAmount
         , CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditAmount
         , CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitBiz2
         , CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditBiz2
    INTO #K_CtTmp
    FROM dbo.B00CtTmp AS bct;
    EXECUTE dbo.usp_sys_DefaultTable @_Table = '#K_CtTmp';
    EXECUTE dbo.usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                           , @_DocDate2 = @_DocDate2
                                           , @_Key1 = ''
                                           , @_Key2 = @_Key2
                                           , @_CtTmp = '#K_CtTmp'
                                           , @_nUserId = @_nUserId
                                           , @_LangId = @_LangId
                                           , @_BranchCode = @_BranchCode
                                           , @_CurrencyCode0 = @_CurrencyCode0
                                           , @_BranchReportId = @_BranchReportId
                                           , @_PrintExec = 1;



    IF @_AccountLevel = 1
        UPDATE #K_CtTmp
        SET Account = LEFT(Account, 3);
    SELECT @_Step = N' Bước 3: Lấy xong dữ liệu dữ liệu Phát sinh Công nợ theo Khế ước vay #K_CtTmp';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;

    DELETE #K_CtTmp
    WHERE ABS(DebitAmount) + ABS(CreditAmount) = 0;

    --2026-09-30 => chỉ cập nhật trường hợp trả nợ hạch toán Nợ 341
	--20/01/2026
	;WITH cte
	AS (SELECT DISTINCT
			   BizDocId_LC
			 , DocDate
			 , DebitAccount
		FROM #K_CtTmp AS k
		WHERE k.DebitAccount LIKE '341%')
		, cte_STRING_AGG
	AS (SELECT k.BizDocId_LC,DebitAccount
			 , STRING_AGG(FORMAT(k.DocDate, 'dd/MM/yyyy'), ' ' + CHAR(13) + CHAR(10) + '') WITHIN GROUP (ORDER BY DocDate ASC) AS DocDate
		FROM cte AS k
		GROUP BY BizDocId_LC,DebitAccount)
	UPDATE biz
	SET biz.RepaymentDate = k.DocDate
	FROM #BizDoc AS biz
		OUTER APPLY
	(
		SELECT TOP 1
			   k.BizDocId_LC
			 , k.DocDate
		FROM cte_STRING_AGG AS k
		WHERE (k.BizDocId_LC = biz.BizDocId AND k. DebitAccount = biz.Account)
			  AND _RN = 1
	)            AS k;
 

	--SELECT * FROM #BizDoc RETURN 
    -- ========================================================
    -- 4. insert số Đầu kỳ (#OpenBiz) vào bảng  (#K_CtTmp) 
    -- ========================================================
    INSERT INTO #K_CtTmp
    (
        Account
      , CustomerId
      , BranchCode
      , BizDocId
      , BizDocId_LC
      , BizDocId_C1
      , BizDocId_C2
      , BizDocId_DA
      , DebitBiz1
      , CreditBiz1
      , OriginalDebitBiz1
      , OriginalCreditBiz1
    )
    SELECT Account
         , CustomerId
         , BranchCode
         , BizDocId
         , BizDocId_LC
         , BizDocId_C1
         , BizDocId_C2
         , BizDocId_DA
         , SUM(DebitBiz1)          AS DebitBiz1
         , SUM(CreditBiz1)         AS CreditBiz1
         , SUM(OriginalDebitBiz1)  AS OriginalDebitBiz1
         , SUM(OriginalCreditBiz1) AS OriginalCreditBiz1
    FROM #OpenBiz
    GROUP BY Account
           , CustomerId
           , ProductId
           , ProductCatgId
           , BranchCode
           , BizDocId
           , BizDocId_LC
           , BizDocId_C1
           , BizDocId_C2
           , BizDocId_DA;

    UPDATE #K_CtTmp
    SET #K_CtTmp.BizDocId = CASE
                                WHEN ISNULL(#K_CtTmp.BizDocId_LC, '') <> '' THEN
                                    #K_CtTmp.BizDocId_LC
                                ELSE
                                    #K_CtTmp.BizDocId
                            END;
    UPDATE #K_CtTmp
    SET #K_CtTmp.CustomerId = CASE
                                  WHEN a.CustomerId IS NULL THEN
                                      b.CustomerId
                                  ELSE
                                      a.CustomerId
                              END
      , #K_CtTmp.Account = CASE
                               WHEN a.Account IS NULL THEN
                                   b.Account
                               ELSE
                                   a.Account
                           END
    FROM #K_CtTmp         AS a
        LEFT JOIN #BizDoc AS b
            ON a.BizDocId = b.BizDocId;

    SELECT @_Step = N' Bước 4: xong bước insert số Đầu kỳ (#OpenBiz) vào bảng  (#K_CtTmp) ';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;
    -- ========================================================
    -- 5. insert số Đầu kỳ (#OpenBiz), bảng số Phát sinh (#K_CtTmp)  vào bảng (#K_CtTmp1) 
    -- ========================================================
    DECLARE @_Biz         NUMERIC(18, 5) = 0
          , @_OriginalBiz NUMERIC(18, 5) = 0;
    DROP TABLE IF EXISTS #K_CtTmp1;
    SELECT BranchCode
         , BizDocId                  AS BizDocId
         , CustomerId
         , Account
         , SUM(DebitBiz1)            AS DebitBiz1
         , SUM(CreditBiz1)           AS CreditBiz1
         , SUM(DebitAmount)          AS DebitAmount
         , SUM(CreditAmount)         AS CreditAmount
         , CAST(0 AS NUMERIC(18, 2)) AS DebitBiz2
         , CAST(0 AS NUMERIC(18, 2)) AS CreditBiz2
         , SUM(OriginalDebitBiz1)    AS OriginalDebitBiz1
         , SUM(OriginalCreditBiz1)   AS OriginalCreditBiz1
         , SUM(OriginalDebitAmount)  AS OriginalDebitAmount
         , SUM(OriginalCreditAmount) AS OriginalCreditAmount
         , CAST(0 AS NUMERIC(18, 2)) AS OriginalDebitBiz2
         , CAST(0 AS NUMERIC(18, 2)) AS OriginalCreditBiz2
    --,CAST(0 AS BIT) AS IsGroup
    INTO #K_CtTmp1
    FROM #K_CtTmp
    GROUP BY CustomerId
           , BranchCode
           , Account
           , BizDocId;
    SELECT @_Step
        = N' Bước 5: xong bước insert số Đầu kỳ (#OpenBiz), bảng số Phát sinh (#K_CtTmp)  vào bảng (#K_CtTmp1)  ';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;
    -- ========================================================
    -- 6. Xử lý tính toán số Cuối kỳ = Số đầu kỳ (Nợ - có) + Số phát sinh (Nợ - Có)
    -- ========================================================
    UPDATE #K_CtTmp1
    SET @_Biz = (tb.DebitBiz1 - tb.CreditBiz1) + (tb.DebitAmount - tb.CreditAmount)
      , #K_CtTmp1.DebitBiz2 = IIF(@_Biz >= 0, @_Biz, 0)
      , #K_CtTmp1.CreditBiz2 = IIF(@_Biz >= 0, 0, -@_Biz)
      , @_OriginalBiz = (tb.OriginalDebitBiz1 - tb.OriginalCreditBiz1)
                        + (tb.OriginalDebitAmount - tb.OriginalCreditAmount)
      , #K_CtTmp1.OriginalDebitBiz2 = IIF(@_OriginalBiz >= 0, @_OriginalBiz, 0)
      , #K_CtTmp1.OriginalCreditBiz2 = IIF(@_OriginalBiz >= 0, 0, -@_OriginalBiz)
    FROM #K_CtTmp1 AS tb;
    SELECT @_Step = N' Bước 6: Xử lý tính toán số Cuối kỳ = Số đầu kỳ (Nợ - có) + Số phát sinh (Nợ - Có)';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;
    UPDATE #K_CtTmp1
    SET #K_CtTmp1.DebitBiz1 = CASE
                                  WHEN #K_CtTmp1.DebitBiz1 > #K_CtTmp1.CreditBiz1 THEN
                                      #K_CtTmp1.DebitBiz1 - #K_CtTmp1.CreditBiz1
                                  ELSE
                                      0
                              END
      , #K_CtTmp1.CreditBiz1 = CASE
                                   WHEN #K_CtTmp1.CreditBiz1 > #K_CtTmp1.DebitBiz1 THEN
                                       #K_CtTmp1.CreditBiz1 - #K_CtTmp1.DebitBiz1
                                   ELSE
                                       0
                               END;



    UPDATE #BizDoc
    SET #BizDoc.CustomerCode = dm.Code
      , #BizDoc.CustomerName = dm.Name
    FROM #BizDoc                  AS tb
        LEFT JOIN dbo.B20Customer AS dm WITH (NOLOCK)
            ON tb.CustomerId = dm.Id;


    UPDATE a
    SET
        --Tiền VND
        a.DebitBiz1 = ISNULL(b.DebitBiz1, 0)
      , a.CreditBiz1 = ISNULL(b.CreditBiz1, 0)
      , a.DebitAmount = ISNULL(b.DebitAmount, 0)
      , a.CreditAmount = ISNULL(b.CreditAmount, 0)
      , a.DebitBiz2 = ISNULL(b.DebitBiz2, 0)
      , a.CreditBiz2 = ISNULL(b.CreditBiz2, 0)
      --Tiền nguyên tệ
      , a.OriginalDebitBiz1 = ISNULL(b.OriginalDebitBiz1, 0)
      , a.OriginalCreditBiz1 = ISNULL(b.OriginalCreditBiz1, 0)
      , a.OriginalDebitAmount = ISNULL(b.OriginalDebitAmount, 0)
      , a.OriginalCreditAmount = ISNULL(b.OriginalCreditAmount, 0)
      , a.OriginalDebitBiz2 = ISNULL(b.OriginalDebitBiz2, 0)
      , a.OriginalCreditBiz2 = ISNULL(b.OriginalDebitBiz2, 0)
    FROM #BizDoc            AS a
        LEFT JOIN #K_CtTmp1 AS b
            ON a.BizDocId = b.BizDocId
               AND a.Account = b.Account
               AND a.CustomerId = b.CustomerId;


    -- ========================================================
    -- 7. Xử lý tính toán Trả lãi trong kỳ
    -- ========================================================
    DROP TABLE IF EXISTS #K_Interest;
    SELECT TOP (0)
           CAST(NULL AS INT) AS Id
         , BranchCode
         , DocDate
         , DocNo
         , DocCode
         , DocGroup
         , Stt
         , Account
         , CrspAccount
         , CustomerId
         , CustomerId0
         , BizDocId          AS BizDocId_LC
         , DebitAmount
         , CreditAmount
    INTO #K_Interest
    FROM dbo.B00CtTmp;
    EXECUTE dbo.usp_sys_DefaultTable @_Table = '#K_Interest';
    EXECUTE dbo.usp_B30GeneralLedger_GetData @_DocDate1 = @_DocDate1
                                           , @_DocDate2 = @_DocDate2
                                           , @_Key1 = ''
                                           , @_Key2 = @_Key_Interest
                                           , @_CtTmp = '#K_Interest'
                                           , @_nUserId = @_nUserId
                                           , @_LangId = @_LangId
                                           , @_BranchCode = @_BranchCode
                                           , @_CurrencyCode0 = @_CurrencyCode0
                                           , @_GroupByCols = 'DocDate, DocGroup, DocCode, DocNo, Id, Stt, Account, CustomerId0, CrspAccount,BizDocId_LC'
                                           , @_BranchReportId = @_BranchReportId
                                           , @_NotSumCols = 'ExchangeRate'
                                           , @_PrintExec = 0;

    --SELECT * FROM #K_Interest

    UPDATE a
    SET a.Interest_Payment = ISNULL(b.Interest_Payment, 0)
      , a.InterestDuringThePeriod = ISNULL(b.InterestDuringThePeriod, 0)
    FROM #BizDoc AS a
        LEFT JOIN
        (
            SELECT k.BizDocId_LC
                 , SUM(ISNULL(k.DebitAmount, 0))  AS Interest_Payment
                 , SUM(ISNULL(k.CreditAmount, 0)) AS InterestDuringThePeriod
            FROM #K_Interest AS k
            GROUP BY k.BizDocId_LC
        )        AS b
            ON b.BizDocId_LC = a.BizDocId
               AND _RN = 1;

    UPDATE biz
    SET biz.BranchName = bb.BranchName
      , BranchInfo = CONCAT(biz.BranchCode, ' : ', bb.BranchName)
    FROM #BizDoc                 AS biz
        INNER JOIN dbo.B00Branch AS bb
            ON biz.BranchCode = bb.BranchCode;

    SELECT @_Step = N' Bước 7: Xử lý tính toán số Trả lãi trong kỳ ';
    EXEC dbo.usp_sys_CheckDebugTime @_StepName = @_Step
                                  , @_DebugStepTime = @_DebugStepTime OUTPUT;

    UPDATE biz
    SET biz.DocNo_CR = bdc.DocNo
    FROM #BizDoc             AS biz
        INNER JOIN #BizDocCR AS bdc
            ON biz.BizDocId_CR = bdc.BizDocId
    WHERE _RN <> 1;

    UPDATE biz
    SET biz.AccountName = bdc.Name
    FROM #BizDoc                     AS biz
        LEFT JOIN vB20ChartOfAccount AS bdc
            ON biz.Account = bdc.Code;



    SELECT *
    FROM #BizDoc AS biz
    ORDER BY biz.BranchCode ASC
           , biz.DocDate ASC
           , biz.DocNo ASC
           , biz._RN ASC;

    DROP TABLE IF EXISTS #BizDoc
                       , #K_CtTmp
                       , #K_CtTmp1
                       , #OpenBiz;
    SET @_DebugMsg
        = N'--- TỔNG THỜI GIAN CHẠY SP: ' + CAST(DATEDIFF(ms, @_Time1, GETDATE()) AS VARCHAR) + N' ms ---' + @_nl
          + N'--- TỔNG THỜI GIAN CHẠY SP: ' + CAST(DATEDIFF(ss, @_Time1, GETDATE()) AS VARCHAR) + N' ss ---';
    PRINT @_DebugMsg;
END;
GO

GO


SET DATEFORMAT DMY;
EXEC 


usp_detailed_report_on_outstanding_loans_test @_DocDate1='01/01/2026 00:00:00.000',@_DocDate2='14/10/2026 00:00:00.000',@_DocType_CR='0',@_BizDocId_LC='I112229608LC',@_nUserId=1213,@_LangId=0,@_BranchCode='I25',@_DocCode='LC',@_AccountLevel=0;
