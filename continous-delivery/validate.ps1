$app = Get-Item -Path 'C:\Program Files\Docker\Docker\Docker Desktop.exe' 

$clonefiles = Get-Item -Path 'C:\Workspaces\lab\mcw-continuous-delivery-lab-files'

if(($app -ne $null) -and ($clonefiles -ne $null))
{
    Write-Output "succeeded"
    $Validstatus = 'Successfull'

}
else {
    Write-Warning "Validation Failed - see log output"
    $Validstatus="Failed"  ##Failed or Successful at the last step
    $Validmessage="PS script execution failed"
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
