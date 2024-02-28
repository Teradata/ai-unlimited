targetScope = 'subscription'

@description('name for the resource group.')
param ResourceGroupName string = 'ai-unlimited-jupyter'

@description('Name for the Jupyter Labs service\'s virtual machine.')
param JupyterName string

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

@description('The Jupyter Labs VM type')
param InstanceType string = 'Standard_D2s_v3'

@description('Name of the network to run the Jupyter Labs service in')
param Network string

@description('Name of the subnet to run the Jupyter Labs service in')
param Subnet string

@description('Name of the network security group')
param SecurityGroup string = 'JupyterSecurityGroup'

@description('The CIDR ranges that can be used to communicate with the Jupyter Labs service instance.')
param AccessCIDRs array = [ '0.0.0.0/0' ]

@description('port to access the Jupyter Labs UI.')
param JupyterHttpPort string = '8888'

@description('Source Application Security Groups to access the Jupyter Labs service api.')
param SourceAppSecGroups array = []

@description('Destination Application Security Groups to give access to Jupyter Labs service instance.')
param detinationAppSecGroups array = []

@description('allow access the Jupyter Labs ssh port from the access cidr.')
param AllowPublicSSH bool = true

@description('should we use a new or existing volume for persistent data on the Jupyter server.')
@allowed([ 'New', 'None', 'Existing' ])
param UsePersistentVolume string = 'New'

@description('size of the optional persistent disk to the Jpuyter server.')
param PersistentVolumeSize int = 100

@description('Name of the existing persistent volume to attach. Must be in the same region and resourcegroup zone as the Jupyter Labs server.')
param ExistingPersistentVolume string = 'NONE'

@description('Container Version of the Jupyter Labs service')
param JupyterVersion string = 'latest'

@description('Join token for the Jupyter Labs service')
param JupyterToken string = uniqueString(subscription().id, utcNow())

@description('Use a Network Load Balancer to connect to the Jupyter Labs server')
param UseNLB bool = false

@description('Tags to apply to all newly created resources, in the form of {"key_one":"value_one","key_two":"value_two"}')
param Tags object = {}

var registry = 'teradata'
var jupyterRepository = 'ai-unlimited-jupyter'

var dnsLabelPrefix = 'td${uniqueString(rg.id, deployment().name, JupyterName)}'

var cloudInitData = base64(
  format(
    loadTextContent('../templates/jupyter.cloudinit.yaml'),
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
    jupyterHttpPort: JupyterHttpPort
    sourceAppSecGroups: SourceAppSecGroups
    detinationAppSecGroups: detinationAppSecGroups
    tags: Tags
  }
}

module nlb '../modules/nlb.bicep' = if (UseNLB) {
  scope: rg
  name: 'loadbalancer'
  params: {
    name: JupyterName
    location: rg.location
    dnsPrefix: dnsLabelPrefix
    jupyterHttpPort: int(JupyterHttpPort)
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
    nlbName: UseNLB ? JupyterName : ''
    nlbPoolNames: UseNLB ? nlb.outputs.nlbPools : []
    usePublicIp: !UseNLB
    tags: Tags
  }
}

output PublicIP string = UseNLB ? nlb.outputs.PublicIp : jupyter.outputs.PublicIP
output PrivateIP string = jupyter.outputs.PrivateIP
output JupyterLabPublicHttpAccess string = 'http://${UseNLB ? nlb.outputs.PublicDns : jupyter.outputs.PublicIP}:${JupyterHttpPort}?token=${JupyterToken}'
output JupyterLabPrivateHttpAccess string = 'http://${jupyter.outputs.PrivateIP}:${JupyterHttpPort}?token=${JupyterToken}'
output sshCommand string = 'ssh azureuser@${UseNLB ? jupyter.outputs.PrivateIP : jupyter.outputs.PublicIP}'
output SecurityGroup string = firewall.outputs.Id
