using './jupyter-with-alb.bicep'

param ResourceGroupName = 'ai-unlimited-jupyter'
param JupyterName = 'ai-unlimited-jupyter'
param PublicKey = ''
param OSVersion = 'Ubuntu-2004'
param InstanceType = 'Standard_D2s_v3'
param VirtualNetworkName = 'ai-unlimited'
param SubnetName = 'ai-unlimited'
param AlbSubnetName = 'ai-unlimited-jupyter-gtw-subnet'
param SecurityGroup = 'ai-unlimited-jupyter-security-group'
param AccessCIDRs = [
  '0.0.0.0/0'
]
param JupyterHttpPort = '8888'
param SourceAppSecGroups = []
param detinationAppSecGroups = []
param UsePersistentVolume = 'New'
param PersistentVolumeSize = 100
param ExistingPersistentVolume = 'NONE'
param JupyterVersion = 'latest'
param JupyterToken = 'USE_A_SECURE_TOKEN'
param ApplicationgateWayCertificate = ''
param ApplicationgateWayCertificatePassword = ''
param Tags = {}
