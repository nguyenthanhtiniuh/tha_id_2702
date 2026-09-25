DROP TABLE IF EXISTS #T
SELECT *
     , MONTH(DocDate) AS M_DocDate
INTO #T
FROM vB32010ZSaleProduct_Explore
WHERE ISNULL(TotalCostAmount_Z, 0) = 0
      --AND MONTH(DocDate) = 1
      AND IsBreakDown = 1


SELECT COUNT(ProductId)
     , M_DocDate
FROM #T
GROUP BY M_DocDate 
ORDER BY M_DocDate