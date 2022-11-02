. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword

az login --username "$userName" --password "$password"

az role assignment create  --scope '/' --role 'owner' --assignee $AzureUserName 

#Import Common Functions
$commonscriptpath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.12\Downloads\0\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath


Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\deploybicep.txt -Append

cd C:\BicepTemplates

git clone --branch main https://github.com/shivashant25/eslz-bicep.git


. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword
$subscriptionId = $AzureSubscriptionID
$TenantID = $AzureTenantID


$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null


cd eslz-bicep

refreshenv

#BICEP DEPLOYMENTS STARTS FROM HERE

#Deploy Management groups
$mgmttemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\managementGroups"
$mgmtparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\managementGroups\parameters"

New-AzTenantDeployment -Name "Managment1" -TemplateFile "$mgmttemplate\managementGroups.bicep" -TemplateParameterFile "$mgmtparameters\managementGroups.parameters.all.json" -Location "centralus" 



# Deploy Azure policy definitions
$cpdtemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\definitions"
$cpdparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\definitions\parameters"

New-AzManagementGroupDeployment -Name "Managment2" -TemplateFile "$cpdtemplate\customPolicyDefinitions.bicep" -TemplateParameterFile "$cpdparameters\customPolicyDefinitions.parameters.all.json" -Location "centralus" -ManagementGroupId eslz



# Deploy custom roles
$rbactemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\customRoleDefinitions"
$rbacparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\customRoleDefinitions\parameters"

New-AzManagementGroupDeployment -Name "Managment3" -TemplateFile "$rbactemplate\customRoleDefinitions.bicep" -TemplateParameterFile "$rbacparameters\customRoleDefinitions.parameters.all.json" -Location centralus -ManagementGroupId eslz  




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

New-AzResourceGroupDeployment -Name "RG1" -TemplateFile "$logtemplate\logging.bicep" -TemplateParameterFile "$logparameters\logging.parameters.all.json" -ResourceGroup eslz-mgmt



# Deploy Hub Networking before deploying orchestration
# Set Platform connectivity subscription ID which is L1 - Connectivity Sub - Sufiix

$AllsubID = (Get-AzSubscription).Id

$ConnectivitySubscriptionId = $AllsubID[1]

Select-AzSubscription -SubscriptionId $ConnectivitySubscriptionId

New-AzResourceGroup -Name 'eslz_Hub_Networking' `
  -Location 'centralus'

$nettemplate = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\hubNetworking"
$netparameters = "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\/hubNetworking\parameters"

  
New-AzResourceGroupDeployment -Name "RG2" -TemplateFile "$nettemplate\hubNetworking.bicep" -TemplateParameterFile "$netparameters\hubNetworking.parameters.all.json" -ResourceGroupName 'eslz_Hub_Networking'

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
  -Name "Managment4" `
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
  -Name "Managment5" `
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
   -Name "Managment6" `
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
  -Name "Managment6" `
  -TemplateFile "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\assignments\alzDefaults\alzDefaultPolicyAssignments.bicep" `
  -TemplateParameterFile "C:\BicepTemplates\eslz-bicep\infra-as-code\bicep\modules\policy\assignments\alzDefaults\parameters\alzDefaultPolicyAssignments.parameters.all.json" `
  -Location centralus `
  -ManagementGroupId eslz

  $Managment2 = Get-AzManagementGroupDeployment -Name Managment2 -ManagementGroupId eslz
  $Managment3 = Get-AzManagementGroupDeployment -Name Managment3 -ManagementGroupId eslz
  $Managment4 = Get-AzManagementGroupDeployment -Name Managment4 -ManagementGroupId eslz
  $Managment5 = Get-AzManagementGroupDeployment -Name Managment5 -ManagementGroupId eslz-platform 
  $Managment6 = Get-AzManagementGroupDeployment -Name Managment6 -ManagementGroupId eslz
    Select-AzSubscription -Subscription $ManagementSubscriptionId

  $RG1 = Get-AzResourceGroupDeployment -Name "RG1" -ResourceGroupName 'eslz-mgmt'
  Select-AzSubscription -Subscription $ConnectivitySubscriptionId 
  $RG2 = Get-AzResourceGroupDeployment -Name "RG2" -ResourceGroupName 'eslz_Hub_Networking'
  $Managment2 = $Managment2.ProvisioningState
  $Managment3 = $Managment3.ProvisioningState
  $Managment4 = $Managment4.ProvisioningState
  $Managment5 = $Managment5.ProvisioningState
  $Managment6 = $Managment6.ProvisioningState
  $RG1 = $RG1.ProvisioningState
  $RG2 = $RG2.ProvisioningState



  if ($Managment2 -eq "Succeeded" -and $Managment3 -eq "Succeeded" -and $Managment4 -eq "Succeeded"-and $Managment5 -eq "Succeeded"-and $Managment6 -eq "Succeeded"-and $RG1 -eq "Succeeded"-and $RG2 -eq "Succeeded")
  {
  
    $status = "Succeeded"
  }
  else
  {
  $status = $null
  }


$status
if ($status -ne $null)
{
 
    $Validstatus="Succeeded"  ##Failed or Successful at the last step
   $Validmessage="Management level deployments are succeeded"



}
else {
    Write-Warning "Validation Failed - see log output"
    $Validstatus="Failed"  ##Failed or Successful at the last step
    $Validmessage="Management level deployments failed after root level role assignment"
      }


CloudlabsManualAgent setStatus

#Start the cloudlabs agent service 
CloudlabsManualAgent Start

Stop-Transcript

sleep 5
Unregister-ScheduledTask -TaskName "Setup1" -Confirm:$false
