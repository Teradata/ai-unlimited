using './ai-unlimited-with-alb.bicep'

param ResourceGroupName = 'ai-unlimited'
param AiUnlimitedName = 'ai-unlimited'
param PublicKey = ''
param OSVersion = 'Ubuntu-2004'
param InstanceType = 'Standard_D2s_v3'
param VirtualNetworkName = 'ai-unlimited'
param SubnetName = 'ai-unlimited'
param AlbSubnetName = 'ai-unlimited-gtw-subnet'
param SecurityGroup = 'ai-unlimited-security-group'
param AccessCIDRs = [
  '0.0.0.0/0'
]
param AiUnlimitedHttpPort = 3000
param AiUnlimitedGrpcPort = 3282
param SourceAppSecGroups = []
param detinationAppSecGroups = []
param RoleDefinitionId = ''
param ApplicationgateWayCertificate = ''
param ApplicationgateWayCertificatePassword = ''
param UseKeyVault = 'New'
param KeyVaultName = 'ai-unlimited-kv'
param UsePersistentVolume = 'New'
param PersistentVolumeSize = 100
param ExistingPersistentVolume = 'NONE'
param AiUnlimitedVersion = 'latest'
param Tags = {}
