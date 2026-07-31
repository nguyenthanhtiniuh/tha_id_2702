SET DATEFORMAT DMY

DECLARE @_Doc1 DATE
DECLARE @_Doc2 DATE

SELECT @_Doc1 = '2026-01-01'
SELECT @_Doc2 = '2026-01-31'

--loc cac ma san pham co Nhap thanh pham trong thang
DROP TABLE IF EXISTS #AssetProduct;
WITH cte
AS (SELECT StageId,
           ProductId
    FROM dbo.B32010StockLedger
    WHERE DocCode = 'TP'
          AND DocDate
          BETWEEN @_Doc1 AND @_Doc2)
SELECT ap.*
INTO #AssetProduct
FROM B32010AssetProduct ap
WHERE StageId IN
      (
          SELECT DISTINCT StageId FROM cte
      )

--lay vat tu nhap thanh pham
DROP TABLE IF EXISTS #tbl_nhaptp
SELECT DISTINCT
       ItemId,
       StageId,Quantity
INTO #tbl_nhaptp
FROM dbo.B32010StockLedger sl
WHERE sl.DocCode = 'TP'
      AND sl.DocDate
      BETWEEN @_Doc1 AND @_Doc2

/*
<FilterKey>ParentCode='DMVT_Loai_Vt'</FilterKey>
                                  <DataMember>ItemType</DataMember>

SELECT *
FROM dbo.B20Class
WHERE ParentCode = 'DMVT_Loai_Vt'
*/

--lay thong tin san pham tu vat tu nhap thanh pham 
DROP TABLE IF EXISTS #tbl_nhaptp_info
SELECT nhaptp.ItemId,
       nhaptp.StageId,
       nhaptp.Quantity,
       ItemInfo.ProductId,
       t.Code AS ItemCode
INTO #tbl_nhaptp_info
FROM #tbl_nhaptp nhaptp
    INNER JOIN B20Item t WITH (NOLOCK)
        ON nhaptp.itemid = t.id
    INNER JOIN dbo.B20ItemInfo ItemInfo WITH (NOLOCK)
        ON ItemInfo.itemid = t.id
WHERE t.itemtype = 1

--loc lai cac ma san pham co the Phan bo trong ky
--co khai bao ma san pham va ma cong doan trong bang #AssetProduct
SELECT nhaptp.*,
       ass.Type,
       ass.Code AS AssetCode,
       ass.Id
FROM #tbl_nhaptp_info nhaptp
    LEFT JOIN #AssetProduct ap
        ON nhaptp.ProductId = ap.ProductId
           AND nhaptp.StageId = ap.StageId
    LEFT JOIN dbo.B22010Asset  ass WITH (NOLOCK)
        ON ap.assetId = ass.id
WHERE ap.ProductId IS NOT NULL
      AND ap.StageId IS NOT NULL ORDER BY Type ASC ,Id ASC 
      

