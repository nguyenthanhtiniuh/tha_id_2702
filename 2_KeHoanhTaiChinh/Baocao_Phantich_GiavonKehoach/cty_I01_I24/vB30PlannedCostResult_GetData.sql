SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
ALTER VIEW dbo.vB30PlannedCostResult_GetData
AS
SELECT pc.ProductId
     , pc.ItemId
     , pc.DocDate
     , pc.BranchCode
     , pcr.CostFactorId
     , pcr.VariableAmount
     , pcr.FixedAmount
     , pcr.IsActive
     , item.ProductClassId
     , pcr.Quantity
     , pcr.Coeff,pcr.Id
FROM dbo.B30PlannedCost (NOLOCK)                 AS pc
    INNER JOIN dbo.B30PlannedCostResult (NOLOCK) AS pcr
        ON pcr.DocDate = pc.DocDate
           AND pcr.ItemId = pc.ItemId
    LEFT JOIN B20Item (NOLOCK)                   AS item
        ON pc.ItemId = item.Id;
GO
dbo._CreateTableByBranch @_TableName = 'vB30PlannedCostResult_GetData'

SELECT *
FROM B30PlannedCostResult