@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string
param dateTime string = utcNow('d')
param tickettag string
param CreatedBy string
param Enviroment string
param vnetname string
param subnetname string 
param resourceTags object = {
  Ticket: tickettag
  CreationDate: dateTime
  Environment: Enviroment
  Engineer : CreatedBy
}


@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')
/*
@description('Name for the Public IP used to access the Virtual Machine.')
param publicIpName string = 'CCU-PIP-01'*/
/*
@description('Allocation method for the Public IP used to access the Virtual Machine.')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'


@description('SKU for the Public IP used to access the Virtual Machine.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'*/

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
'2019-Datacenter'
'2019-Datacenter-Core'
'2019-datacenter-core-g2'
'2019-Datacenter-Core-smalldisk'
'2019-datacenter-core-smalldisk-g2'
'2019-Datacenter-Core-with-Containers'
'2019-datacenter-core-with-containers-g2'
'2019-Datacenter-Core-with-Containers-smalldisk'
'2019-datacenter-core-with-containers-smalldisk-g2'
'2019-datacenter-gensecond'
'2019-datacenter-gs'
'2019-Datacenter-smalldisk'
'2019-datacenter-smalldisk-g2'
'2019-Datacenter-with-Containers'
'2019-datacenter-with-containers-g2'
'2019-datacenter-with-containers-gs'
'2019-Datacenter-with-Containers-smalldisk'
'2019-datacenter-with-containers-smalldisk-g2'
'2019-Datacenter-zhcn'
'2019-datacenter-zhcn-g2'
'2022-datacenter'
'2022-datacenter-azure-edition'
'2022-datacenter-azure-edition-core'
'2022-datacenter-azure-edition-core-smalldisk'
'2022-datacenter-azure-edition-smalldisk'
'2022-datacenter-core'
'2022-datacenter-core-g2'
'2022-datacenter-core-smalldisk'
'2022-datacenter-core-smalldisk-g2'
'2022-datacenter-g2'
'2022-datacenter-smalldisk'
'2022-datacenter-smalldisk-g2'
])
param OSVersion string = '2022-datacenter'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2as_v4'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string = 'CCU-AZ-R1'

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = 'VMNic1'
var networkSecurityGroupName = 'default-NSG'

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

/*resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}*/

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
resource vn1 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetname
}

resource sub 'Microsoft.Network/virtualnetworks/subnets@2015-06-15' existing = {
  parent:vn1
  name: subnetname
}
/*
resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: CCUVNET
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
    ]
  }
}
*/
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vn1.name, sub.name)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
   tags:resourceTags
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 128
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}


