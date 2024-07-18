targetScope = 'subscription'

@description('name for the role to create for use with the AI Unlimited instance.')
param name string = 'ai-unlimited-deployment-role'

resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(name, subscription().id)
  properties: {
    roleName: 'Custom Role - AI Unlimited ${name} Deployment Permissions'
    description: 'Subscription level permissions for AI Unlimited to create ai-unlimited deployments in there own resource groups'
    type: 'customRole'
    permissions: [
      {
        actions: [
          'Microsoft.Compute/disks/read'
          'Microsoft.Compute/disks/write'
          'Microsoft.Compute/disks/delete'
          'Microsoft.Compute/sshPublicKeys/read'
          'Microsoft.Compute/sshPublicKeys/write'
          'Microsoft.Compute/sshPublicKeys/delete'
          'Microsoft.Compute/virtualMachines/read'
          'Microsoft.Compute/virtualMachines/write'
          'Microsoft.Compute/virtualMachines/delete'
          'Microsoft.KeyVault/vaults/read'
          'Microsoft.KeyVault/vaults/write'
          'Microsoft.KeyVault/vaults/delete'
          'Microsoft.KeyVault/vaults/accessPolicies/write'
          'Microsoft.KeyVault/locations/operationResults/read'
          'Microsoft.KeyVault/locations/deletedVaults/purge/action'
          'Microsoft.ManagedIdentity/userAssignedIdentities/delete'
          'Microsoft.ManagedIdentity/userAssignedIdentities/assign/action'
          'Microsoft.ManagedIdentity/userAssignedIdentities/listAssociatedResources/action'
          'Microsoft.ManagedIdentity/userAssignedIdentities/read'
          'Microsoft.ManagedIdentity/userAssignedIdentities/write'
          'Microsoft.Network/applicationSecurityGroups/read'
          'Microsoft.Network/applicationSecurityGroups/write'
          'Microsoft.Network/applicationSecurityGroups/joinIpConfiguration/action'
          'Microsoft.Network/applicationSecurityGroups/delete'
          'Microsoft.Network/virtualNetworks/read'
          'Microsoft.Network/virtualNetworks/write'
          'Microsoft.Network/virtualNetworks/delete'
          'Microsoft.Network/virtualNetworks/subnets/read'
          'Microsoft.Network/virtualNetworks/subnets/write'
          'Microsoft.Network/virtualNetworks/subnets/delete'
          'Microsoft.Network/virtualNetworks/subnets/join/action'
          'Microsoft.Network/networkInterfaces/read'
          'Microsoft.Network/networkInterfaces/write'
          'Microsoft.Network/networkInterfaces/delete'
          'Microsoft.Network/networkInterfaces/join/action'
          'Microsoft.Network/networkSecurityGroups/read'
          'Microsoft.Network/networkSecurityGroups/write'
          'Microsoft.Network/networkSecurityGroups/delete'
          'Microsoft.Network/networkSecurityGroups/securityRules/read'
          'Microsoft.Network/networkSecurityGroups/securityRules/write'
          'Microsoft.Network/networkSecurityGroups/securityRules/delete'
          'Microsoft.Network/networkSecurityGroups/join/action'
          'Microsoft.Network/publicIPAddresses/read'
          'Microsoft.Network/publicIPAddresses/write'
          'Microsoft.Network/publicIPAddresses/join/action'
          'Microsoft.Network/publicIPAddresses/delete'
          'Microsoft.Resources/subscriptions/resourcegroups/read'
          'Microsoft.Resources/subscriptions/resourcegroups/write'
          'Microsoft.Resources/subscriptions/resourcegroups/delete'
          'Microsoft.Resources/deployments/read'
          'Microsoft.Resources/deployments/write'
          'Microsoft.Resources/deployments/delete'
          'Microsoft.Resources/deployments/operationStatuses/read'
          'Microsoft.Resources/deploymentStacks/read'
          'Microsoft.Resources/deploymentStacks/write'
          'Microsoft.Resources/deploymentStacks/delete'
          'Microsoft.Compute/galleries/images/versions/read'
        ]
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

output RoleDefinitionId string = roleDef.name
