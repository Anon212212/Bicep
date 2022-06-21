param location string ='northeurope'
param dateTime string = utcNow('d')
param prefix string 
param tickettag string
param CostcenterTag string
param CreatedBy string
param Enviroment string
param resourceTags object = {
  Ticket: tickettag
  CostCenter: CostcenterTag
  CreationDate: dateTime
  Environment: environment()
  Engineer : CreatedBy
}





resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${prefix}VNET'
  location: location
  tags:resourceTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: '${prefix}LAN-000'
        properties: {
          addressPrefix:'10.100.0.0/24'
    
        }
      }
      {
        name: '${prefix}LAN-001'
        properties: {
          addressPrefix:'10.100.1.0/24'
        }
      }
      {
      name:'${prefix}LAN-002'
      properties: {
        addressPrefix:'10.100.2.0/24'
      } 
      }
      {
        name:'${prefix}LAN-003'
        properties: {
          addressPrefix:'10.100.3.0/24'
        }
      }
    ]
  }
}
