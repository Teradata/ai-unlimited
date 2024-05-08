param encryptVolumes bool
param keyVaultName string
param location string
param tags object = {}

resource vault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  location: location
  name: keyVaultName
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    softDeleteRetentionInDays: 7
    enableSoftDelete: true
    enablePurgeProtection: encryptVolumes ? true : null
    enabledForDiskEncryption: encryptVolumes
    accessPolicies: []
  }
}

output id string = vault.id
output name string = vault.name

