Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsLogOnTask.txt -Append
Write-Host "Logon-task-started" 

$commonscriptpath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.14\Downloads\0\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

$DeploymentID = $env:DeploymentID

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$Inputstring = $AzureUserName
$CharArray =$InputString.Split("@")
$CharArray[1]
$tenantName = $CharArray[1]

cd C:\Packages

$RGname = "PowerBI-Embedded-RG"

New-AzResourceGroupDeployment -Name "createresources" -TemplateFile "deploy-02.json" -TemplateParameterFile "deploy-02.parameters.json" -ResourceGroup $RGname


sleep 5
Unregister-ScheduledTask -TaskName "logontask" -Confirm:$false 
Restart-Computer -Force 
