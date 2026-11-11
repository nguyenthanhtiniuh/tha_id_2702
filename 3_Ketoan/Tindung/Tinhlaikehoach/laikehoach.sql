USE B10THACOIDACC
GO
/*
Lấy dữ liệu Lịch trả nợ dự kiến
Chạy thủ tục tính lãi
append vào bảng

*/
SET DATEFORMAT DMY

DECLARE @_DocDate1     DATE       = '01/11/2026 00:00:00.000'
      , @_DocDate2     DATE       = '11/11/2026 00:00:00.000'
      , @_DocDatePlan2 DATE       = '31/12/2027 00:00:00.000'
      , @_BranchCode   VARCHAR(3) = 'I25'

--WHILE EXISTS
--      (
--          SELECT *
--          FROM #BizDoc AS biz
--          WHERE _Check = 0
--                AND EXISTS
--          (
--              SELECT *
--              FROM #BizDocPayment_Plan AS paym
--              WHERE paym.BizDocId = biz.BizDocId
--                    AND paym.BranchCode = biz.BranchCode
--          )
--      )


DECLARE @_DataCode_Tmp VARCHAR(4) = ''

SELECT TOP (1)
       @_DataCode_Tmp = DataCode
FROM dbo.B00Branch
WHERE BranchCode = @_BranchCode

DECLARE @_TableDestination       NVARCHAR(256) = N'B30PlannedCost'
      , @_TableDestinationResult NVARCHAR(256) = N'B30BizDocInterestPlan'

SELECT @_TableDestination       = REPLACE(@_TableDestination, 'B30', 'B3' + @_DataCode_Tmp)
     , @_TableDestinationResult = REPLACE(@_TableDestinationResult, 'B30', 'B3' + @_DataCode_Tmp)

DROP TABLE IF EXISTS #BizDocPayment
SELECT TOP (0)
       BizDocId
     , BuiltinOrder
     , DocDate
     , RowId
     , Description
     , PaymentPercent
     , OriginalAmount
     , Amount
     , EstimatedPaymentDate
     , OriginalPaid
     , Paid
     , IsActive
     , BranchCode
     , CustomerId
     , 0 AS IS_Week
INTO #BizDocPayment
FROM dbo.vB30BizDocPayment_GetData
--SELECT @_Key = N'   EXISTS (SELECT * FROM #BizDoc B WHERE B.BizDocId  = sc.BizDocId	) '
EXECUTE dbo.usp_BizDoc_GetData @_DocDate1 = @_DocDate1
                             , @_DocDate2 = @_DocDatePlan2
                             , @_CtTmp = N'#BizDocPayment'
                             , @_BizDocName = 'dbo.vB30BizDocPayment_GetData'
                             , @_BranchCode = @_BranchCode
                             , @_UsingDateKey = 1
                             , @_DateCol = 'EstimatedPaymentDate'
                             , @_PrintExec = 0

DROP TABLE IF EXISTS #BizDoc
SELECT DISTINCT
       BizDocId
     , BranchCode
     , 0 AS _Check
INTO #BizDoc
FROM #BizDocPayment

DECLARE @_BizDocId_LC_Filter VARCHAR(16) = ''

DECLARE @_BranchCode_Filrer VARCHAR(3) = ''

BEGIN

    SELECT TOP (1)
           @_BizDocId_LC_Filter = BizDocId
         , @_BranchCode_Filrer  = BranchCode
    FROM #BizDoc
    WHERE _Check = 0
    ORDER BY BizDocId ASC

    UPDATE #BizDoc
    SET _Check = 1
    WHERE BizDocId = @_BizDocId_LC_Filter

    DROP TABLE IF EXISTS #BcTmpInterest
    SELECT TOP 0
           BizDocId
         , BuiltinOrder
         , DocDate
         , Date1
         , Date2
         , OpeningAmount
         , OriginalIncreaseAmount
         , OriginalDecreaseAmount
         , InterestRate
         , ClosingAmount
         , NumberOfDaysInterest
         , DaysOfYear
         , InterestAmount
         , IsOpening
         , IsClosing
         , CustomerId
         , IsPlan
    INTO #BcTmpInterest
    FROM B30BizDocInterestPlan

    ALTER TABLE #BcTmpInterest
    ADD IsActive BIT
            DEFAULT 1
      , CreatedBy INT NULL
            DEFAULT-1
      , CreatedAt SMALLDATETIME NULL
            DEFAULT GETUTCDATE()
      , ModifiedBy INT NULL
            DEFAULT-1
      , ModifiedAt SMALLDATETIME NULL
            DEFAULT GETUTCDATE()

    EXEC usp_Kth_DetailLoanInterest @_DocDate1 = @_DocDate1
                                  , @_DocDate2 = @_DocDate2
                                  , @_DocDatePlan2 = @_DocDatePlan2
                                  , @_BizDocId_LC = 'I112229590LC'
                                  , @_BranchCode = 'i25'
                                  , @_IsGetPlan = 1
                                  , @_TableName = '#BcTmpInterest'

    DECLARE @_strExec NVARCHAR(MAX)
        = N' DELETE   ' + @_TableDestinationResult + ' WHERE bizdocid IN ( SELECT bizdocid FROM #BcTmpInterest    ) '
    EXEC (@_strExec)
    EXECUTE dbo.usp_sys_Append @_TableSource = N'#BcTmpInterest'
                             , @_TableDestination = @_TableDestinationResult

    SELECT @_strExec = N' SELECT * FROM  ' + @_TableDestinationResult + ''
    EXEC (@_strExec)

END