SELECT BranchCode
     , AssetTransType
     , AssetTransId
     --, AssetTransCode
     , AssetTransName
     , DocDate
     , DocGroup
     , AssetId
     , EquityId
     , OriginalCost
     , Depreciation
     , NetBookValue
     , AmountForDepr
     , IncQuantity
     , DeQuantity
     , IncOriginalCost
     , DeOriginalCost
     , IncDepreciation
     , DeDepreciation
     , AmountForIncDepr
     , AmountForDeDepr
     , DeprDebitAccount
     , DeprCreditAccount
     , DeptId
     , CostCentreId
     , ExpenseCatgId
     , ProductId
     , EmployeeId
     , Quantity
     , DeptName
     , EquityName
     , ExpenseCatgName
     , IsDeprAdjusted
     , DeprAmountBeginOfYear
     , DeprAllocationRate
     , DocNo
     , Description
     , UsefulMonth
     , AssetCode
     , AssetName
     , AssetType
     , Trans
     , ParentId
     , CardNo
     , FirstDeprDate
     , FirstUsedDate
     , AssetAccount
     , Unit
     , AssetFuncId
     , IsActive
     , Id
     , IsGroup
     , CreatedAt
     , IsActiveAsset
     , AllocateByCapacity
     , ProductionCapacity
     , DeprMethod
     , ProfitCenterId
     , StageId
     , RouteCode
     , TerritoryId
     , BizDocId_C2
FROM vB32001AssetDoc
WHERE DocDate
      BETWEEN '1900-01-01' AND '2026-07-31'
      AND BranchCode = 'I01'
      AND IsActive = 1
      AND IsActiveAsset = 1
      AND (AssetType = 1)
      AND
      (
          (DeprAllocationRate = 0)
          OR
          (
              DeprAllocationRate <> 0
              AND AssetTransType = 'KHAUHAO'
          )
      )
      AND FORMAT(docdate, 'yyyyMM') = '202607'
      AND AssetTransType <> 'KHAUHAO'
ORDER BY DocDate DESC;
--SELECT DISTINCT assetcode FROM vB32001AssetDoc_Resign WHERE branchcode ='i01' AND type = 1 AND AssetTransType='GIAMTAISAN' AND DocDate = '20260701' AND isactive = 1