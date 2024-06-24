param location string
param name string

param accessCidrs array = []
param sourceAppSecGroups array = []
param detinationAppSecGroups array = []
param sshAccess bool = false
param aiUnlimitedHttpPort int = 0
param aiUnlimitedGrpcPort int = 0
param aiUnlimitedSchedulerHttpPort int = 0
param aiUnlimitedSchedulerGrpcPort int = 0
param jupyterHttpPort int = 0
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: name
  tags: tags
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

// resource sshDeny 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (!sshAccess) {
//   name: '${name}-ssh-deny'
//   parent: networkSecurityGroup

//   properties: {
//     access: sshAccess ? 'Allow' : 'Deny'
//     description: 'deny ssh to the workspace instance'
//     destinationAddressPrefix: '*'
//     destinationPortRange: '22'
//     direction: 'Inbound'
//     priority: 700
//     protocol: 'Tcp'
//     sourceAddressPrefix: '*'
//     sourcePortRange: '*'
//   }
// }

resource AiUnlimitedHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (aiUnlimitedHttpPort != 0) {
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
    destinationPortRange: string(aiUnlimitedHttpPort) // destinationPortRanges: []
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

resource AiUnlimitedGRPC 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (aiUnlimitedGrpcPort != 0) {
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
    destinationPortRange: string(aiUnlimitedGrpcPort) // destinationPortRanges: []
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

resource JupyterHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (jupyterHttpPort != 0) {
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
    destinationPortRange: string(jupyterHttpPort) // destinationPortRanges: []
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

resource AiUnlimitedSchedulerHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (aiUnlimitedSchedulerHttpPort != 0) {
  name: '${name}-scheduler-http-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow http to the scheduler instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [for secgroup in detinationAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    destinationPortRange: string(aiUnlimitedSchedulerHttpPort) // destinationPortRanges: []
    direction: 'Inbound'
    priority: 704
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

resource AiUnlimitedSchedulerGRPC 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (aiUnlimitedSchedulerGrpcPort != 0) {
  name: '${name}-scheduler-grpc-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow grpc to the scheduler instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [for secgroup in detinationAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    destinationPortRange: string(aiUnlimitedSchedulerGrpcPort) // destinationPortRanges: []
    direction: 'Inbound'
    priority: 705
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
