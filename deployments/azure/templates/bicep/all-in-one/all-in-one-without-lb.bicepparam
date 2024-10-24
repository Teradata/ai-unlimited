using './all-in-one-without-lb.bicep'

param ResourceGroupName = 'ai-unlimited-workspace'
param AiUnlimitedName = ''
param PublicKey = ''
param OSVersion = 'Ubuntu-2004'
param InstanceType = 'Standard_D2s_v3'
param Network = ''
param Subnet = ''
param SecurityGroup = 'AiUnlimitedSecurityGroup'
param AccessCIDRs = [
  '0.0.0.0/0'
]
param JupyterHttpPort = 8888
param AiUnlimitedHttpPort = 3000
param AiUnlimitedGrpcPort = 3282
// param AiUnlimitedSchedulerGrpcPort = 50051
// param AiUnlimitedSchedulerHttpPort = 50061
param SourceAppSecGroups = []
param detinationAppSecGroups = []
param RoleDefinitionId = ''
param AllowPublicSSH = true
param UseKeyVault = 'New'
param UsePersistentVolume = 'New'
param PersistentVolumeSize = 100
param ExistingPersistentVolume = 'NONE'
param AiUnlimitedVersion = 'v0.2.23'
param JupyterVersion = 'latest'
// param AiUnlimitedSchedulerVersion = 'latest'
param JupyterToken = 'USE_A_SECURE_TOKEN'
param Tags = {}
