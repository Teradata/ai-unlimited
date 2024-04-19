targetScope = 'subscription'

// default input values that should be defined at the start
@description('name for the resource group.')
param ResourceGroupName string = 'ai-unlimited-jupyter'

@description('Name for the Jupyter Labs service\'s virtual machine.')
param JupyterName string = 'ai-unlimited-jupyter'

@description('Name of the network to run the Jupyter Labs service in')
param VirtualNetworkName string = 'ai-unlimited'

@description('Name of the subnet to run the Jupyter Labs service in')
param SubnetName string = 'ai-unlimited'

@description('Name of the subnet for ALB to use')
param AlbSubnetName string = 'ai-unlimited-gtw-subnet'

@description('Name of the network security group')
param SecurityGroup string = 'ai-unlimited-jupyter-security-group'

@description('should we create a new Azure Key Vault for bootstrapping the AI Unlimited Engine nodes.')
@allowed(['New', 'Existing', 'None'])
param UseKeyVault string = 'New'

@description('should we create a new Azure Key Vault for bootstrapping the AI Unlimited Engine nodes.')
param KeyVaultName string = 'ai-unlimited-kv'

// inputs that are required from user
@description('SSH public key value')
@secure()
param PublicKey string

@description('The CIDR ranges that can be used to communicate with the Jupyter Labs service instance.')
param AccessCIDRs array = [ '0.0.0.0/0' ]

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

@description('Join token for the Jupyter Labs service')
@secure()
param JupyterToken string

@description('Container Version of the Jupyter Labs service')
param JupyterVersion string = 'latest'

// below inputs are not so important from user
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param OSVersion string = 'Ubuntu-2004'

// 2vCPUs + 8GiB RAM
@description('The Jupyter Labs VM type')
@allowed([ 'Standard_D2s_v3', 'Standard_D2s_v4', 'Standard_D2s_v5'])
param InstanceType string = 'Standard_D2s_v3'

@description('port to access the Jupyter Labs UI.')
param JupyterHttpPort int = 8888

@description('Source Application Security Groups to access the Jupyter Labs service api.')
param SourceAppSecGroups array = []

@description('Destination Application Security Groups to give access to Jupyter Labs service instance.')
param detinationAppSecGroups array = []

@description('should we use a new or existing volume for persistent data on the Jupyter server.')
@allowed([ 'New', 'None', 'Existing' ])
param UsePersistentVolume string = 'New'

@description('size of the optional persistent disk to the Jpuyter server.')
param PersistentVolumeSize int = 100

@description('Name of the existing persistent volume to attach. Must be in the same region and resourcegroup zone as the Jupyter Labs server.')
param ExistingPersistentVolume string = 'NONE'

@description('Tags to apply to all newly created resources, in the form of {"key_one":"value_one","key_two":"value_two"}')
param Tags object = {}

var gtwPublicIP = '${JupyterName}-gtw-inbound'
var gtwListenerCert = '${JupyterName}-gtw-cert'
var gtwCertMSI = '${JupyterName}-msi'

// below are static and are not expected to be changed
var registry = 'teradata'
var jupyterRepository = 'ai-unlimited-jupyter'

var cloudInitData = base64(
  format(
    loadTextContent('../../../scripts/jupyter.cloudinit.yaml'),
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

module vault '../modules/vault/vault.bicep' = if (UseKeyVault == 'New') {
  scope: rg
  name: 'vault'
  params: {
    encryptVolumes: true
    keyVaultName: KeyVaultName
    location: rg.location
    tags: Tags
  }
}

module albMsiVaultAccessPolicy '../modules/vault/access-policy.bicep' = if (UseKeyVault != 'None') {
  scope: rg
  name: 'alb-msi-vault-access-policy'
  params: {
    vaultName: KeyVaultName
    accessPolicy: {
      tenantId: subscription().tenantId
      objectId: UseKeyVault != 'None' ? albKvMsi.outputs.principalId : ''
      permissions: {
        secrets: [ 'Get', 'Set', 'List' ]
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
  name: 'firewall'
  params: {
    location: rg.location
    name: SecurityGroup
    accessCidrs: AccessCIDRs
    jupyterHttpPort: JupyterHttpPort
    sourceAppSecGroups: SourceAppSecGroups
    detinationAppSecGroups: detinationAppSecGroups
    sshAccess: AllowPublicSSH
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
    name: JupyterName
    location: rg.location

    virtualNetworkName: VirtualNetworkName
    jupyterHttpPort: JupyterHttpPort

    serviceIP: jupyter.outputs.PrivateIP
    gtwPublicIP: gtwPublicIP
    gtwPublicSubnet: AlbSubnetName

    gtwMSI: gtwCertMSI

    gtwSSLCert: UseSelfSignedCertForALB ? '' : ApplicationgateWayCertificate
    gtwSSLCertPwd: UseSelfSignedCertForALB ? '' : ApplicationgateWayCertificatePassword
    gtwSSLCertSecretUri: UseSelfSignedCertForALB ? gtwSelfSignedCert.outputs.certificateSecretIdUnversioned : ''

    tags: Tags
  }

  dependsOn: [jupyter]
}

module jupyter '../modules/instance.bicep' = {
  scope: rg
  name: 'jupyter'
  params: {
    location: rg.location
    name: JupyterName
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
    albName: JupyterName
    usePublicIp: AllowPublicSSH

    tags: Tags
  }
}

output PublicIP string = gtwFrontEndIP.outputs.Ip
output PrivateIP string = jupyter.outputs.PrivateIP
output JupyterLabPublicHttpAccess string = 'https://${gtwFrontEndIP.outputs.Dns}:${JupyterHttpPort}?token=${JupyterToken}'
output JupyterLabPrivateHttpAccess string = 'http://${jupyter.outputs.PrivateIP}:${JupyterHttpPort}?token=${JupyterToken}'
output sshCommand string = 'ssh azureuser@${AllowPublicSSH ? jupyter.outputs.PublicIP : jupyter.outputs.PrivateIP}'
output SecurityGroup string = firewall.outputs.Id
