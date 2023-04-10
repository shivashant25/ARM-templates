Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsLogOnTask.txt -Append
Write-Host "Logon-task-started" 

$commonscriptpath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.*\Downloads\0\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

$DeploymentID = $env:DeploymentID

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

(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "c5f6469b-a484-46c3-a676-8a3b33b7e33d", "$PBID"} | Set-Content -Path "$path\appsettings.json"

(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "fad26f53-114b-4613-9459-b751124c8fe5", "$reportid"} | Set-Content -Path "$path\appsettings.json"

(Get-Content -Path "$path\appsettings.json") | ForEach-Object {$_ -Replace "f82722f4-a92c-4612-9c3f-1ab21aa1a308", "$datasetid"} | Set-Content -Path "$path\appsettings.json"

sleep 5

$path = "C:\Users\hacker1\Desktop\hacker\Power BI Embedded workshop_latest\wwwroot\js"
(Get-Content -Path "$path\index.js") | ForEach-Object {$_ -Replace "6f22f059-088b-40ca-9adf-f285dc9ff2bb", "$datasetid"} | Set-Content -Path "$path\index.js"

sleep 5

$userName = "powerbiembeddedlab@cloudevents.ai"
$password = "Admin@powerbi" | ConvertTo-SecureString -AsPlainText -Force

$cred = New-Object -TypeName PSCredential -ArgumentList $userName, $password

$tenantid = "0b9d902d-e3c1-48f1-8979-365832b339dd"

Connect-AzAccount -TenantId $tenantid -Credential $cred 

$userid = (Get-AzADUser -DisplayName "ODL_User $DeploymentID").Id

$deploymentid = "$DeploymentID"

#get Service Principal details
$servicePrincipalDisplayName = "https://odl_user_sp_$deploymentid"
$servicePrincipal = Get-AzADServicePrincipal -DisplayName $servicePrincipalDisplayName

sleep 5

$SPobjectID = $servicePrincipal.Id

Get-AzureADGroup -ObjectID 7de766d3-56cd-4945-8d5d-07bc2e3af5e5

Add-AzureADGroupMember -ObjectId 7de766d3-56cd-4945-8d5d-07bc2e3af5e5 -RefObjectId $SPobjectID
sleep 5

$userName = "powerbiembeddedlab@cloudevents.ai"
$password = "Admin@powerbi" | ConvertTo-SecureString -AsPlainText -Force

$cred = New-Object -TypeName PSCredential -ArgumentList $userName, $password

$tenantid = "0b9d902d-e3c1-48f1-8979-365832b339dd"

Connect-AzureAD -TenantId $tenantid -Credential $cred 

Get-AzureADDirectoryRole -ObjectId 19182b4e-77ae-49fe-9f99-cdfd9d449c21

Add-AzureADDirectoryRoleMember -ObjectId 19182b4e-77ae-49fe-9f99-cdfd9d449c21 -RefObjectId $userid

#check Power BI Workspace creation
$validatereport = Get-PowerBIReport -Name 'Wingtip Sales Analysis' -WorkspaceId $PBID

#validate all deployments and assignments for manual status agent
if($validatereport -ne $null)
{
    Write-Information "Validation Passed"
    
    $validstatus = "Successfull"
}
else {
    Write-Warning "Validation Failed - see log output"
    $validstatus = "Failed"
      }

Function SetDeploymentStatus($ManualStepStatus, $ManualStepMessage)
{

    (Get-Content -Path "C:\WindowsAzure\Logs\status-sample.txt") | ForEach-Object {$_ -Replace "ReplaceStatus", "$ManualStepStatus"} | Set-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt"
    (Get-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt") | ForEach-Object {$_ -Replace "ReplaceMessage", "$ManualStepMessage"} | Set-Content -Path "C:\WindowsAzure\Logs\validationstatus.txt"
}
 if ($validstatus -eq "Successfull") {
    $ValidStatus="Succeeded"
    $ValidMessage="Environment is validated and the deployment is successful"

Remove-Item 'C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt' -force
      }
else {
    Write-Warning "Validation Failed - see log output"
    $ValidStatus="Failed"
    $ValidMessage="Environment Validation Failed and the deployment is Failed"
      } 
 SetDeploymentStatus $ValidStatus $ValidMessage

#Start the cloudlabs agent service 
CloudlabsManualAgent Start     

sleep 5
Unregister-ScheduledTask -TaskName "logontask" -Confirm:$false 
Restart-Computer -Force 

sleep 5
Unregister-ScheduledTask -TaskName "logontask" -Confirm:$false 
Restart-Computer -Force 
