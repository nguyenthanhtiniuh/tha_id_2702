ALTER PROC dbo.usp_TINNT_check_DefaultValue_Table @_Table_Name VARCHAR(256) ='B30LCDoc', @_Column_Name_List VARCHAR(4000) ='', @_DATA_TYPE_Infor VARCHAR(4000) ='', @_Column_Name_List_Exclude VARCHAR(4000) =''
AS BEGIN
    DECLARE @_object_id INT=OBJECT_ID(@_Table_Name)
    DROP TABLE IF EXISTS #tblINFORMATION_SCHEMACOLUMNS
    SELECT ',' AS Comma_COLUMN, _description.DefaultValue, schemacolumns.COLUMN_NAME, _description.value, CAST('' AS NVARCHAR(256)) AS DATA_TYPE_Infor, CAST('Tbl.Col.value(''@' AS NVARCHAR(256)) AS TblCol, UPPER(schemacolumns.DATA_TYPE) AS DATA_TYPE, schemacolumns.CHARACTER_MAXIMUM_LENGTH, schemacolumns.IS_NULLABLE, schemacolumns.ORDINAL_POSITION, CASE WHEN RIGHT(schemacolumns.COLUMN_NAME, 2)='Id' THEN 'Id'
                                                                                                                                                                                                                                                                                                                                                              WHEN RIGHT(schemacolumns.COLUMN_NAME, 4)='Code' THEN 'Code' ELSE '' END AS _TypeColum, CAST(NULL AS NVARCHAR(4000)) AS _Parame, CAST(NULL AS NVARCHAR(4000)) AS _Parame_Assign
    INTO #tblINFORMATION_SCHEMACOLUMNS
    FROM INFORMATION_SCHEMA.COLUMNS schemacolumns
         LEFT JOIN(SELECT prop.value, col.column_id, dc.definition AS DefaultValue
                   FROM sys.columns col
                        INNER JOIN sys.tables tab ON col.object_id=tab.object_id AND tab.name=@_Table_Name
                        LEFT JOIN sys.extended_properties prop ON col.object_id=prop.major_id AND col.column_id=prop.minor_id AND prop.class=1
                        LEFT JOIN sys.default_constraints dc ON col.default_object_id=dc.object_id AND col.object_id=OBJECT_ID(@_Table_Name)) _description ON _description.column_id=schemacolumns.ORDINAL_POSITION
    WHERE schemacolumns.TABLE_NAME=@_Table_Name
    UPDATE #tblINFORMATION_SCHEMACOLUMNS
    SET DATA_TYPE_Infor=CONCAT(DATA_TYPE, CASE WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN CONCAT('(', CHARACTER_MAXIMUM_LENGTH, ')') ELSE '' END)
    UPDATE #tblINFORMATION_SCHEMACOLUMNS
    SET TblCol=CONCAT(',', TblCol, COLUMN_NAME, ''' , ''', DATA_TYPE_Infor, ''' ) AS  ', COLUMN_NAME), _Parame=CONCAT(', @_', COLUMN_NAME, ' ', CASE WHEN DATA_TYPE_Infor LIKE '%VAR%' THEN DATA_TYPE_Infor
                                                                                                                                                WHEN DATA_TYPE_Infor NOT LIKE '%VAR%' THEN DATA_TYPE_Infor ELSE '' END, '= NULL OUTPUT '), _Parame_Assign=CONCAT(', @_', COLUMN_NAME, '=', COLUMN_NAME)
    IF(@_DATA_TYPE_Infor<>'')BEGIN
        DELETE #tblINFORMATION_SCHEMACOLUMNS
        WHERE DATA_TYPE_Infor NOT LIKE @_DATA_TYPE_Infor
    END
    IF @_Column_Name_List_Exclude<>'' BEGIN
        SELECT @_Column_Name_List_Exclude='%'+@_Column_Name_List_Exclude+'%'
        --SELECT @_Column_Name_List_Exclude
        DELETE #tblINFORMATION_SCHEMACOLUMNS
        WHERE Column_Name LIKE @_Column_Name_List_Exclude
    END
    IF @_Column_Name_List<>'' BEGIN
        SELECT *
        FROM #tblINFORMATION_SCHEMACOLUMNS
        WHERE COLUMN_NAME IN(SELECT * FROM STRING_SPLIT(@_Column_Name_List, ',') AS ss)
    END
    ELSE BEGIN
        SELECT * FROM #tblINFORMATION_SCHEMACOLUMNS ORDER BY COLUMN_NAME ASC
    END
    DROP TABLE IF EXISTS #tblINFORMATION_SCHEMACOLUMNS
END
GO
SET DATEFORMAT DMY
EXEC usp_TINNT_check_DefaultValue_Table @_Table_Name=N'B30OpenBalance', @_DATA_TYPE_Infor='NUMERIC'
--,@_Column_Name_List_Exclude = 'Original' -- Các cột loại trừ ko cần xem 
--,@_Column_Name_List = N'EInvoiceLink,EInvoiceKey' --thêm biến @_Column_Name_List để lọc các cột ưu tiên cần check


SELECT * FROM vB32000OpenBalance