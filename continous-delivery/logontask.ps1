
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\extensionlog.txt -Append
Write-Host "Logon-task-started" 

$DeploymentID = $env:DeploymentID

Start-Process C:\Packages\extensions.bat
Write-Host "Bypass-Execution-Policy" 

choco install docker-desktop --version=4.7.0
Write-Host "Docker-install"

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

#Download lab files
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
