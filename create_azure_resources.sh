#!/bin/bash

function replace_json_field {
    tmpfile=/tmp/tmp.json
    cp $1 $tmpfile
    jq "$2 |= \"$3\"" $tmpfile > $1
    rm "$tmpfile"
}

AZURE_CREDENTIALS={ "clientId": "943abbae-8858-4aae-b132-93efa094dd72", "clientSecret": "Spg32RMDOi66yQSyOIet4Bcrmv6Xx.1dT1", "subscriptionId": "a5932f36-63c8-4bc7-b97a-f90a2900b8a1", "tenantId": "495d5cd4-4a6c-4d4e-bdaa-5e1f96a097aa", "activeDirectoryEndpointUrl": "https://login.microsoftonline.com", "resourceManagerEndpointUrl": "https://management.azure.com/", "activeDirectoryGraphResourceId": "https://graph.windows.net/", "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/", "galleryEndpointUrl": "https://gallery.azure.com/", "managementEndpointUrl": "https://management.core.windows.net/" }

# Check if SUFFIX envvar exists
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
