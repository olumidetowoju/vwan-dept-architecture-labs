// day5_s2s_only.bicep — vWAN S2S (vpnSite + vHub vpnGateway + connection)

@description('Existing Virtual Hub name (from Day 2), e.g., clab-dev-hub-eastus')
param vhubName string

@description('Location (match your vHub region)')
param location string = resourceGroup().location

@description('Branch VPN site name')
param siteName string = 'clab-dev-site-branch1'

@description('Branch device public IP (replace with your real IP)')
param sitePublicIp string

@description('LAN prefixes reachable at the branch')
param siteAddressPrefixes array = [
  '192.168.10.0/24'
]

@secure()
@description('Pre-shared key for the S2S tunnel')
param s2sPsk string

var vhubId = resourceId('Microsoft.Network/virtualHubs', vhubName)

@description('VPN Site (branch identity)')
resource vpnSite 'Microsoft.Network/vpnSites@2023-09-01' = {
  name: siteName
  location: location
  properties: {
    ipAddress: sitePublicIp
    addressSpace: {
      addressPrefixes: siteAddressPrefixes
    }
  }
}

@description('vHub S2S VPN Gateway (vWAN)')
resource s2sGateway 'Microsoft.Network/vpnGateways@2023-09-01' = {
  name: 'clab-dev-s2s-gw'
  location: location
  properties: {
    virtualHub: {
      id: vhubId
    }
  }
}


output vhubResourceId string = vhubId
output vpnSiteId string = vpnSite.id
output s2sGatewayId string = s2sGateway.id
