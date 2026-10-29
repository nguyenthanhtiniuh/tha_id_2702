--DECLARE @_o_id INT;

DECLARE @_TableName VARCHAR(24) = 'B20Asset';


DROP TABLE IF EXISTS #t;
WITH Tbl
AS (SELECT DISTINCT
           b.DataCode
         , REPLACE(@_TableName, '0', b.DataCode) AS TableName
    FROM dbo.B00Branch AS b)
SELECT t.DataCode
     , t.TableName
     , o.object_id
     , c.name                    AS ColumnName
     , TYPE_NAME(c.user_type_id) AS DataType
     , c.max_length              AS MaxLength
     , CASE c.is_nullable
           WHEN 0 THEN
               'NOT NULL'
           WHEN 1 THEN
               'NULL'
       END                       AS Nullable
     , c.is_identity             AS IsIdentity
     , dc.definition             AS DefaultValue
INTO #t
FROM Tbl                              AS t
    LEFT JOIN sys.objects             AS o
        ON o.object_id = OBJECT_ID(N'dbo.' + t.TableName)
    LEFT JOIN sys.columns             AS c
        ON c.object_id = o.object_id
           AND c.name = 'Code'
    LEFT JOIN sys.default_constraints AS dc
        ON dc.object_id = c.default_object_id
ORDER BY t.DataCode;


SELECT *
     , '


UPDATE dbo.' + TableName + '
SET [Code] = ''''
WHERE [Code] IS NULL;

ALTER TABLE dbo.[' + TableName + ']
ALTER COLUMN [Code] VARCHAR(24) NOT NULL;

ALTER TABLE dbo.[' + TableName + ']
ADD CONSTRAINT [DF_' + TableName + '_Code]
DEFAULT ('''') FOR [Code];

'
FROM #t
WHERE Nullable = 'NULL';