SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

ALTER PROC dbo.usp_CheckAssetThaco2
    @_DocDate1              DATETIME      = NULL
   ,@_DocDate2              DATETIME      = NULL
   ,@_nUserId AS            INT           = 0
   ,@_LangId                SMALLINT      = 0
   ,@_DefinitionTableName   NVARCHAR(32)  = N'B10CheckAsset2'
   ,@_ConsolCode            NVARCHAR(512) = ''
   ,@_Not_ConsolCode        NVARCHAR(512) = ''
   ,@_Not_BranchCode        NVARCHAR(512) = ''
   ,@_Not_RouteCode         NVARCHAR(512) = ''
   ,@_BranchCode1           NVARCHAR(512) = ''
   ,@_Not_BranchCode1       NVARCHAR(512) = ''
   ,@_Not_BranchCode1Detail NVARCHAR(512) = ''
   ,@_CheckType             NVARCHAR(16)  = ''
   ,@_ReportType            NVARCHAR(16)  = ''
   ,@_BranchCode            NCHAR(3)      = N'A00'
   ,@_CurrencyCode0         NVARCHAR(3)   = N'VND'
   ,@_LAYOUT_XML            NVARCHAR(MAX) = '' OUTPUT
   ,@_StrTime               NVARCHAR(254) = '' OUTPUT
   ,@_Test                  TINYINT       = 0
   ,@_NewVer                TINYINT       = 0 --Cuonglm viet lai vi bao cao xu lys sai tinhs chat tk 214

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @_Time1 DATETIME
           ,@_Time2 DATETIME
    SELECT @_Time1 = GETDATE(), @_StrTime = ''
    DECLARE @_Ma_DvcsFilter     NVARCHAR(3)
           ,@_BranchCode1Filter NVARCHAR(16)
           ,@_BranchName        NVARCHAR(64)
           ,@_CalSum            NVARCHAR(MAX) = N''

    SELECT @_Ma_DvcsFilter = N'', @_BranchCode1Filter = N'', @_BranchName = N''
 
    IF OBJECT_ID('TempDb..#_DsDvcs') IS NOT NULL DROP TABLE #_DsDvcs
 
    SELECT BranchCode
          ,BranchCode AS BranchCode1
          ,DataCode
          ,CAST(0 AS INT) AS _Scan
    INTO #_DsDvcs
    FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode)
 
    IF OBJECT_ID(N'Tempdb..#tblTmp') IS NOT NULL DROP TABLE #tblTmp
    CREATE TABLE #tblTmp (Id INT DEFAULT 0)
    EXECUTE usp_sys_CreateTable '#tblTmp', @_DefinitionTableName
    EXECUTE usp_sys_Append @_DefinitionTableName, '#tblTmp'

    ALTER TABLE #tblTmp
    ADD OpenAmountAccount NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,DebitAmountAccount NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,CreditAmountAccount NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,CloseAmountAccount NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,OpenAmountAsset NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,AmountAssetT NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,AmountAssetG NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,CloseAmountAsset NUMERIC(18, 2)
            DEFAULT 0 NOT NULL

    IF OBJECT_ID(N'Tempdb..#tblTmp3') IS NOT NULL DROP TABLE #tblTmp3
    CREATE TABLE #tblTmp3
    (
        BranchCode          NVARCHAR(3)
       ,BuiltinOrder        INT
       ,Description         NVARCHAR(512)
       ,ItemLevel           INT
       ,ItemNo              NVARCHAR(3)
       ,ItemType            NVARCHAR(24)
       ,Account             NVARCHAR(254)
       ,OpenAmountAccount   NUMERIC(18, 2)
       ,DebitAmountAccount  NUMERIC(18, 2)
       ,CreditAmountAccount NUMERIC(18, 2)
       ,CloseAmountAccount  NUMERIC(18, 2)
       ,OpenAmountAsset     NUMERIC(18, 2)
       ,AmountAssetT        NUMERIC(18, 2)
       ,AmountAssetG        NUMERIC(18, 2)
       ,CloseAmountAsset    NUMERIC(18, 2)
       ,IsPrint             INT
       ,Formula             NVARCHAR(512)
    )

    WHILE EXISTS (SELECT BranchCode FROM #_DsDvcs WHERE _Scan = 0)
    BEGIN
        SELECT TOP 1
               @_Ma_DvcsFilter = BranchCode
              ,@_BranchCode1Filter = @_BranchCode1
        FROM #_DsDvcs
        WHERE _Scan = 0

        INSERT INTO #tblTmp3
        (
            BranchCode
           ,BuiltinOrder
           ,Description
           ,ItemLevel
           ,ItemType
           ,ItemNo
           ,Account
           ,OpenAmountAccount
           ,DebitAmountAccount
           ,CreditAmountAccount
           ,CloseAmountAccount
           ,OpenAmountAsset
           ,AmountAssetT
           ,AmountAssetG
           ,CloseAmountAsset
           ,IsPrint
           ,Formula
        )
        SELECT @_Ma_DvcsFilter AS BranchCode
              ,BuiltinOrder
              ,Description
              ,ItemLevel
              ,ItemType
              ,ItemNo
              ,Account
              ,0 AS OpenAmountAccount
              ,0 AS DebitAmountAccount
              ,0 AS CreditAmountAccount
              ,0 AS CloseAmountAccount
              ,0 AS OpenAmountAsset
              ,0 AS AmountAssetT
              ,0 AS AmountAssetG
              ,0 AS CloseAmountAsset
              ,IsPrint
              ,Formula
        FROM #tblTmp

        IF @_Test = 0
        BEGIN
            EXEC usp_Tinh_keToan_CheckAssetThaco2 @_DocDate1 = @_DocDate1
                                                 ,@_DocDate2 = @_DocDate2
                                                 ,@_DefinitionTableName = @_DefinitionTableName                                                 
                                                 ,@_nUserId = @_nUserId
                                                 ,@_tblTmp = '#tblTmp'
                                                 ,@_LangId = @_LangId
                                                 ,@_Not_BranchCode1 = @_Not_BranchCode1
                                                 ,@_Not_BranchCode1Detail = @_Not_BranchCode1Detail
                                                 ,@_BranchCode = @_Ma_DvcsFilter
                                                 ,@_CurrencyCode0 = @_CurrencyCode0
                                                 ,@_NewVer = @_NewVer
        END

        EXEC usp_Tinh_TaiSan_CheckAssetThaco2 @_DocDate1 = @_DocDate1
                                             ,@_DocDate2 = @_DocDate2
                                             ,@_DefinitionTableName = @_DefinitionTableName                                             
                                             ,@_nUserId = @_nUserId
                                             ,@_tblTmp = '#tblTmp'
                                             ,@_LangId = @_LangId
                                             ,@_Not_BranchCode1 = @_Not_BranchCode1
                                             ,@_Not_BranchCode1Detail = @_Not_BranchCode1Detail
                                             ,@_BranchCode = @_Ma_DvcsFilter
                                             ,@_CurrencyCode0 = @_CurrencyCode0
                                             ,@_NewVer = @_NewVer

											   

        UPDATE #tblTmp3
        SET OpenAmountAccount = ISNULL(T1.OpenAmountAccount, 0)
           ,DebitAmountAccount = ISNULL(T1.DebitAmountAccount, 0)
           ,CreditAmountAccount = ISNULL(T1.CreditAmountAccount, 0)
           ,CloseAmountAccount = ISNULL(T1.CloseAmountAccount, 0)
           ,OpenAmountAsset = ISNULL(T1.OpenAmountAsset, 0)
           ,AmountAssetT = ISNULL(T1.AmountAssetT, 0)
           ,AmountAssetG = ISNULL(T1.AmountAssetG, 0)
           ,CloseAmountAsset = ISNULL(T1.CloseAmountAsset, 0)
        FROM #tblTmp3 T3
             INNER JOIN #tblTmp T1 ON T3.BuiltinOrder = T1.BuiltinOrder
                                      AND T3.BranchCode = @_Ma_DvcsFilter

        UPDATE #tblTmp
        SET OpenAmountAccount = 0
           ,DebitAmountAccount = 0
           ,CreditAmountAccount = 0
           ,CloseAmountAccount = 0
           ,OpenAmountAsset = 0
           ,AmountAssetT = 0
           ,AmountAssetG = 0
           ,CloseAmountAsset = 0
        UPDATE #_DsDvcs SET _Scan = 1 WHERE BranchCode = @_Ma_DvcsFilter

    END

    ALTER TABLE #tblTmp3
    ADD OpenAmount_Difference NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,DebitAmount_Difference NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,CreditAmount_Difference NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,CloseAmount_Difference NUMERIC(18, 2)
            DEFAULT 0 NOT NULL
       ,BranchName NVARCHAR(256)
            DEFAULT '' NOT NULL

    UPDATE #tblTmp3
    SET BranchName = Dvcs.BranchCode + '-' + Dvcs.BranchName
    FROM #tblTmp3 T
         INNER JOIN dbo.B00Branch Dvcs ON T.BranchCode = Dvcs.BranchCode

    UPDATE #tblTmp3
    SET OpenAmount_Difference = OpenAmountAccount - OpenAmountAsset
       ,DebitAmount_Difference = DebitAmountAccount - AmountAssetT
       ,CreditAmount_Difference = CreditAmountAccount - AmountAssetG
       ,CloseAmount_Difference = CloseAmountAccount - CloseAmountAsset

    SET @_CalSum
        = N'OpenAmountAccount,OpenAmountAsset,OpenAmount_Difference,DebitAmountAccount,AmountAssetT,DebitAmount_Difference,CreditAmountAccount,AmountAssetG,CreditAmount_Difference,CloseAmountAccount,CloseAmountAsset,CloseAmount_Difference'

    EXECUTE usp_sys_SumValue_B7 @_Table = '#tblTmp3'
                               ,@_FieldList = @_CalSum
                               ,@_FieldKey = 'ItemNo'
                               ,@_FieldCal = 'Formula'
                               ,@_FieldBac = 'ItemLevel'
                               ,@_FieldIn_Ck = 'IsPrint'
                               ,@_ResetFormula = NULL

    SELECT * FROM #tblTmp3 ORDER BY BranchCode, BuiltinOrder
    SELECT @_Time2 = GETDATE()

    DROP TABLE IF EXISTS #tblTmp3
    DROP TABLE IF EXISTS #tblTmp
    DROP TABLE IF EXISTS #_DsDvcs
               
END

GO

GO

SET DATEFORMAT DMY
EXEC usp_CheckAssetThaco2 @_DocDate1 = '01/01/2026 00:00:00.000'
                         ,@_DocDate2 = '31/01/2026 00:00:00.000'
                         ,@_LangId = 0
                         ,@_DefinitionTableName = 'B10CheckAsset2'
                         ,@_BranchCode = 'I15'
                         ,@_CurrencyCode0 = 'VND'
                         ,@_StrTime = ''
