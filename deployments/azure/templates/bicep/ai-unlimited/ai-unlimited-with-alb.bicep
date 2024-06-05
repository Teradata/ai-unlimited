targetScope = 'subscription'

// default input values that should be defined at the start
@description('name for the resource group.')
param ResourceGroupName string = 'ai-unlimited'

@description('Name for the AI Unlimited service\'s virtual machine.')
param AiUnlimitedName string = 'ai-unlimited'

@description('Name of the network to run the AI Unlimited service in')
param VirtualNetworkName string = 'ai-unlimited'

@description('Name of the subnet to run the AI Unlimited service in')
param SubnetName string = 'ai-unlimited'

@description('Name of the subnet for ALB to use')
param AlbSubnetName string = 'ai-unlimited-gtw-subnet'

@description('Name of the network security group')
param SecurityGroup string = 'ai-unlimited-security-group'

@description('use Azure Key Vault for saving ALB SSL cert.')
@allowed(['New', 'Existing', 'None'])
param UseKeyVault string = 'New'

@description('name of the keyvault for AI Unlimited Engine to use.')
param KeyVaultName string = 'ai-unlimited-kv'

// inputs that are required from user
@description('SSH public key value')
@secure()
param PublicKey string

@description('The CIDR ranges that can be used to communicate with the AI Unlimited service instance.')
param AccessCIDRs array = ['0.0.0.0/0']

@description('GUID of the AI Unlimited Custom Role')
param RoleDefinitionId string

@description('allow access the AI Unlimited ssh port from the access cidr.')
param AllowPublicSSH bool = false

@description('allow access the AI Unlimited ssh port from the access cidr.')
param UseSelfSignedCertForALB bool = true

@description('base64 content of SSL certificate file for ALB to use')
@secure()
param ApplicationgateWayCertificate string = ''

@description('password (if present) for certificate')
@secure()
param ApplicationgateWayCertificatePassword string = ''

@description('Dns label prefix for ALB')
param dnsLabelPrefix string

@description('Container Version of the AI Unlimited service')
param AiUnlimitedVersion string = 'latest'

@description('Container Version of the AI Unlimited scheduler service')
param AiUnlimitedSchedulerVersion string = 'latest'

// below inputs are not so important from user
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param OSVersion string = 'Ubuntu-2004'

// 2vCPUs + 8GiB RAM
@description('The AI Unlimited VM type')
@allowed([ 'Standard_D2s_v3', 'Standard_D2s_v4', 'Standard_D2s_v5'])
param InstanceType string = 'Standard_D2s_v3'

@description('port to access the AI Unlimited service UI.')
param AiUnlimitedHttpPort int = 3000

@description('port to access the AI Unlimited service api.')
param AiUnlimitedGrpcPort int = 3282

@description('port to access the AI Unlimited scheduler service api.')
param AiUnlimitedSchedulerPort int = 50051

@description('Source Application Security Groups to access the AI Unlimited service api.')
param SourceAppSecGroups array = []

@description('Destination Application Security Groups to give access to AI Unlimited service instance.')
param detinationAppSecGroups array = []

@description('should we use a new or existing volume for persistent data on the AI Unlimited server.')
@allowed(['New', 'None', 'Existing'])
param UsePersistentVolume string = 'New'

@description('size of the optional persistent disk to the AI Unlimited server.')
param PersistentVolumeSize int = 100

@description('Name of the existing persistent volume to attach. Must be in the same region and resourcegroup zone as the AI Unlimited server.')
param ExistingPersistentVolume string = 'NONE'

@description('Tags to apply to all newly created resources, in the form of {"key_one":"value_one","key_two":"value_two"}')
param Tags object = {}

var roleAssignmentName = guid(subscription().id, AiUnlimitedName, rg.id, RoleDefinitionId)

var gtwPublicIP = '${AiUnlimitedName}-gtw-inbound'
var gtwListenerCert = '${AiUnlimitedName}-gtw-cert'
var gtwCertMSI = '${AiUnlimitedName}-msi'

// below are static and are not expected to be changed
var registry = 'teradata'
var workspaceRepository = 'ai-unlimited-workspaces'
var workspaceSchedulerRepository = 'ai-unlimited-scheduler'

var cloudInitData = base64(format(
  loadTextContent('../../../scripts/ai-unlimited.cloudinit.yaml'),
  base64(format(
    loadTextContent('../../../scripts/ai-unlimited.service'),
    registry,
    workspaceRepository,
    AiUnlimitedVersion,
    AiUnlimitedHttpPort,
    AiUnlimitedGrpcPort,
    subscription().subscriptionId,
    subscription().tenantId,
    '--network-alias ${gtwFrontEndIP.outputs.Dns}'
  )),
  base64(format(
    loadTextContent('../../../scripts/ai-unlimited-scheduler.service'),
    registry,
    workspaceSchedulerRepository,
    AiUnlimitedSchedulerVersion,
    AiUnlimitedSchedulerPort
  ))
))

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

module albKvMsi '../modules/identity.bicep' =
  if (UseKeyVault != 'None') {
    scope: rg
    name: 'ssl-cert-keyvault-identity'
    params: {
      name: gtwCertMSI
      location: rg.location
      tags: Tags
    }
  }

module vault '../modules/vault/vault.bicep' =
  if (UseKeyVault == 'New') {
    scope: rg
    name: 'ssl-cert-keyvault'
    params: {
      encryptVolumes: false
      keyVaultName: KeyVaultName
      location: rg.location
      tags: Tags
    }
  }

// because of https://github.com/Azure/bicep/issues/2371
// (UseKeyVault != 'None') confition is required for objectId
module albMsiVaultAccessPolicy '../modules/vault/access-policy.bicep' = if (UseKeyVault != 'None') {
  scope: rg
  name: 'alb-msi-vault-access-policy'
  params: {
    vaultName: KeyVaultName
    accessPolicy: {
      tenantId: subscription().tenantId
      objectId: UseKeyVault != 'None' ? albKvMsi.outputs.principalId : ''
      permissions: {
        secrets: ['Get', 'Set', 'List']
        certificates: [ 'Get', 'Set', 'List' ]
      }
    }
  }
}

module gtwSelfSignedCert 'br/public:deployment-scripts/create-kv-certificate:1.1.1' = if (UseSelfSignedCertForALB) {
  scope: rg
  name: 'alb-self-signed-cert'
  params: {
    akvName: KeyVaultName
    managedIdentityName: gtwCertMSI
    certificateName: gtwListenerCert
    certificateCommonName: dnsLabelPrefix
  }
  dependsOn:[albMsiVaultAccessPolicy]
}

module firewall '../modules/firewall.bicep' = {
  scope: rg
  name: 'ai-engine-firewall'
  params: {
    location: rg.location
    name: SecurityGroup
    accessCidrs: AccessCIDRs
    aiUnlimitedHttpPort: AiUnlimitedHttpPort
    aiUnlimitedGrpcPort: AiUnlimitedGrpcPort
    sourceAppSecGroups: SourceAppSecGroups
    detinationAppSecGroups: detinationAppSecGroups
    sshAccess : AllowPublicSSH
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

    serviceIP: aiUnlimited.outputs.PrivateIP
    gtwPublicIP: gtwPublicIP
    gtwPublicSubnet: AlbSubnetName

    gtwMSI: gtwCertMSI

    gtwSSLCert: UseSelfSignedCertForALB ? '' : ApplicationgateWayCertificate
    gtwSSLCertPwd: UseSelfSignedCertForALB ? '' : ApplicationgateWayCertificatePassword
    gtwSSLCertSecretUri: UseSelfSignedCertForALB ? gtwSelfSignedCert.outputs.certificateSecretIdUnversioned : ''

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
    albName: AiUnlimitedName
    usePublicIp: AllowPublicSSH

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
output AiUnlimitedPublicHttpAccess string = 'https://${gtwFrontEndIP.outputs.Dns}:${AiUnlimitedHttpPort}'
output AiUnlimitedPrivateHttpAccess string = 'http://${aiUnlimited.outputs.PrivateIP}:${AiUnlimitedHttpPort}'
output AiUnlimitedPublicGrpcAccess string = 'https://${gtwFrontEndIP.outputs.Dns}:${AiUnlimitedGrpcPort}'
output AiUnlimitedPrivateGrpcAccess string = 'http://${aiUnlimited.outputs.PrivateIP}:${AiUnlimitedGrpcPort}'
output sshCommand string = 'ssh azureuser@${AllowPublicSSH ? aiUnlimited.outputs.PublicIP : aiUnlimited.outputs.PrivateIP}'
output SecurityGroup string = firewall.outputs.Id
