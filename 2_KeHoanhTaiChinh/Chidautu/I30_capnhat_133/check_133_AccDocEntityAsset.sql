SELECT *
FROM vB32022AccDocEntityAsset_Explore AS AccDocEntityAsset
    INNER JOIN B32022GeneralLedger    AS CT
        ON AccDocEntityAsset.ParentRowId = CT.RowId
           AND AccDocEntityAsset.BranchCode = CT.BranchCode
           AND AccDocEntityAsset.EntryNo = CT.EntryNo
--AND (CT.EntryNo LIKE '%A')
WHERE AccDocEntityAsset.Stt = 'IBC0001121';
--AND CT.EntryNo IS NOT NULL;

/*
KẾ THỪA CẢ DÒNG THUẾ
*/
SELECT *
FROM B32022AccDocEntityAsset
WHERE Stt = 'IBC0001121';
--EntryNo ='A' OR EntryNo ='E3A'

SELECT * FROM vB32022AccDocAtchPurchase_Edit
WHERE Stt = 'IBC0001121';

SELECT *
FROM B32022GeneralLedger
WHERE Stt = 'IBC0001121';

GO

--dbo._CreateTableByBranch @_TableName = 'vB30AccDocEntityAsset_Explore' -- varchar(128)
--                       , @_BranchCode = ''                       -- nvarchar(3)
--                       , @_NewTableName = ''                     -- varchar(128)
--                       , @_DropObjBefCreate = 0                  -- tinyint
--                       , @_CreateSeq = 0                         -- int
--                       , @_RunType = 1                           -- tinyint
--                       , @_PrintCmd = 1                          -- tinyint
--                       , @_CreateTrigger = 1                     -- tinyint
