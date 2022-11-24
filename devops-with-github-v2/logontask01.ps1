
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\extensionlog.txt -Append
Write-Host "Logon-task-started" 

$DeploymentID = $env:DeploymentID

Start-Process C:\Packages\extensions.bat
Write-Host "Bypass-Execution-Policy"


choco install docker-desktop --version=4.7.0
Write-Host "Docker-install"

[Environment]::SetEnvironmentVariable("Path", $env:Path+";C:\Users\demouser\AppData\Roaming\npm\node_modules\azure-functions-core-tools\bin","User")

#WSL 2 pacakage installation
(New-Object System.Net.WebClient).DownloadFile('https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi', 'C:\wsl_update_x64.msi')
Start-Process C:\wsl_update_x64.msi -ArgumentList "/quiet"

. C:\LabFiles\AzureCreds.ps1

$user = $AzureUserName

$deploymentid = $env:DeploymentID

$connectionToken = "twoexomspxea4p3p7qqduxmgkzznzjd2uyiavkngvkyjtwutiowa"

refreshenv

az config set extension.use_dynamic_install=yes_without_prompt


Set-VSTeamAccount -Account https://dev.azure.com/aiw-devops/ -PersonalAccessToken $connectionToken

Add-VSTeamProject -ProjectName fabrikam-$deploymentid -ProcessTemplate Basic 

$project = Get-VSTeamProject -Name fabrikam-$deploymentid



$projectID = $project.Id


Add-VSTeamUserEntitlement -Email $user -ProjectName $project.Name -License Express -LicensingSource none -Group ProjectAdministrator   -Verbose



$base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $base64AuthInfo")
$headers.Add("Content-Type", "application/json")



$body = "{
 `"accessLevel`": {
 `"accountLicenseType`": `"express`"
 },
 `"extensions`": [
 {
 `"id`": `"ms.feed`"
 }
 ],
 `"user`": {
 `"principalName`": `"$user`",
 `"subjectKind`": `"user`"
 },
 `"projectEntitlements`": [
 {
 `"group`": {
 `"groupType`": `"projectAdministrator`"
 },
 `"projectRef`": {
 `"id`": `"$projectID`"
 }
 }
 ]
}"

$response = Invoke-RestMethod 'https://vsaex.dev.azure.com/aiw-devops/_apis/userentitlements?api-version=6.0-preview.3' -Method 'POST' -Headers $headers -Body $body
$response | ConvertTo-Json

#Download lab files
cd C:\

#create directory and clone bicep templates

mkdir C:\Workspaces
cd C:\Workspaces
mkdir lab
cd lab

mkdir aiw-devops-with-github-lab-files
cd aiw-devops-with-github-lab-files

git clone --branch main https://github.com/shivashant25/aiw-devops-with-github-lab-files.git

Sleep 5

$path = "C:\Workspaces\lab\aiw-devops-with-github-lab-files\iac"
(Get-Content -Path "$path\createResources.parameters.json") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\createResources.parameters.json"
#(Get-Content -Path "$path\configure-webapp.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\configure-webapp.ps1"
#(Get-Content -Path "$path\deploy-appinsights.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\deploy-appinsights.ps1"
#(Get-Content -Path "$path\deploy-infrastructure.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\deploy-infrastructure.ps1"
#(Get-Content -Path "$path\seed-cosmosdb.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\seed-cosmosdb.ps1"

Sleep 5

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID


$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null


cd C:\Workspaces\lab\aiw-devops-with-github-lab-files\iac

$RGname=contoso-traders-$deploymentid

New-AzResourceGroupDeployment -Name "createresources" -TemplateFile "createResources.bicep" -TemplateParameterFile "createResources.parameters.json" -ResourceGroup $RGname

$AKS_CLUSTER_NAME= "contoso-traders-aks"
$AKS_NODES_RESOURCE_GROUP_NAME= "contoso-traders-aks-nodes-$deploymentid"
$CDN_PROFILE_NAME= "contoso-traders-cdn"
$SUB_DEPLOYMENT_REGION= "eastus"
$KV_NAME= "contosotraderskv$deploymentid"
$PRODUCTS_DB_NAME= "productsdb"
$PRODUCTS_DB_SERVER_NAME= "contoso-traders-products"
$PRODUCTS_DB_USER_NAME= "localadmin"
$PRODUCT_DETAILS_CONTAINER_NAME= "product-details"
$PRODUCT_IMAGES_STORAGE_ACCOUNT_NAME= "contosotradersimg"
$PRODUCT_LIST_CONTAINER_NAME= "product-list"
$PRODUCTS_CDN_ENDPOINT_NAME= "contoso-traders-images"
$RESOURCE_GROUP_NAME= "contoso-traders-$deploymentid"
$STORAGE_ACCOUNT_NAME= "contosotradersimg"




Set-AzKeyVaultAccessPolicy -VaultName $KV_NAME

















sleep 20

#check status of docker app installation aand cloned lab files
$app = Get-Item -Path 'C:\Program Files\Docker\Docker\Docker Desktop.exe' 
$clonefiles = Get-Item -Path 'C:\Workspaces\lab\mcw-continuous-delivery-lab-files\content-api'

if(($app -ne $null) -and ($clonefiles -ne $null))
{
    Write-Information "Validation Passed"
    
    $validstatus = "Successfull"
}
else {
    Write-Warning "Validation Failed - see log output"
    $validstatus = "Failed"
      }
      
Function SetDeploymentStatus($ManualStepStatus, $ManualStepMessage)
{

    (Get-Content -Path "C:\WindowsAzure\Logs\status-sample.txt") | ForEach-Object {$_ -Replace "ReplaceStatus", "$ManualStepStatus"} | Set-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt"
    (Get-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt") | ForEach-Object {$_ -Replace "ReplaceMessage", "$ManualStepMessage"} | Set-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt"
}
 if ($validstatus -eq "Successfull") {
    $ValidStatus="Succeeded"
    $ValidMessage="Environment is validated and the deployment is successful"
    
Remove-Item 'C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt' -force
      }
else {
    Write-Warning "Validation Failed - see log output"
    $ValidStatus="Failed"
    $ValidMessage="Environment Validation Failed and the deployment is Failed"
      } 
 SetDeploymentStatus $ValidStatus $ValidMessage

#Import Common Functions
$commonscriptpath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.12\Downloads\0\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

sleep 3
#Start the cloudlabs agent service 
CloudlabsManualAgent Start

sleep 5
Unregister-ScheduledTask -TaskName "Installdocker" -Confirm:$false 
Restart-Computer -Force 
