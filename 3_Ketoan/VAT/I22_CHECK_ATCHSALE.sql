SELECT Id
     , BranchCode
     , Stt
     , BuiltinOrder
     , CurrencyCode
     , DocCode
     , DocNo
     , DocDate
     , DocSerialNo
     , Description
     , CustomerId
     , AtchDocNo
     , AtchDocDate
     , AtchDocSerialNo
     , AtchDocFormNo
     , Amount2
     , DebitAccount3
     , CreditAccount3
     , Amount3
     , OriginalAmount3
     , TaxCode
     , TaxRate
     , TaxRegNo
     , TaxRegName
     , ItemName
     , DueDate
     , EInvoiceLink
     , EInvoiceKey
FROM vB32018AccDocAtch_GetDataVAT
WHERE DocDate
      BETWEEN '20260901' AND '20260930'
      AND BranchCode = 'I20'
      AND
      (
          (
              ((
                   DebitAccount3 LIKE '3331%'
                   OR CreditAccount3 LIKE '3331%'
               )
              )
              OR
              (
                  DocCode = 'XT'
                  AND
                  (
                      DebitAccount3 LIKE '3331%'
                      OR CreditAccount3 LIKE '3331%'
                  )
              )
          )
          AND TaxCode IN
              (
                  SELECT Code FROM B20Tax WHERE Type = 2
              )
          AND TaxCode NOT IN ( 'R00D' )
      )
      AND DocNo = '00002265';


	  SELECT * FROM B32018AccDocSales WHERE  DocNo = '00002265';
	  SELECT AmountBeforeTax,* FROM vB32018AccDocAtch WHERE Stt='I200149299AXK'
	  SELECT AmountBeforeTax,* FROM B32018AccDocAtchSales WHERE Stt='I200149299AXK'