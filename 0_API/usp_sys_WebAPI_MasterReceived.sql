 [dbo].[usp_sys_WebAPI_MasterReceived_Tin]
	@_JsonData = N'{
  "Type": "ApiReport20",
  "CommandType": "GET",
  "Parameter": [
    {
      "FromDate": "01/01/2026",
      "ToDate": "31/01/2026",
      "BranchCode": "CASC"
    }
  ]
}

',
	@_ClientInfo = '',
	@_Type = 'ApiReport20',
	@_Id_APILog  =0