CREATE OR ALTER VIEW vB30LCDoc_Explore
AS
SELECT LCDoc.Id
     , LCDoc.ParentId
     , LCDoc.IsGroup
     , LCDoc.BranchCode
     , LCDoc.LCDocId
     , LCDoc.LCRequestId
     , LCDoc.DocCode
     , LCDoc.DocNo
     , LCDoc.DocDate
     , LCDoc.Description
     , LCDoc.DocStatus
     , LCDoc.EffectiveDate
     , LCDoc.ExpiryDate
     , LCDoc.CustomerFinanceId
     , LCDoc.CustomerId
     , LCDoc.LCType
     , LCDoc.OriginalAmount
     , LCDoc.CurrencyCode
     , LCDoc.OriginalAmountDeposit
     , LCDoc.CurrencyCodeDeposit
     , LCDoc.Amount
     , LCDoc.AmountDeposit
     , LCDoc.ExchangeRate
     , LCDoc.ExchangeRateDeposit
     , LCDoc.Loai_Ps
     , LCDoc.MortgageContractNo
     , LCDoc.CustomerCodeBorrow
     , LCDoc.Quantity_CP
     , LCDoc.IsActive
     , LCDoc.CreatedAt
     , LCDoc.CreatedBy
     , LCDoc.ModifiedBy
     , LCDoc.ModifiedAt
     , LCDoc.timestamp
     , LCDoc.IsCancelled
     , Customer.Code        AS CustomerCode
     , Customer.Name        AS CustomerName
     , CustomerFinance.Code AS CustomerFinanceCode
     , CustomerFinance.Name AS CustomerFinanceName
     , CreatedBy.FullName   AS CreatedName
     , ModifiedBy.FullName  AS ModifiedName
FROM B30LCDoc                 AS LCDoc
    LEFT JOIN B20Customer     AS Customer WITH (NOLOCK)
        ON LCDoc.CustomerId = Customer.Id
    LEFT JOIN B20Customer     AS CustomerFinance WITH (NOLOCK)
        ON LCDoc.CustomerFinanceId = CustomerFinance.Id
    LEFT JOIN dbo.B00UserList AS CreatedBy WITH (NOLOCK)
        ON LCDoc.CreatedBy = CreatedBy.Id
    LEFT JOIN dbo.B00UserList AS ModifiedBy WITH (NOLOCK)
        ON LCDoc.ModifiedBy = ModifiedBy.Id