@description('Name for the jupyter service virtual machine.')
param jupyterName string = 'jupyter'

@description('SSH public key value')
@secure()
param sshPublicKey string

@description('jupyter token value')
@secure()
param jupyterToken string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  'Ubuntu-1804'
  'Ubuntu-2004'
  'Ubuntu-2204'
])
param ubuntuOSVersion string = 'Ubuntu-2004'

@description('The size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('ID of the subnet in the virtual network')
param networkName string

@description('ID of the subnet in the virtual network')
param subnetName string

@description('The CIDR ranges that can be used to communicate with the jupyter instance.')
param accessCidrs array = ['0.0.0.0/0']

@description('port to access the jupyter service UI.')
param httpPort string = '8888'

@description('allow access the jupyter ssh port from the access cidr.')
param sshAccess bool = true

var imageReference = {
  'Ubuntu-1804': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}
var publicIPAddressName = '${jupyterName}PublicIP'
var networkInterfaceName = '${jupyterName}NetInt'
var networkSecurityGroupName = '${jupyterName}SecGroup'

var osDiskType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/azureuser/.ssh/authorized_keys'
        keyData: sshPublicKey
      }
    ]
  }
}

var trustedExtensionName = 'GuestAttestation'
var trustedExtensionPublisher = 'Microsoft.Azure.Security.LinuxAttestation'
var trustedExtensionVersion = '1.0'
var trustedMaaTenantName = 'GuestAttestation'
var trustedMaaEndpoint = substring('emptystring', 0, 0)
var dockerExtensionName = 'DockerExtension'
var dockerExtensionPublisher = 'Microsoft.Azure.Extensions'
var dockerExtensionVersion = '1.1'

var registry = 'teradata'
var repository = 'ai-unlimited-jupyter'
var version = 'latest'
var cloudInitData = base64(
  format(
    loadTextContent('templates/jupyter.cloudinit.yaml'), 
    base64(
      format(
        loadTextContent('templates/jupyter.service'),
        registry,
        repository,
        version,
        httpPort,
        jupyterToken
      )
    )
  )
)

resource network 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: networkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  parent: network
  name: subnetName
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: networkInterfaceName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: networkSecurityGroupName
  location: resourceGroup().location
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
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: publicIPAddressName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: uniqueString(resourceGroup().id, deployment().name, jupyterName)
    }
    idleTimeoutInMinutes: 4
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: jupyterName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    
    osProfile: {
      computerName: jupyterName
      adminUsername: 'azureuser'
      linuxConfiguration: linuxConfiguration
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    userData: cloudInitData
  }
}

resource jupyterName_extension_trusted 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: vm
  name: trustedExtensionName
  location: resourceGroup().location
  properties: {
    publisher: trustedExtensionPublisher
    type: trustedExtensionName
    typeHandlerVersion: trustedExtensionVersion
    autoUpgradeMinorVersion: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: trustedMaaEndpoint
          maaTenantName: trustedMaaTenantName
        }
      }
    }
  }
}

resource jupyterName_extension_docker 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: vm
  name: dockerExtensionName
  location: resourceGroup().location
  properties: {
    publisher: dockerExtensionPublisher
    type: dockerExtensionName
    typeHandlerVersion: dockerExtensionVersion
    autoUpgradeMinorVersion: true
  }
}

output PublicIP string = publicIPAddress.properties.ipAddress
output PrivateIP string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
output PublicHttpAccess string = 'http://${ publicIPAddress.properties.ipAddress }:${ httpPort }?token=${ jupyterToken }'
output PrivateHttpAccess string = 'http://${ networkInterface.properties.ipConfigurations[0].properties.privateIPAddress }:${ httpPort }'
output sshCommand string = 'ssh azureuser@${ publicIPAddress.properties.ipAddress }'
