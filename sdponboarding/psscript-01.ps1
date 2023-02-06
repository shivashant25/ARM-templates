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
InstallCloudLabsShadow $ODLID $InstallCloudLabsShadow
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID $azuserobjectid
InstallChocolatey

sleep 10

#install AZ-module latest version
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Install-Module -Name Az -Force

sleep 10

#Az Login

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/shivashant25/ARM-templates/main/sdponboarding/deploy-02.json","C:\Packages\deploy-02.json")

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/shivashant25/ARM-templates/main/sdponboarding/deploy-02.parameters.json","C:\Packages\deploy-02.parameters.json")

$path = "C:\Packages"
(Get-Content -Path "$path\deploy-02.parameters.json") | ForEach-Object {$_ -Replace "deploymentidvalue", "$DeploymentID"} | Set-Content -Path "$path\deploy-02.parameters.json"

sleep 5

$path = "C:\Workspaces\lab\aiw-devops-with-github-lab-files\iac"
(Get-Content -Path "$path\deploy-02.parameters.json") | ForEach-Object {$_ -Replace "azureusername", "$AzureUserName"} | Set-Content -Path "$path\deploy-02.parameters.json"

sleep 5

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

cd C:\Packages

$RGname = "PowerBI-Embedded-RG"

New-AzResourceGroupDeployment -Name "createresources" -TemplateFile "deploy-02.json" -TemplateParameterFile "deploy-02.parameters.json" -ResourceGroup $RGname

sleep 5

Enable-CloudLabsEmbeddedShadow $vmAdminUsername $trainerUserName $trainerUserPassword

Stop-Transcript
Restart-Computer -Force 
