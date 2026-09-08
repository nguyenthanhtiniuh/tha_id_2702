--select distinct entryno from b32001generalledger ORDER BY entryno

/*--5 loại
HD
A:
DebitAccount	CreditAccount
632201	155101
B

 
EntryNo	DebitAccount	CreditAccount
E2A	131101	511301
E2B	131101	511301
E3A	131101	333111
E3B	131101	333111


Stt			RowId			EntryNo			DebitAccount	CreditAccount
I010077877	I010648399HD	A				632201			155101
I010077877	I010648399HD	B				632201			155101
I010077877	I010648399HD	E2A				131101			511201
I010077877	I010648399HD	E2B				131101			511201
I010077877	I010648399HD	E3A				131101			333111
I010077877	I010648399HD	E3B				131101			333111

E2A: cặp hạch toán HD 1 
E2B: cặp hạch toán HD 2 
*/
 
select * from b32001generalledger where stt in (select * from string_split('I010078669,I010077215,I010078659,I010077889,I010077893,I010074371',','))
and (account like '511%' or crspaccount like '511%')
order by STT,ROWID,EntryNo 
select * from b32001stockledger where stt in (select * from string_split('I010078669,I010077215,I010078659,I010077889,I010077893,I010074371',',')) order by STT,ROWID,EntryNo 


SELECT Id,BranchCode,DocDate,DocNo,Description,DocGroup,DocCode,Stt,RowId,EntryNo,CustomerId,CustomerId0,ItemId,CurrencyCode,Account,CrspAccount,DebitAccount,CreditAccount,Quantity,OriginalAmount,Amount,OriginalDebitAmount,OriginalCreditAmount,DebitAmount,CreditAmount,BizDocId_C2
FROM vB32001GeneralLedger (NoLock) as sc 
WHERE (IsActive = 1) AND (DocDate BETWEEN '20260701' AND '20260730')
 AND BranchCode = 'I01'  AND (((Account LIKE '511%') OR (Account LIKE '521%')) AND ((CrspAccount NOT LIKE '911%')))

  