param name string
param location string
param workspacesHttpPort int = 0
param workspacesGrpcPort int = 0
param jupyterHttpPort int = 0
param tags object = {}

resource lbPublicIPAddress 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'inbound'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource lbPublicIPAddressOutbound 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'outbound'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource lb 'Microsoft.Network/loadBalancers@2021-08-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: '${name}Inbound'
        properties: {
          publicIPAddress: {
            id: lbPublicIPAddress.id
          }
        }
      }
      {
        name: '${name}Outbound'
        properties: {
          publicIPAddress: {
            id: lbPublicIPAddressOutbound.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: '${name}InboundBackendPool'
      }
      {
        name: '${name}OutboundBackendPool'
      }
    ]
    loadBalancingRules: flatten([
      workspacesHttpPort != 0 ? [ {
          name: 'WorkspacesUI'
          properties: {
            frontendIPConfiguration: {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
            }
            backendAddressPool: {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, '${name}OutboundBackendPool')
            }
            frontendPort: workspacesHttpPort
            backendPort: workspacesHttpPort
            enableFloatingIP: false
            idleTimeoutInMinutes: 15
            protocol: 'Tcp'
            enableTcpReset: true
            loadDistribution: 'Default'
            disableOutboundSnat: true
            probe: {
              id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}UILbProbe')
            }
          }
        } ] : [], workspacesGrpcPort != 0 ? [ {
          name: 'WorkspacesAPI'
          properties: {
            frontendIPConfiguration: {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
            }
            backendAddressPool: {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, '${name}OutboundBackendPool')
            }
            frontendPort: workspacesGrpcPort
            backendPort: workspacesGrpcPort
            enableFloatingIP: false
            idleTimeoutInMinutes: 15
            protocol: 'Tcp'
            enableTcpReset: true
            loadDistribution: 'Default'
            disableOutboundSnat: true
            probe: {
              id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}APILbProbe')
            }
          }
        } ] : [], jupyterHttpPort != 0 ? [ {
          name: 'JupyterUI'
          properties: {
            frontendIPConfiguration: {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
            }
            backendAddressPool: {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, '${name}OutboundBackendPool')
            }
            frontendPort: jupyterHttpPort
            backendPort: jupyterHttpPort
            enableFloatingIP: false
            idleTimeoutInMinutes: 15
            protocol: 'Tcp'
            enableTcpReset: true
            loadDistribution: 'Default'
            disableOutboundSnat: true
            probe: {
              id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}JupyterLbProbe')
            }
          }
        } ] : []
    ])
    probes: flatten([
      workspacesHttpPort != 0 ? [
        {
          name: '${name}UILbProbe'
          properties: {
            protocol: 'Tcp'
            port: workspacesHttpPort
            intervalInSeconds: 5
            numberOfProbes: 2
          }
        } ] : [], workspacesGrpcPort != 0 ? [
        {
          name: '${name}APILbProbe'
          properties: {
            protocol: 'Tcp'
            port: workspacesGrpcPort
            intervalInSeconds: 5
            numberOfProbes: 2
          }
        } ] : [], jupyterHttpPort != 0 ? [
        {
          name: '${name}JupyterLbProbe'
          properties: {
            protocol: 'Tcp'
            port: jupyterHttpPort
            intervalInSeconds: 5
            numberOfProbes: 2
          }
        } ] : []
    ])
    outboundRules: [
      {
        name: 'myOutboundRule'
        properties: {
          allocatedOutboundPorts: 10000
          protocol: 'All'
          enableTcpReset: false
          idleTimeoutInMinutes: 15
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, '${name}OutboundBackendPool')
          }
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Outbound')
            }
          ]
        }
      }
    ]
  }
  tags: tags
}

output nlbPools array = [ '${name}InboundBackendPool', '${name}OutboundBackendPool' ]
output PublicIp string = lbPublicIPAddress.properties.ipAddress
