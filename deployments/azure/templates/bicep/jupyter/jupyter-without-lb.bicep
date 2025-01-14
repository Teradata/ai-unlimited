targetScope = 'subscription'

@description('name for the resource group.')
param ResourceGroupName string = 'ai-unlimited-jupyter'

@description('Name for the Jupyter Labs service\'s virtual machine.')
param JupyterName string

@description('GUID of the AI Unlimited Role')
param RoleDefinitionId string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param OSVersion string = 'Ubuntu-2004'

@description('The Jupyter Labs VM type')
param InstanceType string = 'Standard_D2s_v3'

@description('Name of the network to run the Jupyter Labs service in')
param Network string

@description('Name of the subnet to run the Jupyter Labs service in')
param Subnet string

@description('Name of the network security group')
param SecurityGroup string = 'JupyterSecurityGroup'

@description('The CIDR ranges that can be used to communicate with the Jupyter Labs service instance.')
param AccessCIDRs array = ['0.0.0.0/0']

@description('port to access the Jupyter Labs UI.')
param JupyterHttpPort int = 8888

@description('Source Application Security Groups to access the Jupyter Labs service api.')
param SourceAppSecGroups array = []

@description('Destination Application Security Groups to give access to Jupyter Labs service instance.')
param detinationAppSecGroups array = []

@description('should we use a new or existing volume for persistent data on the Jupyter server.')
@allowed(['New', 'Existing'])
param UsePersistentVolume string = 'New'

@description('size of the optional persistent disk to the Jpuyter server.')
param PersistentVolumeSize int = 100

@description('Name of the existing persistent volume to attach. Must be in the same region and resourcegroup zone as the Jupyter Labs server.')
param ExistingPersistentVolume string = 'NONE'

@description('Container Version of the Jupyter Labs service')
param JupyterVersion string = 'v0.1.0'

@description('Join token for the Jupyter Labs service')
@secure()
param JupyterToken string

@description('Tags to apply to all newly created resources, in the form of {"key_one":"value_one","key_two":"value_two"}')
param Tags object = {}

var dnsLabelPrefix = 'td${uniqueString(rg.id, deployment().name, JupyterName)}'

// below are static and are not expected to be changed
var registry = 'teradata'
var jupyterRepository = 'ai-unlimited-jupyter'

var cloudInitData = base64(format(
  loadTextContent('../../../scripts/jupyter.cloudinit.yaml'),
  base64(format(
    loadTextContent('../../../scripts/jupyter.service'),
    registry,
    jupyterRepository,
    JupyterVersion,
    JupyterHttpPort,
    JupyterToken
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

module vault '../modules/vault/vault.bicep' = {
  scope: rg
  name: 'vault'
  params: {
    encryptVolumes: true
    keyVaultName: JupyterName 
    location: rg.location
    tags: Tags
  }
}

module vaultAccessPolicy '../modules/vault/access-policy.bicep' = {
  scope: rg
  name: 'vault-access-policy'
  params: {
    vaultName: vault.outputs.name
    accessPolicy: {
      tenantId: subscription().tenantId
      objectId: jupyter.outputs.PrincipleId
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
    sshAccess: false
    jupyterHttpPort: JupyterHttpPort
    sourceAppSecGroups: SourceAppSecGroups
    detinationAppSecGroups: detinationAppSecGroups
    tags: Tags
  }
}

module jupyter '../modules/instance.bicep' = {
  scope: rg
  name: 'jupyter'
  params: {
    location: rg.location
    name: JupyterName
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
    usePublicIp: true
    tags: Tags
  }
}

module PublicKey '../modules/public-key.bicep' = {
  scope: rg
  name: 'Public-Key'
  params: {
    Name: JupyterName
    Location: deployment().location
    VaultName: vault.outputs.name
    RoleID: RoleDefinitionId
  }
}

output PublicIP string = jupyter.outputs.PublicIP
output PrivateIP string = jupyter.outputs.PrivateIP
output JupyterLabPublicHttpAccess string = 'http://${jupyter.outputs.PublicIP}:${JupyterHttpPort}?token=${JupyterToken}'
output JupyterLabPrivateHttpAccess string = 'http://${jupyter.outputs.PrivateIP}:${JupyterHttpPort}?token=${JupyterToken}'
output NetworkSecurityGroupId string = firewall.outputs.Id
