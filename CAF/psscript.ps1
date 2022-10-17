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
    $OBJECTID,

    [string]
    $InstallCloudLabsShadow,

    [string]
    $vmAdminUsername,

    [string]
    $trainerUserName,

    [string]
    $trainerUserPassword,

    [string]
    $adminPassword
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

#InstallManualStatusAgent
CloudlabsManualAgent Install

# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon
#InstallAzCLI
#InstallCloudLabsShadow $ODLID $InstallCloudLabsShadow
Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID $OBJECTID

$FileDir ="C:\LabFiles"


#Install az cli
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://azcliprod.blob.core.windows.net/msi/azure-cli-2.21.0.msi","C:\Packages\azure-cli-2.21.0.msi")
sleep 2
Start-Process msiexec.exe -Wait '/I C:\Packages\azure-cli-2.21.0.msi /qn' -Verbose

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloud-adoption-framework/files/vnetdmz-deploy.json","C:\LabFiles\vnetdmz-deploy.json")

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloud-adoption-framework/scripts/logontask.ps1","C:\LabFiles\logontask.ps1")

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/shivashant25/ARM-templates/main/CAF/deploybicep.ps1","C:\LabFiles\deploybicep.ps1")


$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloud-adoption-framework/scripts/logontask1.ps1","C:\LabFiles\logontask1.ps1")

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloud-adoption-framework/files/cleanup.ps1","C:\LabFiles\cleanup.ps1")


#install AZ-module latest version

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Install-Module -Name Az -Force

#Az Login

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

#install git
choco install git

#install bicep module
choco install bicep

#create directory and clone bicep templates

mkdir C:\BicepTemplates
cd C:\BicepTemplates

git clone --branch main https://github.com/shivashant25/eslz-bicep.git

#Enable Autologon
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\demouser" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "$adminPassword" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord

# Scheduled Task
$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\demouser" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $FileDir\logontask.ps1"
Register-ScheduledTask -TaskName "Setup" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force 


#Connect-AzureAD -Credential $cred | Out-Null

#az login --username "$userName" --password "$password"


#New-AzRoleAssignment -Scope '/' -RoleDefinitionName 'Owner' -ObjectId $OBJECTID

#sleep 300

#az role assignment create  --scope '/' --role 'owner' --assignee $AzureUserName 

#sleep 300

CloudlabsManualAgent Start

Restart-Computer -Force
