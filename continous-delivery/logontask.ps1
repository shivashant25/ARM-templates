
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\extensionlog.txt -Append
Write-Host "Logon-task-started" 

$DeploymentID = $env:DeploymentID

Start-Process C:\Packages\extensions.bat
Write-Host "Bypass-Execution-Policy" 
 
choco install docker-desktop --version=4.7.0
Write-Host "Docker-install"

#Installing PostgreSQL extension fro Azure Data Studio
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/microsoft/azuredatastudio-postgresql/releases/download/v0.2.6/azuredatastudio-postgresql-0.2.6-win-x64.vsix","C:\Windows\System32\azuredatastudio-postgresql-0.2.6-win-x64.vsix")
azuredatastudio --install-extension azuredatastudio-postgresql-0.2.6-win-x64.vsix 

[Environment]::SetEnvironmentVariable("Path", $env:Path+";C:\Users\demouser\AppData\Roaming\npm\node_modules\azure-functions-core-tools\bin","User")


. C:\LabFiles\AzureCreds.ps1

$user = $AzureUserName

$deploymentid = $DeploymentID

$connectionToken = "5lhucmsyocp736jqdydrzeuzije7jpj34tcede3rtk32qu6hy2fa"

refreshenv

az config set extension.use_dynamic_install=yes_without_prompt

echo $connectionToken | az devops login --organization https://dev.azure.com/aiw-devops/


$project = az devops project create --name fabrikam-$deploymentid --org https://dev.azure.com/aiw-devops/ --process basic
$project

$split =$project.Split("/")

$projectID = $split[22]

az devops user add --email-id $user --license-type express --org https://dev.azure.com/aiw-devops/ --output table


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


cd C:\

mkdir C:\Workspaces
cd C:\Workspaces
mkdir lab
cd lab

git clone --branch stage https://github.com/CloudLabs-MCW/MCW-Continuous-delivery-in-Azure-DevOps

mkdir mcw-continuous-delivery-lab-files
cd mcw-continuous-delivery-lab-files

Copy-Item '..\mcw-continuous-delivery-in-azure-devops\Hands-on lab\lab-files\*' -Destination ./ -Recurse

Sleep 5
$path = "C:\Workspaces\lab\mcw-continuous-delivery-lab-files\infrastructure"
(Get-Content -Path "$path\deploy-webapp.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\deploy-webapp.ps1"
(Get-Content -Path "$path\configure-webapp.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\configure-webapp.ps1"
(Get-Content -Path "$path\deploy-appinsights.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\deploy-appinsights.ps1"
(Get-Content -Path "$path\deploy-infrastructure.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\deploy-infrastructure.ps1"
(Get-Content -Path "$path\seed-cosmosdb.ps1") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\seed-cosmosdb.ps1"

Unregister-ScheduledTask -TaskName "Installdocker" -Confirm:$false 
Restart-Computer -Force 
