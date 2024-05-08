param name string
param tags object
param vaultName string
param value string

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${vaultName}/${name}'
  properties: {
    value: value
  }
  tags:tags
}

output id string = secret.id
output secretUri string = secret.properties.secretUri
