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

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

Stop-Transcript
Restart-Computer -Force 
