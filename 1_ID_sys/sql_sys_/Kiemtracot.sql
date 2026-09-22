SELECT c1.name       AS ColumnName
     , c1.max_length AS Length_TableA
FROM sys.columns AS c1
WHERE c1.object_id = OBJECT_ID('dbo.B10BusinessPlanPNDetail')
ORDER BY c1.name;

SELECT c1.name       AS ColumnName
     , c1.max_length AS Length_TableA
FROM sys.columns AS c1
WHERE c1.object_id = OBJECT_ID('dbo.B10BusinessPlanHNDetail')
ORDER BY c1.name;


SELECT c1.name       AS ColumnName
     --, t1.name       AS DataType_TableA
     , c1.max_length AS Length_TableA
     --, t2.name       AS DataType_TableB
     , c2.max_length AS Length_TableB
FROM sys.columns     AS c1
    JOIN sys.columns AS c2
        ON c1.name <> c2.name
 
WHERE c1.object_id = OBJECT_ID('dbo.B10BusinessPlanPNDetail')
      AND c2.object_id = OBJECT_ID('dbo.B10BusinessPlanHNDetail')
ORDER BY c1.name;


