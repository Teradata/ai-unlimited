targetScope = 'subscription'

@description('name for the resource group.')
param ResourceGroupName string = 'ai-unlimited-workspace'

@description('Name for the AI Unlimited service\'s virtual machine.')
param AiUnlimitedName string

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

@description('The AI Unlimited VM type')
param InstanceType string = 'Standard_D2s_v3'

@description('Name of the network to run the AI Unlimited service in')
param Network string

@description('Name of the subnet to run the AI Unlimited service in')
param Subnet string

@description('Name of the network security group')
param SecurityGroup string = 'AiUnlimitedSecurityGroup'

@description('The CIDR ranges that can be used to communicate with the AI Unlimited service instance.')
param AccessCIDRs array = [ '0.0.0.0/0' ]

@description('port to access the AI Unlimited service UI.')
param AiUnlimitedHttpPort string = '3000'

@description('port to access the AI Unlimited service api.')
param AiUnlimitedGrpcPort string = '3282'

@description('Source Application Security Groups to access the AI Unlimited service api.')
param SourceAppSecGroups array = []

@description('Destination Application Security Groups to give access to AI Unlimited service instance.')
param detinationAppSecGroups array = []

@description('GUID of the AI Unlimited Role')
param RoleDefinitionId string

@description('allow access the AI Unlimited ssh port from the access cidr.')
param AllowPublicSSH bool = true

@description('should we create a new Azure Key Vault for bootstrapping the AI Unlimited Engine nodes.')
@allowed([ 'New', 'None' ])
param UseKeyVault string = 'New'

@description('should we use a new or existing volume for persistent data on the AI Unlimited server.')
@allowed([ 'New', 'None', 'Existing' ])
param UsePersistentVolume string = 'New'

@description('size of the optional persistent disk to the AI Unlimited server.')
param PersistentVolumeSize int = 100

@description('Name of the existing persistent volume to attach. Must be in the same region and resourcegroup zone as the AI Unlimited server.')
param ExistingPersistentVolume string = 'NONE'

@description('Container Version of the AI Unlimited service')
param AiUnlimitedVersion string = 'latest'

@description('Use a Network Load Balancer to connect to the AI Unlimited server')
param UseNLB bool = false

@description('Tags to apply to all newly created resources, in the form of {"key_one":"value_one","key_two":"value_two"}')
param Tags object = {}

var roleAssignmentName = guid(subscription().id, AiUnlimitedName, rg.id, RoleDefinitionId)

var registry = 'teradata'
var workspaceRepository = 'ai-unlimited-workspaces'

var dnsLabelPrefix = 'td${uniqueString(rg.id, deployment().name, AiUnlimitedName)}'

var cloudInitData = base64(
  format(
    loadTextContent('../templates/ai-unlimited.cloudinit.yaml'),
    base64(
      format(
        loadTextContent('../templates/ai-unlimited.service'),
        registry,
        workspaceRepository,
        AiUnlimitedVersion,
        AiUnlimitedHttpPort,
        AiUnlimitedGrpcPort,
        subscription().subscriptionId,
        subscription().tenantId,
        '--network-alias ${UseNLB ? nlb.outputs.PublicDns : 'ai-unlimited'}'
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

module vault '../modules/vault.bicep' = if (UseKeyVault == 'New') {
  scope: rg
  name: 'vault'
  params: {
    encryptVolumes: true
    keyVaultName: AiUnlimitedName
    location: rg.location
    userClientId: aiUnlimited.outputs.PrincipleId
    tags: Tags
  }
}

module firewall '../modules/firewall.bicep' = {
  scope: rg
  name: 'firewall'
  params: {
    location: rg.location
    name: SecurityGroup
    accessCidrs: AccessCIDRs
    sshAccess: AllowPublicSSH
    aiUnlimitedHttpPort: AiUnlimitedHttpPort
    aiUnlimitedGrpcPort: AiUnlimitedGrpcPort
    sourceAppSecGroups: SourceAppSecGroups
    detinationAppSecGroups: detinationAppSecGroups
    tags: Tags
  }
}

module nlb '../modules/nlb.bicep' = if (UseNLB) {
  scope: rg
  name: 'loadbalancer'
  params: {
    name: AiUnlimitedName
    dnsPrefix: dnsLabelPrefix
    location: rg.location
    aiUnlimitedHttpPort: int(AiUnlimitedHttpPort)
    aiUnlimitedGrpcPort: int(AiUnlimitedGrpcPort)
    tags: Tags
  }
}

module aiUnlimited '../modules/instance.bicep' = {
  scope: rg
  name: 'ai-unlimited'
  params: {
    location: rg.location
    name: AiUnlimitedName
    adminUsername: 'azureuser'
    sshPublicKey: PublicKey
    dnsLabelPrefix: dnsLabelPrefix
    vmSize: InstanceType
    subnetId: subnet.id
    networkSecurityGroupID: firewall.outputs.Id
    osVersion: OSVersion
    cloudInitData: cloudInitData
    usePersistentVolume: UsePersistentVolume
    persistentVolumeSize: PersistentVolumeSize
    existingPersistentVolume: ExistingPersistentVolume
    nlbName: UseNLB ? AiUnlimitedName : ''
    nlbPoolNames: UseNLB ? nlb.outputs.nlbPools : []
    usePublicIp: !UseNLB
    tags: Tags
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: subscription()
  name: roleAssignmentName
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionId)
    principalId: aiUnlimited.outputs.PrincipleId
  }
}

output PublicIP string = UseNLB ? nlb.outputs.PublicIp : aiUnlimited.outputs.PublicIP
output PrivateIP string = aiUnlimited.outputs.PrivateIP
output AiUnlimitedPublicHttpAccess string = 'http://${UseNLB ? nlb.outputs.PublicDns : aiUnlimited.outputs.PublicIP}:${AiUnlimitedHttpPort}'
output AiUnlimitedPrivateHttpAccess string = 'http://${aiUnlimited.outputs.PrivateIP}:${AiUnlimitedHttpPort}'
output AiUnlimitedPublicGrpcAccess string = 'http://${UseNLB ? nlb.outputs.PublicDns : aiUnlimited.outputs.PublicIP}:${AiUnlimitedGrpcPort}'
output AiUnlimitedPrivateGrpcAccess string = 'http://${aiUnlimited.outputs.PrivateIP}:${AiUnlimitedGrpcPort}'
output sshCommand string = 'ssh azureuser@${UseNLB ? aiUnlimited.outputs.PrivateIP : aiUnlimited.outputs.PublicIP}'
output SecurityGroup string = firewall.outputs.Id
