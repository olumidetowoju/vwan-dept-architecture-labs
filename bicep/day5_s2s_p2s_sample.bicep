// day5_s2s_p2s_sample.bicep (vWAN-corrected)
// Fixes:
//  - Removed unsupported `sku` from Microsoft.Network/vpnGateways (vWAN).
//  - Removed Microsoft.Network/vpnSites/vpnSiteLinks child (not supported to PUT).
//  - Kept API versions aligned and minimal properties for vWAN.

@description('Name of the existing Virtual Hub (created on Day 2).')
param vhubName string

@description('Location (use the vHub location, e.g., eastus).')
param location string = resourceGroup().location

@description('Toggle to deploy Site-to-Site (S2S) resources.')
param deployS2S bool = false

@description('Toggle to deploy Point-to-Site (P2S) resources.')
param deployP2S bool = false

// ----- S2S inputs -----
@description('VPN Site (branch) name.')
param siteName string = 'clab-dev-site-branch1'

@description('Public IP of branch device. Use a real public IP for real deployments.')
param sitePublicIp string = '203.0.113.10'

@description('Address space reachable at the branch (LAN).')
param siteAddressPrefixes array = [
  '192.168.10.0/24'
]

@description('Name of the vHub S2S VPN Gateway to create.')
param s2sGatewayName string = 'clab-dev-s2s-gw'

@description('Gateway scale unit (keep 1 for cost control).')
param s2sScaleUnit int = 1

@secure()
@description('Pre-shared key used for the S2S connection.')
param s2sPsk string = 'P@ssw0rd-ChangeMe!'  // replace for real deployments

// ----- P2S inputs -----
@description('VPN Server Configuration name for P2S.')
param vpnServerConfigName string = 'clab-dev-vpnservercfg'

@description('P2S Gateway name.')
param p2sGatewayName string = 'clab-dev-p2s-gw'

@description('Address pool assigned to P2S clients.')
param p2sClientPool array = [
  '172.16.0.0/24'
]

@description('Root certificate name for P2S (certificate auth).')
param rootCertName string = 'clabRoot'

// NOTE: This must be the Base64 of the root CA cert (DER/PEM body only, no headers) for real deploys.
@description('Base64-encoded public root certificate for P2S (no BEGIN/END headers).')
param rootCertData string = 'MIIC...REPLACEME...'

// Refs
var vhubId = resourceId('Microsoft.Network/virtualHubs', vhubName)

// =======================
// S2S Resources (optional)
// =======================
@description('VPN Site (branch identity).')
resource vpnSite 'Microsoft.Network/vpnSites@2023-09-01' = if (deployS2S) {
  name: siteName
  location: location
  properties: {
    // For vWAN, a default vpnSiteLink is created automatically by the platform.
    ipAddress: sitePublicIp
    addressSpace: {
      addressPrefixes: siteAddressPrefixes
    }
    // virtualWan reference is optional for vHub connection scenarios.
  }
}

@description('vHub S2S VPN Gateway.')
resource s2sGateway 'Microsoft.Network/vpnGateways@2023-09-01' = if (deployS2S) {
  name: s2sGatewayName
  location: location
  properties: {
    virtualHub: {
      id: vhubId
    }
    // vWAN gateway capacity is managed via scaleUnit on the connection/gateway plane.
    // No `sku` for vWAN vpnGateways.
  }
}

@description('S2S connection from vHub gateway to branch VPN Site (vWAN)')
resource s2sConnection 'Microsoft.Network/vpnGateways/vpnConnections@2023-09-01' = if (deployS2S) {
  name: '${s2sGatewayName}/${siteName}'
  properties: {
    remoteVpnSite: {
      id: vpnSite.id
    }
    // For vWAN, omit 'connectionType'. The platform assumes IPsec automatically.
    vpnLinkConnections: [
      {
        name: 'link1'
        properties: {
          sharedKey: s2sPsk
        }
      }
    ]
  }
  dependsOn: [
    s2sGateway
    vpnSite
  ]
}

// =======================
// P2S Resources (optional)
// =======================
@description('VPN Server Configuration (certificate auth).')
resource vpnServerCfg 'Microsoft.Network/vpnServerConfigurations@2023-09-01' = if (deployP2S) {
  name: vpnServerConfigName
  location: location
  properties: {
    vpnProtocols: [
      'OpenVPN'
    ]
    vpnAuthenticationTypes: [
      'Certificate'
    ]
    clientRootCertificates: [
      {
        name: rootCertName
        publicCertData: rootCertData
      }
    ]
  }
}

@description('vHub P2S VPN Gateway.')
resource p2sGateway 'Microsoft.Network/p2sVpnGateways@2023-09-01' = if (deployP2S) {
  name: p2sGatewayName
  location: location
  properties: {
    virtualHub: {
      id: vhubId
    }
    vpnServerConfiguration: {
      id: vpnServerCfg.id
    }
    scaleUnit: 1
    vpnClientAddressPool: {
      addressPrefixes: p2sClientPool
    }
}

// =======================
// Outputs
// =======================
output vhubResourceId string = vhubId
output s2sGatewayId string = deployS2S ? s2sGateway.id : 'not-deployed'
output p2sGatewayId string = deployP2S ? p2sGateway.id : 'not-deployed'
