--update B10KqtCashFlowPlan set SourceTable = 'B10KqtCashFlowPlan' where KqtCashFlowPlanId='T000000003'
--select SourceTable,* from B10KqtCashFlowPlan where KqtCashFlowPlanId='T000000003'


SET DATEFORMAT dmy;
DECLARE @_Doc1 AS DATE, @_Doc2 AS DATE;
SELECT @_Doc1 = '20260601',@_Doc2 = '20260630';

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
--CFOI2-04
--17696470

*/


DROP TABLE IF EXISTS #TblCashFlowData;

SELECT ge.Stt,RowId,DebitAccount,CreditAccount,Account,CrspAccount,DebitAmount,CreditAmount,EntryNo,CashFlowId,cu.MESGroupCode
INTO   #TblCashFlowData
FROM   b32002generalledger ge inner join B20Customer (nolock) cu on ge.CustomerId0 = cu.Id
WHERE  docdate BETWEEN @_doc1 AND @_doc2
       AND (Account LIKE '111%'
       or Account LIKE '112%'
       or Account LIKE '113%')
       --) or (CrspAccount LIKE '111%'
       --or CrspAccount LIKE '112%'
       --or CrspAccount LIKE '113%'
       --)
       AND (EntryNo = 'A'
       or EntryNo = 'B')
       AND CashFlowId IS NOT NULL;

--bang khai bao
DROP TABLE IF EXISTS #K_BcTmp;

SELECT *,
       CAST ('' AS NVARCHAR (MAX)) AS CashFlowCode,
       CAST ('' AS NVARCHAR (MAX)) AS CashFlowId_List
INTO   #K_BcTmp
FROM   B10KqtCashFlowPlan
WHERE  SourceTable = 'B10KqtCashFlowPlan'
       AND KqtCashFlowPlanId = 'T000000003'; 

      -- SELECT dbo.ufn_Get_List_CatgDetail(ca.value, 'B20CashFlow', 'Code') AS CashFlowCode,
      --       dbo.ufn_Get_List_CatgDetail(ca.value, 'B20CashFlow', 'Id') AS CashFlowId,
      --       tmp.Id,tmp.BuiltinOrder,Description,Loai_Ps,VarValue
      --FROM   #K_BcTmp AS tmp CROSS APPLY (SELECT value
      --                                    FROM   STRING_SPLIT (CashFlowId, ',')) AS ca
      --WHERE  ISNULL(tmp.CashFlowId, '') <> '' order by Loai_Ps,BuiltinOrder,VarValue asc  return 
 
;WITH cte
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
        CashFlowId_List = ISNULL(IIF (c1.List_CashFlowId <> '', c1.List_CashFlowId, ''), ''),
        VarValue= isnull(VarValue,'')
FROM    #K_BcTmp AS tmp2
        LEFT OUTER JOIN
        cte1 AS c1
        ON tmp2.Id = c1.Id;

update #K_BcTmp set CashFlowId_List = CashFlowId where ItemLevel = 9 and CashFlowId_List ='' and CashFlowId<>''

        --select * from #K_BcTmp where ItemLevel = 9 
        ----and CashFlowId_List ='' and CashFlowId<>'' 
        --return 

        --select * from #K_BcTmp where Loai_Ps = 'PS_CO' 
        
        --select Id,VarValue,value from #K_BcTmp
        --cross apply (select value from STRING_SPLIT(CashFlowId_List,',')) as ca
        --where Loai_Ps = 'PS_CO' return   
--select * from #TblCashFlowData where EntryNo = 'B' return 

--thu tiền
DROP TABLE IF EXISTS #TblCashFlowData_A;
SELECT   bc.Description as DescriptionBcTmp,bc.BuiltinOrder,bc.Id as IdBcTmp,Loai_Ps,dat.* into #TblCashFlowData_A
FROM     #TblCashFlowData dat left join #K_BcTmp bc 
on charindex( (','+trim(str(dat.CashFlowId))+',') ,( ','+bc.CashFlowId_List+',')) <>0
and (charindex((','+dat.MESGroupCode+',') ,(','+ bc.VarValue+',') ) <>  0 
or isnull(bc.VarValue,'')='')
where bc.Description is not null and EntryNo='A' and Loai_Ps='PS_NO'
 order by bc.Description ASC 


DROP TABLE IF EXISTS #TblCashFlowData_b;
SELECT   bc.Description as DescriptionBcTmp,bc.Id as IdBcTmp,Loai_Ps,bc.BuiltinOrder,dat.*    into #TblCashFlowData_B
FROM     #TblCashFlowData dat left join #K_BcTmp bc 
on charindex( (','+trim(str(dat.CashFlowId))+',') ,( ','+bc.CashFlowId_List+',')) <>0
and  ( charindex((','+dat.MESGroupCode+',') ,(','+ bc.VarValue+',') ) <>  0
or isnull(bc.VarValue,'')='')
where  bc.Description is not null and EntryNo='B' and Loai_Ps='PS_CO'
 order by bc.Description ASC 
 

--select * from #TblCashFlowData_A

--select * from #TblCashFlowData_b return 

select *     from #TblCashFlowData_A

select sum(DebitAmount) as DebitAmount,format(sum(DebitAmount),'N0'),'CashFlowData_A' as CashFlowData,DescriptionBcTmp,BuiltinOrder,Loai_Ps
 from #TblCashFlowData_A  group by DescriptionBcTmp,BuiltinOrder,Loai_Ps


 select *     from #TblCashFlowData_b
select sum(CreditAmount) as CreditAmount,format(sum(CreditAmount),'N0'),'CashFlowData_B' as CashFlowData,DescriptionBcTmp,BuiltinOrder,Loai_Ps
from #TblCashFlowData_b group by DescriptionBcTmp,BuiltinOrder,Loai_Ps
 
  
 
 ;with cteCashFlowData as (
select sum(DebitAmount) as DebitAmount,'TblCashFlowDataEntryNoA' as TblCashFlowDataEntryNoA from #TblCashFlowData where EntryNo = 'A')
,TblCashFlowData_A as 
(select sum(DebitAmount) as DebitAmount from #TblCashFlowData_A  )select c.DebitAmount-a.DebitAmount as diffDebitAmount from cteCashFlowData c ,TblCashFlowData_A a

select sum(CreditAmount),'TblCashFlowDataEntryNoB' as TblCashFlowDataEntryNoB from #TblCashFlowData where EntryNo = 'B'


select sum(DebitAmount)    as DebitAmount
,  sum(CreditAmount) as CreditAmount  from #TblCashFlowData 