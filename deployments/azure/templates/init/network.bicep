param networkName string
param networkCidr array
param subnetCidr string
param location string
param tags object = {}

resource network 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: networkName
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: networkCidr
    }
    subnets: [
      {
        name: networkName
        properties: {
          addressPrefix: subnetCidr
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
  tags: tags
}

output networkName string = network.name
output subnetName string = network.properties.subnets[0].name
