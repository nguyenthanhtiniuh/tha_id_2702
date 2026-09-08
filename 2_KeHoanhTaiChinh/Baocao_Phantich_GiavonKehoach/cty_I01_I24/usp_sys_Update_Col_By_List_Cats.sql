SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
ALTER   PROC dbo.usp_sys_Update_Col_By_List_Cats 
    @_CtTmp NVARCHAR(254) = ''
   ,@_List_Cats NVARCHAR(4000) = ''
   ,@_SetString_Other NVARCHAR(4000) = ''
   ,@_WhereString NVARCHAR(4000) = ''
   ,@_PrintExec INT = 0
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @_objId_CtTmp INT = OBJECT_ID(N'TempDb..' + @_CtTmp, N'U')
           ,@_nl CHAR(1) = CHAR(13)

    DECLARE @Tbl_List_Cats TABLE
    (
        No_Num INT IDENTITY
       ,Name VARCHAR(256)
    )

    INSERT INTO @Tbl_List_Cats
    (
        Name
    )
    SELECT ss.value
    FROM STRING_SPLIT(@_List_Cats, ',') AS ss


    DECLARE @_StrExec NVARCHAR(MAX) = N''
    DROP TABLE IF EXISTS #_TempTbl_Columns
    SELECT tsysCol.name
          ,ISNULL(tlc.Name, '') AS AliasTableName
          ,'B20' + tlc.Name AS TableName
          ,tsysCol.system_type_id
          ,tsysCol.max_length
          ,tsysCol.precision
          ,tsysCol.scale
          ,CASE
               WHEN RIGHT(tsysCol.name, 2) = 'Id' THEN
                   'Id'
               WHEN RIGHT(tsysCol.name, 4) = 'Code' THEN
                   'Code'
               WHEN RIGHT(tsysCol.name, 4) = 'Name' THEN
                   'Name'
               ELSE
                   ''
           END AS _TypeColum
          ,CAST('' AS NVARCHAR(4000)) AS _SetString
          ,CAST('' AS NVARCHAR(4000)) AS _JOINString
          ,CAST('' AS NVARCHAR(4000)) AS _INNER_JOINString
          ,PATINDEX(tlc.Name + '%', tsysCol.name) AS _t
    INTO #_TempTbl_Columns
    FROM @Tbl_List_Cats AS tlc
         LEFT JOIN tempdb.sys.columns AS tsysCol WITH (NOLOCK) ON (PATINDEX(tlc.Name + '%', tsysCol.name) >= 1)
    WHERE tsysCol.object_id = @_objId_CtTmp

    DELETE #_TempTbl_Columns
    WHERE ISNULL(_TypeColum, '') = ''

    UPDATE #_TempTbl_Columns
    SET _SetString = 'kq.' + name + ' = ISNULL(' + AliasTableName + '.' + _TypeColum + ','''')'
    WHERE _TypeColum IN ( 'Code', 'Name' )

    UPDATE #_TempTbl_Columns
    SET _JOINString = ' ON kq.' + name + ' = ' + AliasTableName + '.' + _TypeColum
    WHERE _TypeColum IN ( 'Id' )

    UPDATE #_TempTbl_Columns
    SET _INNER_JOINString = ' INNER JOIN dbo.' + TableName + ' ' + AliasTableName + ' ' + _JOINString
    WHERE _TypeColum IN ( 'Id' )

    DECLARE @_SetString NVARCHAR(4000) = ((
                                              SELECT STRING_AGG(_SetString + @_nl, ',')
                                              FROM #_TempTbl_Columns
                                              WHERE ISNULL(_SetString, '') <> ''
                                          )
                                         )

    IF ISNULL(@_SetString_Other, '') <> ''
        SELECT @_SetString = @_SetString + @_nl + @_SetString_Other
 
    DECLARE @_INNER_JOINString NVARCHAR(4000) = N'';
    WITH cte
    AS (SELECT DISTINCT
               _INNER_JOINString
        FROM #_TempTbl_Columns
        WHERE _INNER_JOINString <> ''  AND name NOT LIKE '%MESId%'  )
    SELECT @_INNER_JOINString = STRING_AGG(cte._INNER_JOINString, @_nl)
    FROM cte

    DECLARE @_PRINT_Str NVARCHAR(MAX)

    IF ISNULL(@_SetString, '') = ''
        SELECT @_PRINT_Str
            = N'Ko có chu?i @_SetString. Khai báo thi?u c?t Code,Name c?a danh m?c. Hãy ki?m tra l?i b?ng ' + @_CtTmp
              + N'!!! '
    IF ISNULL(@_INNER_JOINString, '') = ''
        SELECT @_PRINT_Str += N',ko có chu?i @_INNER_JOINString'

    SELECT @_StrExec = N'   
UPDATE kq SET ' + @_nl + @_SetString + N'  
FROM ' + @_CtTmp + N' kq  
' +     @_INNER_JOINString + N' ' + @_nl + @_WhereString
    /*  
    1.Id là tiêu chí ?? join  
    2.Các c?t type là tiêu chí ?? c?p nh?t      
    */
    IF @_PrintExec = 1
    BEGIN
        PRINT (@_PRINT_Str)
        PRINT (@_StrExec)
    END
    IF ISNULL(@_StrExec, '') <> ''
        EXEC (@_StrExec)
    ELSE IF ISNULL(@_StrExec, '') = ''
    BEGIN
        SELECT @_SetString AS SetString
              ,@_CtTmp AS CtTmp
              ,@_INNER_JOINString AS INNER_JOINString
              ,@_StrExec AS StrExec
    END
    DROP TABLE IF EXISTS #_TempTbl_Columns
END
GO

