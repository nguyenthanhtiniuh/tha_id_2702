/*
Get dữ liệu 641,642 cho các đơn vị B10
*/

USE B10THACOIDACC
GO

CREATE OR ALTER PROC usp_Get_QPBH_CPQL
    @_LstBranchCodeB10 NVARCHAR(MAX) = 'I01'
  , @_Account NVARCHAR(24) = '641'
  , @_DocDate1 DATE = ''
  , @_DocDate2 DATE = ''
  , @_StrTime NVARCHAR(128) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    IF @_DocDate1 = ''
       AND @_DocDate2 = ''
        RETURN

    DECLARE @_Time1 DATETIME = GETUTCDATE()
          , @_Time2 DATETIME

    -- => Nhập mã đơn vị  
    DROP TABLE IF EXISTS #T_Dvcs_B10
    SELECT BranchCode
    INTO #T_Dvcs_B10
    FROM dbo.B00Branch
    WHERE BranchCode IN
          (
              SELECT * FROM STRING_SPLIT(@_LstBranchCodeB10, ',')
          )

    DECLARE @_ExpenditureType VARCHAR(24)

    WHILE EXISTS (SELECT * FROM #T_Dvcs_B10)
    BEGIN

        DROP TABLE IF EXISTS #T_Date;
        WITH cte
        AS (SELECT EOMONTH(@_DocDate1) AS DocDate
            UNION ALL
            SELECT EOMONTH(DATEADD(MONTH, 1, DocDate))
            FROM cte
            WHERE EOMONTH(DATEADD(MONTH, 1, DocDate)) <= EOMONTH(@_DocDate2))
        SELECT DocDate
        INTO #T_Date
        FROM cte
        OPTION (MAXRECURSION 0);

        --chỉ lấy dữ liệu tới tháng trước tháng hiện tại
        DELETE #T_Date
        WHERE DocDate >= EOMONTH(GETDATE())

        --Biển scope => tùy chỉnh trong vòng lặp
        DECLARE @_DocDate1_Filter DATE = ''
        DECLARE @_DocDate2_Filter DATE = ''
        DECLARE @_DocDate_Filter    DATE = ''
              , @_BranchCode_Filter NVARCHAR(3)

        SELECT TOP (1)
               @_BranchCode_Filter = BranchCode
        FROM #T_Dvcs_B10
        ORDER BY BranchCode ASC

        DROP TABLE IF EXISTS #T_Get64
        CREATE TABLE #T_Get64
        (
            Id INT
          , CreatedAt SMALLDATETIME
          , DataSourceVer VARCHAR(24)
          , DocDate1 DATE
          , DocDate2 DATE
          , IsActive INT
                DEFAULT 1
          , BranchCode VARCHAR(3)
          , ExpenditureType VARCHAR(24)
        )

        SELECT TOP 1
               @_ExpenditureType = Code
        FROM B10THACOID_Data.dbo.b20class
        WHERE ParentCode = 'ExpenditureType'
              AND LEFT(ValueCol, 3) = @_Account


        WHILE EXISTS (SELECT * FROM #T_Date)
        BEGIN

            SELECT @_DocDate_Filter = ''
            SELECT TOP (1)
                   @_DocDate_Filter = DocDate
            FROM #T_Date
            ORDER BY DocDate ASC

            SELECT @_DocDate2_Filter = EOMONTH(@_DocDate_Filter)
            SELECT @_DocDate1_Filter = DATEFROMPARTS(YEAR(@_DocDate2_Filter), MONTH(@_DocDate2_Filter), '01')

            SET DATEFORMAT DMY
            EXEC usp_Kct_TransactionListBySubAccount @_DocDate1 = @_DocDate1_Filter
                                                   , @_DocDate2 = @_DocDate2_Filter
                                                   , @_Account = @_Account
                                                   , @_ExcludeCrspAccount = '911'
                                                   , @_nUserId = 1213
                                                   , @_LangId = 0
                                                   , @_BranchCode = @_BranchCode_Filter
                                                   --  , @_StrTime = '00:00:00'
                                                   , @_CtTmp = '#T_Get64'

            -----------------
            EXEC usp_sys_CreateTable @_Table = '#T_Get64'
                                   , @_BaseTable = 'B40GeneralLedgerConsol'

            UPDATE #T_Get64
            SET CreatedAt = GETUTCDATE()
              , DataSourceVer = 'B10'
              , DocDate1 = @_DocDate1_Filter
              , DocDate2 = @_DocDate2_Filter
              , IsActive = 1
              , BranchCode = @_BranchCode_Filter
              , ExpenditureType = @_ExpenditureType

            DELETE B40GeneralLedgerConsol
            WHERE BranchCode = @_BranchCode_Filter
                  AND LEFT(Account, 3) = @_Account
                  AND
                  (
                      DocDate1 = @_DocDate1_Filter
                      AND DocDate2 = @_DocDate2_Filter
                  )
            -----
            EXEC dbo.usp_sys_Append @_TableSource = '#T_Get64'                    -- nvarchar(128)
                                  , @_TableDestination = 'B40GeneralLedgerConsol' -- nvarchar(128)

            TRUNCATE TABLE #T_Get64

            DELETE #T_Date
            WHERE DocDate = @_DocDate_Filter

            SELECT *
            FROM B40GeneralLedgerConsol
            WHERE BranchCode = @_BranchCode_Filter
                  AND LEFT(Account, 3) = @_Account
                  AND
                  (
                      DocDate1 = @_DocDate1_Filter
                      AND DocDate2 = @_DocDate2_Filter
                  )
        END

        DELETE #T_Dvcs_B10
        WHERE BranchCode = @_BranchCode_Filter
    END

    DROP TABLE #T_Get64
             , #T_Date
             , #T_Dvcs_B10

    SELECT @_Time2 = GETUTCDATE()
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, @_Time2))) --
    SELECT @_StrTime
END

GO
SET DATEFORMAT DMY
EXEC usp_Get_QPBH_CPQL @_DocDate1 = '01/01/2026 00:00:00.000'
                     , @_DocDate2 = '31/08/2026 00:00:00.000'
                     , @_LstBranchCodeB10 = 'I01,I02,I04,I08,I09,I10,I11,I12,I14,I15,I17,I19,I20,I21,I22,I23,I24,I25,I26,I27,I29,I30'
                     --, @_LstBranchCodeB10 = 'I09'
                     , @_Account = '642'
--, @_LstBranchCodeB7 = 'A46'

