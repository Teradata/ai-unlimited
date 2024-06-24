param name string
param location string
param tags object

param virtualNetworkName string
param aiUnlimitedHttpPort int = 0
param aiUnlimitedGrpcPort int = 0
param aiUnlimitedSchedulerHttpPort int = 0
param aiUnlimitedSchedulerGrpcPort int = 0
param jupyterHttpPort int = 0

param gtwPublicSubnet string
param gtwPublicIP string
param serviceIP string

param gtwMSI string

param gtwSSLCertSecretUri string
@secure()
param gtwSSLCert string

@secure()
param gtwSSLCertPwd string

var gatewayName = '${name}-gtw'
var gatewaySKU = 'Standard_v2'
var gtwFrontEndIPConfigName = '${name}-gtw-front-end-ip'
var gtwListenerCert = '${name}-gtw-cert'

var gtwBackendSettingUI = aiUnlimitedHttpPort != 0 ? '${name}-ui' : ''
var gtwBackendSettingAPI = aiUnlimitedGrpcPort != 0 ? '${name}-api' : ''
var gtwBackendSettingSchedulerHttp = aiUnlimitedSchedulerHttpPort != 0 ? '${name}-scheduler-http' : ''
var gtwBackendSettingSchedulerGrpc = aiUnlimitedSchedulerGrpcPort != 0 ? '${name}-scheduler-grpc' : ''
var gtwBackendSettingJupyter = jupyterHttpPort != 0 ? '${name}-jupyter' : ''
var gtwBackendProtocol = 'Http'
var gtwBackendPool = '${name}-ai-engine'

resource applicationGateWay 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: '${name}-gtw'
  location: location
  identity: gtwSSLCertSecretUri != ''
    ? {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', gtwMSI)}': {}
        }
      }
    : null
  properties: {
    sku: {
      name: gatewaySKU
      tier: gatewaySKU
    }
    gatewayIPConfigurations: [
      {
        name: '${name}-gtw-config'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, gtwPublicSubnet)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: gtwFrontEndIPConfigName
        properties: {
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', gtwPublicIP)
          }
        }
      }
    ]
    frontendPorts: flatten([
      aiUnlimitedHttpPort != 0
        ? [
            {
              name: gtwBackendSettingUI
              properties: {
                port: aiUnlimitedHttpPort
              }
            }
          ]
        : []
      aiUnlimitedGrpcPort != 0
        ? [
            {
              name: gtwBackendSettingAPI
              properties: {
                port: aiUnlimitedGrpcPort
              }
            }
          ]
        : []
      jupyterHttpPort != 0
        ? [
            {
              name: gtwBackendSettingJupyter
              properties: {
                port: jupyterHttpPort
              }
            }
          ]
        : []
      aiUnlimitedSchedulerHttpPort != 0
        ? [
            {
              name: gtwBackendSettingSchedulerHttp
              properties: {
                port: aiUnlimitedSchedulerHttpPort
              }
            }
          ]
        : []
      aiUnlimitedSchedulerGrpcPort != 0
        ? [
            {
              name: gtwBackendSettingSchedulerGrpc
              properties: {
                port: aiUnlimitedSchedulerGrpcPort
              }
            }
          ]
        : []
    ])
    backendAddressPools: [
      {
        name: gtwBackendPool
        properties: {
          backendAddresses: [
            {
              ipAddress: serviceIP
            }
          ]
        }
      }
    ]
    sslCertificates: flatten([
      gtwSSLCertSecretUri == ''
        ? (gtwSSLCertPwd == ''
            ? [
                {
                  name: gtwListenerCert
                  properties: {
                    data: gtwSSLCert
                  }
                }
              ]
            : [
                {
                  name: gtwListenerCert
                  properties: {
                    data: gtwSSLCert
                    password: gtwSSLCertPwd
                  }
                }
              ])
        : [
            {
              name: gtwListenerCert
              properties: {
                keyVaultSecretId: gtwSSLCertSecretUri
              }
            }
          ]
    ])
    probes: flatten([
      aiUnlimitedSchedulerHttpPort != 0 
        ? [
            {
              name: gtwBackendSettingSchedulerHttp
              properties: {
                host: gtwBackendPool
                path: '/healthcheck'
                protocol: gtwBackendProtocol
                timeout: 30
                interval: 30
                unhealthyThreshold: 3
              }
            }
        ]
      : []
    ])
    backendHttpSettingsCollection: flatten([
      aiUnlimitedHttpPort != 0
        ? [
            {
              name: gtwBackendSettingUI
              properties: {
                port: aiUnlimitedHttpPort
                protocol: gtwBackendProtocol
                cookieBasedAffinity: 'Disabled'
                pickHostNameFromBackendAddress: false
                requestTimeout: 20
              }
            }
          ]
        : []
      aiUnlimitedGrpcPort != 0
        ? [
            {
              name: gtwBackendSettingAPI
              properties: {
                port: aiUnlimitedGrpcPort
                protocol: gtwBackendProtocol
                cookieBasedAffinity: 'Disabled'
                pickHostNameFromBackendAddress: false
                requestTimeout: 20
              }
            }
          ]
        : []
      jupyterHttpPort != 0
        ? [
            {
              name: gtwBackendSettingJupyter
              properties: {
                port: jupyterHttpPort
                protocol: gtwBackendProtocol
                cookieBasedAffinity: 'Disabled'
                pickHostNameFromBackendAddress: false
                requestTimeout: 20
              }
            }
          ]
        : []
      aiUnlimitedSchedulerHttpPort != 0
        ? [
            {
              name: gtwBackendSettingSchedulerHttp
              properties: {
                port: aiUnlimitedSchedulerHttpPort
                protocol: gtwBackendProtocol
                probe: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/probes', 
                    gatewayName, 
                    gtwBackendSettingSchedulerHttp
                  )
                }
                probeEnabled: true
                cookieBasedAffinity: 'Disabled'
                pickHostNameFromBackendAddress: false
                requestTimeout: 20
              }
            }
          ]
        : []
      aiUnlimitedSchedulerGrpcPort != 0
        ? [
            {
              name: gtwBackendSettingSchedulerGrpc
              properties: {
                port: aiUnlimitedSchedulerGrpcPort
                protocol: gtwBackendProtocol
                cookieBasedAffinity: 'Disabled'
                pickHostNameFromBackendAddress: false
                requestTimeout: 20
              }
            }
          ]
        : []
    ])
    httpListeners: flatten([
      aiUnlimitedHttpPort != 0
        ? [
            {
              name: gtwBackendSettingUI
              properties: {
                frontendIPConfiguration: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendIPConfigurations',
                    gatewayName,
                    gtwFrontEndIPConfigName
                  )
                }
                frontendPort: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendPorts',
                    gatewayName,
                    gtwBackendSettingUI
                  )
                }
                sslCertificate: {
                  id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', gatewayName, gtwListenerCert)
                }
                protocol: 'Https'
                requireServerNameIndication: false
              }
            }
          ]
        : []
      aiUnlimitedGrpcPort != 0
        ? [
            {
              name: gtwBackendSettingAPI
              properties: {
                frontendIPConfiguration: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendIPConfigurations',
                    gatewayName,
                    gtwFrontEndIPConfigName
                  )
                }
                frontendPort: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendPorts',
                    gatewayName,
                    gtwBackendSettingAPI
                  )
                }
                sslCertificate: {
                  id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', gatewayName, gtwListenerCert)
                }
                protocol: 'Https'
                requireServerNameIndication: false
              }
            }
          ]
        : []
      jupyterHttpPort != 0
        ? [
            {
              name: gtwBackendSettingJupyter
              properties: {
                frontendIPConfiguration: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendIPConfigurations',
                    gatewayName,
                    gtwFrontEndIPConfigName
                  )
                }
                frontendPort: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendPorts',
                    gatewayName,
                    gtwBackendSettingJupyter
                  )
                }
                sslCertificate: {
                  id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', gatewayName, gtwListenerCert)
                }
                protocol: 'Https'
                requireServerNameIndication: false
              }
            }
          ]
        : []
      aiUnlimitedSchedulerHttpPort != 0
        ? [
            {
              name: gtwBackendSettingSchedulerHttp
              properties: {
                frontendIPConfiguration: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendIPConfigurations',
                    gatewayName,
                    gtwFrontEndIPConfigName
                  )
                }
                frontendPort: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendPorts',
                    gatewayName,
                    gtwBackendSettingSchedulerHttp
                  )
                }
                // sslCertificate: {
                //   id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', gatewayName, gtwListenerCert)
                // }
                protocol: 'Http'
                requireServerNameIndication: false
              }
            }
          ]
        : []
      aiUnlimitedSchedulerGrpcPort != 0
        ? [
            {
              name: gtwBackendSettingSchedulerGrpc
              properties: {
                frontendIPConfiguration: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendIPConfigurations',
                    gatewayName,
                    gtwFrontEndIPConfigName
                  )
                }
                frontendPort: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/frontendPorts',
                    gatewayName,
                    gtwBackendSettingSchedulerGrpc
                  )
                }
                // sslCertificate: {
                //   id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', gatewayName, gtwListenerCert)
                // }
                protocol: 'Http'
                requireServerNameIndication: false
              }
            }
          ]
        : []
    ])
    requestRoutingRules: flatten([
      aiUnlimitedHttpPort != 0
        ? [
            {
              name: gtwBackendSettingUI
              properties: {
                ruleType: 'Basic'
                httpListener: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/httpListeners',
                    gatewayName,
                    gtwBackendSettingUI
                  )
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    gatewayName,
                    gtwBackendPool
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    gatewayName,
                    gtwBackendSettingUI
                  )
                }
              }
            }
          ]
        : []
      aiUnlimitedGrpcPort != 0
        ? [
            {
              name: gtwBackendSettingAPI
              properties: {
                ruleType: 'Basic'
                httpListener: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/httpListeners',
                    gatewayName,
                    gtwBackendSettingAPI
                  )
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    gatewayName,
                    gtwBackendPool
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    gatewayName,
                    gtwBackendSettingAPI
                  )
                }
              }
            }
          ]
        : []
      jupyterHttpPort != 0
        ? [
            {
              name: gtwBackendSettingJupyter
              properties: {
                ruleType: 'Basic'
                httpListener: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/httpListeners',
                    gatewayName,
                    gtwBackendSettingJupyter
                  )
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    gatewayName,
                    gtwBackendPool
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    gatewayName,
                    gtwBackendSettingJupyter
                  )
                }
              }
            }
          ]
        : []
      aiUnlimitedSchedulerHttpPort != 0
        ? [
            {
              name: gtwBackendSettingSchedulerHttp
              properties: {
                ruleType: 'Basic'
                httpListener: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/httpListeners',
                    gatewayName,
                    gtwBackendSettingSchedulerHttp
                  )
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    gatewayName,
                    gtwBackendPool
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    gatewayName,
                    gtwBackendSettingSchedulerHttp
                  )
                }
              }
            }
          ]
        : []
      aiUnlimitedSchedulerGrpcPort != 0
        ? [
            {
              name: gtwBackendSettingSchedulerGrpc
              properties: {
                ruleType: 'Basic'
                httpListener: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/httpListeners',
                    gatewayName,
                    gtwBackendSettingSchedulerGrpc
                  )
                }
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    gatewayName,
                    gtwBackendPool
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    gatewayName,
                    gtwBackendSettingSchedulerGrpc
                  )
                }
              }
            }
          ]
        : []
    ])
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 2
    }
  }
  tags: tags
}
