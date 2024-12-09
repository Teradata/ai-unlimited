param Location string
param Name string
param VaultName string
param RoleID string
param Uuid string = newGuid()

var SecretName = format('{0}-PrivateKey', Name)
var ScriptName = format('{0}-createKeys', Name)
var IdentityName = format('{0}-scratch', Name)
var RoleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', RoleID)
var RoleDefinitionName = guid(Identity.id, RoleDefinitionId, resourceGroup().id)

resource Identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: IdentityName
  location: Location
}

resource RoleDefinition 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: RoleDefinitionName
  properties: {
    roleDefinitionId: RoleDefinitionId
    principalId: Identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource Script 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: ScriptName
  location: Location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${Identity.id}': {}
    }
  }
  kind: 'AzureCLI'
  properties: {
    forceUpdateTag: Uuid
    azCliVersion: '2.0.80'
    timeout: 'PT30M'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    scriptContent: '''
      #/bin/bash -e

      echo -e 'y' | ssh-keygen -f scratch

      privateKey=$(cat scratch)
      publicKey=$(cat 'scratch.pub')

      json="{\"keyinfo\":{\"privateKey\":\"$privateKey\",\"publicKey\":\"$publicKey\"}}"

      echo "$json" > $AZ_SCRIPTS_OUTPUT_PATH
    '''
    // primaryScriptUri: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.resources/deployment-script-ssh-key-gen/new-key.sh'
  }
  dependsOn: [
    RoleDefinition
  ]
}

resource SshKeyecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${VaultName}/${SecretName}'
  properties: {
    value: Script.properties.outputs.keyinfo.privateKey
  }
}

output PublicKey string = Script.properties.outputs.keyinfo.publicKey
output Status object = Script.properties.status
