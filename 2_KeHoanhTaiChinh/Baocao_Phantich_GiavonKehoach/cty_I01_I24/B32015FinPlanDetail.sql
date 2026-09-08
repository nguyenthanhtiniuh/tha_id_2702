SELECT * FROM I24_FINPLAN

EXEC dbo.usp_sys_Append @_TableSource = 'I24_FINPLAN'          -- nvarchar(128)
                      , @_TableDestination = 'B32015FinPlanDetail'     -- nvarchar(128)
                    
UPDATE dbo.B32015FinPlanDetail
SET BizDocId
='I240000001FP'

SELECT * FROM B32012FinPlanDetail
SELECT DebitAccount,* FROM vB32015AccDocItem_Edit