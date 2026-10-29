USE B10THACOID;
GO

DROP TABLE IF EXISTS #T_Logging;
 
CREATE TABLE #T_Logging
(
    Id INT
  , CommandKey VARCHAR(24)
  , ParentCommandKey VARCHAR(24)
  , SubCommandKeys VARCHAR(512)
  , TableName VARCHAR(48)
  , LoggingColumns VARCHAR(512)
  , IdentityColumn VARCHAR(48)
  , IsActive BIT
  , CreatedBy INT
  , CreatedAt SMALLDATETIME
  , ModifiedBy INT
  , ModifiedAt SMALLDATETIME
  , LoggingColumns_Old VARCHAR(512)
  , SubLoggingColumn VARCHAR(512)
);

INSERT INTO #T_Logging
(
    Id
  , CommandKey
  , ParentCommandKey
  , SubCommandKeys
  , TableName
  , LoggingColumns
  , IdentityColumn
  , IsActive
  , CreatedBy
  , CreatedAt
  , ModifiedBy
  , ModifiedAt
  , LoggingColumns_Old
  , SubLoggingColumn
)
VALUES
(2722, 'OpenBiz_LC', NULL, NULL, 'B30OpenBizDoc', 'BizDocId', NULL, 1, 1213, N'2026-10-06T07:26:00', -1
, N'2026-10-06T07:26:00', 'Stt,DocNo,Description', 'DocNo')
, (2723, 'EDIT_OpenBiz_LC', 'OpenBiz_LC', NULL, 'B30OpenBizDoc', 'BizDocId', NULL, 1, 1213, N'2026-10-06T07:27:00', -1
 , N'2026-10-06T07:27:00', 'Stt,DocNo,Description', 'DocNo');


ALTER TABLE #T_Logging DROP COLUMN Id;

SELECT *
FROM #T_Logging;


EXEC dbo.usp_sys_Append @_TableSource = '#T_Logging'       -- nvarchar(128)
                      , @_TableDestination = 'B00Logging'; -- nvarchar(128)

SELECT *
FROM dbo.B00Logging
WHERE CommandKey IN
      (
          SELECT CommandKey FROM #T_Logging
      )
ORDER BY Id ASC;

DROP TABLE #T_Logging;