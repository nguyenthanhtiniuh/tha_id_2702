--update B10KqtCashFlowPlan set SourceTable = 'B10KqtCashFlowPlan' where KqtCashFlowPlanId='T000000003'
--select SourceTable,* from B10KqtCashFlowPlan where KqtCashFlowPlanId='T000000003'


DECLARE @_Doc1 AS DATE;

DECLARE @_Doc2 AS DATE;

SET DATEFORMAT dmy;

SELECT @_Doc1 = '20260101';

SELECT @_Doc2 = '20260131';

/*
điểm bất hợp lý:
	I. Dòng tiền thu < Dòng tiền chi
		1. Tạo 1 bảng mới #TblCashFlowData
			i. Lấy dữ liệu sổ cái -> lấy mã Hoạt động dòng tiền trong tháng + Mã Nhóm khách hàng
		2. #TblCashFlowData Join với Bảng khai báo
		3. Check nguyên nhân 
			i. …
		4. Giải pháp xử lý
…

*/

--CFOI2-04
--17696470

DROP TABLE IF EXISTS #TblCashFlowData;

--update b32002generalledger
--set CashFlowId = 17696470 
--where docdate BETWEEN '20260101' AND '20260131'
--       AND account LIKE '112%'
--       AND EntryNo = 'A' and rowid in (select * from string_split('I235586831TD,I235586857TD,I235586839TD,I235586859TD,I235586861TD,I235587035TD,I235587549TD,I230680227TD',','))
--       AND CashFlowId IS   NULL;

update B32002AccDocAutoEntry1 set CashFlowId = 17696470 where docdate BETWEEN '20260101' AND '20260131' and rowid in (select * from string_split('I235586831TD,I235586857TD,I235586839TD,I235586859TD,I235586861TD,I235587035TD,I235587549TD,I230680227TD',','))
select * from  B32002AccDocAutoEntry1  where docdate BETWEEN '20260101' AND '20260131' and rowid in (select * from string_split('I235586831TD,I235586857TD,I235586839TD,I235586859TD,I235586861TD,I235587035TD,I235587549TD,I230680227TD',','))

SELECT ge.*,cu.MESGroupCode
INTO   #TblCashFlowData2002
FROM   b32002generalledger ge inner join B20Customer (nolock) cu on ge.CustomerId0 = cu.Id
WHERE  docdate BETWEEN @_doc1 AND @_doc2
       AND account LIKE '11%'
       AND EntryNo = 'A' and rowid in (select * from string_split('I235586831TD,I235586857TD,I235586839TD,I235586859TD,I235586861TD,I235587035TD,I235587549TD,I230680227TD',','))
       AND CashFlowId IS   NULL;

--bang khai bao
DROP TABLE IF EXISTS #K_BcTmp;

SELECT *,
       CAST ('' AS NVARCHAR (MAX)) AS CashFlowCode,
       CAST ('' AS NVARCHAR (MAX)) AS CashFlowId_List
INTO   #K_BcTmp
FROM   B10KqtCashFlowPlan
WHERE  SourceTable = 'B10KqtCashFlowPlan'
       AND KqtCashFlowPlanId = 'T000000003'; --select * from #K_BcTmp  return   

WITH cte
AS   (SELECT dbo.ufn_Get_List_CatgDetail(ca.value, 'B20CashFlow', 'Code') AS CashFlowCode,
             dbo.ufn_Get_List_CatgDetail(ca.value, 'B20CashFlow', 'Id') AS CashFlowId,
             tmp.Id
      FROM   #K_BcTmp AS tmp CROSS APPLY (SELECT value
                                          FROM   STRING_SPLIT (CashFlowId, ',')) AS ca
      WHERE  ISNULL(tmp.CashFlowId, '') <> ''),
     cte1
AS   (SELECT   STRING_AGG(cte.CashFlowCode, ',') AS List_CatgDetailCode,
               STRING_AGG(cte.CashFlowId, ',') AS List_CashFlowId,
               cte.Id
      FROM     cte
      WHERE    cte.CashFlowCode <> ''
      GROUP BY cte.Id)
UPDATE  #K_BcTmp
    SET CashFlowCode    = ISNULL(IIF (c1.List_CatgDetailCode <> '', c1.List_CatgDetailCode, ''), ''),
        CashFlowId_List = ISNULL(IIF (c1.List_CashFlowId <> '', c1.List_CashFlowId, ''), '')
FROM    #K_BcTmp AS tmp2
        LEFT OUTER JOIN
        cte1 AS c1
        ON tmp2.Id = c1.Id;

        --select * from #K_BcTmp

SELECT   bc.Description,bc.Id,dat.*
FROM     #TblCashFlowData dat left join #K_BcTmp bc 
on charindex( (','+trim(str(dat.CashFlowId))+',') ,( ','+bc.CashFlowId_List+',')) <>0
and dat.MESGroupCode = bc.VarValue
 order by bc.Description ASC 
--ORDER BY docdate ASC