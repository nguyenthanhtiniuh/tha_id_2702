

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE dbo.usp_CheckAssetThaco2_test
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
   ,@_NewVer                TINYINT       = 1    --Cuonglm viet lai vi bao cao xu lys sai tinhs chat tk 214
   ,@_BranchReportId        INT           = NULL -- V?LA x? lý báo báo IAS/IFRS
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @_Time1 DATETIME =GETDATE()
           ,@_Time2 DATETIME
 
    DECLARE @_Ma_DvcsFilter NVARCHAR(3) =  N''
           ,@_BranchCode1Filter NVARCHAR(16)= N''
           ,@_BranchName NVARCHAR(64)  = N''
           ,@_CalSum NVARCHAR(MAX) = N''
   
    IF OBJECT_ID('TempDb..#_DsDvcs') IS NOT NULL
        DROP TABLE #_DsDvcs
    SELECT TOP 0
           BranchCode
          ,BranchCode AS BranchCode1
          ,DataCode
          ,CAST(0 AS INT) AS _Scan
    INTO #_DsDvcs
    FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode)
    IF ISNULL(@_BranchReportId, 0) <> 0
    BEGIN
        DROP TABLE IF EXISTS #BranchCode0
        SELECT a.BranchCode0
        INTO #BranchCode0
        FROM dbo.B20BranchReportDetail AS a
             INNER JOIN dbo.B20BranchReport AS b ON a.BranchReportId = b.Id
        WHERE b.Id = @_BranchReportId
        DECLARE @_BranchCode0 VARCHAR(3) = ''
        WHILE EXISTS (SELECT * FROM #BranchCode0)
        BEGIN
            SELECT TOP 1
                   @_BranchCode0 = BranchCode0
            FROM #BranchCode0
            DELETE #BranchCode0
            WHERE BranchCode0 = @_BranchCode0
            INSERT INTO #_DsDvcs
            (
                BranchCode
               ,BranchCode1
               ,DataCode
               ,_Scan
            )
            SELECT BranchCode
                  ,BranchCode AS BranchCode1
                  ,DataCode
                  ,CAST(0 AS INT) AS _Scan
            FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode0)
        END
        DROP TABLE IF EXISTS #BranchCode0
    END
    ELSE
    BEGIN
        INSERT INTO #_DsDvcs
        (
            BranchCode
           ,BranchCode1
           ,DataCode
           ,_Scan
        )
        SELECT BranchCode
              ,BranchCode AS BranchCode1
              ,DataCode
              ,CAST(0 AS INT) AS _Scan
        FROM dbo.ufn_B00Branch_GetChildTable(@_BranchCode)
    END

    IF OBJECT_ID(N'Tempdb..#tblTmp') IS NOT NULL
        DROP TABLE #tblTmp
    CREATE TABLE #tblTmp
        (Id INT DEFAULT 0)
    EXECUTE dbo.usp_sys_CreateTable '#tblTmp', @_DefinitionTableName
    EXECUTE dbo.usp_sys_Append @_DefinitionTableName, '#tblTmp'

    ALTER TABLE #tblTmp
    ADD OpenAmountAccount NUMERIC(18, 2) DEFAULT 0 NOT NULL
       ,DebitAmountAccount NUMERIC(18, 2) DEFAULT 0 NOT NULL
       ,CreditAmountAccount NUMERIC(18, 2) DEFAULT 0 NOT NULL
       ,CloseAmountAccount NUMERIC(18, 2) DEFAULT 0 NOT NULL
       ,OpenAmountAsset NUMERIC(18, 2) DEFAULT 0 NOT NULL
       ,AmountAssetT NUMERIC(18, 2) DEFAULT 0 NOT NULL
       ,AmountAssetG NUMERIC(18, 2) DEFAULT 0 NOT NULL
       ,CloseAmountAsset NUMERIC(18, 2) DEFAULT 0 NOT NULL

    IF OBJECT_ID(N'Tempdb..#tblTmp3') IS NOT NULL DROP TABLE #tblTmp3
    CREATE TABLE #tblTmp3
        (Id                      INT
        ,BranchCode              NVARCHAR(3)
        ,BuiltinOrder            INT
        ,Description             NVARCHAR(512)
        ,ItemLevel               INT
        ,ItemNo                  NVARCHAR(3)
        ,ItemType                NVARCHAR(24)
        ,Account                 NVARCHAR(254)
        ,OpenAmountAccount       NUMERIC(18, 2)
        ,DebitAmountAccount      NUMERIC(18, 2)
        ,CreditAmountAccount     NUMERIC(18, 2)
        ,CloseAmountAccount      NUMERIC(18, 2)
        ,OpenAmountAsset         NUMERIC(18, 2)
        ,AmountAssetT            NUMERIC(18, 2)
        ,AmountAssetG            NUMERIC(18, 2)
        ,CloseAmountAsset        NUMERIC(18, 2)
        ,IsPrint                 INT
        ,Formula                 NVARCHAR(512)
        ,OpenAmount_Difference   NUMERIC(18, 2) DEFAULT 0 NOT NULL
        ,DebitAmount_Difference  NUMERIC(18, 2) DEFAULT 0 NOT NULL
        ,CreditAmount_Difference NUMERIC(18, 2) DEFAULT 0 NOT NULL
        ,CloseAmount_Difference  NUMERIC(18, 2) DEFAULT 0 NOT NULL
        ,BranchName              NVARCHAR(256)  DEFAULT '' NOT NULL
        ,_FormatStyleKey         NVARCHAR(256)  DEFAULT '' NOT NULL
        ,_LinkCommand            NVARCHAR(256)  DEFAULT '' NOT NULL
        ,LinkCommand_Acc         NVARCHAR(256)  DEFAULT '' NOT NULL)

    DECLARE @_Key VARCHAR(4000) = ''
    WHILE EXISTS (SELECT BranchCode FROM #_DsDvcs WHERE _Scan = 0)
    BEGIN
        SELECT TOP 1
               @_Ma_DvcsFilter = BranchCode
              ,@_BranchCode1Filter = @_BranchCode1
        FROM #_DsDvcs
        WHERE _Scan = 0
        INSERT INTO #tblTmp3
        (
            Id
           ,BranchCode
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
           ,_FormatStyleKey
           ,_LinkCommand
        )
        SELECT Id
              ,@_Ma_DvcsFilter AS BranchCode
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
              ,_FormatStyleKey
              ,ISNULL(_LinkCommand, '')
        FROM #tblTmp
        IF @_Test = 0
        BEGIN
            EXEC dbo.usp_Tinh_keToan_CheckAssetThaco2 @_DocDate1 = @_DocDate1
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
        EXEC dbo.usp_Tinh_TaiSan_CheckAssetThaco2_test  @_DocDate1 = @_DocDate1
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
                                                 ,@_PRINT_Exec = 0 

												 return 
											 

        UPDATE #tblTmp3
        SET OpenAmountAccount = ISNULL(T1.OpenAmountAccount, 0)
           ,DebitAmountAccount = ISNULL(T1.DebitAmountAccount, 0)
           ,CreditAmountAccount = ISNULL(T1.CreditAmountAccount, 0)
           ,CloseAmountAccount = ISNULL(T1.CloseAmountAccount, 0)
           ,OpenAmountAsset = ISNULL(T1.OpenAmountAsset, 0)
           ,AmountAssetT = ISNULL(T1.AmountAssetT, 0)
           ,AmountAssetG = ISNULL(T1.AmountAssetG, 0)
           ,CloseAmountAsset = ISNULL(T1.CloseAmountAsset, 0)
        FROM #tblTmp3 AS T3
             INNER JOIN #tblTmp AS T1 ON T3.BuiltinOrder = T1.BuiltinOrder
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

        UPDATE #_DsDvcs
        SET _Scan = 1
        WHERE BranchCode = @_Ma_DvcsFilter

        UPDATE #tblTmp3
        SET BranchName = Dvcs.BranchCode + '-' + Dvcs.BranchName
        FROM #tblTmp3 AS T
             INNER JOIN dbo.B00Branch AS Dvcs ON T.BranchCode = Dvcs.BranchCode

        UPDATE #tblTmp3
        SET OpenAmount_Difference = OpenAmountAccount - OpenAmountAsset
           ,DebitAmount_Difference = DebitAmountAccount - AmountAssetT
           ,CreditAmount_Difference = CreditAmountAccount - AmountAssetG
           ,CloseAmount_Difference = CloseAmountAccount - CloseAmountAsset

        SET @_CalSum
            = N'OpenAmountAccount,OpenAmountAsset,OpenAmount_Difference,DebitAmountAccount,AmountAssetT,DebitAmount_Difference,CreditAmountAccount,AmountAssetG,CreditAmount_Difference,CloseAmountAccount,CloseAmountAsset,CloseAmount_Difference'
        SELECT @_Key = ' BranchCode = ''' + @_Ma_DvcsFilter + ''' '
        EXECUTE dbo.usp_sys_SumValue @_Table = '#tblTmp3'
                                    ,@_FieldList = @_CalSum
                                    ,@_FieldKey = 'ItemNo'
                                    ,@_FieldCal = 'Formula'
                                    ,@_FieldBac = 'ItemLevel'
                                    ,@_Key = @_Key
                                    ,@_FieldIn_Ck = 'IsPrint'
                                    ,@_ResetFormula = 1
                                    ,@_PRINT_Exec = 0
    END
    DECLARE @_LinkCommand AS NVARCHAR(MAX)
    SET @_LinkCommand = N'REP07_KCD_CDTK '
	
	UPDATE  #tblTmp3
	SET _LinkCommand = IIF(ISNULL(_LinkCommand, '') <> ''
						  ,CASE WHEN _LinkCommand = 'REP02_AssetSummaryTable' THEN CONCAT(_LinkCommand, '  DocDate1=''{=@_DocDate1}'';DocDate2=''{=@_DocDate2}'';AssetAccount=''{=Account}'';')
						   WHEN _LinkCommand = 'REP02_ToolInstAllocCalc' THEN CONCAT(_LinkCommand, '  DocDate1=''{=@_DocDate1}'';DocDate2=''{=@_DocDate2}'';DeprCreditAccount=''{=Account}'';')
						   ELSE ''
						   END
						  ,'')
    
	UPDATE #tblTmp3
    SET LinkCommand_Acc = @_LinkCommand
    WHERE Account <> ''
          AND _LinkCommand <> ''
          AND CHARINDEX(',', Account) <= 0

	SELECT  Id, BranchCode, BuiltinOrder, Description, ItemLevel, ItemNo, ItemType, Account, OpenAmountAccount, DebitAmountAccount, CreditAmountAccount, CloseAmountAccount, OpenAmountAsset, AmountAssetT, AmountAssetG, CloseAmountAsset, IsPrint, Formula, OpenAmount_Difference, DebitAmount_Difference, CreditAmount_Difference, CloseAmount_Difference, BranchName, _FormatStyleKey, _LinkCommand, LinkCommand_Acc
	FROM    #tblTmp3
	ORDER BY BranchCode ASC, BuiltinOrder ASC 
 
    SELECT @_Time2 = GETDATE()

    DROP TABLE IF EXISTS #tblTmp3
    DROP TABLE IF EXISTS #tblTmp
    DROP TABLE IF EXISTS #_DsDvcs
END
GO



--declare @p17 nvarchar(max)
 
--declare @p18 varchar(max)
 
--exec usp_CheckAssetThaco2 @_DocDate1='2026-07-01 00:00:00',@_DocDate2='2026-07-31 00:00:00',@_nUserId=default,@_LangId=0,@_DefinitionTableName='B10CheckAsset2',@_ConsolCode=default,@_Not_ConsolCode=default,@_Not_BranchCode=default,@_Not_RouteCode=default,@_BranchCode1=default,@_Not_BranchCode1=default,@_Not_BranchCode1Detail=default,@_CheckType=default,@_ReportType=default,@_BranchCode='I01',@_CurrencyCode0='VND',@_LAYOUT_XML=@p17 output,@_StrTime=@p18 output,@_Test=default,@_NewVer=1,@_BranchReportId=default
 