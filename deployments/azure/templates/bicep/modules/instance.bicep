param location string
param name string
param adminUsername string
param sshPublicKey string
param vmSize string
param subnetId string
param networkSecurityGroupID string
param osVersion string
param usePersistentVolume string
param persistentVolumeSize int
param existingPersistentVolume string
param cloudInitData string

param usePublicIp bool = false
param nlbName string = ''
param albName string = ''
param nlbPoolNames array = []
param tags object = {}
param dnsLabelPrefix string = ''

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

var publicIPAddressName = '${name}PublicIP'
var networkInterfaceName = '${name}-nic'
var osDiskType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
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

var resourcePools = [
  for poolName in nlbPoolNames: {
    id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', nlbName, poolName)
  }
]

resource existingPersistentDisk 'Microsoft.Compute/disks@2023-04-02' existing =
  if (usePersistentVolume == 'Existing') {
    name: existingPersistentVolume
  }

resource newPersistentDisk 'Microsoft.Compute/disks@2023-04-02' =
  if (usePersistentVolume == 'New') {
    location: location
    name: '${name}-disk'
    tags: tags
    properties: {
      creationData: {
        createOption: 'Empty'
      }
      diskSizeGB: persistentVolumeSize
      maxShares: 1
      osType: 'Linux'
    }
  }

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: networkInterfaceName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      usePublicIp
        ? {
            name: 'ipconfigpublic'
            properties: {
              privateIPAllocationMethod: 'Dynamic'
              subnet: {
                id: subnetId
              }
              publicIPAddress: {
                id: publicIP.outputs.Id
              }
              loadBalancerBackendAddressPools: resourcePools
            }
          }
        : albName == ''
            ? {
                name: 'ipconfigprivate'
                properties: {
                  privateIPAllocationMethod: 'Dynamic'
                  subnet: {
                    id: subnetId
                  }
                  loadBalancerBackendAddressPools: resourcePools
                }
              }
            : {
                name: 'ipconfigprivate'
                properties: {
                  privateIPAllocationMethod: 'Dynamic'
                  subnet: {
                    id: subnetId
                  }
                }
              }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupID
    }
  }
}

module publicIP 'public-ip.bicep' =
  if (usePublicIp) {
    name: publicIPAddressName
    params: {
      name: publicIPAddressName
      location: location
      dnsPrefix: dnsLabelPrefix
      tags: tags
    }
  }

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: name
  location: location
  tags: tags
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
      dataDisks: usePersistentVolume == 'None'
        ? []
        : [
            {
              lun: 0
              createOption: 'Attach'
              managedDisk: {
                id: usePersistentVolume == 'New' ? newPersistentDisk.id : existingPersistentDisk.id
              }
            }
          ]
      imageReference: imageReference[osVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }

    osProfile: {
      computerName: name
      adminUsername: adminUsername
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

resource ai_unlimited_extension_trusted 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: vm
  name: trustedExtensionName
  tags: tags
  location: location
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

resource ai_unlimited_extension_docker 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: vm
  name: dockerExtensionName
  tags: tags
  location: location
  properties: {
    publisher: dockerExtensionPublisher
    type: dockerExtensionName
    typeHandlerVersion: dockerExtensionVersion
    autoUpgradeMinorVersion: true
  }
}

output PublicIP string = usePublicIp ? publicIP.outputs.Ip : ''
output PrivateIP string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
output PrincipleId string = vm.identity.principalId
