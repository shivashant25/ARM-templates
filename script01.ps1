Param (
    [Parameter(Mandatory = $true)]
    [string]
    $adminUsername,
 
    [string]
    $adminPassword,
 
    [string]
    $tenantID,
 
    [string]
    $subscriptionID,
 
    [string]
    $DID,

 

     [string]
    $azureUsername,
 
    [string]
    $azurePassword
    
   
)

 

Start-Transcript -Path C:\WindowsAzure\Logs\CustomscriptLogs.txt -Append

 

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

 


#Import Common Functions
$path = pwd
$path=$path.Path
$commonscriptpath = "$path" + "\cloudlabs-common\cloudlabs-windows-functions.ps1"
. $commonscriptpath

 

# Run Imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon

 


InstallAzPowerShellModule

 

$userName = $AzureUserName
$password = $AzurePassword
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
 
Connect-AzAccount -Credential $cred | Out-Null
$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*hands-on-lab-RG-*" }).ResourceGroupName
$deploymentId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]

 

#template deployment
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateUri "https://raw.githubusercontent.com/Shivashant25/ARM-templates/main/synapse.json" `
  -deploymentId $DID

 

 


New-Item -Path C:\CosmosMCW -ItemType directory
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://github.com/Microsoft/MCW-Cosmos-DB-Real-Time-Advanced-Analytics/archive/master.zip","C:\CosmosMCW\MCW-Cosmos-DB-Real-Time-Advanced-Analytics-master.zip")
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
Expand-ZIPFile -File "C:\CosmosMCW\MCW-Cosmos-DB-Real-Time-Advanced-Analytics-master.zip" -Destination "C:\CosmosMCW\"

 

#Download and Install PowerBi Desktop
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup_x64.exe","C:\Packages\PBIDesktop_x64.exe")
Start-Process -FilePath "C:\Packages\PBIDesktop_x64.exe" -ArgumentList '-quiet','ACCEPT_EULA=1'