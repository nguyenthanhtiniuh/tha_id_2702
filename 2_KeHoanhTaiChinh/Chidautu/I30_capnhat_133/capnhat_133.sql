UPDATE B32022AccDocEntityAsset
SET EntryNo = NULL

--SELECT *
FROM B32022AccDocEntityAsset       AS AccDocEntityAsset
    INNER JOIN B32022GeneralLedger AS CT
        ON AccDocEntityAsset.ParentRowId = CT.RowId
           AND AccDocEntityAsset.BranchCode = CT.BranchCode
           AND
           (
               CT.EntryNo = 'A'
               OR CT.EntryNo = 'E3A'
           )
WHERE AccDocEntityAsset.EntryNo IS NULL;
--AND AccDocEntityAsset.EntryNo = CT.EntryNo;


UPDATE AccDocEntityAsset
SET EntryNo = CT.EntryNo
  , ParentUniqueId = CT.UniqueId
--SELECT *
FROM B32022AccDocEntityAsset       AS AccDocEntityAsset
    INNER JOIN B32022GeneralLedger AS CT
        ON AccDocEntityAsset.ParentRowId = CT.RowId
           AND AccDocEntityAsset.BranchCode = CT.BranchCode
           AND
           (
               CT.EntryNo = 'A'
               OR CT.EntryNo = 'E3A'
           )
           AND AccDocEntityAsset.Amount = CT.debitamount
WHERE AccDocEntityAsset.EntryNo IS NULL;
--AND AccDocEntityAsset.EntryNo = CT.EntryNo;