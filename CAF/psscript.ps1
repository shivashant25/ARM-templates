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

cd eslz-bicep

refreshenv

#BICEP DEPLOYMENTS STARTS FROM HERE

#Deploy Management groups
$mgmttemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\managementGroups"
$mgmtparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\managementGroups\parameters"

New-AzTenantDeployment -TemplateFile "$mgmttemplate\managementGroups.bicep" -TemplateParameterFile "$mgmtparameters\managementGroups.parameters.all.json" -Location "centralus" 



# Deploy Azure policy definitions
$cpdtemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\definitions"
$cpdparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\definitions\parameters"

New-AzManagementGroupDeployment `
  -TemplateFile "$cpdtemplate\customPolicyDefinitions.bicep" `
  -TemplateParameterFile "$cpdparameters\customPolicyDefinitions.parameters.all.json" `
  -Location "centralus" `
  -ManagementGroupId eslz



# Deploy custom roles
$rbactemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\customRoleDefinitions"
$rbacparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\customRoleDefinitions\parameters"

New-AzManagementGroupDeployment `
  -TemplateFile "$rbactemplate\customRoleDefinitions.bicep" `
  -TemplateParameterFile "$rbacparameters\customRoleDefinitions.parameters.all.json" `
  -Location centralus `
  -ManagementGroupId eslz  




# Deploy Log Analytics

# Set Management Sub - suffix subscription  ID as the the current subscription

$AllsubID = (Get-AzSubscription).Id

$ManagementSubscriptionId = $AllsubID[6]

Select-AzSubscription -SubscriptionId $ManagementSubscriptionId

# Create Resource Group - optional when using an existing resource group
New-AzResourceGroup `
  -Name eslz-mgmt `
  -Location centralus

$logtemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\logging"
$logparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\logging\parameters"

New-AzResourceGroupDeployment `
  -TemplateFile "$logtemplate\logging.bicep" `
  -TemplateParameterFile "$logparameters\logging.parameters.all.json" `
  -ResourceGroup eslz-mgmt



# Deploy Hub Networking before deploying orchestration
# Set Platform connectivity subscription ID which is L1 - Connectivity Sub - Sufiix

$AllsubID = (Get-AzSubscription).Id

$ConnectivitySubscriptionId = $AllsubID[1]

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId

New-AzResourceGroup -Name 'eslz_Hub_Networking' `
  -Location 'centralus'

$nettemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\hubNetworking"
$netparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\/hubNetworking\parameters"

  
New-AzResourceGroupDeployment `
  -TemplateFile "$nettemplate\hubNetworking.bicep" `
  -TemplateParameterFile "$netparameters\hubNetworking.parameters.all.json" `
  -ResourceGroupName 'eslz_Hub_Networking'


#Replacing connectivity Sub ID and Hub Vnet ResourceId in parameters file

$AllsubID = (Get-AzSubscription).Id

$ConnectivitySubscriptionId = $AllsubID[1]

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId


(Get-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\hubPeeredSpoke\parameters\hubPeeredSpoke.parameters.all.json") | ForEach-Object {$_ -Replace "connectivitysubid", $ConnectivitySubscriptionId} | Set-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\hubPeeredSpoke\parameters\hubPeeredSpoke.parameters.all.json"

$hubvnet = (Get-AzResource -Name "eslz-hub-centralus").ResourceId

(Get-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\hubPeeredSpoke\parameters\hubPeeredSpoke.parameters.all.json") | ForEach-Object {$_ -Replace "hubvnetid", $hubvnet} | Set-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\hubPeeredSpoke\parameters\hubPeeredSpoke.parameters.all.json"

  # Deploy hubPeeredSpoke - Spoke network

$hpstemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\hubPeeredSpoke"
$hpsparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\hubPeeredSpoke\parameters"

New-AzManagementGroupDeployment `
  -TemplateFile "$hpstemplate\hubPeeredSpoke.bicep" `
  -TemplateParameterFile "$hpsparameters\hubPeeredSpoke.parameters.all.json" `
  -Location centralus `
  -ManagementGroupId eslz



#create service pricipal and get oject ID

$servicePrincipalDisplayName = "eslzsp"
$servicePrincipal = New-AzADServicePrincipal -DisplayName $servicePrincipalDisplayName
$sp = (Get-AzADServicePrincipal -DisplayName 'eslzsp').Id
(Get-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\roleAssignments\parameters\roleAssignmentManagementGroup.servicePrincipal.parameters.all.json") | ForEach-Object {$_ -Replace "spid", $sp} | Set-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\roleAssignments\parameters\roleAssignmentManagementGroup.servicePrincipal.parameters.all.json"

#Replacing SP object ID in parameters

# Assign role 

$ratemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\roleAssignments"
$raparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\roleAssignments\parameters"

New-AzManagementGroupDeployment `
  -TemplateFile "$ratemplate\roleAssignmentManagementGroup.bicep" `
  -TemplateParameterFile "$raparameters\roleAssignmentManagementGroup.servicePrincipal.parameters.all.json" `
  -ManagementGroupId eslz-platform `
  -Location centralus




#Subscription placement

$AllsubID = (Get-AzSubscription).Id

$ConnectivitySubscriptionId = $AllsubID[1]
$MigrationLZSubscriptionId = $AllsubID[2]
$GovernanceSubscriptionId = $AllsubID[3]
$IdentitySubscriptionId = $AllsubID[4]
$IdentitySubscriptionId = $AllsubID[4]
$LandingZoneSubscriptionId= $AllsubID[5]
$ManagementSubscriptionId = $AllsubID[6]


(Get-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.all.json") | ForEach-Object {$_ -Replace "managementsubid", $ManagementSubscriptionId} | Set-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.all.json"
(Get-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.all.json") | ForEach-Object {$_ -Replace "identitysubid", $IdentitySubscriptionId} | Set-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.all.json"
(Get-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.all.json") | ForEach-Object {$_ -Replace "corpsubid", $LandingZoneSubscriptionId} | Set-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.all.json"


$subparameters= "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll\parameters"
$subtemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll"

# For Azure global regions
New-AzManagementGroupDeployment `
  -TemplateFile "$subtemplate\subPlacementAll.bicep" `
  -TemplateParameterFile "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\orchestration\subPlacementAll\parameters\subPlacementAll.parameters.all.json" `
  -Location centralus `
  -ManagementGroupId eslz


#Replacing ResourceId
$ddosid= (Get-AzResource -Name "eslz-ddos-plan").ResourceId
(Get-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\assignments\alzDefaults\parameters\alzDefaultPolicyAssignments.parameters.all.json") | ForEach-Object {$_ -Replace "ddosid", $ddosid} | Set-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\assignments\alzDefaults\parameters\alzDefaultPolicyAssignments.parameters.all.json"


$AllsubID = (Get-AzSubscription).Id

$ManagementSubscriptionId = $AllsubID[6]


Select-AzSubscription -SubscriptionId $ManagementSubscriptionId

$loganalyticsid= (Get-AzResource -ResourceGroupName "eslz-mgmt" -ResourceType "Microsoft.OperationalInsights/workspaces" ).ResourceId

(Get-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\assignments\alzDefaults\parameters\alzDefaultPolicyAssignments.parameters.all.json") | ForEach-Object {$_ -Replace "logid", $loganalyticsid} | Set-Content -Path "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\assignments\alzDefaults\parameters\alzDefaultPolicyAssignments.parameters.all.json"

# For Azure global regions
New-AzManagementGroupDeployment `
  -TemplateFile "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\assignments\alzDefaults\alzDefaultPolicyAssignments.bicep" `
  -TemplateParameterFile "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\assignments\alzDefaults\parameters\alzDefaultPolicyAssignments.parameters.all.json" `
  -Location centralus `
  -ManagementGroupId eslz



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
