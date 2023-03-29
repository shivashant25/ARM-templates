Param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,
    [string]
    $AzurePassword,
    [string]
    $AzureTenantID,
    [string]
    $AzureSubscriptionID,
    [string]
    $ODLID,
    [string]
    $DeploymentID,
    [string]
    $azuserobjectid,
    [string]
    $InstallCloudLabsShadow,
    [string]
    $vmAdminUsername,
    [string]
    $trainerUserName,
    [string]
    $vmAdminPassword,
    [string]
    $trainerUserPassword

)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 
$adminUsername = "demouser"
[System.Environment]::SetEnvironmentVariable('DeploymentID', $DeploymentID,[System.EnvironmentVariableTarget]::Machine)

#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID $azuserobjectid
InstallChocolatey

sleep 10

#install AZ-module latest version
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Install-Module -Name Az -Force

sleep 5

Install-Module -Name MicrosoftPowerBIMgmt -Force

sleep 5

#Download PBI reports

cd C:\LabFiles

(New-Object Net.WebClient).DownloadFile("https://pbiembeddedlabfiles23.blob.core.windows.net/pbi-report/Wingtip Sales Analysis.pbix", "C:\LabFiles\Wingtip Sales Analysis.pbix")

(New-Object Net.WebClient).DownloadFile("https://pbiembeddedlabfiles23.blob.core.windows.net/pbi-report/Sales & Returns Sample without RLS.pbix", "C:\LabFiles\Sales & Returns Sample without RLS.pbix")

(New-Object Net.WebClient).DownloadFile("https://pbiembeddedlabfiles23.blob.core.windows.net/pbi-report/Sales & Returns Sample with RLS.pbix", "C:\LabFiles\Sales & Returns Sample with RLS.pbix")

#Az login
. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-PowerBIServiceAccount -Credential $cred | Out-Null

New-PowerBIWorkspace -Name "hacker$DeploymentID"

cd C:\LabFiles

$PBID = (Get-PowerBIWorkspace).Id

New-PowerBIReport -Path 'C:\LabFiles\Wingtip Sales Analysis.pbix' -Name 'Wingtip Sales Analysis' -WorkspaceId $PBID

sleep 5

$salesreport = Get-PowerBIReport -Name 'Wingtip Sales Analysis' -WorkspaceId $PBID

sleep 5

$reportid = $salesreport.Id

$datasetid = $salesreport.DatasetId

cd C:\LabFiles

New-Item C:\LabFiles\workspacedetails.txt

Add-Content C:\LabFiles\workspacedetails.txt "workspaceID= $PBID"

Add-Content C:\LabFiles\workspacedetails.txt "reportID= $reportid"

Add-Content C:\LabFiles\workspacedetails.txt "datasetID= $datasetid"

sleep 5

$path = "C:\Users\hacker1\Desktop\hacker\Power BI Embedded workshop_latest"
(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "42c563a4-2575-42a1-992e-9bebb8588971", "<client id>"} | Set-Content -Path "$path\appsettings.json"

(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "2a1ab401-76ec-42b7-bc31-6ac0fa26600c", "<tenant id>"} | Set-Content -Path "$path\appsettings.json"

(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "Ou48Q~1vuDW.9TXLpTVgYrx~_C1ZptcAck59ta53", "<client secret>"} | Set-Content -Path "$path\appsettings.json"

(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "c5f6469b-a484-46c3-a676-8a3b33b7e33d", "$PBID"} | Set-Content -Path "$path\appsettings.json"

(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "fad26f53-114b-4613-9459-b751124c8fe5", "$reportid"} | Set-Content -Path "$path\appsettings.json"

(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "f82722f4-a92c-4612-9c3f-1ab21aa1a308", "$datasetid"} | Set-Content -Path "$path\appsettings.json"

sleep 5

$path = "C:\Users\hacker1\Desktop\hacker\Power BI Embedded workshop_latest\wwwroot\js"
(Get-Content -Path "$path\index.js") | ForEach-Object {$_ -Replace "6f22f059-088b-40ca-9adf-f285dc9ff2bb", "$datasetid"} | Set-Content -Path "$path\index.js"

sleep 5

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

Stop-Transcript
Restart-Computer -Force 
