SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
-- View chung cac bang AtchDoc
ALTER VIEW dbo.vB30AccDocAtch
AS
SELECT a.Id, a.Stt, a.RowId, '' AS RowId_Tmp, CAST('' AS VARCHAR(16)) AS RowId_SourceDoc, a.BranchCode, a.DocCode, a.DocDate, a.AtchDocDate, a.AtchDocNo, a.AtchDocFormNo, a.AtchDocSerialNo, a.Description, a.DueDate, a.Account, a.OriginalAmount9, a.Amount9, a.OriginalAmountBeforeTax,
        a.AmountBeforeTax, a.TaxCode, a.TaxRate, a.CustomerId, a.DebitAccount, a.CreditAccount, a.OriginalAmount, a.Amount, a.TaxRegNo, a.TaxRegName, a.Quantity, a.AtchDocType, a.OriginalDueAmount, a.DueAmount, a.PaidOriginalAmount, a.PaidAmount,
        a.EInvoiceLink, a.EInvoiceKey, a.CurrencyCode, a.ExchangeRate, a.Posted, a.IsOpenDue, a.EmployeeId, a.VNDAmountBeforeTax, a.VNDAmount, a.Unit, a.OriginalOpenPaidAmount, a.OpenPaidAmount, a.IsActive, a.CreatedBy, a.CreatedAt, a.ModifiedBy, a.ModifiedAt,
        a.timestamp, a.BizDocId_LC, a.BizDocId_PO, a.BizDocId_SO, a.BizDocId_DA, a.BizDocId_PA, a.BizDocId_G2, a.BizDocId_G3, a.ExpenseCatgId, a.ProductId, a.DeptId, a.CashFlowId, a.CustomFieldId1, a.CustomFieldId2, a.CustomFieldId3, a.JobId, a.CostCentreId,
        a.WorkProcessId, 'B30AccDocAtchOther' AS TblName, a.NoteFactorId, a.BuiltinOrder, a.ItemName, a.AtchDocOrder, a.UnitCost, a.OriginalUnitCost 
	FROM dbo.B30AccDocAtchOther a
UNION ALL
SELECT a.Id, a.Stt, a.RowId, '' AS RowId_Tmp, CAST('' AS VARCHAR(16)) AS RowId_SourceDoc, a.BranchCode, a.DocCode, a.DocDate, a.AtchDocDate, a.AtchDocNo, a.AtchDocFormNo, a.AtchDocSerialNo, a.Description, a.DueDate, a.Account, a.OriginalAmount9, a.Amount9, a.OriginalAmountBeforeTax,
        a.AmountBeforeTax, a.TaxCode, a.TaxRate, a.CustomerId, a.DebitAccount, a.CreditAccount, a.OriginalAmount, a.Amount, a.TaxRegNo, a.TaxRegName, a.Quantity, a.AtchDocType, a.OriginalDueAmount, a.DueAmount, a.PaidOriginalAmount, a.PaidAmount,
        a.EInvoiceLink, a.EInvoiceKey, a.CurrencyCode, a.ExchangeRate, a.Posted, a.IsOpenDue, a.EmployeeId, a.VNDAmountBeforeTax, a.VNDAmount, a.Unit, a.OriginalOpenPaidAmount, a.OpenPaidAmount, a.IsActive, a.CreatedBy, a.CreatedAt, a.ModifiedBy, a.ModifiedAt,
        a.timestamp, a.BizDocId_LC, a.BizDocId_PO, a.BizDocId_SO, a.BizDocId_DA, a.BizDocId_PA, a.BizDocId_G2, a.BizDocId_G3, a.ExpenseCatgId, a.ProductId, a.DeptId, a.CashFlowId, a.CustomFieldId1, a.CustomFieldId2, a.CustomFieldId3, a.JobId, a.CostCentreId,
        a.WorkProcessId, 'B30AccDocAtchSales' AS TblName, a.NoteFactorId, CAST(0 AS SMALLINT) AS BuiltinOrder, CAST('' AS NVARCHAR(192)) AS ItemName, CAST(0 AS SMALLINT) AS AtchDocOrder, CAST(0 AS NUMERIC(18, 2)) AS UnitCost, CAST(0 AS NUMERIC(18, 2)) AS OriginalUnitCost
	FROM dbo.B30AccDocAtchSales a
UNION ALL
SELECT a.Id, a.Stt, a.RowId, a.Stt AS RowId_Tmp, CAST('' AS VARCHAR(16)) AS RowId_SourceDoc, a.BranchCode, a.DocCode, a.DocDate, a.AtchDocDate, a.AtchDocNo, a.AtchDocFormNo, a.AtchDocSerialNo, a.Description, a.DueDate, a.Account, a.OriginalAmount9, a.Amount9, a.OriginalAmountBeforeTax,
        a.AmountBeforeTax, a.TaxCode, a.TaxRate, a.CustomerId, a.DebitAccount, a.CreditAccount, a.OriginalAmount, a.Amount, a.TaxRegNo, a.TaxRegName, a.Quantity, a.AtchDocType, a.OriginalDueAmount, a.DueAmount, a.PaidOriginalAmount, a.PaidAmount,
        a.EInvoiceLink, a.EInvoiceKey, a.CurrencyCode, a.ExchangeRate, a.Posted, a.IsOpenDue, a.EmployeeId, a.VNDAmountBeforeTax, a.VNDAmount, a.Unit, a.OriginalOpenPaidAmount, a.OpenPaidAmount, a.IsActive, a.CreatedBy, a.CreatedAt, a.ModifiedBy, a.ModifiedAt,
        a.timestamp, a.BizDocId_LC, a.BizDocId_PO, a.BizDocId_SO, a.BizDocId_DA, a.BizDocId_PA, a.BizDocId_G2, a.BizDocId_G3, a.ExpenseCatgId, a.ProductId, a.DeptId, a.CashFlowId, a.CustomFieldId1, a.CustomFieldId2, a.CustomFieldId3, a.JobId, a.CostCentreId,
        a.WorkProcessId, 'B30AccDocAtchPurchase' AS TblName, a.NoteFactorId, a.BuiltinOrder, a.ItemName, a.AtchDocOrder, a.UnitCost, a.OriginalUnitCost
	FROM dbo.B30AccDocAtchPurchase a
UNION ALL
SELECT a.Id, a.Stt, a.RowId, '' AS RowId_Tmp, a.RowId_SourceDoc, a.BranchCode, a.DocCode, a.DocDate, a.AtchDocDate, a.AtchDocNo, a.AtchDocFormNo, a.AtchDocSerialNo, a.Description, a.DueDate, a.Account, a.OriginalAmount9, a.Amount9, a.OriginalAmountBeforeTax,
        a.AmountBeforeTax, a.TaxCode, a.TaxRate, a.CustomerId, a.DebitAccount, a.CreditAccount, a.OriginalAmount, a.Amount, a.TaxRegNo, a.TaxRegName, a.Quantity, a.AtchDocType, a.OriginalDueAmount, a.DueAmount, a.PaidOriginalAmount, a.PaidAmount,
        a.EInvoiceLink, a.EInvoiceKey, a.CurrencyCode, a.ExchangeRate, a.Posted, a.IsOpenDue, a.EmployeeId, a.VNDAmountBeforeTax, a.VNDAmount, a.Unit, a.OriginalOpenPaidAmount, a.OpenPaidAmount, a.IsActive, a.CreatedBy, a.CreatedAt, a.ModifiedBy, a.ModifiedAt,
        a.timestamp, a.BizDocId_LC, a.BizDocId_PO, a.BizDocId_SO, a.BizDocId_DA, a.BizDocId_PA, a.BizDocId_G2, a.BizDocId_G3, a.ExpenseCatgId, a.ProductId, a.DeptId, a.CashFlowId, a.CustomFieldId1, a.CustomFieldId2, a.CustomFieldId3, a.JobId, a.CostCentreId,
        a.WorkProcessId, 'B30AccDocAtchE3' AS TblName, a.NoteFactorId, a.BuiltinOrder, a.ItemName, a.AtchDocOrder, a.UnitCost, a.OriginalUnitCost
	FROM dbo.B30AccDocAtchE3 a
GO

--SELECT * FROM B32010AccDocAtchOther WHERE docno = 'CL-2601-0004'
SELECT  a.EInvoiceLink, a.EInvoiceKey, * FROM vB32010AccDocOther_Edit a WHERE  Stt ='I150037835'


SELECT  a.EInvoiceLink, a.EInvoiceKey, * FROM vB32010AccDocAtch a WHERE  Stt ='I150037835'


SELECT  * FROM B32010AccDoc a WHERE  Stt ='I150037835'