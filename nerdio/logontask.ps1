Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

#Import Common Functions
$commonscriptpath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.12\Downloads\0\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath
sleep 5


. C:\LabFiles\AzureCreds.ps1



$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID
$resourceGroup = "AVD-RG"

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$Inputstring = $AzureUserName
$CharArray =$InputString.Split("@")
$CharArray[1]
$tenantName = $CharArray[1]

Do {
    Sleep 300 

$Token = ('Bearer {0}' -f ((Get-AzAccessToken -TenantId $TenantID).Token))
$RESTAPIHeaders = @{'Authorization'=$Token;'Accept'='application/json'}
#$URI = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups?api-version=2014-04-01"
$URI = "https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${resourceGroup}/providers/Microsoft.AAD/DomainServices/${tenantName}?api-version=2021-05-01&healthdata=true"
$GetResourceGroupsRequest = Invoke-WebRequest -UseBasicParsing -Uri $URI -Method GET -Headers $RESTAPIHeaders
$ResourceGroups = ($GetResourceGroupsRequest.Content | ConvertFrom-Json).value
$ResourceGroups

$JsonValue= $GetResourceGroupsRequest | ConvertFrom-Json
$Status = $JsonValue.properties.replicaSets[0].serviceStatus

}
Until ($status -eq "Running")


if ( $status -eq "Running")
{
 
$ValidStatus="Succeeded"
$Validmessage = "Validation Successfull"
}
else

{
$ValidStatus="Failed"
$Validmessage = "Validation Failed"

}

#Set the final deployment status
CloudlabsManualAgent setStatus

#Start the cloudlabs agent service 
CloudlabsManualAgent Start


Stop-Transcript



#Remove AVD-RG Deployment History
Remove-AzResourceGroupDeployment -ResourceGroupName AVD-RG -Name deploy-01
Remove-AzResourceGroup -Name NetworkWatcherRG -Force
