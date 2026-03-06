DROP TABLE IF EXISTS #AssetProduct
SELECT DISTINCT
       assetid,
       ProductId
INTO #AssetProduct
FROM B32009AssetProduct

DROP TABLE IF EXISTS #tmpB32009AssetDoc_Trans
SELECT Id,
       ProductId
INTO #tmpB32009AssetDoc_Trans
FROM vB32009AssetDoc_Trans
WHERE AssetId IN
      (
          SELECT AssetId FROM #AssetProduct AS ap
      )
SELECT *
FROM #tmpB32009AssetDoc_Trans


SELECT ad.ProductId,
       *
FROM B32009AssetDoc ad
    INNER JOIN #AssetProduct ap
        ON ad.assetid = ap.assetid
WHERE id IN
      (
          SELECT Id FROM #tmpB32009AssetDoc_Trans
      )