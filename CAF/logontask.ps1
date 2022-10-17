Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsLogOnTask.txt -Append

. C:\LabFiles\AzureCreds.ps1

$userName = $AzureUserName
$password = $AzurePassword

az login --username "$userName" --password "$password"


refreshenv
sleep 2
az rest --method post --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"

sleep 10
az logout

sleep 5
az login --username "$userName" --password "$password"

refreshenv
az role assignment create  --scope '/' --role 'owner' --assignee $userName 



function validateroleassignment{
                       
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
Connect-AzAccount -Credential $cred | Out-Null
$roles = Get-AzRoleAssignment -SignInName  $userName    -Scope '/'
$roles1 = $roles[1]
$rolename = $roles1.RoleDefinitionName
$rolescope = $roles1.Scope

if( "$rolename -eq 'Owner' -and $rolescope -eq '/' " -or "$rolename2 -eq 'Owner' -and $rolescope2 -eq "/" "-or "$rolename3 -eq 'Owner' -and $rolescope3 -eq "/" ")

{
Write-Output "Owner role is already available"

$break

}
else{
Write-Output "adding the role assignment"
az role assignment create  --scope '/' --role 'owner' --assignee $userName 

Start-Sleep 50

Write-Output "refreshing the azure creds"

Disconnect-AzAccount
Write-Output "calling the function again to get the latest role assignments"

 validateroleassignment

}

}
validateroleassignment

Disconnect-AzAccount

#Enable Autologon
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\demouser" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "Password.1!!" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord

$FileDir ="C:\LabFiles"

# Scheduled Task
$Trigger= New-ScheduledTaskTrigger -AtLogOn
$User= "$($env:ComputerName)\demouser" 
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe" -Argument "-executionPolicy Unrestricted -File $FileDir\deploybicep.ps1"
Register-ScheduledTask -TaskName "Setup1" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force 


Disconnect-AzAccount

#sleep 600

#. C:\LabFiles\AzureCreds.ps1

#$userName = $AzureUserName
#$password = $AzurePassword

#az login --username "$userName" --password "$password"

#az role assignment create  --scope '/' --role 'owner' --assignee $AzureUserName 

#Import Common Functions
#$commonscriptpath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.12\Downloads\0\cloudlabs-common\cloudlabs-windows-functions.ps1"
#. $commonscriptpath

#$status = (Get-AzRoleAssignment -Scope '/' -RoleDefinitionName "Owner"-SignInName $AzureUserName)
#$status
#if ($status -ne $null)
#{
 
#    $Validstatus="Succeeded"  ##Failed or Successful at the last step
#   $Validmessage="Role assignment succeeded"



#}
#else {
#    Write-Warning "Validation Failed - see log output"
 #   $Validstatus="Failed"  ##Failed or Successful at the last step
#    $Validmessage="Owner role assignment for object id failed"
      #}


#CloudlabsManualAgent setStatus

sleep 5
Unregister-ScheduledTask -TaskName "Setup" -Confirm:$false
