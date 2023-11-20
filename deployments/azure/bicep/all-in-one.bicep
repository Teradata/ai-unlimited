targetScope = 'subscription'

@description('name for the resource group.')
param ResourceGroupName string = 'ai-unlimited-workspace'

@description('Name for the Workspace service\'s virtual machine.')
param WorkspacesName string

@description('SSH public key value')
@secure()
param PublicKey string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param OSVersion string = 'Ubuntu-2004'

@description('The Workspace VM type')
param InstanceType string = 'Standard_D2s_v3'

@description('Name of the network to run the Workspace service in')
param Network string

@description('Name of the subnet to run the Workspace service in')
param Subnet string

@description('Name of the network security group')
param SecurityGroup string = 'WorkspacesSecurityGroup'

@description('The CIDR ranges that can be used to communicate with the Workspace service instance.')
param AccessCIDRs array = [ '0.0.0.0/0' ]

@description('port to access the Jupyter Labs UI.')
param JupyterHttpPort string = '8888'

@description('port to access the workspaces service UI.')
param WorkspacesHttpPort string = '3000'

@description('port to access the workspaces service api.')
param WorkspacesGrpcPort string = '3282'

@description('Source Application Security Groups to access the workspaces service api.')
param SourceAppSecGroups array = []

@description('Destination Application Security Groups to give access to workspaces service instance.')
param detinationAppSecGroups array = []

@description('GUID of the Workspaces Role')
param RoleDefinitionId string

@description('allow access the workspaces ssh port from the access cidr.')
param AllowPublicSSH bool = true

@description('should we use a new or existing volume for persistent data on the workspace server.')
@allowed([ 'New', 'None', 'Existing' ])
param UsePersistentVolume string = 'New'

@description('size of the optional persistent disk to the workspace server.')
param PersistentVolumeSize int = 100

@description('Name of the existing persistent volume to attach. Must be in the same region and resourcegroup zone as the workspaces server.')
param ExistingPersistentVolume string = 'NONE'

@description('Container Version of the Workspace service')
param WorkspacesVersion string = 'latest'

@description('Container Version of the Jupyter Labs service')
param JupyterVersion string = 'latest'

@description('Join token for the Jupyter Labs service')
param JupyterToken string = uniqueString(subscription().id, utcNow())

var roleAssignmentName = guid(subscription().id, WorkspacesName, rg.id, RoleDefinitionId)

var registry = 'teradata'
var workspaceRepository = 'ai-unlimited-workspaces'
var jupyterRepository = 'ai-unlimited-jupyter'

var cloudInitData = base64(
  format(
    loadTextContent('../templates/all-in-one.cloudinit.yaml'),
    base64(
      format(
        loadTextContent('../templates/workspaces.service'),
        registry,
        workspaceRepository,
        WorkspacesVersion,
        WorkspacesHttpPort,
        WorkspacesGrpcPort,
        subscription().subscriptionId,
        subscription().tenantId
      )
    ),
    base64(
      format(
        loadTextContent('../templates/jupyter.service'),
        registry,
        jupyterRepository,
        JupyterVersion,
        JupyterHttpPort,
        JupyterToken
      )
    )
  )
)

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: ResourceGroupName
}

resource network 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  scope: rg
  name: Network
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  parent: network
  name: Subnet
}

module firewall '../modules/firewall.bicep' = {
  scope: rg
  name: 'firewall'
  params: {
    location: rg.location
    name: SecurityGroup
    accessCidrs: AccessCIDRs
    sshAccess: AllowPublicSSH
    workspacesHttpPort: WorkspacesHttpPort
    workspacesGrpcPort: WorkspacesGrpcPort
    jupyterHttpPort: JupyterHttpPort
    sourceAppSecGroups: SourceAppSecGroups
    detinationAppSecGroups: detinationAppSecGroups
  }
}

module workspaces '../modules/instance.bicep' = {
  scope: rg
  name: 'workspaces'
  params: {
    location: rg.location
    name: WorkspacesName
    adminUsername: 'azureuser'
    sshPublicKey: PublicKey
    dnsLabelPrefix: uniqueString(rg.id, deployment().name, WorkspacesName)
    vmSize: InstanceType
    subnetId: subnet.id
    networkSecurityGroupID: firewall.outputs.Id
    osVersion: OSVersion
    cloudInitData: cloudInitData
    usePersistentVolume: UsePersistentVolume
    persistentVolumeSize: PersistentVolumeSize
    existingPersistentVolume: ExistingPersistentVolume
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: subscription()
  name: roleAssignmentName
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
    principalId: workspaces.outputs.PrincipleId
  }
}

output PublicIP string = workspaces.outputs.PublicIP
output PrivateIP string = workspaces.outputs.PrivateIP
output WorkspacesPublicHttpAccess string = 'http://${workspaces.outputs.PublicIP}:${WorkspacesHttpPort}'
output WorkspacesPrivateHttpAccess string = 'http://${workspaces.outputs.PrivateIP}:${WorkspacesHttpPort}'
output WorkspacesPublicGrpcAccess string = 'http://${workspaces.outputs.PublicIP}:${WorkspacesGrpcPort}'
output WorkspacesPrivateGrpcAccess string = 'http://${workspaces.outputs.PrivateIP}:${WorkspacesGrpcPort}'
output JupyterLabPublicHttpAccess string = 'http://${workspaces.outputs.PublicIP}:${JupyterHttpPort}?token=${JupyterToken}'
output JupyterLabPrivateHttpAccess string = 'http://${workspaces.outputs.PrivateIP}:${JupyterHttpPort}?token=${JupyterToken}'
output sshCommand string = 'ssh azureuser@${workspaces.outputs.PublicIP}'
output SecurityGroup string = firewall.outputs.Id
