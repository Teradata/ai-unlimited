param name string
param location string
param dnsPrefix string
param aiUnlimitedHttpPort int = 0
param aiUnlimitedGrpcPort int = 0
param aiUnlimitedSchedulerHttpPort int = 0
param aiUnlimitedSchedulerGrpcPort int = 0
param jupyterHttpPort int = 0
param tags object = {}

module lbPublicIPAddress 'public-ip.bicep' = {
  name: '${name}-inbound'
  params: {
    name: '${name}-inbound'
    location: location
    dnsPrefix: dnsPrefix
    tags: tags
  }
}

module lbPublicIPAddressOutbound 'public-ip.bicep' = {
  name: '${name}-outbound'
  params: {
    name: '${name}-outbound'
    location: location
    dnsPrefix: ''
    tags: tags
  }
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
            id: lbPublicIPAddress.outputs.Id
          }
        }
      }
      {
        name: '${name}Outbound'
        properties: {
          publicIPAddress: {
            id: lbPublicIPAddressOutbound.outputs.Id
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
      aiUnlimitedHttpPort != 0
        ? [
            {
              name: 'AiUnlimitedUI'
              properties: {
                frontendIPConfiguration: {
                  id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/loadBalancers/backendAddressPools',
                    name,
                    '${name}OutboundBackendPool'
                  )
                }
                frontendPort: aiUnlimitedHttpPort
                backendPort: aiUnlimitedHttpPort
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
            }
          ]
        : []
      aiUnlimitedGrpcPort != 0
        ? [
            {
              name: 'AiUnlimitedAPI'
              properties: {
                frontendIPConfiguration: {
                  id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/loadBalancers/backendAddressPools',
                    name,
                    '${name}OutboundBackendPool'
                  )
                }
                frontendPort: aiUnlimitedGrpcPort
                backendPort: aiUnlimitedGrpcPort
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
            }
          ]
        : []
      jupyterHttpPort != 0
        ? [
            {
              name: 'JupyterUI'
              properties: {
                frontendIPConfiguration: {
                  id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/loadBalancers/backendAddressPools',
                    name,
                    '${name}OutboundBackendPool'
                  )
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
            }
          ]
        : []
      aiUnlimitedHttpPort != 0
        ? [
            {
              name: 'AiUnlimitedSchedulerHttp'
              properties: {
                frontendIPConfiguration: {
                  id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/loadBalancers/backendAddressPools',
                    name,
                    '${name}OutboundBackendPool'
                  )
                }
                frontendPort: aiUnlimitedSchedulerHttpPort
                backendPort: aiUnlimitedSchedulerHttpPort
                enableFloatingIP: false
                idleTimeoutInMinutes: 15
                protocol: 'Tcp'
                enableTcpReset: true
                loadDistribution: 'Default'
                disableOutboundSnat: true
                probe: {
                  id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}SchedulerHttpLbProbe')
                }
              }
            }
          ]
        : []
      aiUnlimitedGrpcPort != 0
        ? [
            {
              name: 'AiUnlimitedSchedulerGrpc'
              properties: {
                frontendIPConfiguration: {
                  id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/loadBalancers/backendAddressPools',
                    name,
                    '${name}OutboundBackendPool'
                  )
                }
                frontendPort: aiUnlimitedSchedulerGrpcPort
                backendPort: aiUnlimitedSchedulerGrpcPort
                enableFloatingIP: false
                idleTimeoutInMinutes: 15
                protocol: 'Tcp'
                enableTcpReset: true
                loadDistribution: 'Default'
                disableOutboundSnat: true
                probe: {
                  id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}SchedulerGrpcLbProbe')
                }
              }
            }
          ]
        : []
    ])
    probes: flatten([
      aiUnlimitedHttpPort != 0
        ? [
            {
              name: '${name}UILbProbe'
              properties: {
                protocol: 'Tcp'
                port: aiUnlimitedHttpPort
                intervalInSeconds: 5
                numberOfProbes: 2
              }
            }
          ]
        : []
      aiUnlimitedGrpcPort != 0
        ? [
            {
              name: '${name}APILbProbe'
              properties: {
                protocol: 'Tcp'
                port: aiUnlimitedGrpcPort
                intervalInSeconds: 5
                numberOfProbes: 2
              }
            }
          ]
        : []
      jupyterHttpPort != 0
        ? [
            {
              name: '${name}JupyterLbProbe'
              properties: {
                protocol: 'Tcp'
                port: jupyterHttpPort
                intervalInSeconds: 5
                numberOfProbes: 2
              }
            }
          ]
        : []
      aiUnlimitedHttpPort != 0
        ? [
            {
              name: '${name}SchedulerHttpLbProbe'
              properties: {
                protocol: 'Http'
                port: aiUnlimitedSchedulerHttpPort
                requestPath: '/healthcheck'
                intervalInSeconds: 5
                numberOfProbes: 2
              }
            }
          ]
        : []
      aiUnlimitedGrpcPort != 0
        ? [
            {
              name: '${name}SchedulerGrpcLbProbe'
              properties: {
                protocol: 'Http'
                port: aiUnlimitedSchedulerGrpcPort
                requestPath: '/healthcheck'
                intervalInSeconds: 5
                numberOfProbes: 2
              }
            }
          ]
        : []
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

output nlbPools array = ['${name}InboundBackendPool', '${name}OutboundBackendPool']
output PublicIp string = lbPublicIPAddress.outputs.Ip
output PublicDns string = lbPublicIPAddress.outputs.Dns
