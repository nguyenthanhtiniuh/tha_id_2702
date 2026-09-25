USE B10THACOID
GO

CREATE PROC usp_sys_FixTest_B00FieldList
    ---------
    @_Tbl_MasterTable NVARCHAR(256) = 'B20Customer'
  ---------
  , @_Tbl_Req NVARCHAR(256) = 'B30LCDoc'
  , @_Tbl_Field_Name NVARCHAR(256) = 'CustomerBorrowId'
  , @_Cre_Id INT = NULL
AS
BEGIN
    SET NOCOUNT ON

    IF @_Tbl_MasterTable = ''
       OR @_Tbl_Req = ''
       OR @_Tbl_Field_Name = ''
       OR @_Cre_Id = ''
        RETURN


    DROP TABLE IF EXISTS #tbl
    SELECT TOP (1)
           MasterTable
         , MasterField
         , Table_Name
         , Field_Name
    INTO #tbl
    FROM B00FieldList AS fl
    WHERE MasterTable LIKE '%' + @_Tbl_MasterTable + '%'
          AND Field_Name = @_Tbl_Field_Name
    ORDER BY fl.Id DESC

    UPDATE #tbl
    SET Table_Name = @_Tbl_Req

    DROP TABLE IF EXISTS #T_Append
    SELECT fl.MasterTable
         , fl.MasterField
         , REPLACE(Table_Name, '0', br.DataCode) AS Table_Name
         , fl.Field_Name
         , GETUTCDATE()                          AS CreatedAt
         , @_Cre_Id                              AS CreatedBy
         , GETUTCDATE()                          AS ModifiedAt
         , -1                                    AS ModifiedBy
    INTO #T_Append
    FROM #tbl AS fl
       , B00Branch AS br
    WHERE br.BranchCode <> 'T00'
    ORDER BY br.DataCode DESC

    SELECT *
    FROM #T_Append

    EXEC dbo.usp_sys_Append @_TableSource = '#T_Append'         -- nvarchar(128)
                          , @_TableDestination = 'b00fieldlist' -- nvarchar(128)

    SELECT @_Tbl_Req = REPLACE(@_Tbl_Req, '0', '%')

    SELECT *
    FROM B00FieldList
    WHERE Table_Name LIKE @_Tbl_Req
          AND Field_Name = @_Tbl_Field_Name

    DROP TABLE IF EXISTS #tbl
                       , #T_Append

END
GO


SET DATEFORMAT DMY
EXEC usp_sys_FixTest_B00FieldList
    ---------
    @_Tbl_MasterTable = 'B20Customer'
  ---------
  , @_Tbl_Req = 'B30LCDoc'
  , @_Tbl_Field_Name = 'CustomerBorrowId'
  , @_Cre_Id = 1213