--gi? AI monitor: -- 1. TOP CÁC THÀNH PH?N SQL SERVER ?ANG N?P VÀO RAM
SELECT TOP 5
    type AS [Component_Type],
    CASE type
        WHEN 'MEMORYCLERK_SQLBUFFERPOOL' THEN N'Buffer Pool (Cache d? li?u & Index t? ??a)'
        WHEN 'CACHESTORE_SQLCP' THEN N'Ad-hoc Query Plan Cache (K? ho?ch th?c thi câu SQL ??ng)'
        WHEN 'CACHESTORE_OBJCP' THEN N'Object Plan Cache (K? ho?ch SP, Trigger, Function)'
        WHEN 'MEMORYCLERK_SQLSTOREDPROC' THEN N'B? nh? th?c thi Stored Procedure'
        WHEN 'MEMORYCLERK_SQLOPTIMIZER' THEN N'B? nh? dành cho SQL Optimizer'
        ELSE N'Thành ph?n khác'
    END AS [Description],
    SUM(pages_kb) / 1024 AS [Memory_MB]
FROM sys.dm_os_memory_clerks
GROUP BY type
ORDER BY SUM(pages_kb) DESC;

-- 2. TOP DATABASE ?ANG NG?N RAM TRONG BUFFER POOL
SELECT TOP 5
    DB_NAME(database_id) AS [Database_Name],
    COUNT(*) * 8 / 1024 AS [Buffer_Pool_MB]
FROM sys.dm_os_buffer_descriptors
WHERE database_id <> 32767
GROUP BY DB_NAME(database_id)
ORDER BY [Buffer_Pool_MB] DESC;

-- 3. TOP CÂU TRUY V?N ?ANG ?ÒI C?P NHI?U MEMORY GRANT NH?T (Memory-Intensive Queries)
SELECT TOP 5
    qs.grant_in_use_kb / 1024 AS [Grant_In_Use_MB],
    qs.requested_memory_kb / 1024 AS [Requested_MB],
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,   
        ((CASE qs.statement_end_offset  
          WHEN -1 THEN DATALENGTH(st.text)  
         ELSE qs.statement_end_offset  
         END - qs.statement_start_offset)/2) + 1) AS [Query_Text]
FROM sys.dm_exec_query_memory_grants qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.grant_in_use_kb DESC 