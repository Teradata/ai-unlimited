param networkName string
param networkCidr array
param subnetCidr string
param location string

resource network 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: networkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: networkCidr
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  parent: network
  name: networkName
  properties: {
    addressPrefix: subnetCidr
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

output subnetName string = subnet.name
output networkName string = network.name
