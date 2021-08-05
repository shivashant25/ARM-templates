{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminUsername": {
      "type": "String"
    },
    "adminPassword": {
      "type": "SecureString"
    },
    "AzureUserName": {
      "type": "string"
    },
    "AzurePassword": {
      "type": "securestring"
    },
    "ODLID": {
      "type": "string"
    },
    "DeploymentID": {
      "type": "string"
    },
    "azuserobjectid": {
      "type": "String",
      "metadata": {
        "description": "The Object Id associated with the account you used to sign into the Azure portal. Retrieve this using the Azure CLI and 'az ad signed-in-user show --query objectId -o tsv'."
      }
    },
    "InstallCloudLabsShadow": {
      "type": "string",
      "defaultValue": "yes",
      "allowedValues": [
        "yes",
        "no"
      ]
    },
    "trainerUserName": {
      "type": "string"
    },
    "trainerUserPassword": {
      "type": "string"
    }
  },
  "variables": {
    "cloudlabsCommon": "[concat(' -AzureUserName ', parameters('AzureUserName'), ' -AzurePassword ', parameters('AzurePassword'), ' -AzureTenantID ', variables('AzureTenantID'), ' -AzureSubscriptionID ', variables('AzureSubscriptionID'), ' -ODLID ', parameters('ODLID'), ' -DeploymentID ', parameters('DeploymentID'),' -azuserobjectid ', parameters('azuserobjectid'),' -InstallCloudLabsShadow ', parameters('InstallCloudLabsShadow'))]",
    "Enable-CloudLabsEmbeddedShadow": "[concat(' -vmAdminUsername ', parameters('adminUsername'), ' -trainerUserName ', parameters('trainerUserName'), ' -trainerUserPassword ', parameters('trainerUserPassword'))]",
    "AzureSubscriptionID": "[subscription().subscriptionId]",
    "AzureTenantID": "[subscription().tenantId]",
    "rgName": "[resourceGroup().name]",
    "addressPrefix": "10.0.0.0/16",
    "networkInterfaceName": "labvm-nic",
    "networkSecurityGroupName": "labvm-nsg",
    "publicIpAddressDNSName": "[concat('labvm-', uniqueString(resourceGroup().id))]",
    "publicIpAddressName": "[concat('labvm-pip', uniqueString(resourceGroup().id))]",
    "subnetName": "Subnet",
    "subnetPrefix": "10.0.0.0/24",
    "subnetRef": "[resourceId('Microsoft.Network/virtualNetworks/subnets/',variables('virtualNetworkName'), variables('subnetName'))]",
    "virtualMachineSize": "Standard_D2s_v3",
    "virtualNetworkName": "labvm-vnet",
    "vmName": "[concat('labvm-',parameters('DeploymentID'))]",
    "adlsStorageAccountName": "[concat('asadatalake', parameters('DeploymentID'))]",
    "location": "[resourceGroup().location]"
  },
  "resources": [
    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2017-04-01",
      "name": "[variables('virtualNetworkName')]",
      "location": "[variables('location')]",
      "properties": {
        "addressSpace": {
          "addressPrefixes": [
            "[variables('addressPrefix')]"
          ]
        },
        "subnets": [
          {
            "name": "[variables('subnetName')]",
            "properties": {
              "addressPrefix": "[variables('subnetPrefix')]"
            }
          }
        ]
      }
    },
    {
      "type": "Microsoft.Network/publicIpAddresses",
      "apiVersion": "2017-08-01",
      "name": "[variables('publicIpAddressName')]",
      "location": "[variables('location')]",
      "properties": {
        "publicIpAllocationMethod": "Dynamic",
        "dnsSettings": {
          "domainNameLabel": "[concat(variables('publicIpAddressDNSName'))]"
        }
      }
    },
    {
      "type": "Microsoft.Compute/virtualMachines",
      "apiVersion": "2017-03-30",
      "name": "[variables('vmName')]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[concat('Microsoft.Network/networkInterfaces/', variables('networkInterfaceName'))]"
      ],
      "properties": {
        "osProfile": {
          "computerName": "[variables('vmName')]",
          "adminUsername": "[parameters('adminUsername')]",
          "adminPassword": "[parameters('adminPassword')]",
          "windowsConfiguration": {
            "provisionVmAgent": "true"
          }
        },
        "hardwareProfile": {
          "vmSize": "[variables('virtualMachineSize')]"
        },
        "storageProfile": {
          "imageReference": {
            "publisher": "MicrosoftWindowsServer",
            "offer": "WindowsServer",
            "sku": "2019-Datacenter",
            "version": "latest"
          },
          "osDisk": {
            "createOption": "fromImage",
            "name": "[concat(variables('vmName'), '-osdisk')]",
            "managedDisk": {
              "storageAccountType": "Premium_LRS"
            }
          },
          "dataDisks": [

          ]
        },
        "networkProfile": {
          "networkInterfaces": [
            {
              "id": "[resourceId('Microsoft.Network/networkInterfaces', variables('networkInterfaceName'))]"
            }
          ]
        }
      },
      "resources": [
        {
          "type": "Microsoft.Compute/virtualMachines/extensions",
          "name": "[concat(variables('vmName'),'/', 'winExtension')]",
          "apiVersion": "2015-06-15",
          "location": "[resourceGroup().location]",
          "comments": "Script",
          "tags": {
            "displayName": "VM Extension"
          },
          "dependsOn": [
            "[concat('Microsoft.Compute/virtualMachines/', variables('vmName'))]"
          ],
          "properties": {
            "publisher": "Microsoft.Compute",
            "type": "CustomScriptExtension",
            "typeHandlerVersion": "1.8",
            "autoUpgradeMinorVersion": true,
            "settings": {
              "fileUris": [
                "https://experienceazure.blob.core.windows.net/templates/synapse-tech-immersion/instructor/psscript3.ps1",
                "https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/cloudlabs-windows-functions.ps1"
              ]
            },
            "protectedSettings": {
              "commandToExecute": "[concat('powershell.exe -ExecutionPolicy Unrestricted -File synapse-tech-immersion/instructor/psscript3.ps1', variables('cloudlabsCommon'),variables('Enable-CloudLabsEmbeddedShadow'))]"
            }
          }
        }
      ]
    },
    {
      "type": "Microsoft.Network/networkSecurityGroups",
      "apiVersion": "2017-06-01",
      "name": "[variables('networkSecurityGroupName')]",
      "location": "[variables('location')]",
      "properties": {
        "securityRules": [
          {
            "name": "default-allow-rdp",
            "properties": {
              "priority": 110,
              "protocol": "TCP",
              "access": "Allow",
              "direction": "Inbound",
              "sourceAddressPrefix": "*",
              "sourcePortRange": "*",
              "destinationAddressPrefix": "*",
              "destinationPortRange": "3389"
            }
          }
        ]
      }
    },
    {
      "type": "Microsoft.Network/networkInterfaces",
      "apiVersion": "2016-09-01",
      "name": "[variables('networkInterfaceName')]",
      "location": "[variables('location')]",
      "dependsOn": [
        "[concat('Microsoft.Network/virtualNetworks/', variables('virtualNetworkName'))]",
        "[concat('Microsoft.Network/publicIpAddresses/', variables('publicIpAddressName'))]",
        "[concat('Microsoft.Network/networkSecurityGroups/', variables('networkSecurityGroupName'))]"
      ],
      "properties": {
        "ipConfigurations": [
          {
            "name": "ipconfig1",
            "properties": {
              "subnet": {
                "id": "[variables('subnetRef')]"
              },
              "privateIPAllocationMethod": "Dynamic",
              "publicIpAddress": {
                "id": "[resourceId(resourceGroup().name,'Microsoft.Network/publicIpAddresses', variables('publicIpAddressName'))]"
              }
            }
          }
        ],
        "networkSecurityGroup": {
          "id": "[resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', variables('networkSecurityGroupName'))]"
        }
      }
    }
  ],
  "outputs": {
    "uniqueId": {
      "type": "String",
      "value": "[ parameters('DeploymentID')]"
    },
    "Storage Account Name": {
      "type": "String",
      "value": "[variables('adlsStorageAccountName')]"
    },
    "LABVM Admin Username": {
      "type": "String",
      "value": "[parameters('adminUsername')]"
    },
    "LABVM Admin Password": {
      "type": "String",
      "value": "[parameters('adminPassword')]"
    },
    "LABVM DNS Name": {
      "type": "String",
      "value": "[reference(resourceId('Microsoft.Network/publicIPAddresses',variables('publicIpAddressName'))).dnsSettings.fqdn]"
    }
  }
}
