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

#Use the commonfunction to install the required files for cloudlabsagent service 
CloudlabsManualAgent Install

# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID $azuserobjectid
InstallModernVmValidator
InstallChocolatey

sleep 10

#install AZ-module latest version
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Install-Module -Name Az -Force

sleep 5

Install-Module -Name MicrosoftPowerBIMgmt -Force

sleep 5

Install-Module AzureAD -Force -AllowClobber

sleep 5

Import-Module AzureAD -Force

sleep 5

Install-WindowsFeature RSAT-AD-PowerShell

sleep 5

Import-Module ActiveDirectory

#Download PBI reports

cd C:\LabFiles

(New-Object Net.WebClient).DownloadFile("https://pbiembeddedlabfiles23.blob.core.windows.net/pbi-report/Wingtip Sales Analysis.pbix", "C:\LabFiles\Wingtip Sales Analysis.pbix")

(New-Object Net.WebClient).DownloadFile("https://pbiembeddedlabfiles23.blob.core.windows.net/pbi-report/Sales & Returns Sample without RLS.pbix", "C:\LabFiles\Sales & Returns Sample without RLS.pbix")

(New-Object Net.WebClient).DownloadFile("https://pbiembeddedlabfiles23.blob.core.windows.net/pbi-report/Sales & Returns Sample with RLS.pbix", "C:\LabFiles\Sales & Returns Sample with RLS.pbix")

#Download Logon-task file

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/shivashant25/ARM-templates/main/powerbiembedded/logontask.ps1","C:\Packages\logontask.ps1")

sleep 5

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

#Enable Autologon
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\demouser" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "$vmAdminPassword" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord


# Scheduled Task to Run PostConfig.ps1 screen on logon
$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\$adminUsername" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File C:\Packages\logontask.ps1"
Register-ScheduledTask -TaskName "logontask" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force

#Use the cloudlabs common function to write the status to validation status txt file 
$Validstatus="Pending"  ##Failed or Successful at the last step
$Validmessage="Post Deployment is Pending"
CloudlabsManualAgent setStatus

Stop-Transcript
Restart-Computer -Force 
