SET DATEFORMAT DMY
EXEC usp_B30AssetDoc_AllocAssetDepreciation  @_Date = '01/01/2026 00:00:00.000',
                                            @_Year = '2026',
                                            @_AssetAccount = '',
                                            @_AssetId = '6207982',
                                            @_CustomerId = '10008486',
                                            @_TransCode = 'JV-123',
                                            @_DocNo = 'PBCCDC01/26',
                                            @_AssetType = 1,
                                            @_Round = 0,
                                            @_BranchCode = 'I15',
                                            @_nUserId = 1213,
                                            @_AutoDisposals = 0,
                                            @_DisposalsTransCode = '',
                                            @_DataXML = '<?xml version="1.0" standalone="yes"?>
<NewDataSet>
	<CalcAssetDepreciation Id="6207982" BranchCode="I15" ParentId="-1" IsGroup="false" EquityId="-1" Name="Ti?n thuê d?t nam 2026" Code="PRES-C1326-671" OriginalCost="1886589905.00" NetBookValue="1886589905.00" AmountForDepr="1886589905.00" MonthDepr="157215825.00" FirstDeprDate="2026/01/01 00:00:00" LastDeprDate="2026/12/31 00:00:00" FirstUsedDate="2026/01/01 00:00:00" MonthForDepr="12.000000000" IsDeprAdjusted="0" AllocateByCapacity="0" FirstDiposalDate="2026/01/01 00:00:00" MonthDeprSave="157215825.00" DeprAllocationRate="0.00000" SoThangDaKhauHao="0" SoThangConLai="12" />
</NewDataSet>
',
                                            @_CommandKey = 'HACHTOAN_CCDC'