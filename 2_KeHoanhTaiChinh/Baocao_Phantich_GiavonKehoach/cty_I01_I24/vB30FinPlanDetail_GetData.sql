SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
ALTER VIEW dbo.vB30FinPlanDetail_GetData
AS
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, --DocDate00 c?t ??nh danh d? li?u theo tháng c?a b?ng chi ti?t
    DATEFROMPARTS(Year, 01, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, --DocDate c?t ghi nh?n Th?i gian duy?t (thông tin k? th?a t? ph?n m?m MES)
    FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 1 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity01 AS Quantity, Detail.Quantity01_W1 AS Quantity_W1, Detail.Quantity01_W2 AS Quantity_W2, Detail.Quantity01_W3 AS Quantity_W3, Detail.Quantity01_W4 AS Quantity_W4, Detail.Quantity01_W5 AS Quantity_W5, Detail.Quantity01_W6 AS Quantity_W6, Detail.Amount01 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 02, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 2 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity02 AS Quantity, Detail.Quantity02_W1 AS Quantity_W1, Detail.Quantity02_W2 AS Quantity_W2, Detail.Quantity02_W3 AS Quantity_W3, Detail.Quantity02_W4 AS Quantity_W4, Detail.Quantity02_W5 AS Quantity_W5, Detail.Quantity02_W6 AS Quantity_W6, Detail.Amount02 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 03, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 3 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity03 AS Quantity, Detail.Quantity03_W1 AS Quantity_W1, Detail.Quantity03_W2 AS Quantity_W2, Detail.Quantity03_W3 AS Quantity_W3, Detail.Quantity03_W4 AS Quantity_W4, Detail.Quantity03_W5 AS Quantity_W5, Detail.Quantity03_W6 AS Quantity_W6, Detail.Amount03 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 04, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 4 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity04 AS Quantity, Detail.Quantity04_W1 AS Quantity_W1, Detail.Quantity04_W2 AS Quantity_W2, Detail.Quantity04_W3 AS Quantity_W3, Detail.Quantity04_W4 AS Quantity_W4, Detail.Quantity04_W5 AS Quantity_W5, Detail.Quantity04_W6 AS Quantity_W6, Detail.Amount04 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 05, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 5 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity05 AS Quantity, Detail.Quantity05_W1 AS Quantity_W1, Detail.Quantity05_W2 AS Quantity_W2, Detail.Quantity05_W3 AS Quantity_W3, Detail.Quantity05_W4 AS Quantity_W4, Detail.Quantity05_W5 AS Quantity_W5, Detail.Quantity05_W6 AS Quantity_W6, Detail.Amount05 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 06, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 6 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity06 AS Quantity, Detail.Quantity06_W1 AS Quantity_W1, Detail.Quantity06_W2 AS Quantity_W2, Detail.Quantity06_W3 AS Quantity_W3, Detail.Quantity06_W4 AS Quantity_W4, Detail.Quantity06_W5 AS Quantity_W5, Detail.Quantity06_W6 AS Quantity_W6, Detail.Amount06 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 07, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 7 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity07 AS Quantity, Detail.Quantity07_W1 AS Quantity_W1, Detail.Quantity07_W2 AS Quantity_W2, Detail.Quantity07_W3 AS Quantity_W3, Detail.Quantity07_W4 AS Quantity_W4, Detail.Quantity07_W5 AS Quantity_W5, Detail.Quantity07_W6 AS Quantity_W6, Detail.Amount07 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 08, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 8 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity08 AS Quantity, Detail.Quantity08_W1 AS Quantity_W1, Detail.Quantity08_W2 AS Quantity_W2, Detail.Quantity08_W3 AS Quantity_W3, Detail.Quantity08_W4 AS Quantity_W4, Detail.Quantity08_W5 AS Quantity_W5, Detail.Quantity08_W6 AS Quantity_W6, Detail.Amount08 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 09, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 9 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity09 AS Quantity, Detail.Quantity09_W1 AS Quantity_W1, Detail.Quantity09_W2 AS Quantity_W2, Detail.Quantity09_W3 AS Quantity_W3, Detail.Quantity09_W4 AS Quantity_W4, Detail.Quantity09_W5 AS Quantity_W5, Detail.Quantity09_W6 AS Quantity_W6, Detail.Amount09 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 10, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.YEAR AS Year, 10 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity10 AS Quantity, Detail.Quantity10_W1 AS Quantity_W1, Detail.Quantity10_W2 AS Quantity_W2, Detail.Quantity10_W3 AS Quantity_W3, Detail.Quantity10_W4 AS Quantity_W4, Detail.Quantity10_W5 AS Quantity_W5, Detail.Quantity10_W6 AS Quantity_W6, Detail.Amount10 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 11, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.Year AS Year, 11 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity11 AS Quantity, Detail.Quantity11_W1 AS Quantity_W1, Detail.Quantity11_W2 AS Quantity_W2, Detail.Quantity11_W3 AS Quantity_W3, Detail.Quantity11_W4 AS Quantity_W4, Detail.Quantity11_W5 AS Quantity_W5, Detail.Quantity11_W6 AS Quantity_W6, Detail.Amount11 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
UNION ALL
SELECT Detail.Id, FinPlan.Id AS ParentId, FinPlan.IsGroup, FinPlan.BizDocId, DATEFROMPARTS(Year, 12, 01) AS DocDate00, FinPlan.DocNo, FinPlan.DocDate, FinPlan.Description, FinPlan.BranchCode, FinPlan.CurrencyCode, FinPlan.Year AS Year, 12 AS _Month, Detail.BuiltinOrder, Detail.CustomerId, Detail.ItemId, Detail.Unit, Detail.ProfitCenterId, Detail.OriginalUnitCost, Detail.Quantity12 AS Quantity, Detail.Quantity12_W1 AS Quantity_W1, Detail.Quantity12_W2 AS Quantity_W2, Detail.Quantity12_W3 AS Quantity_W3, Detail.Quantity12_W4 AS Quantity_W4, Detail.Quantity12_W5 AS Quantity_W5, Detail.Quantity12_W6 AS Quantity_W6, Detail.Amount12 AS Amount, FinPlan.IsActive, FinPlan.CreatedBy, FinPlan.CreatedAt, FinPlan.ModifiedBy, FinPlan.ModifiedAt, item.ProductClassId, Detail.ProductGroupId, item.ProductLevelId, Detail.ProductLineId
FROM dbo.B30FinPlan AS FinPlan
     INNER JOIN dbo.B30FinPlanDetail AS Detail ON FinPlan.BizDocId=Detail.BizDocId
     LEFT JOIN dbo.B20Item AS item(NOLOCK)ON Detail.ItemId=item.Id
GO
dbo._CreateTableByBranch @_TableName='vB30FinPlanDetail_GetData' 