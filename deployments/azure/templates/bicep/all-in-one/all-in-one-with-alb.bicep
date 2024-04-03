targetScope = 'subscription'

@description('name for the resource group.')
param ResourceGroupName string = 'ai-unlimited-workspace'

@description('Name for the Workspace service\'s virtual machine.')
param AiUnlimitedName string = 'ai-unlimited'

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
param VirtualNetworkName string = 'ai-unlimited'

@description('Name of the subnet to run the AI Unlimited service in')
param SubnetName string = 'ai-unlimited'

@description('Name of the subnet for ALB to use')
param AlbSubnetName string = 'ai-unlimited-gtw-subnet'

@description('Name of the network security group')
param SecurityGroup string = 'ai-unlimited-security-group'

@description('The CIDR ranges that can be used to communicate with the AI Unlimited service instance.')
param AccessCIDRs array = [ '0.0.0.0/0' ]

@description('port to access the Jupyter Labs UI.')
param JupyterHttpPort string = '8888'

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

@description('base64 content of SSL certificate file for ALB to use')
@secure()
param ApplicationgateWayCertificate string

@description('password (if present) for certificate')
@secure()
param ApplicationgateWayCertificatePassword string = ''

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

@description('Container Version of the Jupyter Labs service')
param JupyterVersion string = 'latest'

@description('Join token for the Jupyter Labs service')
param JupyterToken string = uniqueString(subscription().id, utcNow())

@description('Tags to apply to all newly created resources, in the form of {"key_one":"value_one","key_two":"value_two"}')
param Tags object = {}

var roleAssignmentName = guid(subscription().id, AiUnlimitedName, rg.id, RoleDefinitionId)

var registry = 'teradata'
var workspaceRepository = 'ai-unlimited-workspaces'
var jupyterRepository = 'ai-unlimited-jupyter'
var gtwPublicIP = '${AiUnlimitedName}-gtw-inbound'


var dnsLabelPrefix = 'td${uniqueString(rg.id, deployment().name, AiUnlimitedName)}'

var cloudInitData = base64(
  format(
    loadTextContent('../../../scripts/all-in-one.cloudinit.yaml'),
    base64(
      format(
        loadTextContent('../../../scripts/ai-unlimited.service'),
        registry,
        workspaceRepository,
        AiUnlimitedVersion,
        AiUnlimitedHttpPort,
        AiUnlimitedGrpcPort,
        subscription().subscriptionId,
        subscription().tenantId,
        '--network-alias ${gtwFrontEndIP.outputs.Dns}'
      )
    ),
    base64(
      format(
        loadTextContent('../../../scripts/jupyter.service'),
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
  name: VirtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  parent: network
  name: SubnetName
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
  params:{
    vaultName: AiUnlimitedName
    accessPolicy:  {
        tenantId: subscription().tenantId
        objectId: aiUnlimited.outputs.PrincipleId
        permissions: {
          keys: [
            'Create', 'Delete', 'Get', 'List', 'Update', 'Purge', 'Recover', 'Decrypt', 'Encrypt'
            'Sign', 'UnwrapKey', 'Verify', 'WrapKey', 'GetRotationPolicy', 'SetRotationPolicy'
          ]
          secrets: [ 'Get', 'Set', 'Delete', 'List', 'Purge' ]
          storage: [ 'Get' ]
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
    aiUnlimitedHttpPort: AiUnlimitedHttpPort
    aiUnlimitedGrpcPort: AiUnlimitedGrpcPort
    jupyterHttpPort: JupyterHttpPort
    sourceAppSecGroups: SourceAppSecGroups
    detinationAppSecGroups: detinationAppSecGroups
    tags: Tags
  }
}

module gtwFrontEndIP '../modules/public-ip.bicep' = {
  scope: rg
  name: 'alb-frontend-public-ip'
  params: {
    name: gtwPublicIP
    location: rg.location
    dnsPrefix: dnsLabelPrefix
    tags: Tags
  }
}

module alb '../modules/alb.bicep' = {
  scope: rg
  name: 'alb'
  params: {
    name: AiUnlimitedName
    location: rg.location

    virtualNetworkName: VirtualNetworkName
    aiUnlimitedHttpPort: int(AiUnlimitedHttpPort)
    aiUnlimitedGrpcPort: int(AiUnlimitedGrpcPort)
    jupyterHttpPort: int(JupyterHttpPort)
    serviceIP: aiUnlimited.outputs.PrivateIP

    gtwPublicIP: gtwPublicIP
    gtwPublicSubnet: AlbSubnetName
    gtwSSLCert: ApplicationgateWayCertificate
    gtwSSLCertPwd: ApplicationgateWayCertificatePassword

    tags: Tags
  }

  dependsOn: [aiUnlimited]
}

module aiUnlimited '../modules/instance.bicep' = {
  scope: rg
  name: 'ai-unlimited'
  params: {
    location: rg.location
    name: AiUnlimitedName
    adminUsername: 'azureuser'
    sshPublicKey: PublicKey
    vmSize: InstanceType
    subnetId: subnet.id
    networkSecurityGroupID: firewall.outputs.Id
    osVersion: OSVersion
    cloudInitData: cloudInitData
    usePersistentVolume: UsePersistentVolume
    persistentVolumeSize: PersistentVolumeSize
    existingPersistentVolume: ExistingPersistentVolume
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

output PublicIP string = gtwFrontEndIP.outputs.Ip
output PrivateIP string = aiUnlimited.outputs.PrivateIP
output AiUnlimitedPublicHttpAccess string = 'http://${gtwFrontEndIP.outputs.Dns}:${AiUnlimitedHttpPort}'
output AiUnlimitedPrivateHttpAccess string = 'http://${aiUnlimited.outputs.PrivateIP}:${AiUnlimitedHttpPort}'
output AiUnlimitedPublicGrpcAccess string = 'http://${gtwFrontEndIP.outputs.Dns}:${AiUnlimitedGrpcPort}'
output AiUnlimitedPrivateGrpcAccess string = 'http://${aiUnlimited.outputs.PrivateIP}:${AiUnlimitedGrpcPort}'
output JupyterLabPublicHttpAccess string = 'http://${gtwFrontEndIP.outputs.Dns}:${JupyterHttpPort}?token=${JupyterToken}'
output JupyterLabPrivateHttpAccess string = 'http://${aiUnlimited.outputs.PrivateIP}:${JupyterHttpPort}?token=${JupyterToken}'
output sshCommand string = 'ssh azureuser@${aiUnlimited.outputs.PrivateIP}'
output SecurityGroup string = firewall.outputs.Id
