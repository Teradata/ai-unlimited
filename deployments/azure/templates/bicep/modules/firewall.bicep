param location string
param name string

param accessCidrs array = []
param sourceAppSecGroups array = []
param detinationAppSecGroups array = []
param sshAccess bool = false
param aiUnlimitedHttpPort int = 0
param aiUnlimitedGrpcPort int = 0
param aiUnlimitedSchedulerHttpPort int = 0
// param aiUnlimitedSchedulerGrpcPort int = 0
param aiUnlimitedUIHttpPort int = 0
param jupyterHttpPort int = 0
param tags object = {}
param uuid string = newGuid()

var nameCharLimit = 60
var uniqueName = '${name}-${uniqueString(uuid)}'
var uniqueSecurityGroupName = substring(
  '${uniqueName}',
  0,
  length(uniqueName) < nameCharLimit ? length(uniqueName) : nameCharLimit
)

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: uniqueSecurityGroupName
  tags: tags
  location: location
}

resource sshAllow 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (sshAccess) {
  name: '${uniqueSecurityGroupName}-ssh-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow ssh to the workspace instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [
      for secgroup in detinationAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    destinationPortRange: '22' // destinationPortRanges: []
    direction: 'Inbound'
    priority: 700
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [
      for secgroup in sourceAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

// resource sshDeny 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (!sshAccess) {
//   name: '${uniqueSecurityGroupName}-ssh-deny'
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
  name: '${uniqueSecurityGroupName}-workspace-http-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow http to the workspace instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [
      for secgroup in detinationAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    destinationPortRange: string(aiUnlimitedHttpPort) // destinationPortRanges: []
    direction: 'Inbound'
    priority: 701
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [
      for secgroup in sourceAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

resource AiUnlimitedGRPC 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (aiUnlimitedGrpcPort != 0) {
  name: '${uniqueSecurityGroupName}-workspace-grpc-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow grpc to the workspace instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [
      for secgroup in detinationAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    destinationPortRange: string(aiUnlimitedGrpcPort) // destinationPortRanges: []
    direction: 'Inbound'
    priority: 702
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [
      for secgroup in sourceAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

resource JupyterHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (jupyterHttpPort != 0) {
  name: '${uniqueSecurityGroupName}-juptyer-http-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow http to the jupyter instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [
      for secgroup in detinationAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    destinationPortRange: string(jupyterHttpPort) // destinationPortRanges: []
    direction: 'Inbound'
    priority: 703
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [
      for secgroup in sourceAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

resource AiUnlimitedSchedulerHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (aiUnlimitedSchedulerHttpPort != 0) {
  name: '${uniqueSecurityGroupName}-scheduler-http-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow http to the scheduler instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [
      for secgroup in detinationAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    destinationPortRange: string(aiUnlimitedSchedulerHttpPort) // destinationPortRanges: []
    direction: 'Inbound'
    priority: 704
    protocol: 'Tcp'
    sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
    sourceApplicationSecurityGroups: [
      for secgroup in sourceAppSecGroups: {
        id: secgroup
        location: location
      }
    ]
    sourcePortRange: '*' // sourcePortRanges: []
  }
}

resource AiUnlimitedUIHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (aiUnlimitedUIHttpPort != 0) {
  name: '${name}-workspace-ui-http-allow'
  parent: networkSecurityGroup

  properties: {
    access: 'Allow'
    description: 'allow http to the workspace ui instance'
    destinationAddressPrefix: '*' // destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [for secgroup in detinationAppSecGroups: {
      id: secgroup
      location: location
    }
    ]
    destinationPortRange: string(aiUnlimitedUIHttpPort) // destinationPortRanges: []
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

// resource AiUnlimitedSchedulerGRPC 'Microsoft.Network/networkSecurityGroups/securityRules@2023-04-01' = if (aiUnlimitedSchedulerGrpcPort != 0) {
//   name: '${uniqueSecurityGroupName}-scheduler-grpc-allow'
//   parent: networkSecurityGroup

//   properties: {
//     access: 'Allow'
//     description: 'allow grpc to the scheduler instance'
//     destinationAddressPrefix: '*' // destinationAddressPrefixes: []
//     destinationApplicationSecurityGroups: [for secgroup in detinationAppSecGroups: {
//       id: secgroup
//       location: location
//     }
//     ]
//     destinationPortRange: string(aiUnlimitedSchedulerGrpcPort) // destinationPortRanges: []
//     direction: 'Inbound'
//     priority: 705
//     protocol: 'Tcp'
//     sourceAddressPrefixes: accessCidrs // sourceAddressPrefix: 'string'
//     sourceApplicationSecurityGroups: [for secgroup in sourceAppSecGroups: {
//       id: secgroup
//       location: location
//     }
//     ]
//     sourcePortRange: '*' // sourcePortRanges: []
//   }
// }

output Id string = networkSecurityGroup.id
