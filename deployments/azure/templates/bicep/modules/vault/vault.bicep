param encryptVolumes bool
param keyVaultName string
param location string
param tags object = {}
param uuid string = newGuid()

var nameCharLimit = 24
var uniqueName = '${keyVaultName}-${uniqueString(uuid)}'
var uniqueKeyVaultName = substring(
  '${uniqueName}',
  0,
  length(uniqueName) < nameCharLimit ? length(uniqueName) : nameCharLimit
)


resource vault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  location: location
  name: uniqueKeyVaultName
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

