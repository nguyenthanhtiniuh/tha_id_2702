USE B10THACOIDACC
GO

CREATE OR ALTER PROC usp_GetAssetSummaryB7
    @_LstBranchCodeB7 NVARCHAR(MAX) = 'A46,A70,A74,B13,B27,B73'
  , @_DocDate1 DATE
  , @_DocDate2 DATE
  , @_StrTime NVARCHAR(128) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @_Time1 DATETIME = GETDATE()
          , @_Time2 DATETIME
    DECLARE @_branch_B7 NVARCHAR(3) = ''

    DROP TABLE IF EXISTS #T_Dvcs_B7
    SELECT value AS BranchCode
    INTO #T_Dvcs_B7
    FROM STRING_SPLIT(@_LstBranchCodeB7, ',')

    WHILE EXISTS (SELECT * FROM #T_Dvcs_B7)
    BEGIN

        SELECT TOP 1
               @_branch_B7 = BranchCode
        FROM #T_Dvcs_B7
        ORDER BY BranchCode ASC

        --Biển scope => tùy chỉnh trong vòng lặp
        DECLARE @_DocDate_Filter DATE = ''
        DECLARE @_DocDate1_Filter DATE = ''
        DECLARE @_DocDate2_Filter DATE = ''

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

        --chỉ lấy dữ liệu tới tháng trước tháng hiện tại
        DELETE #T_Date
        WHERE DocDate >= EOMONTH(GETDATE())

        WHILE EXISTS (SELECT * FROM #T_Date)
        BEGIN

            SELECT @_DocDate_Filter = ''

            SELECT TOP (1)
                   @_DocDate_Filter = DocDate
            FROM #T_Date
            ORDER BY DocDate ASC

            DELETE #T_Date
            WHERE DocDate = @_DocDate_Filter

            DROP TABLE IF EXISTS #T_B7
            CREATE TABLE #T_B7
            (
                Id INT
              , Id0 INT
            )

            EXEC usp_sys_CreateTable @_Table = '#T_B7'
                                   , @_BaseTable = 'B40AssetSummary'

            ALTER TABLE #T_B7 DROP COLUMN Id0

            SELECT @_DocDate2_Filter = ''
                 , @_DocDate1_Filter = ''

            SELECT @_DocDate2_Filter = EOMONTH(@_DocDate_Filter)

            SELECT @_DocDate1_Filter = DATEFROMPARTS(YEAR(@_DocDate2_Filter), MONTH(@_DocDate2_Filter), '01')

            --INSERT INTO #T_B7
            --EXEC TO101_B7ACC.B7_THACO.dbo.usp_Tth_AssetSummaryTable_inherit @_DocDate1 = @_DocDate1_Filter
            --                                                              , @_DocDate2 = @_DocDate2_Filter
            --                                                              , @_BranchCode = @_branch_B7

            DELETE B40AssetSummary
            WHERE BranchCode = @_branch_B7
                  AND
                  (
                      DocDate1 = @_DocDate1_Filter
                      AND DocDate2 = @_DocDate2_Filter
                  )

            SELECT @_branch_B7
                 , @_DocDate1
                 , @_DocDate2

            EXEC dbo.usp_sys_Append @_TableSource = '#T_B7'
                                  , @_TableDestination = 'B40AssetSummary'
            TRUNCATE TABLE #T_B7



            DROP TABLE IF EXISTS #T_B7

        END
        DELETE #T_Dvcs_B7
        WHERE BranchCode = @_branch_B7
    END

    DROP TABLE IF EXISTS #T_B7
                       , #T_Date
                       , #T_Dvcs_B7
    SET @_StrTime = RTRIM(LTRIM(dbo.ufn_sys_StrExcuteTime(@_Time1, @_Time2))) --
    SELECT @_StrTime
END