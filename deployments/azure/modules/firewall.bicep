param location string
param name string
param accessCidrs array = []
param sourceAppSecGroups array = []
param detinationAppSecGroups array = []
param sshAccess bool = false
param workspacesHttpPort string = 'None'
param workspacesGrpcPort string = 'None'
param jupyterHttpPort string = 'None'

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: name
  location: location
}

resource sshAllow 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (sshAccess) {
  name: '${name}-ssh-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow ssh to the workspace instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [for secgroup in detinationAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    destinationPortRange: '22' // destinationPortRanges: []
    direction: 'Inbound'
    priority: 700
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [for secgroup in sourceAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

resource sshDeny 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (!sshAccess) {
  name: '${name}-ssh-deny'
  parent: networkSecurityGroup

  properties: {
    access: sshAccess ? 'Allow' : 'Deny'
    description: 'deny ssh to the workspace instance'
    destinationAddressPrefix: '*'
    destinationPortRange: '22'
    direction: 'Inbound'
    priority: 700
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

resource WorkspacesHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (workspacesHttpPort != 'None') {
  name: '${name}-workspace-http-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow http to the workspace instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [for secgroup in detinationAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    destinationPortRange: workspacesHttpPort // destinationPortRanges: []
    direction: 'Inbound'
    priority: 701
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [for secgroup in sourceAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

resource WorkspacesGRPC 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (workspacesGrpcPort != 'None') {
  name: '${name}-workspace-grpc-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow grpc to the workspace instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [for secgroup in detinationAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    destinationPortRange: workspacesGrpcPort // destinationPortRanges: []
    direction: 'Inbound'
    priority: 702
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [for secgroup in sourceAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

resource JupyterHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (jupyterHttpPort != 'None') {
  name: '${name}-juptyer-http-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow http to the jupyter instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [for secgroup in detinationAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    destinationPortRange: jupyterHttpPort // destinationPortRanges: []
    direction: 'Inbound'
    priority: 703
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [for secgroup in sourceAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

output Id string = networkSecurityGroup.id
