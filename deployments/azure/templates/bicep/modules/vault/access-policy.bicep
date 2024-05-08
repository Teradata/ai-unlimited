param vaultName string
param accessPolicy object

resource kvAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: '${vaultName}/add'
  properties: {
    accessPolicies: [accessPolicy]
  }
}
