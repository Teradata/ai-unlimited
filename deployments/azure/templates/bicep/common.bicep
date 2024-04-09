// // once https://github.com/Azure/bicep/issues/11096 is done this can be used

// // below are static and are not expected to be changed
// @export()
// var registry = 'teradata'

// @export()
// var workspaceRepository = 'ai-unlimited-workspaces'

// @export()
// var jupyterRepository = 'ai-unlimited-jupyter'

// @export()
// var adminUsername = 'azureuser'

// @export()
// func buildAiCloudInitData(registry string, wsRepo string, version string, httpPort int, grpcPort int, dns string) string => base64(format(
//   loadTextContent('../../scripts/ai-unlimited.cloudinit.yaml'),
//   base64(format(
//     loadTextContent('../../scripts/ai-unlimited.service'),
//     registry, wsRepo, version, httpPort, grpcPort,
//     subscription().subscriptionId,
//     subscription().tenantId,
//     '--network-alias ${dns}'
//   ))
// ))
