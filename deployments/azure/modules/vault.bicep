param encryptVolumes bool
param keyVaultName string
param location string
@secure()
param userClientId string

resource vault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  location: location
  name: keyVaultName
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
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: userClientId
        permissions: {
          keys: encryptVolumes ? [
            'Create'
            'Delete'
            'Get'
            'List'
            'Update'
            'Purge'
            'Recover'
            'Decrypt'
            'Encrypt'
            'Sign'
            'UnwrapKey'
            'Verify'
            'WrapKey'
            'GetRotationPolicy'
            'SetRotationPolicy'
          ] : [
            'Get'
            'List'
          ]
          secrets: [
            'Get'
            'Set'
            'Delete'
            'List'
            'Purge'
          ]
          storage: [
            'Get'
          ]
        }
      }
    ]
  }
}

output id string = vault.id
output name string = vault.name
