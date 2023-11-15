targetScope = 'subscription'

@description('name for the resource group.')
param resourceGroupName string = 'workspaces'

@description('Name for the workspaces service virtual machine.')
param workspacesName string

@description('SSH public key value')
@secure()
param sshPublicKey string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('Name of the subnet to run Workspaces in')
param  networkName string

@description('Name of the subnet to run Workspaces in')
param subnetName string

@description('Name of the Network Security Group')
param networkSecurityGroupName string = 'WorkspacesSecurityGroup'

@description('The CIDR ranges that can be used to communicate with the workspaces instance.')
param accessCidrs array = ['0.0.0.0/0']

@description('port to access the workspaces service UI.')
param httpPort string = '3000'

@description('port to access the workspaces service api.')
param grpcPort string = '3282'

@description('GUID of the Workspaces Role')
param roleDefinitionId string

@description('allow access the workspaces ssh port from the access cidr.')
param sshAccess bool = true

var roleAssignmentName = guid(subscription().id, workspacesName, rg.id , roleDefinitionId)

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: resourceGroupName
}

resource network 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  scope: rg
  name: networkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  parent: network
  name: subnetName
}

module firewall 'modules/firewall.bicep' = {
  scope: rg
  name: 'firewall'
  params: {
    location: rg.location
    name: networkSecurityGroupName
    accessCidrs: accessCidrs
    sshAccess: sshAccess
    httpPort: httpPort
    grpcPort: grpcPort
  }
}

module workspaces 'modules/instance.bicep' = {
  scope: rg
  name: 'workspaces'
  params: {
    location: rg.location
    name: workspacesName
    adminUsername: 'azureuser'
    sshPublicKey: sshPublicKey
    dnsLabelPrefix: uniqueString(rg.id, deployment().name, workspacesName)
    vmSize: vmSize
    subnetId: subnet.id
    networkSecurityGroupID: firewall.outputs.Id
    httpPort: httpPort
    grpcPort: grpcPort
    ubuntuOSVersion: ubuntuOSVersion
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: subscription()
  name: roleAssignmentName
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: workspaces.outputs.PrincipleId
  }
}

output PublicIP string = workspaces.outputs.PublicIP
output PrivateIP string = workspaces.outputs.PrivateIP
output PublicHttpAccess string = 'http://${ workspaces.outputs.PublicIP }:${ httpPort }'
output PrivateHttpAccess string = 'http://${ workspaces.outputs.PrivateIP }:${ httpPort }'
output PublicGrpcAccess string = 'http://${ workspaces.outputs.PublicIP }:${ grpcPort }'
output PrivateGrpcAccess string = 'http://${ workspaces.outputs.PrivateIP }:${ grpcPort }'
output SecurityGroup string = firewall.outputs.Id
output sshCommand string = 'ssh azureuser@${workspaces.outputs.PublicIP}'
