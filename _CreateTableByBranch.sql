SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

ALTER PROCEDURE dbo._CreateTableByBranch
    @_TableName VARCHAR(128) = 'vB30ZQTCNDetail_GetData'
   ,@_BranchCode NVARCHAR(3) = ''
                                   --@_DataCode VARCHAR(24) = '8E',
   ,@_NewTableName VARCHAR(128) = ''
   ,@_DropObjBefCreate TINYINT = 0 -- Đối với bảng cần đổi lại cấu trúc
   ,@_CreateSeq INT = 0
   ,@_RunType TINYINT = 1
   ,@_PrintCmd TINYINT = 1
   ,@_CreateTrigger TINYINT = 1
   ,@_Check_Obj TINYINT = 0
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @BranchList TABLE
    (
        BranchCode NVARCHAR(3)
       ,DataCode NVARCHAR(4)
    )

    DECLARE @_BranchCode_Tmp NVARCHAR(3)
           ,@_DataCode_Tmp NVARCHAR(4) = N''

    IF @_BranchCode <> ''
    BEGIN
        INSERT @BranchList
        (
            BranchCode
           ,DataCode
        )
        SELECT BranchCode
              ,DataCode
        FROM B00Branch
        WHERE BranchCode IN
              (
                  SELECT * FROM STRING_SPLIT(@_BranchCode, ',')
              )
    END
    ELSE
    BEGIN
        INSERT @BranchList
        (
            BranchCode
           ,DataCode
        )
        SELECT BranchCode
              ,DataCode
        FROM B00Branch
    END

    DELETE @BranchList
    WHERE BranchCode IN ( 'T00' )
    --DELETE @BranchList WHERE DataCode  NOT IN ('2002')



    WHILE EXISTS (SELECT * FROM @BranchList)
    BEGIN

        SELECT TOP 1
               @_BranchCode_Tmp = BranchCode
              ,@_DataCode_Tmp   = DataCode
        FROM @BranchList

        IF @_CreateSeq = 0
        BEGIN

            EXEC _CreateTable @_DataCode = @_DataCode_Tmp
                             ,@_TableName = @_TableName
                             ,@_NewTableName = @_NewTableName
                             ,@_DropObjBefCreate = @_DropObjBefCreate -- Đối với bảng cần đổi lại cấu trúc
                             ,@_RunType = @_RunType
                             ,@_PrintCmd = @_PrintCmd
                             ,@_CreateTrigger = @_CreateTrigger

        END
        ELSE
        BEGIN

            EXEC _CreateTableAll @_TableName = @_TableName
                                ,@_DataCode = @_DataCode_Tmp
                                ,@_RunType = @_RunType
                                ,@_CreateSeq = @_CreateSeq
                                ,@_DropObjBefCreate = @_DropObjBefCreate
                                ,@_PrintCmd = @_PrintCmd

        END
        DELETE @BranchList
        WHERE BranchCode = @_BranchCode_Tmp

    END

    DECLARE @_TableName_Filter VARCHAR(128)

    SELECT @_TableName_Filter = CASE
                                    WHEN CHARINDEX('20', @_TableName, 0) >= 1 THEN
                                        REPLACE(@_TableName, '20', '2%')
                                    WHEN CHARINDEX('30', @_TableName, 0) >= 1 THEN
                                        REPLACE(@_TableName, '30', '3%')
                                    ELSE
                                        @_TableName
                                END

    IF @_Check_Obj = 1
    BEGIN
        ;WITH cte
         AS (SELECT o.name
                   ,o.object_id
                   ,o.type
                   ,o.type_desc
                   ,o.create_date
                   ,o.modify_date
                   ,CASE
                        WHEN o.name <> @_TableName THEN
                            LEFT(REPLACE(o.name, 'vB3', ''), 4)
                        ELSE
                            '0'
                    END AS DataCode
             FROM sys.objects AS o
             WHERE o.name LIKE @_TableName_Filter)
        SELECT c.*
              ,bb.BranchCode
              ,IIF(c.create_date <> c.modify_date AND bb.BranchCode IS NOT NULL, 'OK', '') AS _Check
        FROM cte                    c
            LEFT JOIN dbo.B00Branch AS bb
                ON c.DataCode = bb.DataCode
        ORDER BY bb.BranchCode ASC


    END

END
GO

GO


dbo._CreateTableByBranch @_TableName = 'vB30OpenBizDoc' -- varchar(128)
                        ,@_Check_Obj = 1

