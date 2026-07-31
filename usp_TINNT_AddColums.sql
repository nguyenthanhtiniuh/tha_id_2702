ALTER PROCEDURE dbo.usp_TINNT_AddColums
    @_TableName NVARCHAR(64) = N''
   ,@_ColName NVARCHAR(64) = N''
   ,@_DataType NVARCHAR(64) = N'INT'
   ,@_Type NVARCHAR(64) = N'ADD'
   ,@_Auto_Exec INT = 0
   ,@_ColName_Old NVARCHAR(64) = N'BizDocId_SO'
   ,@_ColName_New NVARCHAR(64) = N'BizDocId_C2'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @_StrExec NVARCHAR(MAX) = N''
           ,@_BranchCode NVARCHAR(3) = N''
           ,@_DataCode NVARCHAR(4) = N''
           ,@_nl CHAR(1) = CHAR(10)
           ,@_TableName_Alter NVARCHAR(256) = N''

    IF OBJECT_ID('Tempdb..#Dvcs') IS NOT NULL
        DROP TABLE #Dvcs;
    SELECT Id
          ,BranchCode
          ,DataCode
    INTO #Dvcs
    FROM B10THACOID.dbo.B00Branch
    WHERE DataCode <> ''
          AND IsGroup = 0
          AND IsActive = 1
    ORDER BY Id

    DECLARE @sql NVARCHAR(MAX) = N''

    WHILE EXISTS (SELECT * FROM #Dvcs)
    BEGIN
        SELECT TOP 1
               @_BranchCode = BranchCode
              ,@_DataCode   = DataCode
        FROM #Dvcs
        ORDER BY Id

        --SELECT @_DataCode, @_TableName, REPLACE(@_TableName, 'B30', 'B3' + @_DataCode)  

        SELECT @_TableName_Alter = REPLACE(@_TableName, 'B30', 'B3' + @_DataCode)


        IF OBJECT_ID(@_TableName_Alter) IS NOT NULL
        BEGIN


            IF @_Type = 'ADD'
            BEGIN
                SET @_StrExec
                    = N' ALTER TABLE ' + @_TableName_Alter + N'  ADD  ' + @_ColName + N' ' + @_DataType + N'    '
            END

            IF @_Type = 'DROP'
            BEGIN
                SET @_StrExec = N' ALTER TABLE ' + @_TableName_Alter + N'  drop   COLUMN    ' + @_ColName + N' ' + @_nl
            END

            IF @_Type = 'ALTER'
            BEGIN
                SET @_StrExec
                    = N' ALTER TABLE ' + @_TableName_Alter + N' ALTER  COLUMN    ' + @_ColName + N'  NVARCHAR(512) '
                      + @_nl
            END

            --SET @_StrExec = N' ALTER TABLE ' + @_TableName + N'  ADD  ' + @_ColName + N' ' + @_DataType + N' ' +   +' DEFAUTL 0 NOT NULL '  

            --sET @_StrExec = N' ALTER TABLE ' + @_TableName + N'  drop   COLUMN    ' + @_ColName + N' ' + @_nl  

            --SET @_StrExec = N' ALTER TABLE ' + @_TableName + N' ALTER  COLUMN ' + @_ColName + N'  NVARCHAR(512)    DEFAUTL ''''  '  

            --SET @_StrExec = N' DROP TABLE IF EXISTS  ' + @_TableName  

            IF @_Type = 'sp_rename'
            BEGIN
                --SET @_StrExec = N' EXEC sp_rename ''' + @_TableName + N'.BizDocId_C2'', ''BizDocId_SO'', ''COLUMN'';'  


                SET @_StrExec
                    = N' EXEC sp_rename ''' + @_TableName_Alter + N'.' + @_ColName_Old + N''', ''' + @_ColName_New
                      + N''', ''COLUMN'';'
            END

            IF @_Type = 'DF'
            BEGIN

                --SET @_StrExec = N' ALTER TABLE ' + @_TableName + N' ALTER  COLUMN ' + @_ColName + N'  TINYINT '  
                SET @_StrExec
                    = N' ALTER TABLE ' + @_TableName_Alter + N'  ADD CONSTRAINT DF_' + @_TableName
                      + N'_IsMaterialFactor DEFAULT 1 FOR IsMaterialFactor; '

            END

            PRINT @_StrExec

        --SELECT @sql  
        --    =  
        --(  
        --    SELECT STRING_AGG(  
        --                         'ALTER TABLE [' + OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' + name  
        --                         + '];'  
        --                        ,CHAR(13)  
        --                     )  
        --    FROM sys.foreign_keys  
        --    WHERE referenced_object_id = OBJECT_ID(@_TableName)  
        --);  

        --EXEC (@_StrExec)  
        END

        PRINT @sql

        DELETE FROM #Dvcs
        WHERE BranchCode = @_BranchCode

        IF @_Auto_Exec = 1
            EXEC @sql

    END
    IF OBJECT_ID('Tempdb..#Dvcs') IS NOT NULL
        DROP TABLE #Dvcs;
END

GO

/*

EInvoiceLink	NVARCHAR(256)
EInvoiceKey	NVARCHAR(64)

*/

SET DATEFORMAT DMY
EXEC usp_TINNT_AddColums @_TableName = N'B30AssetProduct'
                        ,@_ColName = N'EffectiveDate'
                        ,@_DataType = N'DATE'
                        ,@_Type = N'ADD'
                        ,@_Auto_Exec = 0
--,@_ColName_Old = N'BizDocId_SO'
--,@_ColName_New = N'BizDocId_C2'
