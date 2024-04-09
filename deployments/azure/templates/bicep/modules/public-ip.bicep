param name string
param location string
param dnsPrefix string
param tags object

resource ip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    dnsSettings: dnsPrefix != '' ? {
      domainNameLabel: dnsPrefix
    } : null
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 5
  }
  tags: tags
}

output Id string = ip.id
output Ip string = ip.properties.ipAddress
output Dns string = dnsPrefix != '' ? ip.properties.dnsSettings.fqdn : ''
