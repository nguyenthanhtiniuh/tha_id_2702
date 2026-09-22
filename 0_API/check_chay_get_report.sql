USE B10THACOID
GO
/*

{
          "Type": "ApiReport10",
          "CommandType": "get",
          "Parameter": [
            {
              "FromDate": "01/01/2026",
              "ToDate": "10/01/2026", 
              "BranchCode": "INDUSTRIES"
            }
          ]
        }

		{
  "Type": "ApiReport11",
  "CommandType": "get",
  "Parameter": [
    {
      "ToDate": "30/01/2026",
      "BranchCode": "INDUSTRIES"
    }
  ]
}

*/

EXECUTE dbo.usp_sys_WebAPI @_JsonData = N'{
  "Type": "ApiReport11",
  "CommandType": "get",
  "Parameter": [
    {
      "ToDate": "30/01/2026",
      "BranchCode": "CASC"
    }
  ]
}'
                          ,@_ClientInfo = '192.168.10.2'