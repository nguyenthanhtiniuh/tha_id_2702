DECLARE @_lst_branch_B7 NVARCHAR(MAX) = ''
DECLARE @_branch_B7 NVARCHAR(3) = ''
DECLARE @_DocDate DATE
DECLARE @_DocDate1 DATE
DECLARE @_DocDate2 DATE

---
-- => Nhập mã đơn vị
--SELECT * FROM b20dmsroute
SELECT @_lst_branch_B7 = STRING_AGG(BranchCode, ',')
FROM dbo.B00Branch
WHERE BranchCode NOT IN ( 'I00', 'T00', 'I99' )

--SELECT @_lst_branch_B7 = 'A46'

--
-- => Nhập tháng muốn lấy dữ liệu
SELECT @_DocDate = '20260601'

---
SELECT @_DocDate2 = EOMONTH(@_DocDate)
SELECT @_DocDate1 = DATEFROMPARTS(YEAR(@_DocDate2), MONTH(@_DocDate2), '01')
---
DROP TABLE IF EXISTS #T_Dvcs_B7
SELECT value AS BranchCode
INTO #T_Dvcs_B7
FROM STRING_SPLIT(@_lst_branch_B7, ',')
WHILE EXISTS (SELECT * FROM #T_Dvcs_B7)
BEGIN
    SELECT TOP 1
           @_branch_B7 = BranchCode
    FROM #T_Dvcs_B7
    ORDER BY BranchCode ASC
    DROP TABLE IF EXISTS #temptable
    CREATE TABLE #temptable
    (
        Id INT
      , AssetId INT
      , EquityId INT
      , AssetCode VARCHAR(24)
      , AssetName NVARCHAR(192)
      , AssetAccount VARCHAR(24)
      , DeptId INT
      , DeptCode VARCHAR(24)
      , TerritoryId INT
      , TerritoryCode VARCHAR(24)
      , TerritoryName VARCHAR(24)
      , BranchCode VARCHAR(8)
      , Quantity DECIMAL(38, 2)
      , OriginalCost1 DECIMAL(18, 2)
      , Depreciation1 DECIMAL(18, 2)
      , NetBookValue1 DECIMAL(18, 2)
      , Depreciation_Tk DECIMAL(18, 2)
      , Depreciation DECIMAL(18, 2)
      , IncreaseDeprAmount DECIMAL(18, 2)
      , OriginalCost2 DECIMAL(18, 2)
      , Depreciation2 DECIMAL(18, 2)
      , NetBookValue2 DECIMAL(18, 2)
      , Level TINYINT
      , Bold CHAR(1)
      , IsGroup TINYINT
      , ParentId INT
      , ParentCode NVARCHAR(24)
      , FirstDeprDate DATE
      , SoThangDaKhauHao INT
      , SoThangConLai INT
      , DocDate DATE
      , Unit NVARCHAR(24)
      , _FormatStyleKey NVARCHAR(64)
      , _ParentIdList NVARCHAR(64)
      , _GroupOrder VARCHAR(MAX)
      , Order1 INT
      , Id_Tree INT
      , ParentId_Tree INT
      , UsefulMonth INT
      , ProductionCapacity DECIMAL(15, 2)
      , IncreaseOriginalCost DECIMAL(18, 2)
      , DecreaseOriginalCost DECIMAL(18, 2)
      , IncreaseDepreciation DECIMAL(18, 2)
      , DecreaseDepreciation DECIMAL(18, 2)
      , ExpenseCatgId INT
      , ProfitCenterId INT
      , RouteCode NVARCHAR(56)
      , DeprDebitAccount VARCHAR(24)
      , DeprCreditAccount VARCHAR(24)
      , DeprRuleId INT
      , DeprRuleCode VARCHAR(24)
      , ExpenseCatgCode NVARCHAR(156)
      , ProfitCenterCode NVARCHAR(156)
      , Comment NVARCHAR(512)
      , StageId INT
      , ProductId INT
      , ProductCode NVARCHAR(24)
      , ProductName NVARCHAR(256)
      , BizDocId_C2 VARCHAR(16)
      , StageCode NVARCHAR(24)
      , StageName NVARCHAR(256)
      , AssetCodeB7 VARCHAR(24)
      , ProductCodeList NVARCHAR(MAX)
      , DocNo_C2 NVARCHAR(64)
      , DeprCapacity INT
      , FirstUsedDate DATE
      , DeprMethod TINYINT
      , QuantityCapacityThisPeriod DECIMAL(15, 2)
      , ClassCode1 VARCHAR(24)
      , ClassCode1Name NVARCHAR(256)
      , AssetTransId INT
      , AssetTransCode VARCHAR(24)
      , UsefulMonthbd DECIMAL(18, 0)
    )
    SET DATEFORMAT DMY
    INSERT INTO #temptable
    EXEC usp_Tth_AssetSummaryTable @_DocDate1 = @_DocDate1
                                 , @_DocDate2 = @_DocDate2
                                 , @_AssetAccount = '2112'
                                 , @_ShownIncreaseDeprColumn = 0
                                 , @_GroupByExprs = ''
                                 , @_nUserId = 1213
                                 , @_LangId = 0
                                 , @_BranchCode = @_branch_B7
                                 , @_CurrencyCode0 = 'VND'
                                 , @_ProductionCapacityVisible = 1
    ALTER TABLE #temptable
    ADD DataSourceVer NVARCHAR(24)
      , DocDate1 DATE
      , DocDate2 DATE
      , CreatedAt SMALLDATETIME
      , CreatedBy INT
      , ModifiedBy INT
      , ModifiedAt SMALLDATETIME


    UPDATE #temptable
    SET DataSourceVer = 'B10'
      , DocDate1 = @_DocDate1
      , DocDate2 = @_DocDate2
      , CreatedAt = GETUTCDATE()
      , CreatedBy = -1
      , ModifiedAt = GETUTCDATE()
      , ModifiedBy = -1



    DELETE B40AssetSummary
    WHERE BranchCode = @_branch_B7
          AND
          (
              DocDate1 = @_DocDate1
              AND DocDate2 = @_DocDate2
          )
    EXEC dbo.usp_sys_Append @_TableSource = '#temptable'           -- nvarchar(128)
                          , @_TableDestination = 'B40AssetSummary' -- nvarchar(128)
    SELECT *
    FROM B40AssetSummary
    WHERE BranchCode = @_branch_B7
          AND
          (
              DocDate1 = @_DocDate1
              AND DocDate2 = @_DocDate2
          )
    DELETE #T_Dvcs_B7
    WHERE BranchCode = @_branch_B7
END
DROP TABLE IF EXISTS #temptable