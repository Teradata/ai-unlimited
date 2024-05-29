targetScope = 'subscription'

@description('name for the resource group, role and derived network and subnet names.')
param name string = 'ai-unlimited'

@description('New network CIDR.')
param networkCidr array = [ '10.0.0.0/16' ]

@description('New subnet CIDR.')
param subnetCidr string = '10.0.0.0/24'

@description('Application Load Balancer subnet CIDR.')
param albSubnetCidr string = '10.0.1.0/24'

@description('deploy ALB components')
param deployALBComponents bool = false

@description('Tags to apply to all newly created resources, in the form of {"key_one":"value_one","key_two":"value_two"}')
param Tags object = {}

var location = deployment().location

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
  tags: Tags
}

module network 'network.bicep' = {
  scope: rg
  name: 'networkDeployment'
  params: {
    networkName: name
    networkCidr: networkCidr
    subnetCidr: subnetCidr
    location: location
    albSubnetCidr: albSubnetCidr
    deployAlbSubnet: deployALBComponents
    tags: Tags
  }
}

resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, rg.id)
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
        ]
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

output RoleDefinitionId string = roleDef.name
output NetworkName string = network.outputs.networkName
output SubnetName string = network.outputs.subnetName
output ALBSubnetName string = deployALBComponents ? network.outputs.subnetName : '' 
