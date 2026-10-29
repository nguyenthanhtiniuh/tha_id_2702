USE B10THACOIDACC_Data;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROC dbo.usp_TINNT_check_DefaultValue_Table
    @_Table_Name VARCHAR(256) = 'B30LCDoc'
  , @_Column_Name_List VARCHAR(4000) = ''         -- truyền tên cột cần check
  , @_DATA_TYPE_Infor VARCHAR(4000) = ''          -- truyền loại dữ liệu cần check
  , @_Column_Name_List_Exclude VARCHAR(4000) = '' -- truyền tên cột cần loại trừ khi check
  , @_CheckUnique BIT = 0                         -- kiểm tra đã khai báo cột Index, PrimaryKey hay chưa
  , @_Fix_FieldList BIT = 0
  , @_nUserId INT = 1213
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @_object_id INT = OBJECT_ID(@_Table_Name);
    DROP TABLE IF EXISTS #tblINFORMATION_SCHEMACOLUMNS;
    SELECT ','                                        AS Comma_COLUMN
         , _description.DefaultValue
         , schemacolumns.COLUMN_NAME
         , _description.value
         , CAST('' AS NVARCHAR(256))                  AS DATA_TYPE_Infor
         , CAST('Tbl.Col.value(''@' AS NVARCHAR(256)) AS TblCol
         , UPPER(schemacolumns.DATA_TYPE)             AS DATA_TYPE
         , schemacolumns.CHARACTER_MAXIMUM_LENGTH
         , schemacolumns.IS_NULLABLE
         , schemacolumns.ORDINAL_POSITION
         , CASE
               WHEN RIGHT(schemacolumns.COLUMN_NAME, 2) = 'Id' THEN
                   'Id'
               WHEN RIGHT(schemacolumns.COLUMN_NAME, 4) = 'Code' THEN
                   'Code'
               ELSE
                   ''
           END                                        AS _TypeColum
         , CAST(NULL AS NVARCHAR(4000))               AS _Parame
         , CAST(NULL AS NVARCHAR(4000))               AS _Parame_Assign
    INTO #tblINFORMATION_SCHEMACOLUMNS
    FROM INFORMATION_SCHEMA.COLUMNS AS schemacolumns
        LEFT JOIN
        (
            SELECT prop.value
                 , col.column_id
                 , dc.definition AS DefaultValue
            FROM sys.columns                      AS col
                INNER JOIN sys.tables             AS tab
                    ON col.object_id = tab.object_id
                       AND tab.name = @_Table_Name
                LEFT JOIN sys.extended_properties AS prop
                    ON col.object_id = prop.major_id
                       AND col.column_id = prop.minor_id
                       AND prop.class = 1
                LEFT JOIN sys.default_constraints AS dc
                    ON col.default_object_id = dc.object_id
                       AND col.object_id = OBJECT_ID(@_Table_Name)
        )                           AS _description
            ON _description.column_id = schemacolumns.ORDINAL_POSITION
    WHERE schemacolumns.TABLE_NAME = @_Table_Name;
    UPDATE #tblINFORMATION_SCHEMACOLUMNS
    SET DATA_TYPE_Infor = CONCAT(   DATA_TYPE
                                  , CASE
                                        WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL THEN
                                            CONCAT('(', CHARACTER_MAXIMUM_LENGTH, ')')
                                        ELSE
                                            ''
                                    END
                                );

    IF @_Fix_FieldList = 1
        GOTO Fix_FieldList;

    ELSE
    BEGIN
        UPDATE #tblINFORMATION_SCHEMACOLUMNS
        SET TblCol = CONCAT(',', TblCol, COLUMN_NAME, ''' , ''', DATA_TYPE_Infor, ''' ) AS  ', COLUMN_NAME)
          , _Parame = CONCAT(   ', @_'
                              , COLUMN_NAME
                              , ' '
                              , CASE
                                    WHEN DATA_TYPE_Infor LIKE '%VAR%' THEN
                                        DATA_TYPE_Infor
                                    WHEN DATA_TYPE_Infor NOT LIKE '%VAR%' THEN
                                        DATA_TYPE_Infor
                                    ELSE
                                        ''
                                END
                              , '= NULL OUTPUT '
                            )
          , _Parame_Assign = CONCAT(', @_', COLUMN_NAME, '=', COLUMN_NAME);

        IF (@_DATA_TYPE_Infor <> '')
        BEGIN
            DELETE #tblINFORMATION_SCHEMACOLUMNS
            WHERE DATA_TYPE_Infor NOT LIKE @_DATA_TYPE_Infor;
        END;

        IF @_Column_Name_List_Exclude <> ''
        BEGIN
            SELECT @_Column_Name_List_Exclude = '%' + @_Column_Name_List_Exclude + '%';
            --SELECT @_Column_Name_List_Exclude  
            DELETE #tblINFORMATION_SCHEMACOLUMNS
            WHERE COLUMN_NAME LIKE @_Column_Name_List_Exclude;
        END;

        IF @_CheckUnique = 1
        BEGIN
            SELECT i.name AS IndexName
                 , c.name AS ColumnName
                 , i.is_unique
            FROM sys.indexes           AS i
                JOIN sys.index_columns AS ic
                    ON i.object_id = ic.object_id
                       AND i.index_id = ic.index_id
                JOIN sys.columns       AS c
                    ON ic.object_id = c.object_id
                       AND ic.column_id = c.column_id
            WHERE i.object_id = OBJECT_ID(@_Table_Name)
                  AND i.is_unique = 1
            ORDER BY i.name
                   , ic.key_ordinal;
            RETURN;
        END;

        DROP TABLE IF EXISTS #tmp_Col;
        CREATE TABLE #tmp_Col
        (
            Id INT IDENTITY
          , COLUMN_NAME VARCHAR(256)
        );

        INSERT INTO #tmp_Col
        (
            COLUMN_NAME
        )
        SELECT *
        FROM STRING_SPLIT(@_Column_Name_List, ',') AS ss;

        IF @_Column_Name_List <> ''
        BEGIN
            SELECT col.*
                 , col.COLUMN_NAME
                 , INFORcols.DATA_TYPE_Infor
                 , value
                 , DefaultValue
                 , INFORcols._Parame
                 , INFORcols._Parame_Assign
                 , XML_CODE
            FROM #tmp_Col                                     AS col
                INNER JOIN #tblINFORMATION_SCHEMACOLUMNS      AS INFORcols
                    ON col.COLUMN_NAME = INFORcols.COLUMN_NAME
                LEFT JOIN B10THACOIDACC.dbo.XML_COLUMN_FILTER AS fil
                    ON CHARINDEX(fil.COLUMN_NAME, col.COLUMN_NAME) >= 1
            ORDER BY col.Id ASC;
        END;
        ELSE
        BEGIN
            SELECT *
            FROM #tblINFORMATION_SCHEMACOLUMNS
            ORDER BY ORDINAL_POSITION ASC;
        END;
    END;


    Fix_FieldList:
    BEGIN

        DECLARE @_Exclude NVARCHAR(MAX) = '';

        SELECT @_Exclude = 'Id,ParentId,BranchCode,BizDocId,DocCode';


        DROP TABLE IF EXISTS #T_Fix_FieldList;
        SELECT COLUMN_NAME
             , FieldList.MasterTable
             , FieldList.MasterField
             , FieldList.Table_Name
             , FieldList.Field_Name
             , FieldList.CreatedBy
             , FieldList.CreatedAt
             , FieldList.ModifiedBy
             , FieldList.ModifiedAt
             , CAST(NULL AS BIT) AS _Check
        INTO #T_Fix_FieldList
        FROM #tblINFORMATION_SCHEMACOLUMNS AS t
            OUTER APPLY
        (
            SELECT TOP 1
                   *
            FROM B10THACOID.dbo.B00FieldList AS fl
            WHERE fl.Field_Name = t.COLUMN_NAME
        )                                  AS FieldList
        WHERE _TypeColum <> ''
              AND COLUMN_NAME NOT LIKE '%MES%'
              AND COLUMN_NAME NOT IN
                  (
                      SELECT value FROM STRING_SPLIT(@_Exclude, ',')
                  )
              -- 2026-09-28 lấy thêm Table_Name IS NULL => trường hợp cột chưa khai báo FieldList cho bất kỳ bảng nào
              AND
              (
                  FieldList.Table_Name IS NULL
                  OR B10THACOID.dbo.ufn_ReplaceMiddle4(FieldList.Table_Name) <> @_Table_Name
              )
        ORDER BY ORDINAL_POSITION ASC;



        -- Loại trừ các bảng đã khai báo
        DELETE #T_Fix_FieldList
        WHERE COLUMN_NAME IN
              (
                  SELECT fl.Field_Name
                  FROM #T_Fix_FieldList                      AS T_fl
                      INNER JOIN B10THACOID.dbo.B00FieldList AS fl
                          ON T_fl.Table_Name = fl.Table_Name
                             AND T_fl.Field_Name = fl.Field_Name
                  WHERE fl.CreatedBy IS NOT NULL
              );



        --
        UPDATE #T_Fix_FieldList
        SET Table_Name = @_Table_Name
          , CreatedBy = @_nUserId
          , CreatedAt = GETUTCDATE()
          , ModifiedBy = @_nUserId
          , ModifiedAt = GETUTCDATE();

        IF EXISTS (SELECT * FROM #T_Fix_FieldList)
        BEGIN

            --Step 1: Đổ dữ liệu bảng vào đơn vị T00
            EXEC B10THACOID.dbo.usp_sys_Append @_TableSource = '#T_Fix_FieldList'   -- nvarchar(128)
                                             , @_TableDestination = 'b00fieldlist'; -- nvarchar(128)

            DECLARE @_Tbl_MasterTable NVARCHAR(128) = '';
            DECLARE @_Tbl_Req NVARCHAR(128) = @_Table_Name;
            DECLARE @_Tbl_Field_Name NVARCHAR(128) = '';

            DECLARE @_Table_Name_Ori NVARCHAR(128) = @_Table_Name;


            --Step 2: Đổ dữ liệu bảng vào all đơn vị còn lại
            --WHILE EXISTS (SELECT * FROM #T_Fix_FieldList WHERE _Check IS NULL)
            --BEGIN

            --    SELECT TOP 1
            --           @_Tbl_MasterTable = MasterTable
            --         , @_Tbl_Req         = Table_Name
            --         , @_Tbl_Field_Name  = Field_Name
            --    FROM #T_Fix_FieldList
            --    WHERE _Check IS NULL
            --    ORDER BY MasterTable ASC;

            --    UPDATE #T_Fix_FieldList
            --    SET _Check = 1
            --    WHERE MasterTable = @_Tbl_MasterTable;

            --    SELECT @_Tbl_MasterTable
            --         , @_Tbl_Req
            --         , @_Tbl_Field_Name;

            --    --SET DATEFORMAT DMY;
            --    --EXEC B10THACOID.dbo.usp_sys_FixTest_B00FieldList @_Tbl_MasterTable = @_Tbl_MasterTable
            --    --                                               , @_Tbl_Req = @_Table_Name
            --    --                                               , @_Tbl_Field_Name = @_Tbl_Field_Name
            --    --                                               , @_nUserId = @_nUserId;

            --    --Nếu đã khởi tạo thì chạy đoạn này để check
            --    SELECT @_Table_Name = REPLACE(@_Table_Name, '0', '%');


            --    SELECT a._Count
            --         , fl.*
            --    FROM
            --    (
            --        SELECT COUNT(*) AS _Count
            --        FROM B10THACOID.dbo.B00FieldList
            --        WHERE Table_Name LIKE @_Table_Name AND MasterTable = @_Tbl_MasterTable
            --    ) AS a
            --  , B10THACOID.dbo.B00FieldList AS fl
            --    WHERE Table_Name = @_Table_Name_Ori AND MasterTable = @_Tbl_MasterTable

            --    SELECT a._Count
            --         , fl.*
            --    FROM
            --    (
            --        SELECT COUNT(*) AS _Count
            --        FROM B10THACOID.dbo.B00FieldList
            --        WHERE Table_Name LIKE @_Table_Name AND MasterTable = @_Tbl_MasterTable
            --    ) AS a
            --  , B10THACOID.dbo.B00FieldList AS fl
            --    WHERE Table_Name = @_Table_Name_Ori AND MasterTable = @_Tbl_MasterTable

            --END;
        END;

        ELSE
        BEGIN
            --Nếu đã khởi tạo thì chạy đoạn này để check
            SELECT @_Table_Name = REPLACE(@_Table_Name, '0', '%');

            SELECT *
            FROM B10THACOID.dbo.B00FieldList
            WHERE Table_Name LIKE @_Table_Name;


            SELECT *
            FROM B10THACOIDACC.dbo.B00FieldList
            WHERE Table_Name LIKE @_Table_Name;


        END;



        SELECT *
        FROM #T_Fix_FieldList;


    END;

    DROP TABLE IF EXISTS #tblINFORMATION_SCHEMACOLUMNS
                       , #tmp_Col
                       , #T_Fix_FieldList;
END;

GO


EXEC dbo.usp_TINNT_check_DefaultValue_Table @_Table_Name = N'B30CapExPlanDetail'
                                          , @_CheckUnique = 1
                                          , @_Fix_FieldList = 1;


GO
