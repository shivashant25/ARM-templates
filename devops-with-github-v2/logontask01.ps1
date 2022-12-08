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

$password = $AzurePassword

$deploymentid = $env:DeploymentID

$connectionToken = "vcgq2g3sdbfdkywdwvdzylugpr3dtymx22aybvo66vp5esgdccvq"

refreshenv

choco install bicep
Install-Module Sqlserver -SkipPublisherCheck -Force
Import-Module Sqlserver
az config set extension.use_dynamic_install=yes_without_prompt


Set-VSTeamAccount -Account https://dev.azure.com/aiw-devops/ -PersonalAccessToken $connectionToken

Add-VSTeamProject -ProjectName contosotraders-$deploymentid -ProcessTemplate Basic 

$project = Get-VSTeamProject -Name contosotraders-$deploymentid



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

git clone --branch main https://github.com/shivashant25/aiw-devops-with-github-lab-files.git

Sleep 5

$path = "C:\Workspaces\lab\aiw-devops-with-github-lab-files\iac"
(Get-Content -Path "$path\createResources.parameters.json") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\createResources.parameters.json"

$path = "C:\Workspaces\lab\aiw-devops-with-github-lab-files\src\ContosoTraders.Ui.Website\src\services"
(Get-Content -Path "$path\configService.js") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\configService.js"

$path = "C:\Workspaces\lab\aiw-devops-with-github-lab-files\iac"
(Get-Content -Path "$path\createResources.parameters.json") | ForEach-Object {$_ -Replace "bicepsqlpass", "$password"} | Set-Content -Path "$path\createResources.parameters.json"

Sleep 5

#Az login

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID


$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null


cd C:\Workspaces\lab\aiw-devops-with-github-lab-files\iac

$RGname = "contoso-traders-$deploymentid"

New-AzResourceGroupDeployment -Name "createresources" -TemplateFile "createResources.bicep" -TemplateParameterFile "createResources.parameters.json" -ResourceGroup $RGname

$AKS_CLUSTER_NAME = "contoso-traders-aks$deploymentid"
$AKS_NODES_RESOURCE_GROUP_NAME = "contoso-traders-aks-nodes-rg"
$CDN_PROFILE_NAME = "contoso-traders-cdn$deploymentid"
$SUB_DEPLOYMENT_REGION = "eastus"
$KV_NAME = "contosotraderskv$deploymentid"
$PRODUCTS_DB_NAME = "productsdb"
$PRODUCTS_DB_SERVER_NAME = "contoso-traders-products"
$PRODUCTS_DB_USER_NAME = "localadmin"
$PRODUCT_DETAILS_CONTAINER_NAME = "product-details"
$PRODUCT_IMAGES_STORAGE_ACCOUNT_NAME = "contosotradersimg"
$PRODUCT_LIST_CONTAINER_NAME = "product-list"
$PRODUCTS_CDN_ENDPOINT_NAME = "contoso-traders-images$deploymentid"
$RESOURCE_GROUP_NAME = "contoso-traders-$deploymentid"
$STORAGE_ACCOUNT_NAME = "contosotradersimg$deploymentid"
$server = "contoso-traders-products$deploymentid.database.windows.net"







az login -u $userName -p  $password
cd C:\Workspaces\lab\aiw-devops-with-github-lab-files
  
Invoke-Sqlcmd -InputFile ./src/ContosoTraders.Api.Products/Migration/productsdb.sql -Database productsdb -Username "localadmin" -Password $password -ServerInstance contoso-traders-products802322.database.windows.net -ErrorAction 'Stop' -Verbose -QueryTimeout 1800 # 30min


az aks get-credentials -g $RESOURCE_GROUP_NAME -n $AKS_CLUSTER_NAME

az keyvault set-policy -n $KV_NAME --key-permissions get list  --object-id $(az ad user show --id $(az account show --query "user.name" -o tsv) --query "id" -o tsv)

az keyvault set-policy -n $KV_NAME  --secret-permissions get list --object-id $(az identity show --name "$AKS_CLUSTER_NAME-agentpool" -g $AKS_NODES_RESOURCE_GROUP_NAME --query "principalId" -o tsv)

az storage blob sync --account-name $STORAGE_ACCOUNT_NAME -c $PRODUCT_DETAILS_CONTAINER_NAME -s 'src/ContosoTraders.Api.Images/product-details'

az storage blob sync --account-name $STORAGE_ACCOUNT_NAME -c $PRODUCT_LIST_CONTAINER_NAME -s 'src/ContosoTraders.Api.Images/product-list'

az cdn endpoint purge --no-wait --content-paths '/*' -n $PRODUCTS_CDN_ENDPOINT_NAME -g $RESOURCE_GROUP_NAME --profile-name $CDN_PROFILE_NAME



kubectl get po -n chaos-testing

choco install kubernetes-helm

helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
kubectl create ns chaos-testing
helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock


kubectl get po -n chaos-testing

kubectl run nginx --image=nginx --restart=Never


sleep 20

#check status of docker app installation aand cloned lab files
$app = Get-Item -Path 'C:\Program Files\Docker\Docker\Docker Desktop.exe' 
$clonefiles = Get-Item -Path 'C:\Workspaces\lab\aiw-devops-with-github-lab-files\src'

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
