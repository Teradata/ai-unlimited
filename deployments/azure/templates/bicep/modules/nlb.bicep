param name string
param location string
param dnsPrefix string
param aiUnlimitedAuthPort int = 0
param aiUnlimitedGrpcPort int = 0
param aiUnlimitedSchedulerHttpPort int = 0
// param aiUnlimitedSchedulerGrpcPort int = 0
param jupyterHttpPort int = 0
param aiUnlimitedUIHttpPort int = 0
param aiUnlimitedUIHttpsPort int = 0
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
      aiUnlimitedAuthPort != 0
        ? [
            {
              name: 'AiUnlimitedAuth'
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
                frontendPort: aiUnlimitedAuthPort
                backendPort: aiUnlimitedAuthPort
                enableFloatingIP: false
                idleTimeoutInMinutes: 15
                protocol: 'Tcp'
                enableTcpReset: true
                loadDistribution: 'Default'
                disableOutboundSnat: true
                probe: {
                  id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}AuthLbProbe')
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
      aiUnlimitedSchedulerHttpPort != 0
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
      // aiUnlimitedSchedulerGrpcPort != 0
      //   ? [
      //       {
      //         name: 'AiUnlimitedSchedulerGrpc'
      //         properties: {
      //           frontendIPConfiguration: {
      //             id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, '${name}Inbound')
      //           }
      //           backendAddressPool: {
      //             id: resourceId(
      //               'Microsoft.Network/loadBalancers/backendAddressPools',
      //               name,
      //               '${name}OutboundBackendPool'
      //             )
      //           }
      //           frontendPort: aiUnlimitedSchedulerGrpcPort
      //           backendPort: aiUnlimitedSchedulerGrpcPort
      //           enableFloatingIP: false
      //           idleTimeoutInMinutes: 15
      //           protocol: 'Tcp'
      //           enableTcpReset: true
      //           loadDistribution: 'Default'
      //           disableOutboundSnat: true
      //           probe: {
      //             id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}SchedulerGrpcLbProbe')
      //           }
      //         }
      //       }
      //     ]
      //   : []
      aiUnlimitedUIHttpPort != 0
        ? [
            {
              name: 'AiUnlimitedUIHttp'
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
                frontendPort: aiUnlimitedUIHttpPort
                backendPort: aiUnlimitedUIHttpPort
                enableFloatingIP: false
                idleTimeoutInMinutes: 15
                protocol: 'Tcp'
                enableTcpReset: true
                loadDistribution: 'Default'
                disableOutboundSnat: true
                probe: {
                  id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}UIHttpLbProbe')
                }
              }
            }
          ]
        : []
      aiUnlimitedUIHttpsPort != 0
        ? [
            {
              name: 'AiUnlimitedUIHttps'
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
                frontendPort: aiUnlimitedUIHttpsPort
                backendPort: aiUnlimitedUIHttpsPort
                enableFloatingIP: false
                idleTimeoutInMinutes: 15
                protocol: 'Tcp'
                enableTcpReset: true
                loadDistribution: 'Default'
                disableOutboundSnat: true
                probe: {
                  id: resourceId('Microsoft.Network/loadBalancers/probes', name, '${name}UIHttpsLbProbe')
                }
              }
            }
          ]
        : []
    ])
    probes: flatten([
      aiUnlimitedAuthPort != 0
        ? [
            {
              name: '${name}AuthLbProbe'
              properties: {
                protocol: 'Tcp'
                port: aiUnlimitedAuthPort
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
      aiUnlimitedSchedulerHttpPort != 0
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
      // aiUnlimitedSchedulerGrpcPort != 0
      //   ? [
      //       {
      //         name: '${name}SchedulerGrpcLbProbe'
      //         properties: {
      //           protocol: 'Http'
      //           port: aiUnlimitedSchedulerGrpcPort
      //           requestPath: '/healthcheck'
      //           intervalInSeconds: 5
      //           numberOfProbes: 2
      //         }
      //       }
      //     ]
      //   : []
      aiUnlimitedUIHttpPort != 0
        ? [
            {
              name: '${name}UIHttpLbProbe'
              properties: {
                protocol: 'Http'
                port: aiUnlimitedUIHttpPort
                requestPath: '/'
                intervalInSeconds: 5
                numberOfProbes: 2
              }
            }
          ]
        : []
      aiUnlimitedUIHttpsPort != 0
        ? [
            {
              name: '${name}UIHttpsLbProbe'
              properties: {
                protocol: 'Https'
                port: aiUnlimitedUIHttpsPort
                requestPath: '/'
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
