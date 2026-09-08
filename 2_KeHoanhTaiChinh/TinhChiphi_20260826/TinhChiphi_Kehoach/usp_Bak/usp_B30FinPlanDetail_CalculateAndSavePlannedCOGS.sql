SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE dbo.usp_B30FinPlanDetail_CalculateAndSavePlannedCOGS
    @_DocDate AS DATE = '20260301'
  , @_Year AS VARCHAR(4) = '2026'
  , @_ItemId AS VARCHAR(512) = ''
  , @_nUserId AS INT = 0
  , @_LangId TINYINT = 0
  , @_BranchCode AS VARCHAR(3) = ''
  , @_BizDocId AS VARCHAR(16) = ''
  , @_DataXML XML = NULL
  , @_SelectExec INT = 0
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

    DROP TABLE IF EXISTS #temptable_BP
    CREATE TABLE #temptable_BP
    (
        BranchCode CHAR(3) NULL
      , FiscalYear VARCHAR(24) NULL
      , DocDate DATE
      , ItemId INT
      , ItemCode VARCHAR(24)
      , ItemName NVARCHAR(256)
            DEFAULT ''
      , CostFactorId INT
      , CostFactorCode VARCHAR(24)
      , CostFactorName NVARCHAR(256)
            DEFAULT ''
      , Quantity DECIMAL(18, 2)
      , Coeff DECIMAL(38, 4)
      , VariableAmount DECIMAL(38, 6)
      , ProductId INT
      , ProductCode VARCHAR(24)
      , ProductName NVARCHAR(256)
            DEFAULT ''
      , IsActive BIT NOT NULL
            DEFAULT 1
      , CreatedBy INT
      , CreatedAt SMALLDATETIME
      , ModifiedBy INT
      , ModifiedAt SMALLDATETIME
    )

    DROP TABLE IF EXISTS #temptable_DP
    CREATE TABLE #temptable_DP
    (
        BranchCode CHAR(3) NULL
      , FiscalYear VARCHAR(24) NULL
      , DocDate DATE
      , ItemId INT
      , ItemCode VARCHAR(24)
      , ItemName NVARCHAR(256)
            DEFAULT ''
      , CostFactorId INT
      , CostFactorCode VARCHAR(24)
      , CostFactorName NVARCHAR(256)
            DEFAULT ''
      , FixedAmount DECIMAL(38, 2)
      , ProductId INT
      , ProductCode VARCHAR(24)
      , ProductName NVARCHAR(256)
            DEFAULT ''
      , IsActive BIT NOT NULL
            DEFAULT 1
      , CreatedBy INT
      , CreatedAt SMALLDATETIME
      , ModifiedBy INT
      , ModifiedAt SMALLDATETIME
    )


    IF @_DataXML IS NOT NULL
    BEGIN
        DECLARE @_docHandle INT;
        EXEC sys.sp_xml_preparedocument @_docHandle OUTPUT, @_DataXML;
        INSERT INTO #temptable_BP
        (
            ItemId
          , ItemCode
          , CostFactorId
          , CostFactorCode
          , Quantity
          , Coeff
          , VariableAmount
          , ProductId
          , ProductCode
        )
        SELECT ItemId
             , ItemCode
             , CostFactorId
             , CostFactorCode
             , Quantity
             , Coeff
             , VariableAmount
             , ProductId
             , ProductCode
        FROM
            OPENXML(@_docHandle, '/NewDataSet/GettheLatestMonthlyNormData', 1)
            WITH
            (
                ItemId INT
              , ItemCode VARCHAR(24)
              , CostFactorId INT
              , CostFactorCode VARCHAR(24)
              , Quantity DECIMAL(18, 2)
              , Coeff DECIMAL(38, 4)
              , VariableAmount DECIMAL(38, 6)
              , ProductId INT
              , ProductCode VARCHAR(24)
            )

        INSERT INTO #temptable_DP
        (
            ItemId
          , ItemCode
          , CostFactorId
          , CostFactorCode
          , FixedAmount
          , ProductId
          , ProductCode
        )
        SELECT ItemId
             , ItemCode
             , CostFactorId
             , CostFactorCode
             , FixedAmount
             , ProductId
             , ProductCode
        FROM
            OPENXML(@_docHandle, '/NewDataSet/GettheLatestMonthlyNormData1', 1)
            WITH
            (
                ItemId INT
              , ItemCode VARCHAR(24)
              , CostFactorId INT
              , CostFactorCode VARCHAR(24)
              , FixedAmount DECIMAL(38, 2)
              , ProductId INT
              , ProductCode VARCHAR(24)
            )
    END

    IF NOT EXISTS (SELECT * FROM #temptable_BP)
       AND NOT EXISTS
    (
        SELECT *
        FROM #temptable_DP
    )
    BEGIN

        --EXEC sp_help [usp_B30FinPlanDetail_PlannedOutputDetermination];
        --2026-08-09 lấy dữ liệu sản lượng kế hoạch từ Kế hoạch doanh thu
        EXEC usp_B30FinPlanDetail_GettheLatestMonthlyNormData @_DocDate = @_DocDate
                                                            , @_Year = @_Year
                                                            , @_nUserId = @_nUserId
                                                            , @_LangId = @_LangId
                                                            , @_BranchCode = @_BranchCode
                                                            , @_CtTmp1 = '#temptable_BP';

        EXEC usp_B30FinPlanDetail_GettheLatestMonthlyNormData @_DocDate = @_DocDate
                                                            , @_Year = @_Year
                                                            , @_nUserId = @_nUserId
                                                            , @_LangId = @_LangId
                                                            , @_BranchCode = @_BranchCode
                                                            , @_CtTmp2 = '#temptable_DP';
    END;




    DROP TABLE IF EXISTS #PlannedCostResult
    CREATE TABLE #PlannedCostResult
    (
        BranchCode CHAR(3) NOT NULL
      , FiscalYear VARCHAR(24) NOT NULL
      , DocDate DATE NOT NULL
      , ProductId INT NULL
      , ProductCode VARCHAR(24)
      , ProductName NVARCHAR(256)
            DEFAULT ''
      , ItemId INT NULL
      , ItemCode VARCHAR(24)
      , ItemName NVARCHAR(256)
            DEFAULT ''
      , CostFactorId INT NULL
      , CostFactorCode VARCHAR(24)
      , CostFactorName NVARCHAR(256)
      , Quantity NUMERIC(28, 10) NOT NULL
      , Coeff NUMERIC(28, 10) NOT NULL
      , Coefficient0 NUMERIC(28, 10) NULL
            DEFAULT 0
      , VariableAmount NUMERIC(28, 10) NOT NULL
      , IsActive BIT NOT NULL
      , CreatedBy INT NOT NULL
      , CreatedAt SMALLDATETIME NOT NULL
      , ModifiedBy INT NOT NULL
      , ModifiedAt SMALLDATETIME NOT NULL
      , FixedAmount NUMERIC(28, 10) NULL
            DEFAULT 0
    )

    UPDATE #temptable_BP
    SET BranchCode = @_BranchCode
      , FiscalYear = @_Year
      , DocDate = @_SOMONTH
      , CreatedBy = @_nUserId
      , CreatedAt = GETUTCDATE()
      , ModifiedBy = -1
      , ModifiedAt = GETUTCDATE()
    UPDATE #temptable_DP
    SET BranchCode = @_BranchCode
      , FiscalYear = @_Year
      , DocDate = @_SOMONTH
      , CreatedBy = @_nUserId
      , CreatedAt = GETUTCDATE()
      , ModifiedBy = -1
      , ModifiedAt = GETUTCDATE()

    EXEC dbo.usp_sys_CreateTable @_Table = '#PlannedCostResult'
                               , @_BaseTable = 'B30PlannedCostResult'

    EXECUTE dbo.usp_sys_Append @_TableSource = N'#temptable_BP'
                             , @_TableDestination = N'#PlannedCostResult'

    EXECUTE dbo.usp_sys_Append @_TableSource = N'#temptable_DP'
                             , @_TableDestination = N'#PlannedCostResult'





    CREATE TABLE #PlannedCost
    (
        BranchCode CHAR(3) NOT NULL
      , FiscalYear VARCHAR(24) NOT NULL
      , DocDate DATE NOT NULL
      , DocNo NVARCHAR(64) NOT NULL
      , ItemId INT NULL
      , ProductId INT NULL
      , Quantity NUMERIC(28, 10) NOT NULL
      , VariableAmount NUMERIC(28, 10) NOT NULL
      , FixedAmount NUMERIC(28, 10) NOT NULL
      , Amount NUMERIC(28, 0) NOT NULL
      , IsActive BIT
            DEFAULT 1
      , CreatedBy INT NULL
      , CreatedAt SMALLDATETIME NULL
      , ModifiedBy INT NULL
      , ModifiedAt SMALLDATETIME NULL
    )

    INSERT INTO #PlannedCost
    (
        BranchCode
      , FiscalYear
      , DocDate
      , DocNo
      , ItemId
      --, ProductId
      , Quantity
      , Amount
      , VariableAmount
      , FixedAmount
    )
    SELECT pcr.BranchCode
         , pcr.FiscalYear
         , pcr.DocDate
         , 'KHGV ' + FORMAT(@_DocDate, 'dd-MM-yyyy') + ' ' + MAX(pcr.ItemCode) AS DocNo
         , pcr.ItemId
         --, pcr.ProductId
         , MAX(pcr.Quantity)                                                   AS Quantity
         , ROUND(SUM(pcr.VariableAmount) + SUM(pcr.FixedAmount), 0)            AS Amount
         , SUM(pcr.VariableAmount)                                             AS VariableAmount
         , SUM(pcr.FixedAmount)                                                AS FixedAmount
    FROM #PlannedCostResult AS pcr
    GROUP BY pcr.BranchCode
           , pcr.FiscalYear
           , pcr.DocDate
           --, pcr.ProductId
           , pcr.ItemId

    --SELECT *
    --FROM #temptable_BP
    --WHERE ItemCode = '3821002000'
    --SELECT *
    --FROM #temptable_DP
    --WHERE ItemCode = '3821002000'

    --SELECT *
    --FROM #PlannedCostResult
    --WHERE ItemCode = '3821002000'

    --SELECT *
    --FROM #PlannedCost
    --WHERE ItemId = 1834682

    --RETURN

    UPDATE #PlannedCost
    SET BranchCode = @_BranchCode
      , FiscalYear = @_Year
      , DocDate = @_SOMONTH
      , CreatedBy = @_nUserId
      , CreatedAt = GETUTCDATE()
      , ModifiedBy = -1
      , ModifiedAt = GETUTCDATE()

    DECLARE @_TableDestination       NVARCHAR(256) = N'B30PlannedCost'
          , @_TableDestinationResult NVARCHAR(256) = N'B30PlannedCostResult'

    SELECT @_TableDestination       = REPLACE(@_TableDestination, 'B30', 'B3' + @_DataCode_Tmp)
         , @_TableDestinationResult = REPLACE(@_TableDestinationResult, 'B30', 'B3' + @_DataCode_Tmp)

    SELECT @_strExec
        = N' DELETE ' + @_TableDestination + N' WHERE DocDate = ''' + CAST(@_SOMONTH AS VARCHAR(11))
          + N'''  AND ItemId IN ( SELECT ItemId FROM #PlannedCostResult  )'
    EXEC (@_strExec)
    EXECUTE dbo.usp_sys_Append @_TableSource = N'#PlannedCost'
                             , @_TableDestination = @_TableDestination


    SELECT @_strExec
        = N' DELETE ' + @_TableDestinationResult + N' WHERE DocDate = ''' + CAST(@_SOMONTH AS VARCHAR(11))
          + N'''  AND  ItemId IN ( SELECT ItemId FROM #PlannedCostResult  )    '
    EXEC (@_strExec)
    EXECUTE dbo.usp_sys_Append @_TableSource = N'#PlannedCostResult'
                             , @_TableDestination = @_TableDestinationResult

    --18-07-2026 TINNT
    --bổ sung thêm hàm join lấy dữ liệu trường "Name" các danh mục Item,Product,CostFactor từ bảng danh mục, lấy từ dữ liệu XML sẽ bị lỗi nếu chuỗi XML phần tag trường "Name" có dấu cách
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#PlannedCostResult'
                                           , @_List_Cats = 'Item'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#PlannedCostResult'
                                           , @_List_Cats = 'Product'
    EXEC dbo.usp_sys_Update_Col_By_List_Cats @_CtTmp = '#PlannedCostResult'
                                           , @_List_Cats = 'CostFactor'

    --18-07-2026 TINNT
    --Tái sử dụng trường dữ liệu Code,Name đã get từ bảng được khởi tạo từ dữ liệu @_DataXML. Hạn chế truy xuất tới bảng B20 danh mục để tăng tốc thời gian chạy tính năng
    SELECT @_strExec
        = N' ;WITH	CTE_Item	AS (SELECT DISTINCT pcr.ItemId,pcr.ItemCode,pcr.ItemName FROM #PlannedCostResult AS pcr),
					CTE_Product AS (SELECT DISTINCT pcr.ProductId,pcr.ProductCode,pcr.ProductName FROM #PlannedCostResult AS pcr)	  
				SELECT pc.*	,pcrItem.ItemCode,pcrItem.ItemName
							,pcrProduct.ProductCode,pcrProduct.ProductName
							,CreatedBy.FullName AS CreatedName
							,ModifiedBy.FullName AS ModifiedName								
					FROM  ' + @_TableDestination
          + N' PC 
						LEFT JOIN CTE_Item pcrItem ON PC.ItemId  = pcrItem.ItemId
						LEFT JOIN CTE_Product pcrProduct ON PC.ProductId  = pcrProduct.ProductId
						 LEFT JOIN dbo.B00UserList AS CreatedBy WITH (NOLOCK) ON PC.CreatedBy = CreatedBy.Id
						 LEFT JOIN dbo.B00UserList AS ModifiedBy WITH (NOLOCK) ON PC.ModifiedBy = ModifiedBy.Id
							WHERE DocDate = ''' + CAST(@_SOMONTH AS VARCHAR(11))
          + N'''  AND  PC.ItemId IN ( SELECT ItemId FROM #PlannedCostResult  )  ORDER BY pcrItem.ItemCode ASC  '
 
    SELECT @_strExec
        = @_strExec
          + N'  ;WITH	CTE_Item	AS (SELECT DISTINCT pcr.ItemId,pcr.ItemCode,pcr.ItemName FROM #PlannedCostResult AS pcr),
					CTE_Product AS (SELECT DISTINCT pcr.ProductId,pcr.ProductCode,pcr.ProductName FROM #PlannedCostResult AS pcr)	,
					CTE_CostFactor AS (SELECT DISTINCT pcr.CostFactorId,pcr.CostFactorCode,pcr.CostFactorName FROM #PlannedCostResult AS pcr)	
				SELECT PCR.*,pcrItem.ItemCode,pcrItem.ItemName
									,pcrProduct.ProductCode,pcrProduct.ProductName 
									,pcrCostFactor.CostFactorCode,pcrCostFactor.CostFactorName 
									,CreatedBy.FullName AS CreatedName
									,ModifiedBy.FullName AS ModifiedName
					FROM  ' + @_TableDestinationResult
          + N' PCR 
						LEFT JOIN CTE_Item pcrItem ON PCR.ItemId  = pcrItem.ItemId
						LEFT JOIN CTE_Product pcrProduct ON PCR.ProductId  = pcrProduct.ProductId 
						LEFT JOIN CTE_CostFactor pcrCostFactor ON PCR.CostFactorId  = pcrCostFactor.CostFactorId 
						 LEFT JOIN dbo.B00UserList AS CreatedBy WITH (NOLOCK) ON PCR.CreatedBy = CreatedBy.Id
						 LEFT JOIN dbo.B00UserList AS ModifiedBy WITH (NOLOCK) ON PCR.ModifiedBy = ModifiedBy.Id
							WHERE DocDate = ''' + CAST(@_SOMONTH AS VARCHAR(11))
          + N'''  AND  PCR.ItemId IN ( SELECT ItemId FROM #PlannedCostResult  )  ORDER BY pcrItem.ItemCode ASC,pcrCostFactor.CostFactorCode '
 
    IF @_SelectExec = 1
    BEGIN
        EXEC (@_strExec)
    END

    DROP TABLE IF EXISTS #temptable_BP
                       , #PlannedCostResult
                       , #temptable_DP
                       , #PlannedCost
END
GO

SET DATEFORMAT DMY

EXEC usp_B30FinPlanDetail_CalculateAndSavePlannedCOGS @_DocDate = '01/03/2026 00:00:00.000'
                                                    , @_Year = '2026'
                                                    , @_ItemId = '1834682'
                                                    , @_nUserId = 1213
                                                    , @_BranchCode = 'I09'