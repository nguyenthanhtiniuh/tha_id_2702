 
USE B10THACOIDACC_Data
GO
/****** Object:  StoredProcedure [dbo].[usp_TINNT_AddColums]    Script Date: 2026-09-04 7:32:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE dbo.usp_TINNT_AddColums
    @_TableName NVARCHAR(64) = N''
  , @_ColName NVARCHAR(64) = N''
  , @_DataType NVARCHAR(64) = N'INT'
  , @_Type NVARCHAR(64) = N'ADD'
  , @_Type_ALTER NVARCHAR(64) = N'datetime'
  , @_Auto_Exec INT = 0
  , @_ColName_Old NVARCHAR(64) = N'BizDocId_SO'
  , @_ColName_New NVARCHAR(64) = N'BizDocId_C2'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @_StrExec         NVARCHAR(MAX) = N''
          , @_BranchCode      NVARCHAR(3)   = N''
          , @_DataCode        NVARCHAR(4)   = N''
          , @_nl              CHAR(1)       = CHAR(10)
          , @_TableName_Alter NVARCHAR(256) = N''
    DECLARE @sql NVARCHAR(MAX) = N''

    IF OBJECT_ID('Tempdb..#Dvcs') IS NOT NULL
        DROP TABLE #Dvcs;

    SELECT Id
         , BranchCode
         , DataCode
    INTO #Dvcs
    FROM B10THACOID.dbo.B00Branch
    WHERE DataCode <> ''
          AND IsGroup = 0
          AND IsActive = 1
    ORDER BY Id



    WHILE EXISTS (SELECT * FROM #Dvcs)
    BEGIN
        SELECT TOP (1)
               @_BranchCode = BranchCode
             , @_DataCode   = DataCode
        FROM #Dvcs
        ORDER BY Id

        --SELECT @_DataCode, @_TableName, REPLACE(@_TableName, 'B30', 'B3' + @_DataCode)          
        SELECT @_TableName_Alter = CASE
                                       WHEN (@_TableName LIKE '%30%') THEN
                                           REPLACE(@_TableName, 'B30', 'B3' + @_DataCode)
                                       ELSE
                                           REPLACE(@_TableName, 'B20', 'B2' + @_DataCode)
                                   END

        DECLARE @_ConstraintName NVARCHAR(256);


        IF OBJECT_ID(@_TableName_Alter) IS NULL
            RETURN

        IF OBJECT_ID(@_TableName_Alter) IS NOT NULL
        BEGIN

            IF @_Type = 'ADD'
            BEGIN
                SET @_StrExec
                    = @_StrExec + N' ALTER TABLE ' + @_TableName_Alter + N'  ADD  ' + @_ColName + N' ' + @_DataType
                      + N'    ' + CHAR(13)
            END
            ELSE IF @_Type = 'DROP_CONSTRAINT'
            BEGIN
                SELECT @_ConstraintName = d.name
                FROM sys.tables                  AS t
                    JOIN sys.columns             AS c
                        ON t.object_id = c.object_id
                    JOIN sys.default_constraints AS d
                        ON c.default_object_id = d.object_id
                WHERE t.name = @_TableName_Alter -- Thay tên bảng vào đây
                      AND c.name = @_ColName;

                --DECLARE @_SqlDropConstraint NVARCHAR(MAX)
                -- Nếu tìm thấy constraint thì tiến hành xóa động
                IF @_ConstraintName IS NOT NULL
                BEGIN
                    SELECT @_StrExec
                        = @_StrExec + N'ALTER TABLE ' + @_TableName_Alter + N' DROP CONSTRAINT '
                          + QUOTENAME(@_ConstraintName) + CHAR(13)

                --PRINT @_SqlDropConstraint
                --EXEC sp_executesql @_SqlDropConstraint;
                END



            END
            ELSE IF @_Type = 'DROP_COLUMN'
            BEGIN

                SET @_StrExec
                    = @_StrExec + N' ALTER TABLE ' + @_TableName_Alter + N'  DROP   COLUMN    ' + @_ColName + N' '
                      + @_nl
            END
            ELSE IF @_Type = 'ALTER'
            BEGIN


                SET @_StrExec
                    = @_StrExec + N'DROP INDEX IX_B3' + @_DataCode + N'FinPlan_DocDate ON dbo.B3' + @_DataCode
                      + 'FinPlan; ' + N'ALTER TABLE ' + @_TableName_Alter + N' ALTER  COLUMN    ' + @_ColName + N'   '
                      + @_Type_ALTER + ' ' + N'CREATE NONCLUSTERED INDEX IX_B3' + @_DataCode
                      + N'FinPlan_DocDate ON dbo.B3' + @_DataCode + 'FinPlan (DocDate);' + @_nl

            END
            ELSE IF @_Type = 'SELECT'
            BEGIN
                SET @_StrExec = @_StrExec + N' SELECT TOP 1 * FROM  ' + @_TableName_Alter + @_nl
            END

            IF @_Type = 'sp_rename'
            BEGIN

                SET @_StrExec
                    = @_StrExec + N' EXEC sp_rename ''' + @_TableName_Alter + N'.' + @_ColName_Old + N''', '''
                      + @_ColName_New + N''', ''COLUMN'';' + @_nl
            END
            IF @_Type = 'DF'
            BEGIN


                SET @_StrExec
                    = N' ALTER TABLE ' + @_TableName_Alter + N'  ADD CONSTRAINT DF_' + @_TableName
                      + N'_IsMaterialFactor DEFAULT 1 FOR IsMaterialFactor; '
            END






            DELETE FROM #Dvcs
            WHERE BranchCode = @_BranchCode
        END


    END

    IF @_Auto_Exec = 1
        EXEC (@_StrExec)

    EXEC B10THACOIDACC.dbo._usp_sys_print_StrExec_morethan4000c @_StrExec

    IF OBJECT_ID('Tempdb..#Dvcs') IS NOT NULL
        DROP TABLE #Dvcs;
END


GO


SET DATEFORMAT DMY
EXEC usp_TINNT_AddColums @_TableName = N'B30LCDoc'
                       , @_ColName = N''
                       , @_DataType = N'INT'
                       , @_Type = N'sp_rename'
                       , @_Type_ALTER = N'datetime'
                       , @_Auto_Exec = 1
                       , @_ColName_Old = N'CustomerIdFinance'
                       , @_ColName_New = N'CustomerFinanceId'

                       select * from B30LCDoc
                        EXEC dbo.usp_TINNT_AddColums @_TableName = N'B30LCDoc'
                           , @_Type = 'DROP_COLUMN'
                           , @_DataType = 'int'
                           , @_ColName = 'CustomerCodeBorrow'
                           , @_Auto_Exec = 1