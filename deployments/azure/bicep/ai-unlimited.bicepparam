using './ai-unlimited.bicep'

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
param AiUnlimitedHttpPort = '3000'
param AiUnlimitedGrpcPort = '3282'
param SourceAppSecGroups = []
param detinationAppSecGroups = []
param RoleDefinitionId = ''
param AllowPublicSSH = true
param UseKeyVault = 'New'
param UsePersistentVolume = 'New'
param PersistentVolumeSize = 100
param ExistingPersistentVolume = 'NONE'
param AiUnlimitedVersion = 'latest'
param UseNLB = false
param Tags = {}