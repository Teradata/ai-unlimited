using './ai-unlimited-without-lb.bicep'

param ResourceGroupName = 'ai-unlimited-workspace'
param AiUnlimitedName = ''
param OSVersion = 'Ubuntu-2004'
param InstanceType = 'Standard_D2s_v3'
param Network = ''
param Subnet = ''
param SecurityGroup = 'AiUnlimitedSecurityGroup'
param AccessCIDRs = [
  '0.0.0.0/0'
]
param AiUnlimitedAuthPort = 3000
param AiUnlimitedGrpcPort = 3282
// param AiUnlimitedSchedulerGrpcPort = 50051
param AiUnlimitedSchedulerHttpPort = 50061
// param AiUnlimitedUIHttpPort = 80
// param AiUnlimitedUIHttpsPort = 443 
param SourceAppSecGroups = []
param detinationAppSecGroups = []
param RoleDefinitionId = ''
param UseKeyVault = 'New'
param UsePersistentVolume = 'New'
param PersistentVolumeSize = 100
param ExistingPersistentVolume = 'NONE'
param AiUnlimitedVersion = 'v0.3.7'
param AiUnlimitedUIVersion = 'v0.1.2'
param AiUnlimitedSchedulerVersion = 'v0.1.80'
param Tags = {}
