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

#Creating credfile
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID $ODLID $AzureObjectId

#InstallManualStatusAgent
CloudlabsManualAgent Install

#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon
InstallCloudLabsShadow $ODLID $InstallCloudLabsShadow

#InstallAzPowerShellModule
InstallModernVmValidator


#InstallAzPowerShellModule
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/Azure/azure-powershell/releases/download/v5.0.0-October2020/Az-Cmdlets-5.0.0.33612-x64.msi","C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi")
sleep 5

Start-Process msiexec.exe -Wait '/I C:\Packages\Az-Cmdlets-5.0.0.33612-x64.msi /qn' -Verbose 

#choco install az.powershell -y -force

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SpektraSystems/CloudLabs-Azure/master/azure-synapse-analytics-workshop-400/artifacts/setup/azcopy.exe" -OutFile "C:\LabFiles\azcopy.exe"

Add-Content -Path "C:\LabFiles\AzureCreds.txt" -Value "ODLID= $ODLID" -PassThru

#Download lab files
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/SollianceNet/azure-synapse-analytics-day/archive/master.zip","C:\azure-synapse-analytics-day-master.zip")

#unziping folder
function Expand-ZIPFile($file, $destination)
{
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
{
$shell.Namespace($destination).copyhere($item)
}
}
Expand-ZIPFile -File "C:\azure-synapse-analytics-day-master.zip" -Destination "C:\LabFiles\"


$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/synapse-tech-immersion/testing-templates/Automation1_new1.zip","C:\Automation1.zip")

#unziping folder
function Expand-ZIPFile($file, $destination)
{
$shell = new-object -com shell.application
$zip = $shell.NameSpace($file)
foreach($item in $zip.items())
{
$shell.Namespace($destination).copyhere($item)
}
}
Expand-ZIPFile -File "C:\Automation1.zip" -Destination "C:\LabFiles\"


$LabFilesDirectory = "C:\LabFiles"

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/synapse-tech-immersion/scripts/templateandstorageaiad.ps1","C:\LabFiles\templateandstorage.ps1")

$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/synapse-tech-immersion/scripts/automation.bat","C:\LabFiles\automation.bat")
$WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/synapse-tech-immersion/scripts/export.bat","C:\LabFiles\export.bat")

#Download and Install PowerBi Desktop
#$WebClient = New-Object System.Net.WebClient
#$WebClient.DownloadFile("https://download.microsoft.com/download/3/C/0/3C0A5D40-85C6-4959-BB51-3A2087B18BCA/PBIDesktopRS_x64.msi","C:\Packages\PBIDesktop_x64.msi")
#Start-Process msiexec.exe -Wait '/I C:\Packages\PBIDesktop_x64.msi /qr ACCEPT_EULA=1' 

#Download power Bi desktop
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe","C:\LabFiles\PBIDesktop_x64.exe")
#Start-Process -FilePath "C:\LabFiles\PBIDesktop_x64.exe" -ArgumentList '-quit','ACCEPT_EULA=1'

#Install synapse modules
Install-PackageProvider NuGet -Force
Install-Module -Name Az.Synapse -RequiredVersion 0.3.0 -AllowClobber -Force


#Install python
Install-Package python3 -Scope CurrentUser -Force

sleep 5
Import-Module Az.Synapse

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword

$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*Synapse-AIAD-*" }).ResourceGroupName
$deploymentId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]

$url = "https://experienceazure.blob.core.windows.net/templates/synapse-tech-immersion/testing-templates/deploy-synapse.parameters.json"
$output = "c:\LabFiles\parameters.json";
$wclient = New-Object System.Net.WebClient;
$wclient.CachePolicy = new-object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore);
$wclient.Headers.Add("Cache-Control", "no-cache");
$wclient.DownloadFile($url, $output)
(Get-Content -Path "c:\LabFiles\parameters.json") | ForEach-Object {$_ -Replace "GET-AZUSER-PASSWORD", "$AzurePassword"} | Set-Content -Path "c:\LabFiles\parameters.json"
(Get-Content -Path "c:\LabFiles\parameters.json") | ForEach-Object {$_ -Replace "GET-DEPLOYMENT-ID", "$DeploymentID"} | Set-Content -Path "c:\LabFiles\parameters.json"
(Get-Content -Path "c:\LabFiles\parameters.json") | ForEach-Object {$_ -Replace "GET-AZUSER-UPN", "$AzureUserName "} | Set-Content -Path "c:\LabFiles\parameters.json"
(Get-Content -Path "c:\LabFiles\parameters.json") | ForEach-Object {$_ -Replace "GET-AZUSER-OBJECTID", "$azuserobjectid"} | Set-Content -Path "c:\LabFiles\parameters.json"

Write-Host "Starting main deployment." -ForegroundColor Green -Verbose
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri "https://experienceazure.blob.core.windows.net/templates/synapse-tech-immersion/testing-templates/deploy-synapse.json" -TemplateParameterFile "c:\LabFiles\parameters.json"

New-AzRoleAssignment -ResourceGroupName $resourceGroupName -ErrorAction Ignore -ObjectId "37548b2e-e5ab-4d2b-b0da-4d812f56c30e" -RoleDefinitionName "Owner"

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

#Enable Autologon
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\demouser" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "Password.1!!" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord

#checkdeployment
$status = (Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name "deploy-synapse").ProvisioningState
$status
if ($status -eq "Succeeded")
{
 
    $ValidStatus="Pending"  ##Failed or Successful at the last step
    $ValidMessage="Main Deployment is successful, logontask is pending"
Remove-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name "deploy-synapse"

# Scheduled Task
$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\demouser" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $LabFilesDirectory\templateandstorage.ps1"
Register-ScheduledTask -TaskName "Setup" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force 

}
else {
    Write-Warning "Validation Failed - see log output"
    $ValidStatus="Failed"  ##Failed or Successful at the last step
    $ValidMessage="ARM template Deployment Failed"
      }

SetDeploymentStatus $ValidStatus $ValidMessage

Stop-Transcript
Sleep 10
