targetScope = 'subscription'

@description('name for the resource group.')
param ResourceGroupName string = 'ai-unlimited-workspace'

@description('Name for the AI Unlimited service\'s virtual machine.')
param AiUnlimitedName string

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
param AccessCIDRs array = ['0.0.0.0/0']

@description('port to access the AI Unlimited auth service.')
param AiUnlimitedAuthPort int = 3000

@description('port to access the AI Unlimited service api.')
param AiUnlimitedGrpcPort int = 3282

// @description('port to access the AI Unlimited scheduler service grpc api.')
// var AiUnlimitedSchedulerGrpcPort = 50051

@description('port to access the AI Unlimited scheduler api.')
param AiUnlimitedSchedulerHttpPort int = 50061

// @description('port to access the AI Unlimited service UI http.')
var AiUnlimitedUIHttpPort = 80

// @description('port to access the AI Unlimited service UI https.')
var AiUnlimitedUIHttpsPort = 443

@description('Source Application Security Groups to access the AI Unlimited service api.')
param SourceAppSecGroups array = []

@description('Destination Application Security Groups to give access to AI Unlimited service instance.')
param detinationAppSecGroups array = []

@description('GUID of the AI Unlimited Role')
param RoleDefinitionId string

@description('should we create a new Azure Key Vault for bootstrapping the AI Unlimited Engine nodes.')
@allowed(['New', 'None'])
param UseKeyVault string = 'New'

@description('should we use a new or existing volume for persistent data on the AI Unlimited server.')
@allowed(['New', 'Existing'])
param UsePersistentVolume string = 'New'

@description('size of the optional persistent disk to the AI Unlimited server.')
param PersistentVolumeSize int = 100

@description('Name of the existing persistent volume to attach. Must be in the same region and resourcegroup zone as the AI Unlimited server.')
param ExistingPersistentVolume string = 'NONE'

@description('Container Version of the AI Unlimited service')
param AiUnlimitedVersion string = 'v0.3.7'

@description('Container Version of the AI Unlimited UI service')
param AiUnlimitedUIVersion string = 'v0.1.2'

@description('Container Version of the AI Unlimited scheduler service')
param AiUnlimitedSchedulerVersion string = 'v0.1.80'

@description('Tags to apply to all newly created resources, in the form of {"key_one":"value_one","key_two":"value_two"}')
param Tags object = {}

var roleAssignmentName = guid(subscription().id, AiUnlimitedName, rg.id, RoleDefinitionId)
var dnsId = uniqueString(rg.id, deployment().name, AiUnlimitedName)
var dnsLabelPrefix = 'td${dnsId}'
var nlbDnsLabelPrefix = 'td${dnsId}-nlb'

// below are static and are not expected to be changed
var registry = 'teradata'
var workspaceRepository = 'ai-unlimited-workspaces'
var workspaceSchedulerRepository = 'ai-unlimited-scheduler'
var workspaceUIRepository = 'ai-unlimited-workspaces-ui'

var cloudInitData = base64(format(
  loadTextContent('../../../scripts/ai-unlimited.cloudinit.yaml'),
  base64(format(
    loadTextContent('../../../scripts/ai-unlimited.service'),
    registry,
    workspaceRepository,
    AiUnlimitedVersion,
    AiUnlimitedAuthPort,
    AiUnlimitedGrpcPort,
    subscription().subscriptionId,
    subscription().tenantId,
    '--network-alias ${nlb.outputs.PublicDns}'
  )),
  base64(format(
    loadTextContent('../../../scripts/ai-unlimited-scheduler.service'),
    registry,
    workspaceSchedulerRepository,
    AiUnlimitedSchedulerVersion,
    AiUnlimitedSchedulerHttpPort,
    AiUnlimitedGrpcPort
  )),
  base64(format(
    loadTextContent('../../../scripts/ai-unlimited-ui.service'),
    registry,
    workspaceUIRepository,
    AiUnlimitedUIVersion,
    AiUnlimitedUIHttpPort,
    AiUnlimitedAuthPort,
    AiUnlimitedGrpcPort,
    '--network-alias ${nlb.outputs.PublicDns}'
  ))
))

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

module vault '../modules/vault/vault.bicep' = if (UseKeyVault == 'New') {
  scope: rg
  name: 'vault'
  params: {
    encryptVolumes: true
    keyVaultName: AiUnlimitedName
    location: rg.location
    tags: Tags
  }
}

module vaultAccessPolicy '../modules/vault/access-policy.bicep' = if (UseKeyVault == 'New') {
  scope: rg
  name: 'vault-access-policy'
  params: {
    vaultName: vault.outputs.name
    accessPolicy: {
      tenantId: subscription().tenantId
      objectId: aiUnlimited.outputs.PrincipleId
      permissions: {
        keys: [
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
        ]
        secrets: ['Get', 'Set', 'Delete', 'List', 'Purge']
        storage: ['Get']
      }
    }
  }
}

module firewall '../modules/firewall.bicep' = {
  scope: rg
  name: 'firewall'
  params: {
    location: rg.location
    name: SecurityGroup
    accessCidrs: AccessCIDRs
    aiUnlimitedAuthPort: AiUnlimitedAuthPort
    aiUnlimitedGrpcPort: AiUnlimitedGrpcPort
    aiUnlimitedSchedulerHttpPort: AiUnlimitedSchedulerHttpPort
    // aiUnlimitedSchedulerGrpcPort: AiUnlimitedSchedulerGrpcPort
    aiUnlimitedUIHttpPort: AiUnlimitedUIHttpPort
    aiUnlimitedUIHttpsPort: AiUnlimitedUIHttpsPort
    sourceAppSecGroups: SourceAppSecGroups
    detinationAppSecGroups: detinationAppSecGroups
    sshAccess: false
    tags: Tags
  }
}

module nlb '../modules/nlb.bicep' = {
  scope: rg
  name: 'loadbalancer'
  params: {
    name: AiUnlimitedName
    dnsPrefix: nlbDnsLabelPrefix
    location: rg.location
    aiUnlimitedAuthPort: AiUnlimitedAuthPort
    aiUnlimitedGrpcPort: AiUnlimitedGrpcPort
    aiUnlimitedSchedulerHttpPort: AiUnlimitedSchedulerHttpPort
    // aiUnlimitedSchedulerGrpcPort: AiUnlimitedSchedulerGrpcPort
    aiUnlimitedUIHttpPort: AiUnlimitedUIHttpPort
    aiUnlimitedUIHttpsPort: AiUnlimitedUIHttpsPort
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
    sshPublicKey: PublicKey.outputs.PublicKey
    dnsLabelPrefix: dnsLabelPrefix
    vmSize: InstanceType
    subnetId: subnet.id
    networkSecurityGroupID: firewall.outputs.Id
    osVersion: OSVersion
    cloudInitData: cloudInitData
    usePersistentVolume: UsePersistentVolume
    persistentVolumeSize: PersistentVolumeSize
    existingPersistentVolume: ExistingPersistentVolume
    nlbName: AiUnlimitedName
    nlbPoolNames: nlb.outputs.nlbPools
    usePublicIp: false
    tags: Tags
  }
}

module PublicKey '../modules/public-key.bicep' = {
  scope: rg
  name: 'Public-Key'
  params: {
    Name: AiUnlimitedName
    Location: deployment().location
    VaultName: vault.outputs.name
    RoleID: RoleDefinitionId
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

output PublicIP string = nlb.outputs.PublicIp
output PrivateIP string = aiUnlimited.outputs.PrivateIP
output AiUnlimitedPublicHttpAccess string = concat(
  'http://${nlb.outputs.PublicDns}',
  (AiUnlimitedUIHttpPort != 80 ? concat(':', string(AiUnlimitedUIHttpPort)) : '')
)
output AiUnlimitedPrivateHttpAccess string = concat(
  'http://${aiUnlimited.outputs.PrivateIP}',
  (AiUnlimitedUIHttpPort != 80 ? concat(':', string(AiUnlimitedUIHttpPort)) : '')
)
output AiUnlimitedPublicGrpcAccess string = 'http://${nlb.outputs.PublicDns}:${AiUnlimitedGrpcPort}'
output AiUnlimitedPrivateGrpcAccess string = 'http://${aiUnlimited.outputs.PrivateIP}:${AiUnlimitedGrpcPort}'
output KeyVaultName string = (UseKeyVault == 'New') ? vault.outputs.name : ''
output NetworkSecurityGroupId string = firewall.outputs.Id
