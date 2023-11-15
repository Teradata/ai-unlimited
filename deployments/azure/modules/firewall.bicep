param location string
param name string
param accessCidrs array
param sshAccess bool
param httpPort string
param grpcPort string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: name
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 700
          protocol: 'Tcp'
          access: sshAccess ? 'Allow' : 'Deny'
          direction: 'Inbound'
          sourceAddressPrefixes: accessCidrs
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'HTTP'
        properties: {
          priority: 701
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefixes: accessCidrs
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: httpPort
        }
      }
      {
        name: 'GRPC'
        properties: {
          priority: 702
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefixes: accessCidrs
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: grpcPort
        }
      }
    ]
  }
}

output Id string = networkSecurityGroup.id
