using './jupyter.bicep'

param ResourceGroupName = 'ai-unlimited-jupyter'
param JupyterName = ''
param PublicKey = ''
param OSVersion = 'Ubuntu-2004'
param InstanceType = 'Standard_D2s_v3'
param Network = ''
param Subnet = ''
param SecurityGroup = 'JupyterSecurityGroup'
param AccessCIDRs = [
  '0.0.0.0/0'
]
param JupyterHttpPort = '8888'
param SourceAppSecGroups = []
param detinationAppSecGroups = []
param AllowPublicSSH = true
param UsePersistentVolume = 'New'
param PersistentVolumeSize = 100
param ExistingPersistentVolume = 'NONE'
param JupyterVersion = 'latest'
param JupyterToken = 'USE_A_SECURE_TOKEN' /* TODO : please fix the value assigned to this parameter `uniqueString()` */
param UseNLB = false
param Tags = {}
