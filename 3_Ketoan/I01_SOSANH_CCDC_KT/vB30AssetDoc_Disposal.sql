SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 02/04/2014 CuongNc thêm các trường CreatedBy, ModifiedBy, CreatedAt, ModifiedAt, timestamp
ALTER VIEW [dbo].[vB30AssetDoc_Disposal]
AS
WITH gtcl AS
(SELECT EquityId, AssetId, MAX(DocGroup) AS DocGroup, 
		SUM(OriginalCost) AS OriginalCost,
		SUM(Depreciation) AS Depreciation, 
		SUM(NetBookValue) AS NetBookValue,
		SUM(AmountForDepr) AS AmountForDepr,
		SUM(IncQuantity) AS IncQuantity, SUM(DeQuantity) AS DeQuantity,
		SUM(Depreciation) AS DeDepreciation,
		SUM(AmountForDepr ) AS AmountForDeDepr,
		SUM(DeprAmountBeginOfYear * Trans) AS DeprAmountBeginOfYear,
		MAX(AssetTransType) AS AssetTransType,
		MAX(AssetTransId) AS AssetTransId,
		MAX(DocNo) AS DocNo, MAX(Description) AS Description, MAX(UsefulMonth) AS UsefulMonth,
		MAX(DocDate) AS DocDate,
		MAX(DeprAllocationRate) AS DeprAllocationRate,
		MAX(Id) AS Id, MAX(ParentId) AS ParentId, 
		MAX(CreatedBy) AS CreatedBy,
		MAX(CreatedAt) AS CreatedAt, 
		MAX(ModifiedBy) AS ModifiedBy,
		MAX(ModifiedAt) AS ModifiedAt,
		CAST(1 AS BIT) AS IsActive,
		CAST(0 AS BIT) AS IsGroup,
		MAX(ProductionCapacity) AS ProductionCapacity, --23/09/2021 Duccm Tách thời gian, sản lượng
		MAX(DisposalAccount) AS DisposalAccount, MAX(CustomerId) AS CustomerId -- 27/07/2024 HuyTQ thêm thông tin tài khoản và đối tượng thanh lý
		,MAX(ProfitCenterId) AS ProfitCenterId, MAX(StageId) AS StageId, MAX(RouteCode) AS RouteCode, MAX(TerritoryId) AS TerritoryId, 
        MAX(BizDocId_C2) AS BizDocId_C2,
		MAX(ExpenseCatgId) AS ExpenseCatgId,
		MAX(DeptId) AS DeptId
	FROM dbo.vB30AssetDoc_DisposalDetail
	WHERE IsActive = 1
	GROUP BY AssetId, EquityId
)
SELECT dmts.BranchCode, gtcl.DocDate, gtcl.DocGroup, gtcl.AssetId, gtcl.EquityId, DmNv.Code AS EquityCode, 
	gtcl.OriginalCost, gtcl.Depreciation AS Depreciation, 
	gtcl.NetBookValue, gtcl.AmountForDepr, 
	gtcl.IncQuantity, gtcl.DeQuantity, 
	CAST(0 AS MONEY) AS IncOriginalCost, gtcl.OriginalCost AS DeOriginalCost, CAST(0 AS MONEY) AS IncDepreciation, gtcl.DeDepreciation, 
	CAST(0 AS MONEY) AS AmountForIncDepr, gtcl.AmountForDeDepr, 
	CAST('' AS VARCHAR(24)) AS DeprDebitAccount, CAST('' AS VARCHAR(24)) AS DeprCreditAccount, 
	gtcl.DeptId, CAST(NULL AS INT) AS DeprDeptId, 
	gtcl.ExpenseCatgId , CAST(NULL AS INT) AS ProductId, CAST(NULL AS INT) AS EmployeeId,
	gtcl.AssetTransType, gtcl.AssetTransId, (gtcl.IncQuantity - gtcl.DeQuantity) AS Quantity, 
	CAST('' AS NVARCHAR(64)) AS DeptName, CAST('' AS NVARCHAR(64)) AS EquityName, 
	CAST('' AS NVARCHAR(64)) AS ExpenseCatgName, CAST(0 AS TINYINT) AS IsDeprAdjusted, 
	gtcl.DeprAmountBeginOfYear, gtcl.DeprAllocationRate,
	gtcl.DocNo, gtcl.Description, gtcl.UsefulMonth, CAST('' AS NVARCHAR(64)) AS AssetTransName, 
	dmts.Code AS AssetCode, dmts.Name AS AssetName, DmTs.Type AS AssetType, CAST(-1 AS INT) AS Trans, 
	gtcl.ParentId, gtcl.IsGroup, dmts.CardNo, dmts.FirstDeprDate, dmts.FirstUsedDate, dmts.AssetAccount, dmts.Unit, 
	dmts.AssetFuncId, gtcl.IsActive, gtcl.Id, gtcl.CreatedBy, gtcl.CreatedAt, gtcl.ModifiedBy, gtcl.ModifiedAt,
	DmTs.IsActive AS IsActiveAsset, 
	gtcl.ProductionCapacity, --23/09/2021 Duccm Tách thời gian, sản lượng
	IIF(ISNULL(dmts.DeprMethod, 1) = 3, 1, 0) AllocateByCapacity,	-- 07/03/2022 ThắngĐQ: Xử lý Phân bổ theo sản lượng 
	dmts.DeprMethod,
	gtcl.DisposalAccount, gtcl.CustomerId, -- 27/07/2024 HuyTQ thêm thông tin tài khoản và đối tượng thanh lý
	gtcl.ProfitCenterId, gtcl.StageId, gtcl.RouteCode, gtcl.TerritoryId,gtcl.BizDocId_C2
FROM gtcl 
	LEFT OUTER JOIN dbo.B20Asset AS DmTs ON gtcl.AssetId = DmTs.Id
	LEFT OUTER JOIN B20Equity AS DmNv ON gtcl.EquityId = DmNv.Id
GO
