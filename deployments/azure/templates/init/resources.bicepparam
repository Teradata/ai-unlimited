using './resources.bicep'

param name = 'ai-unlimited'
param networkCidr = [
  '10.0.0.0/16'
]
param subnetCidr = '10.0.0.0/24'
param albSubnetCidr = '10.0.1.0/24'
param deployALBComponents = false
param Tags = {}

