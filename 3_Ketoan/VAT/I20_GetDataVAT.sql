 
SELECT *
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
      );

	  GO
      

	  SELECT * FROM B32018AccDocSales WHERE 