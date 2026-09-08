SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
#CPBH
B30PlannedSellExpenses
B30PlannedSellExpensesResult

#CPQL
B30PlannedAdExpenses
B30PlannedAdExpensesResult

*/
CREATE OR ALTER PROCEDURE dbo.usp_B30PlannedAdExpenses_CalculateAndSavePlanned
    @_DocDate AS DATE = '20260301'
  , @_Year AS VARCHAR(4) = '2026'
  , @_Account VARCHAR(24) = ''
  , @_ItemId AS VARCHAR(512) = ''
  , @_nUserId AS INT = -1
  , @_LangId TINYINT = 0
  , @_BranchCode AS VARCHAR(3) = ''
  , @_BizDocId AS VARCHAR(16) = ''
  , @_DataXML XML = NULL
  , @_SelectExec INT = 0
  , @_Import_Product_New INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET @_nUserId = dbo.ufn_sys_GetValueFromAppName('UserId', @_nUserId)
    DECLARE @_SOMONTH DATE = DATEFROMPARTS(YEAR(@_DocDate), MONTH(@_DocDate), '01')
    DECLARE @_EOMONTH DATE = EOMONTH(@_SOMONTH)
    IF CAST(@_DataXML AS NVARCHAR(MAX)) = ''
        RETURN

    DECLARE @_strExec NVARCHAR(MAX)
    DECLARE @_Key NVARCHAR(MAX) = N''
    DECLARE @_MoneyType    AS dbo.MoneyType = 0
          , @_QuantityType dbo.QuantityType = 0
          , @_TINYINTType  TINYINT          = 0
          , @_INTType      INT              = 0
          , @_CodeType     VARCHAR(24)      = ''
          , @_BizDocIdType VARCHAR(16)      = ''
          , @_NameType     NVARCHAR(256)    = N''
          , @_DataCode_Tmp VARCHAR(8)       = ''

    SELECT TOP (1)
           @_DataCode_Tmp = DataCode
    FROM dbo.B00Branch
    WHERE BranchCode = @_BranchCode

    DROP TABLE IF EXISTS #PlannedAdExpensesResult
    SELECT TOP 0
           @_DocDate                 AS DocDate
         , @_Account                 AS Account
         , ExpenseCatgId
         , CAST(0 AS NUMERIC(18, 2)) AS AVG_Cost
         , CAST(0 AS NUMERIC(18, 2)) AS Amount
    INTO #PlannedAdExpensesResult
    FROM dbo.B00CtTmp

    --EXEC sp_help [usp_B30FinPlanDetail_PlannedOutputDetermination];
    --2026-08-09 lấy dữ liệu sản lượng kế hoạch từ Kế hoạch doanh thu
    EXEC usp_KTH10_v2 @_DocDate = @_DocDate
                    , @_nUserId = @_nUserId
                    , @_LangId = @_LangId
                    , @_BranchCode = @_BranchCode
                    , @_tblOutput = '#PlannedAdExpensesResult'
                    , @_ExpenseAccount = @_Account

    EXEC dbo.usp_sys_CreateTable @_Table = '#PlannedAdExpensesResult'
                               , @_BaseTable = 'B30PlannedCostResult'

    UPDATE #PlannedAdExpensesResult
    SET Amount = ISNULL(AVG_Cost, 0)
      , Account = @_Account
      , DocDate = @_DocDate

    UPDATE #PlannedAdExpensesResult
    SET BranchCode = @_BranchCode
      , FiscalYear = @_Year
      , DocDate = @_SOMONTH
      , CreatedBy = @_nUserId
      , CreatedAt = GETUTCDATE()
      , ModifiedBy = -1
      , ModifiedAt = GETUTCDATE()
      , IsActive = 1
      , ParentId = -1
      , IsGroup = 0

    CREATE TABLE #PlannedAdExpenses
    (
        BranchCode CHAR(3) NOT NULL
      , FiscalYear VARCHAR(4) NOT NULL
      , DocDate DATE NOT NULL
      , DocNo NVARCHAR(64) NOT NULL
      , Account VARCHAR(24) NOT NULL
      , IsActive BIT NULL
            DEFAULT 1
      , CreatedBy INT NULL
      , CreatedAt SMALLDATETIME NULL
      , ModifiedBy INT NULL
      , ModifiedAt SMALLDATETIME NULL
    )

    INSERT INTO #PlannedAdExpenses
    (
        BranchCode
      , FiscalYear
      , DocDate
      , DocNo
      , Account
    )
    SELECT BranchCode
         , FiscalYear
         , DocDate
         , 'KHCPQL' + FORMAT(@_DocDate, 'dd-MM-yyyy') + '' AS DocNo
         , Account
    FROM #PlannedAdExpensesResult
    GROUP BY BranchCode
           , FiscalYear
           , DocDate
           , Account

    UPDATE #PlannedAdExpenses
    SET CreatedBy = @_nUserId
      , CreatedAt = GETUTCDATE()
      , ModifiedBy = -1
      , ModifiedAt = GETUTCDATE()



    /*
B30PlannedAdExpenses
B30PlannedAdExpensesResult
    
    */

    DECLARE @_TableDestination       NVARCHAR(256) = N'B30PlannedAdExpenses'
          , @_TableDestinationResult NVARCHAR(256) = N'B30PlannedAdExpensesResult'

    SELECT @_TableDestination       = REPLACE(@_TableDestination, 'B30', 'B3' + @_DataCode_Tmp)
         , @_TableDestinationResult = REPLACE(@_TableDestinationResult, 'B30', 'B3' + @_DataCode_Tmp)




    SELECT @_strExec
        = N' DELETE ' + @_TableDestination + N' WHERE DocDate = ''' + CAST(@_SOMONTH AS VARCHAR(11))
          + N'''  AND  Account IN ( SELECT Account FROM #PlannedAdExpenses  )    '
    EXEC (@_strExec)
    EXECUTE dbo.usp_sys_Append @_TableSource = N'#PlannedAdExpenses'
                             , @_TableDestination = @_TableDestination


    SELECT @_strExec
        = N' DELETE ' + @_TableDestinationResult + N' WHERE DocDate = ''' + CAST(@_SOMONTH AS VARCHAR(11))
          + N'''  AND Account IN ( SELECT Account FROM #PlannedAdExpensesResult  )'
    EXEC (@_strExec)
    EXECUTE dbo.usp_sys_Append @_TableSource = N'#PlannedAdExpensesResult'
                             , @_TableDestination = @_TableDestinationResult

    SELECT @_strExec
        = N'   
				SELECT pc.*	 
							,CreatedBy.FullName AS CreatedName
							,ModifiedBy.FullName AS ModifiedName								
					FROM  ' + @_TableDestination
          + N' PC 						 
						 LEFT JOIN dbo.B00UserList AS CreatedBy WITH (NOLOCK) ON PC.CreatedBy = CreatedBy.Id
						 LEFT JOIN dbo.B00UserList AS ModifiedBy WITH (NOLOCK) ON PC.ModifiedBy = ModifiedBy.Id
							WHERE DocDate = ''' + CAST(@_SOMONTH AS VARCHAR(11)) + N'''   ORDER BY PC.Id ASC  '

    SELECT @_strExec
        = @_strExec
          + N'  
				SELECT PCR.* 
									,CreatedBy.FullName AS CreatedName
									,ModifiedBy.FullName AS ModifiedName
									, ExpenseCatg.Code    AS ExpenseCatgCode
									, ExpenseCatg.Name    AS ExpenseCatgName
					FROM  ' + @_TableDestinationResult
          + N' PCR 					 
						 LEFT JOIN dbo.B00UserList AS CreatedBy WITH (NOLOCK) ON PCR.CreatedBy = CreatedBy.Id
						 LEFT JOIN dbo.B00UserList AS ModifiedBy WITH (NOLOCK) ON PCR.ModifiedBy = ModifiedBy.Id
						  LEFT JOIN vB20ExpenseCatg_Lookup AS ExpenseCatg WITH (NOLOCK)
							ON PCR.ExpenseCatgId = ExpenseCatg.Id
							WHERE DocDate = ''' + CAST(@_SOMONTH AS VARCHAR(11)) + N'''   ORDER BY PCR.Id ASC '

    IF @_SelectExec = 1
    BEGIN
        EXEC (@_strExec)
    END

    _End:
    DROP TABLE IF EXISTS #PlannedAdExpenses
                       , #PlannedAdExpensesResult
END
GO


GO


SET DATEFORMAT DMY
EXEC usp_B30PlannedAdExpenses_CalculateAndSavePlanned @_DocDate = '20260801'
                                                    , @_Year = '2026'
                                                    , @_Account = '642'
                                                    , @_BranchCode = 'I09'
                                                    , @_nUserId = 1213
                                                    , @_SelectExec = 1
