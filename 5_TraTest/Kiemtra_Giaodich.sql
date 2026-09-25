UPDATE dbo.B00Command
SET IsActive=0
WHERE CommandKey IN(SELECT *
                    FROM STRING_SPLIT('REP_DisbPlanInvest_HN,REP_InvestAssetAccPlanHN,REP_MidLongCreditPlan,REP_WCCreditPlan,REP_DueLoan,REP_LoanDue', ','));

/*
check lại cmd nào lấy từ B7
1. cmd từ B7
2. cmd viết mới
*/
DECLARE @_id INT=1213;
DROP TABLE IF EXISTS #tbl;
SELECT Id, ParentId, IsGroup, CommandKey, CASE WHEN DLLName='DataExplorer' THEN CommandKey
                                          WHEN DLLName='DataEditor' THEN REPLACE(CommandKey, 'Edit_', '')ELSE '' END AS Parent_CommandKey, Text, Text_English DLLName, ClassName, CtorArgs, IsActive, CreatedBy, CreatedAt, ModifiedBy, ModifiedAt
INTO #tbl
FROM B00Command
WHERE CreatedBy=@_id AND DLLName IN(SELECT * FROM STRING_SPLIT('DataEditor,DataExplorer', ','))AND IsActive=1
ORDER BY DLLName;
SELECT CommandB7.CommandKey AS CommandKeyB7, t.*
FROM #tbl t
     LEFT JOIN B00CommandB7 CommandB7 ON t.CommandKey=CommandB7.CommandKey
ORDER BY CommandB7.CommandKey DESC, Parent_CommandKey ASC, Id ASC;

/*
check lại báo cáo nào lấy từ B7
1. báo cáo từ B7
2. báo cáo viết mới
*/
DROP TABLE IF EXISTS #tblReporter;
SELECT Id, ParentId, IsGroup, CommandKey, CASE WHEN DLLName='DataExplorer' THEN CommandKey
                                          WHEN DLLName='DataEditor' THEN REPLACE(CommandKey, 'Edit_', '')ELSE '' END AS Parent_CommandKey, Text, Text_English DLLName, ClassName, CtorArgs, IsActive, CreatedBy, CreatedAt, ModifiedBy, ModifiedAt
INTO #tblReporter
FROM B00Command
WHERE CreatedBy=@_id AND DLLName IN(SELECT * FROM STRING_SPLIT('Reporter,Reporter', ','))AND IsActive=1
ORDER BY DLLName;

SELECT CommandB7.CommandKey AS CommandKeyB7, t.*
FROM #tblReporter t
     LEFT JOIN B00CommandB7 CommandB7 ON t.CommandKey=CommandB7.CommandKey
ORDER BY CommandB7.CommandKey DESC, Parent_CommandKey ASC, Id ASC;

/*
cmd Wizard
*/
DROP TABLE IF EXISTS #tblWizard;
SELECT Id, ParentId, IsGroup, CommandKey, CASE WHEN DLLName='DataExplorer' THEN CommandKey
                                          WHEN DLLName='DataEditor' THEN REPLACE(CommandKey, 'Edit_', '')ELSE '' END AS Parent_CommandKey, Text, Text_English DLLName, ClassName, CtorArgs, IsActive, CreatedBy, CreatedAt, ModifiedBy, ModifiedAt
INTO #tblWizard
FROM B00Command
WHERE CreatedBy=@_id AND DLLName IN(SELECT * FROM STRING_SPLIT('Wizard', ','))AND IsActive=1
ORDER BY DLLName;
SELECT * FROM #tblWizard ORDER BY Parent_CommandKey ASC, Id ASC;