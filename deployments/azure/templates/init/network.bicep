param networkName string
param networkCidr array
param subnetCidr string
param albSubnetCidr string
param deployAlbSubnet bool
param location string
param tags object = {}

var gwSubnetName = '${networkName}-gtw-subnet'

resource network 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: networkName
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: networkCidr
    }
  }
  tags: tags
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

resource gwSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = if (deployAlbSubnet) { 
  parent: network
  name: gwSubnetName

  properties: {
    addressPrefix: albSubnetCidr
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

output networkName string = network.name
output subnetName string = subnet.name
output albSubnetName string = deployAlbSubnet ? gwSubnet.name : ''
