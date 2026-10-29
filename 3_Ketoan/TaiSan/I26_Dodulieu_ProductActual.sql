DROP TABLE IF EXISTS #T_AccDocItem;
SELECT ad.ItemId
     , ad.StageId
     , ad.ProductId
     , ad.Quantity
     , STR(FORMAT(ad.DocDate, 'yyyyMM'), 6) AS M_DocDate
INTO #T_AccDocItem
FROM vB32009AccDocItem1_Explore AS ad
WHERE EXISTS
(
    SELECT *
    FROM vB32009AssetProduct AS ap
    WHERE ap.ItemId = ad.ItemId
          AND ap.StageId = ad.StageId
)
      AND
      (
          OriginalUnitCost <> 0
          AND OriginalAmount9 <> 0
      );


DROP TABLE IF EXISTS #T_AccDocItem_2;
SELECT ItemId
     , CAST(NULL AS INT) AS ProductId
     , StageId
     , SUM(Quantity)     AS Quantity
     , M_DocDate
INTO #T_AccDocItem_2
FROM #T_AccDocItem
WHERE M_DocDate IN ( '202602', '202603' )
GROUP BY M_DocDate
       , ItemId
       , StageId;

UPDATE #T_AccDocItem_2
SET ProductId = inf.ProductId
FROM #T_AccDocItem_2       AS acc
    INNER JOIN b20iteminfo AS inf
        ON acc.ItemId = inf.ItemId;

DROP TABLE IF EXISTS #T_AssetProductActual;
SELECT TOP 0
       ParentId
     , IsGroup
     , BranchCode
     , DocDate
     , AssetId
     , ProductId
     , StageId
     , Quantity
     , Description
     , IsActive
     , CreatedBy
     , CreatedAt
     , ModifiedBy
     , ModifiedAt
     , MonthDepr
     , STR('', 6) AS M_DocDate
INTO #T_AssetProductActual
FROM B30AssetProductActual;

EXEC dbo.usp_sys_Append @_TableSource = '#T_AccDocItem_2'             -- nvarchar(128)
                      , @_TableDestination = '#T_AssetProductActual'; -- nvarchar(128)


UPDATE #T_AssetProductActual
SET DocDate = EOMONTH(M_DocDate + '01')
  , BranchCode = 'I26'
  , IsActive = 1
  , CreatedBy = 1213
  , CreatedAt = GETUTCDATE()
  , ModifiedBy = -1
  , ModifiedAt = GETUTCDATE();

--join bang B3{=BRANCH('DataCode')}AssetProduct lấy Mã ts
UPDATE #T_AssetProductActual
SET AssetId = asspro.AssetId
--,MonthDepr = 
FROM #T_AssetProductActual        AS ass
    INNER JOIN B32009AssetProduct AS asspro
        ON ass.ProductId = asspro.ProductId
           AND ass.StageId = asspro.StageId;


--join bang vB32009AssetDoc_Depreciation lấy Tiền phần bổ
UPDATE #T_AssetProductActual
SET MonthDepr = asspro.Depreciation
FROM #T_AssetProductActual                  AS ass
    INNER JOIN vB32009AssetDoc_Depreciation AS asspro
        ON ass.ProductId = asspro.ProductId
           AND ass.StageId = asspro.StageId
           AND ass.AssetId = asspro.AssetId;

EXEC dbo.usp_sys_Append @_TableSource = '#T_AssetProductActual'          -- nvarchar(128)
                      , @_TableDestination = 'B32009AssetProductActual'; -- nvarchar(128)




DROP TABLE IF EXISTS #T_AccDocItem
                   , #T_AccDocItem_2
                   , #T_AssetProductActual;


GO


SELECT *
FROM B32009AssetProductActual               AS ass
    INNER JOIN vB32009AssetDoc_Depreciation AS asspro
        ON ass.ProductId = asspro.ProductId
           AND ass.StageId = asspro.StageId
           AND ass.AssetId = asspro.AssetId
           AND ass.DocDate = asspro.DocDate
WHERE ass.CreatedBy = 1213
      AND FORMAT(ass.CreatedAt, 'yyyyMMdd') = FORMAT(GETDATE(), 'yyyyMMdd');



UPDATE ass
SET MonthDepr = asspro.Depreciation
FROM B32009AssetProductActual               AS ass
    INNER JOIN vB32009AssetDoc_Depreciation AS asspro
        ON ass.ProductId = asspro.ProductId
           AND ass.StageId = asspro.StageId
           AND ass.AssetId = asspro.AssetId
           AND ass.DocDate = asspro.DocDate
WHERE ass.CreatedBy = 1213
      AND FORMAT(ass.CreatedAt, 'yyyyMMdd') = FORMAT(GETDATE(), 'yyyyMMdd');