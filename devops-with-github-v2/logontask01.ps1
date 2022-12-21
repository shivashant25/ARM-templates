Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsLogOnTask.txt -Append
Write-Host "Logon-task-started" 

$commonscriptpath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.14\Downloads\0\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

$DeploymentID = $env:DeploymentID
$AppID = $env:AppID

Start-Process C:\Packages\extensions.bat
Write-Host "Bypass-Execution-Policy"
dotnet nuget add source "https://api.nuget.org/v3/index.json" --name "nuget.org"


choco install docker-desktop --version=4.7.0
Write-Host "Docker-install"

[Environment]::SetEnvironmentVariable("Path", $env:Path+";C:\Users\demouser\AppData\Roaming\npm\node_modules\azure-functions-core-tools\bin","User")

#WSL 2 pacakage installation
(New-Object System.Net.WebClient).DownloadFile('https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi', 'C:\wsl_update_x64.msi')
Start-Process C:\wsl_update_x64.msi -ArgumentList "/quiet"

choco install bicep
choco install kubernetes-helm
Install-Module Sqlserver -SkipPublisherCheck -Force
Import-Module Sqlserver
choco install kubernetes-cli

#re-install bicep module if choco command fails
# Create the install folder
$installPath = "$env:USERPROFILE\.bicep"
$installDir = New-Item -ItemType Directory -Path $installPath -Force
$installDir.Attributes += 'Hidden'
# Fetch the latest Bicep CLI binary
(New-Object Net.WebClient).DownloadFile("https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe", "$installPath\bicep.exe")
# Add bicep to your PATH
$currentPath = (Get-Item -path "HKCU:\Environment" ).GetValue('Path', '', 'DoNotExpandEnvironmentNames')
if (-not $currentPath.Contains("%USERPROFILE%\.bicep")) { setx PATH ($currentPath + ";%USERPROFILE%\.bicep") }
if (-not $env:path.Contains($installPath)) { $env:path += ";$installPath" }
# Verify you can now access the 'bicep' command.
bicep --help
# Done!

. C:\LabFiles\AzureCreds.ps1

$user = $AzureUserName

$password = $AzurePassword

$deploymentid = $env:DeploymentID

$connectionToken = "m6kk3lesc7gxadtqz4byaidrzc5nm7uot7sprhjcbf7m3vwafxxa"

refreshenv
az config set extension.use_dynamic_install=yes_without_prompt

Set-VSTeamAccount -Account https://dev.azure.com/aiw-devops/ -PersonalAccessToken $connectionToken

Add-VSTeamProject -ProjectName contosotraders-$deploymentid -ProcessTemplate Basic 

$project = Get-VSTeamProject -Name contosotraders-$deploymentid

$projectID = $project.Id

Add-VSTeamUserEntitlement -Email $user -ProjectName $project.Name -License Advanced -LicensingSource none -Group ProjectAdministrator   -Verbose

$base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($connectionToken)"))
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $base64AuthInfo")
$headers.Add("Content-Type", "application/json")

$body = "{
 `"accessLevel`": {
 `"accountLicenseType`": `"advanced`"
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

git clone --branch contosotraders-lab-files https://github.com/CloudLabsAI-Azure/AIW-DevOps-with-GitHub-V2.git

Sleep 5

Rename-Item -Path "C:\Workspaces\lab\AIW-DevOps-with-GitHub-V2"-NewName "aiw-devops-with-github-lab-files"

$password = $AzurePassword
$deploymentid = $env:DeploymentID

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

#deploy resources using bicep templates
cd C:\Workspaces\lab\aiw-devops-with-github-lab-files\iac

$RGname = "contoso-traders-$deploymentid"

New-AzResourceGroupDeployment -Name "createresources" -TemplateFile "createResources.bicep" -TemplateParameterFile "createResources.parameters.json" -ResourceGroup $RGname

$AKS_CLUSTER_NAME = "contoso-traders-aks$deploymentid"
$AKS_NODES_RESOURCE_GROUP_NAME = "contoso-traders-aks-nodes-rg-$deploymentid"
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
  
Invoke-Sqlcmd -InputFile ./src/ContosoTraders.Api.Products/Migration/productsdb.sql -Database productsdb -Username "localadmin" -Password $password -ServerInstance $server  -ErrorAction 'Stop' -Verbose -QueryTimeout 1800 # 30min

az aks get-credentials -g $RESOURCE_GROUP_NAME -n $AKS_CLUSTER_NAME

$USER_ASSIGNED_MANAGED_IDENTITY_NAME = "contoso-traders-mi-kv-access$deploymentid"
az vmss identity assign --identities $(az identity show -g $RESOURCE_GROUP_NAME  --name $USER_ASSIGNED_MANAGED_IDENTITY_NAME  --query "id" -o tsv) --ids $(az vmss list -g $AKS_NODES_RESOURCE_GROUP_NAME --query "[0].id" -o tsv) 

az keyvault set-policy -n $KV_NAME --key-permissions get list  --object-id $(az ad user show --id $(az account show --query "user.name" -o tsv) --query "id" -o tsv)

$servicePrincipalDisplayName = "https://odl_user_sp_$deploymentid"
$servicePrincipal = Get-AzADServicePrincipal -DisplayName $servicePrincipalDisplayName

sleep 10

$SPobjectID = $servicePrincipal.Id

az keyvault set-policy -n $KV_NAME  --secret-permissions get list set --object-id $SPobjectID

az keyvault set-policy -n $KV_NAME --key-permissions get list --object-id $SPobjectID 

az keyvault set-policy -n $KV_NAME  --secret-permissions get list set --object-id $(az identity show --name "$AKS_CLUSTER_NAME-agentpool" -g $AKS_NODES_RESOURCE_GROUP_NAME --query "principalId" -o tsv)

az keyvault set-policy -n $KV_NAME  --secret-permissions get list set --object-id $(az ad sp show --id $(az account show --query "user.name" -o tsv) --query "id" -o tsv)

az storage blob sync --account-name $STORAGE_ACCOUNT_NAME -c $PRODUCT_DETAILS_CONTAINER_NAME -s 'src/ContosoTraders.Api.Images/product-details'

az storage blob sync --account-name $STORAGE_ACCOUNT_NAME -c $PRODUCT_LIST_CONTAINER_NAME -s 'src/ContosoTraders.Api.Images/product-list'

az cdn endpoint purge --no-wait --content-paths '/*' -n $PRODUCTS_CDN_ENDPOINT_NAME -g $RESOURCE_GROUP_NAME --profile-name $CDN_PROFILE_NAME

#Az login
. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update
kubectl create ns chaos-testing

sleep 20

helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock

sleep 20

kubectl get po -n chaos-testing

kubectl run nginx --image=nginx --restart=Never

sleep 20

$definition = New-AzPolicyDefinition -Name 'SpektraCustomPolicy' -DisplayName 'Spektra Custom Policy' -Policy 'https://raw.githubusercontent.com/shivashant25/ARM-templates/main/devops-with-github-v2/policy-01.json'

$RGname = "contoso-traders-$deploymentid"

$rg = Get-AzResourceGroup -Name $RGname

$definition = Get-AzPolicyDefinition | Where-Object { $_.Properties.DisplayName -eq 'SpektraCustomPolicy' }

New-AzPolicyAssignment -Name 'spektra-policy-assignment' -DisplayName 'Spektra Custom Policy Assignment' -Scope $rg.ResourceId -PolicyDefinition $definition

sleep 20

#check bicep deployment status and cloned lab files

$checkpolicy = Get-AzPolicyAssignment -Name 'spektra-policy-assignment' -Scope $rg.ResourceId

$chaspod = kubectl get po -n chaos-testing 

$RGname = "contoso-traders-$deploymentid"

$RG1 = Get-AzResourceGroupDeployment -Name "createresources" -ResourceGroupName $RGname

$RG1 = $RG1.ProvisioningState

$clonefiles = Get-Item -Path 'C:\Workspaces\lab\aiw-devops-with-github-lab-files\src'
$deploymentstatus = $RG1

if(($deploymentstatus -ne $null) -and ($clonefiles -ne $null) -and ($chaspod -ne $null) -and ($checkpolicy -ne $null))
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

#Start the cloudlabs agent service 
CloudlabsManualAgent Start     

sleep 5
Unregister-ScheduledTask -TaskName "logontask" -Confirm:$false 
Restart-Computer -Force 
