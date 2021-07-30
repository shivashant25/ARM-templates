Create Azure DevOps Personal Access Token

1. Log in to https://dev.azure.com/ using the Azure credentials provided in the Environment details tab.

   ![](https://github.com/CloudLabsAI-Azure/AIW-DevOps/blob/dev/Assets/azure-creds-new.png?raw=true)
   
1. If you see the pop-up Get Started with Azure Devops, Check the Privacy Statement box and click continue.
1. Go to home page in Azure DevOps.
1. **Select** the existing project named **aiw-devops**.

   ![](https://github.com/Shivashant25/AIW-DevOps/blob/main/Assets/p1.png?raw=true)
   
   >NOTE: DO NOT CREATE NEW PROJECT USING USER ACCOUNT.
   
1. **Select** CodeToCloudWorkshop-{Suffix}.
    
   ![](https://github.com/Shivashant25/AIW-DevOps/blob/main/Assets/p2.png?raw=true)
  
1. Go to User settings and then select Personal Access Tokens.
  
   ![](https://raw.githubusercontent.com/CloudLabsAI-Azure/AIW-DevOps/main/Assets/azuredevops-pat.png)

1. Click on **+ New Token**
   
   ![](https://raw.githubusercontent.com/CloudLabsAI-Azure/AIW-DevOps/main/Assets/azuredevops-newtoken.png)
  
1. In the Create a new personal access token page enter the following details:
  
   - **Name**: Enter {suffix}-Token
   - **Work Items**: Select Read & Write
   - **Build: Select**: Read & Execute
   - **Project & Team**: Select Read, Write & Manage ( To view Project & Team, click on Show all scopes just above Create button )
   
   ![](https://raw.githubusercontent.com/CloudLabsAI-Azure/AIW-DevOps/main/Assets/azuredevops-createtoken.png)
   
1. Copy the value of the generated token and save it in the notepad where you have stored the GitHub Personal Access Token.

   ![](https://raw.githubusercontent.com/CloudLabsAI-Azure/AIW-DevOps/main/Assets/azuredevops-copypat.png)
   
1. Keep this Personal Access token safe for later use. **DO NOT COMMIT THIS TO YOUR REPO!**.
  
