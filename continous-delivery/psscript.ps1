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
InstallVSCode
choco install dotnetcore-sdk
choco install azure-functions-core-tools
InstallAzCLI

sleep 10

#Install synapse modules
Install-PackageProvider NuGet -Force

#installing extensions to vscode
code --install-extension ms-dotnettools.csharp 
code --install-extension vsciot-vscode.azure-iot-tools
code --install-extension ms-azuretools.vscode-azurefunctions

sleep  10

#Assign Packages to Install
choco install vscode
choco install git
choco install nodejs.install

sleep 5

#DownloadFiles
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/innovate-and-modernize-apps-with-data-and-ai/scripts/extensions.bat","C:\Packages\extensions.bat")

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/shivashant25/ARM-templates/main/continous-delivery/logontask.ps1","C:\Packages\logontask.ps1")



sleep 5

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword


#Enable Autologon
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\demouser" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "Password.1!!" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord


# Scheduled Task to Run PostConfig.ps1 screen on logon
$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\$adminUsername" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File C:\Packages\logontask.ps1"
Register-ScheduledTask -TaskName "Installdocker" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force


Stop-Transcript
Restart-Computer -Force 
