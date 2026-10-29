USE B10THACOIDACC;
GO
--hàm l?y d? li?u c? c?a các ??n v? Industries ?ang s? d?ng B10
CREATE OR ALTER PROC usp_Get_QPBH_CPQL_B7_IND
    @_Account NVARCHAR(24) = '642'
  , @_DocDate1 DATE = ''
  , @_DocDate2 DATE = ''
  , @_StrTime NVARCHAR(128) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @_DocDate1 = ''
       AND @_DocDate2 = ''
        RETURN;

    DECLARE @_Time1 DATETIME = GETUTCDATE()
          , @_Time2 DATETIME;
    DECLARE @_branch_B7 NVARCHAR(3) = '';
    DECLARE @_branch_B10 NVARCHAR(3) = '';



    DECLARE @_ExpenditureType VARCHAR(24);

    DROP TABLE IF EXISTS #tableName;

    CREATE TABLE #tableName
    (
        BranchCodeB10 VARCHAR(512)
      , BranchCodeB7 VARCHAR(512)
    );

    INSERT INTO #tableName
    (
        BranchCodeB10
      , BranchCodeB7
    )
    VALUES
    ('I01', 'B77')
  , ('I02', 'A33')
  , ('I04', 'A65')
  , ('I08', 'A81')
  , ('I09', 'A93')
  , ('I10', 'B06')
  , ('I11', 'B09')
  , ('I12', 'B10')
  , ('I14', 'B18')
  , ('I15', 'B20')
  , ('I17', 'B66')
  , ('I19', 'B83')
  , ('I20', 'B85')
  , ('I21', 'C01')
  , ('I22', 'C02')
  , ('I23', 'C04')
  , ('I24', 'C09')
  , ('I25', 'C20')
  , ('I26', 'C23')
  , ('I27', 'C26')
  , ('I30', 'C39');

    DROP TABLE IF EXISTS #T_Dvcs_B7;
    SELECT BranchCodeB10
         , BranchCodeB7
    INTO #T_Dvcs_B7
    FROM #tableName;



    WHILE EXISTS (SELECT * FROM #T_Dvcs_B7)
    BEGIN

        SELECT TOP (1)
               @_branch_B7  = BranchCodeB7
             , @_branch_B10 = BranchCodeB10
        FROM #T_Dvcs_B7
        ORDER BY BranchCodeB7 ASC;

        --Bi?n scope => tùy ch?nh trong vòng l?p
        DECLARE @_DocDate_Filter DATE = '';
        DECLARE @_DocDate1_Filter DATE = '';
        DECLARE @_DocDate2_Filter DATE = '';

        DROP TABLE IF EXISTS #T_Date;
        WITH cte
        AS (SELECT EOMONTH(@_DocDate1) AS DocDate
            UNION ALL
            SELECT EOMONTH(DATEADD(MONTH, 1, DocDate))
            FROM cte
            WHERE EOMONTH(DATEADD(MONTH, 1, DocDate)) <= EOMONTH(@_DocDate2))
        SELECT DocDate
             , '' AS Tinh
        INTO #T_Date
        FROM cte
        OPTION (MAXRECURSION 0);

        --ch? l?y d? li?u t?i tháng tr??c tháng hi?n t?i
        DELETE #T_Date
        WHERE DocDate >= EOMONTH(GETDATE());

        SELECT TOP 1
               @_ExpenditureType = Code
        FROM B10THACOID_Data.dbo.b20class
        WHERE ParentCode = 'ExpenditureType'
              AND LEFT(ValueCol, 3) = @_Account;

        DECLARE @_jsonData NVARCHAR(MAX) = NULL;

        WHILE EXISTS (SELECT * FROM #T_Date)
        BEGIN

            SELECT @_DocDate_Filter = '';

            SELECT TOP (1)
                   @_DocDate_Filter = DocDate
            FROM #T_Date
            ORDER BY DocDate ASC;

            DELETE #T_Date
            WHERE DocDate = @_DocDate_Filter;

            SELECT @_DocDate2_Filter = ''
                 , @_DocDate1_Filter = '';

            SELECT @_DocDate2_Filter = EOMONTH(@_DocDate_Filter);

            SELECT @_DocDate1_Filter = DATEFROMPARTS(YEAR(@_DocDate2_Filter), MONTH(@_DocDate2_Filter), '01');


            SET DATEFORMAT DMY;

            SELECT @_jsonData = '';

            DECLARE @TjsonData TABLE
            (
                jsonData NVARCHAR(MAX)
            );

            --INSERT INTO #T_Chiphi_B7
            INSERT INTO @TjsonData
            (
                jsonData
            )
            EXEC TO101_B7ACC.B7_THACO.dbo.usp_Kct_BangKeChungTuTheoTieuKhoan_inherit @_DocDate1 = @_DocDate1_Filter
                                                                                   , @_DocDate2 = @_DocDate2_Filter
                                                                                   , @_Account = '642'
                                                                                   , @_Not_CrspAccountList = '911'
                                                                                   , @_AccountSide = '*'
                                                                                   , @_nUserId = 8749
                                                                                   , @_LangId = 0
                                                                                   , @_CurrencyCode0 = 'VND'
                                                                                   , @_Ma_Dvcs = @_branch_B7;

            SELECT TOP 1
                   @_jsonData = jsonData
            FROM @TjsonData;

            DELETE @TjsonData
            WHERE jsonData <> '';

            DROP TABLE IF EXISTS #T_Chiphi_B7;
            ;
            WITH Cte
            AS (SELECT *
                FROM
                    OPENJSON(@_jsonData)
                    WITH
                    (
                        Id INT
                      , DocDate DATE
                      , Status NVARCHAR(1)
                      , DocNo NVARCHAR(24)
                      , DocGroup CHAR(1)
                      , DocCode CHAR(5)
                      , Description NVARCHAR(4000)
                      , Account NVARCHAR(24)
                      , AccountName NVARCHAR(4000)
                      , CrspAccount NVARCHAR(24)
                      , CustomerCode0 NVARCHAR(24)
                      , Person NVARCHAR(4000)
                      , CurrencyCode NCHAR(3)
                      , ExchangeRate DECIMAL(15, 5)
                      , DebitAmount DECIMAL(38, 2)
                      , CreditAmount DECIMAL(38, 2)
                      , OriginalDebitAmount DECIMAL(38, 2)
                      , OriginalCreditAmount DECIMAL(38, 2)
                      , Line NVARCHAR(4000)
                      , Stt VARCHAR(24)
                      , RowId VARCHAR(24)
                      , DocNo_Debit NVARCHAR(4000)
                      , DocNo_Credit NVARCHAR(4000)
                      , _FormatStyleKey VARCHAR(4)
                      , _Status NVARCHAR(1)
                      , _Account NVARCHAR(24)
                      , ExpenseCatgCode NVARCHAR(24)
                    ))
            SELECT Cte.*
            INTO #T_Chiphi_B7
            FROM Cte;

            DELETE B40GeneralLedgerConsol
            WHERE BranchCode = @_branch_B10
                  AND
                  (
                      DocDate1 = @_DocDate1_Filter
                      AND DocDate2 = @_DocDate2_Filter
                  );

            ALTER TABLE #T_Chiphi_B7
            ADD CreatedAt SMALLDATETIME
              , DataSourceVer VARCHAR(24)
              , DocDate1 DATE
              , DocDate2 DATE
              , IsActive INT
                    DEFAULT 1
              , BranchCode VARCHAR(3)
              , ExpenditureType VARCHAR(24);

            EXEC usp_sys_CreateTable @_Table = '#T_Chiphi_B7'
                                   , @_BaseTable = 'B40AssetSummary';


            ALTER TABLE #T_Chiphi_B7 DROP COLUMN Id;

            UPDATE #T_Chiphi_B7
            SET CreatedAt = GETUTCDATE()
              , DataSourceVer = 'B7'
              , DocDate1 = @_DocDate1_Filter
              , DocDate2 = @_DocDate2_Filter
              , IsActive = 1
              , BranchCode = @_branch_B10
              , ExpenditureType = @_ExpenditureType;



            EXEC dbo.usp_sys_Append @_TableSource = '#T_Chiphi_B7'
                                  , @_TableDestination = 'B40GeneralLedgerConsol';


            SELECT *
            FROM B40GeneralLedgerConsol
            WHERE BranchCode = @_branch_B10
                  AND
                  (
                      DocDate1 = @_DocDate1_Filter
                      AND DocDate2 = @_DocDate2_Filter
                  );


            TRUNCATE TABLE #T_Chiphi_B7;
            DROP TABLE IF EXISTS #T_Chiphi_B7;

        END;
        DELETE #T_Dvcs_B7
        WHERE BranchCodeB7 = @_branch_B7;
    END;

    DROP TABLE IF EXISTS #T_Chiphi_B7
                       , #T_Date
                       , #T_Dvcs_B7;

    SELECT @_Time2 = GETUTCDATE();
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, @_Time2))); --
    SELECT @_StrTime;
END;
GO

--

EXEC usp_Get_QPBH_CPQL_B7_IND @_DocDate1 = '20250101'
                            , @_DocDate2 = '20251231';