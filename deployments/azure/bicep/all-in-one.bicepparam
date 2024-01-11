using './all-in-one.bicep'

param ResourceGroupName = 'ai-unlimited-workspace'
param WorkspacesName = ''
param PublicKey = ''
param OSVersion = 'Ubuntu-2004'
param InstanceType = 'Standard_D2s_v3'
param Network = ''
param Subnet = ''
param SecurityGroup = 'WorkspacesSecurityGroup'
param AccessCIDRs = [
  '0.0.0.0/0'
]
param JupyterHttpPort = '8888'
param WorkspacesHttpPort = '3000'
param WorkspacesGrpcPort = '3282'
param SourceAppSecGroups = []
param detinationAppSecGroups = []
param RoleDefinitionId = ''
param AllowPublicSSH = true
param UseKeyVault = 'New'
param UsePersistentVolume = 'New'
param PersistentVolumeSize = 100
param ExistingPersistentVolume = 'NONE'
param WorkspacesVersion = 'latest'
param JupyterVersion = 'latest'
param JupyterToken = 'USE_A_SECURE_TOKEN' /* TODO : please fix the value assigned to this parameter `uniqueString()` */
param UseNLB = false
