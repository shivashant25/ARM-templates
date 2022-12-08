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
InstallCloudLabsShadow $ODLID $InstallCloudLabsShadow
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID $azuserobjectid
InstallChocolatey

sleep 10

Install-Module -Name VSTeam -Force
Import-Module -Name VSTeam -Force

#installing extensions to vscode
code --install-extension ms-dotnettools.csharp 

sleep  10

#Assign Packages to Install
choco install vscode
choco install dotnet-6.0-sdk
choco install azure-cli

sleep  10

#Install nodejs v16.8.0
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://nodejs.org/download/release/v16.8.0/node-v16.8.0-x64.msi","C:\LabFiles\node-v16.8.0-x64.msi")


msiexec.exe /i "C:\LabFiles\node-v16.8.0-x64.msi" /qn ALLUSERS=2 MSIINSTALLPERUSER=1

sleep 5
$arguments = "/i `"C:\LabFiles\node-v16.8.0-x64.msi`" /quiet"
Start-Process msiexec.exe -ArgumentList $arguments -Wait

sleep 5

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
Install-Module Sqlserver -SkipPublisherCheck -Force
Import-Module Sqlserver
sleep 5

#DownloadFiles
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/innovate-and-modernize-apps-with-data-and-ai/scripts/extensions.bat","C:\Packages\extensions.bat")

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/shivashant25/ARM-templates/main/devops-with-github-v2/logontask01.ps1","C:\Packages\logontask.ps1")

sleep 5

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

#WSL 2 pacakage installation
wsl --install
(New-Object System.Net.WebClient).DownloadFile('https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi', 'C:\wsl_update_x64.msi')

sleep 5
$arguments = "/i `"C:\wsl_update_x64.msi`" /quiet"
Start-Process msiexec.exe -ArgumentList $arguments -Wait

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
Register-ScheduledTask -TaskName "Installdocker" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force

#Use the cloudlabs common function to write the status to validation status txt file 
$Validstatus="Pending"  ##Failed or Successful at the last step
$Validmessage="Post Deployment is Pending"
CloudlabsManualAgent setStatus

Stop-Transcript
Restart-Computer -Force 
