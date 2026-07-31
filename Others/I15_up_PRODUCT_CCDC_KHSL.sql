--SELECT * FROM sys.objects WHERE name LIKE 'B3%FTax'       AND type_desc = 'USER_TABLE'
--SELECT * FROM sys.objects WHERE name LIKE 'B3%FTaxDetail'       AND type_desc = 'USER_TABLE'
--B30FTaxDetail

--SELECT * FROM sys.objects WHERE name LIKE '%b3%tax%'       AND type_desc = 'USER_TABLE'



;WITH cte
AS (SELECT assetid
          ,productid
    FROM B32010AssetProduct
    WHERE assetid IN
          (
              SELECT id FROM vB22010Asset_ToolInstrument WHERE DeprMethod = 3
          ))
--UPDATE B32010AssetDoc
--SET productid = c.productid
SELECT * FROM  B32010AssetDoc asset
    INNER JOIN cte  C
        ON C.assetid = asset.assetid
WHERE asset.assetid IN
      (
          SELECT id FROM vB22010Asset_ToolInstrument WHERE DeprMethod = 3
      )
      AND asset.productid IS NULL
      AND asset.assetid IN
          (
              SELECT assetid FROM cte
          )