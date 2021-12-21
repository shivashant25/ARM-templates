#!/bin/bash

function replace_json_field {
    tmpfile=/tmp/tmp.json
    cp $1 $tmpfile
    jq "$2 |= \"$3\"" $tmpfile > $1
    rm "$tmpfile"
}

AZURE_CREDENTIALS={ "clientId": "1c9046b8-1de8-423d-8c4e-ac3d2307e2c5", "clientSecret": "ebye41PTL*CT", "subscriptionId": "04b1e231-3aa7-49b7-9ff2-41a9eef7a1da", "tenantId": "338cad0a-9226-41c6-a09d-748ec1a0b210", "activeDirectoryEndpointUrl": "https://login.microsoftonline.com", "resourceManagerEndpointUrl": "https://management.azure.com/", "activeDirectoryGraphResourceId": "https://graph.windows.net/", "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/", "galleryEndpointUrl": "https://gallery.azure.com/", "managementEndpointUrl": "https://management.core.windows.net/" }

# Check if SUFFIX envvar existsebye41PTL*CT
if [[ -z "${MCW_SUFFIX}" ]]; then
    echo "Please set the MCW_SUFFIX environment variable to a unique three character string."
    exit 1
fi

if [[ -z "${MCW_GITHUB_USERNAME}" ]]; then
    echo "Please set the MCW_GITHUB_USERNAME environment variable to your Github Username"
    exit 1
fi

if [[ -z "${MCW_GITHUB_TOKEN}" ]]; then
    echo "Please set the MCW_GITHUB_TOKEN environment variable to your Github Token"
    exit 1
fi

if [[ -z "${MCW_GITHUB_URL}" ]]; then
    MCW_GITHUB_URL=https://$MCW_GITHUB_USERNAME:$MCW_GITHUB_TOKEN@github.com/$MCW_GITHUB_USERNAME/Fabmedical.git
fi

git config --global user.email "$MCW_GITHUB_EMAIL"
git config --global user.name "$MCW_GITHUB_USERNAME"

cp -R ~/MCW-Cloud-native-applications/Hands-on\ lab/lab-files/developer ~/Fabmedical
cd ~/Fabmedical
git init
git add .
git commit -m "Initial Commit"
git remote add origin $MCW_GITHUB_URL

git config --global --unset credential.helper
git config --global credential.helper store

# Configuring github workflows
cd ~/Fabmedical
sed -i "s/\[SUFFIX\]/$MCW_SUFFIX/g" ~/Fabmedical/.github/workflows/content-init.yml
sed -i "s/\[SUFFIX\]/$MCW_SUFFIX/g" ~/Fabmedical/.github/workflows/content-api.yml
sed -i "s/\[SUFFIX\]/$MCW_SUFFIX/g" ~/Fabmedical/.github/workflows/content-web.yml

ACR_CREDENTIALS=$(az acr credential show -n fabmedical$MCW_SUFFIX)
ACR_USERNAME=$(jq -r -n '$input.username' --argjson input "$ACR_CREDENTIALS")
ACR_PASSWORD=$(jq -r -n '$input.passwords[0].value' --argjson input "$ACR_CREDENTIALS")

GITHUB_TOKEN=$MCW_GITHUB_TOKEN
cd ~/Fabmedical
echo $GITHUB_TOKEN | gh auth login --with-token
gh secret set ACR_USERNAME -b "$ACR_USERNAME"
gh secret set ACR_PASSWORD -b "$ACR_PASSWORD"
gh secret set AZURE_CREDENTIALS -b "$AZURE_CREDENTIALS"

# Committing repository
cd ~/Fabmedical
git branch -m master main
git push -u origin main
