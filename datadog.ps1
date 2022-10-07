Set-ExecutionPolicy -ExecutionPolicy bypass -Force
Start-Transcript -Path C:\WindowsAzure\Logs\logontasklogs.txt -Append

$PSVersionTable.PSVersion
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install git
choco install bicep
bicep

refreshenv

mkdir C:\BicepTemplates
cd C:\BicepTemplates
git clone --branch xxx-DatadogOnAzure "https://github.com/sumitmalik51/WhatTheHack.git"

cd WhatTheHack
cd 059-DatadogOnAzure
cd Student
cd Resources   
cd Challenge-00

$userName = "odl_user_759239@cloudevents.ai"
$password = "jtdr49AKG*B8"
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

cd "C:\Users\admin\Downloads\WhatTheHack-xxx-DatadogOnAzure\WhatTheHack-xxx-DatadogOnAzure\059-DatadogOnAzure\Student\Resources\Challenge-00"

$template= "C:\Users\admin\Downloads\WhatTheHack-xxx-DatadogOnAzure\WhatTheHack-xxx-DatadogOnAzure\059-DatadogOnAzure\Student\Resources\Challenge-00"


New-AzDeployment -TemplateFile "$template\main.bicep" -Location centralus -Verbose 
