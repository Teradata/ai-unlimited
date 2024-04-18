# AI Unlimited and Jupyter Deployments for Azure

This directory contains sample Azure Resource Manager templates to deploy AI Unlimited and Jupyter.

## Prerequisites

### Private Preview Access
AI Unlimited is currently only available as a private prview for select customers. 
Before deploying any AI Unlimited compute engines, Teradata must enable your azure subscription for access to the compute engine image.

To request access see [AI Unlimited](https://www.teradata.com/platform/ai-unlimited).

### Private Preview Marketplace Agreement
Once your subscription has been enabled, you will be able to verify the marketplace offering is available with the Azure command line client.

- Ensure that your az cli is configured for the subscription, and that your user has adequate permissions to view and accept marketplace offers.
- Verify the offer is present via the az cli
```
az vm image list --publisher teradata --offer teradata-ai-unlimited --all -o table
```
- this should return a value including the latest image
```
Architecture    Offer                  Publisher    Sku              Urn                                                    Version
--------------  ---------------------  -----------  ---------------  -----------------------------------------------------  ---------
x64             teradata-ai-unlimited  teradata     td-ai-unlimited  teradata:teradata-ai-unlimited:td-ai-unlimited:0.12.3  0.12.3
```

- To review the terms and conditions run the following command
```
az vm image terms show --publisher teradata --offer teradata-ai-unlimited --plan td-ai-unlimited -o table
```
- Which will return links to the current terms and conditions
```
Accepted    LicenseTextLink                                                                                                                                                                                                                                                           MarketplaceTermsLink                                                                                                                                                                                              Name             Plan             PrivacyPolicyLink                  Product                Publisher    RetrieveDatetime              Signature
----------  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  ---------------  ---------------  ---------------------------------  ---------------------  -----------  ----------------------------  -------------------------------------------------------------------------------------------------------
False        https://mpcprodsa.blob.core.windows.net/legalterms/3E5ED_legalterms_TERADATA%253a24TERADATA%253a2DAI%253a2DUNLIMITED%253a24TD%253a2DAI%253a2DUNLIMITED%253a24IDLJU3KC7LWWPGNVHPQGIXJBRGXCG752HYIQCDUUPHYXJIC2Y52MBL24DTXMKZ5U7RYBLW75MZPJSYH4VG45NI6VPOHCCOZ5IO65KRY.txt  https://mpcprodsa.blob.core.windows.net/marketplaceterms/3EDEF_marketplaceterms_VIRTUALMACHINE%253a24AAK2OAIZEAWW5H4MSP5KSTVB6NDKKRTUBAU23BRFTWN4YC2MQLJUB5ZEYUOUJBVF3YK34CIVPZL2HWYASPGDUY5O2FWEGRBYOXWZE5Y.txt  td-ai-unlimited  td-ai-unlimited  https://www.teradata.com/privacy/  teradata-ai-unlimited  teradata     2024-03-28T20:00:44.4225873Z  DEKD3R5XGCXSRJYB7JWKNAOKXW55ZPVTDTIH333PMHILU4P3CJVZLUZBCHDZVYCFB6D7EJVKY3MP2J7BSKZU4K2W35YHMID4HN762CA
```
- when you are ready to accept the terms, run the following command via the azure cli

```
az vm image terms accept --publisher teradata --offer teradata-ai-unlimited --plan td-ai-unlimited
```

- Once the Marketplace offering has been accepted, you may proceed to deploying the AI Unlimited service.

## Azure Resource Manager (ARM) Templates

### AI Unlimited Template
The all in one template deploys a single instance with AI Unlimited running in a container controlled by systemd.
- [ai-unlimited.json](templates/arm/ai-unlimited/ai-unlimited-without-lb.json) ARM template 
- [ai-unlimited.json](parameters/ai-unlimited.parameters.json) parameter file

![arm_visualization](images/900_ai_unlimited_arm_visualization.png?raw=true)

### Jupyter Template
The all in one template deploys a single instance with Jupyter Lab running in a container controlled by systemd.
- [jupyter.json](templates/arm/jupyter/jupyter-without-lb.json) ARM template 
- [jupyter.json](parameters/jupyter.parameters.json) parameter file

![arm_visualization](images/901_jupyter_arm_visualization.png?raw=true)


### All-In-One Template
The all in one template deploys a single instance with both AI Unlimited and Jupyter running on the same instance.
It uses all the common parameters, as well as the additional parameters from AI Unlimited and Jupyter.

If deploying the all in one, it is possible to use the embedded Jupyter Lab service, or connect external Jupyter labs as well.
You must set the appropriate connection address in the Jupyter notebook, 127.0.0.1 if connecting from the embedded Jupyter service,
or appropriate public, private ip or dns name when connecting from external clients.
- [all-in-one.json](templates/arm/all-in-one/all-in-one-without-lb.json) ARM template 
- [all-in-one.json](parameters/all-in-one.parameters.json) parameter file

![arm_visualization](images/900_ai_unlimited_arm_visualization.png?raw=true)


### Resources Template
The resources template deploys a simple resource group, a role with permissions policy, a network, subnet, and optionally a subnet used for ALB. This is intended only for quick demonstration purposes and production deployments should use existing well defined and secure network best practices.
- [resources.json](templates/arm/init/resources.json) ARM template 
- [resources.json](parameters/resources.parameters.json) parameter file

![arm_visualization](images/902_resources_arm_visualization.png?raw=true)


### Role-Policy Template
The role-policy template creates the role with the required permissions for ai unlimited workspace.
- [role-policy.json](templates/arm/init/role-policy.json) ARM template 
- [role-policy.json](parameters/role-policy.parameters.json) parameter file

## Deployment via Azure Console

### Creating the Resource Group, Network and Role via ARM Custom Template Deployment

In the Azure Console,Search for "Deploy a Custom Template" and select the service icon.

![arm_create_new_resources](images/001_arm_create_new_resources.png?raw=true)

Select the "build your own template" link 

![arm_create_new_resources_custom_deployment](images/002_arm_create_new_resources_custom_deployment.png?raw=true)

In the edit the template dialog, select the "Load file" option.

![arm_create_new_resources_edit_template](images/003_arm_create_new_resources_edit_template.png?raw=true)

and select the resources.json template from the file picker dialog.

![arm_create_new_resources_file_picker](images/004_arm_create_new_resources_file_picker.png?raw=true)

With the file content loaded into the edit template dialog, select "Save"

![arm_create_new_resources_loaded_file](images/005_arm_create_new_resources_loaded_file.png?raw=true)

in the Custom deployment Dialog, select your Subscription.
Also set:
- The region to deploy in.
- The name to use for the created resources ( the resouce group, network, subnet and role will use this value as their name )
- The CIDR to use for the Network
- the CIDR to use for the Subnet in the new network
- the CIDR to use for the ALB Subnet in the new network
- the flag to deploy the ALB Subnet in the new network
- the tags to place on the network and subnet resources

Then select review and create

![arm_create_new_resources_project_details](images/006_arm_create_new_resources_project_details.png?raw=true)

review the information, confirm your settings, and select the create button.

![arm_create_new_resources_review_create](images/007_arm_create_new_resources_review_create.png?raw=true)

The template will proceed to deploy

![arm_create_new_resources_deployment_complete](images/008_arm_create_new_resources_deployment_complete.png?raw=true)

After the template has completed, select the output tab and make note of the network names and the `RoleDefinitionId`.
These value will be needed by the workspace deployment

![arm_create_new_resources_outputs](images/009_arm_create_new_resources_outputs.png?raw=true)

### Creating the All In One Deployment via ARM Custom Template Deployment

This template creates a single instance containing both AI Unlimited Workspace and Jupyter.
Note: The process for deploying AI Unlimited Workspace or Jupyter separately using their respective templates is nearly the same. 

In the Azure Console, Search for "Deploy a Custom Template" and select the service icon.

![arm_create_new_all_in_one](images/010_arm_create_new_all_in_one.png?raw=true)

Select the "build your own template" link 

![arm_create_new_all_in_one_custom_deployment](images/011_arm_create_new_all_in_one_custom_deployment.png?raw=true)

In the edit the template dialog, select the "Load file" option.

![arm_create_new_all_in_one_edit_template](images/012_arm_create_new_all_in_one_edit_template.png?raw=true)

and select the all-in-one.json template from the file picker dialog.

![arm_create_new_all_in_one_file_picker](images/013_arm_create_new_all_in_one_file_picker.png?raw=true)

With the file content loaded into the edit template dialog, select "Save"

![arm_create_new_all_in_one_loaded_file](images/014_arm_create_new_all_in_one_loaded_file.png?raw=true)

in the Custom Deployment Dialog, set values for
- The Region
- The Resource Group
- The Name to use for the created resources
- The ssh public key ( this should start with "ssh-rsa" )
- The OS Version of the AI Unlimited instance
- The instance type of the AI Unlimited instance
- The name of the network to deploy into
- The name of the subnet to deploy into
- The name of the security group we will create for the AI Unlimited instance
- The CIDRs that have permission to connect to the AI Unlimited instance
- The Ports for AI Unlimited HTTP and GRPC Access, and the Port used for HTTP to Jupyter
- The Source Application Security Groups that have permission to connect to the AI Unlimited instance
- The Destination Application Security Groups that have permission to connect to the AI Unlimited instance
- The RoleDefinitionId of the role to use with AI Unlimited
- Will you Allow ssh from the firewall?
- The options (New, None) to choose for using a key vault
- Will you use a persistent volume for storing the AI Unlimited and Jupyter data?
- If using a persistent volume, what size should it be?
- If you are using an existing persistent volume, what is the volume Id?
- The version of AI Unlimited
- The version of Jupyter
- The token to use for Jupyter authentication
- The tags to place on the resources created from this deployment

Then select review and create

![arm_create_new_all_in_one_project_details](images/015_arm_create_new_all_in_one_project_details.png?raw=true)

review the information, confirm your settings, and select the create button.

![arm_create_new_all_in_one_review_create](images/016_arm_create_new_all_in_one_review_create.png?raw=true)

The template will proceed to deploy

![arm_create_new_all_in_one_deployment_complete](images/017_arm_create_new_all_in_one_deployment_complete.png?raw=true)

After the template has completed, connection parameters to AI Unlimited Workspace and Jupyter with the AI Unlimited kernel are will be available in the ouput tab.

![arm_create_new_all_in_one_ouputs](images/018_arm_create_new_all_in_one_ouputs.png?raw=true)

## Configuring AI Unlimited

Using the value of aiUnlimitedPublicHttpAccess from the Custom Deployment output tab, connect to the AI Unlimited UI in you browser.

![ai_unlimited_setup](images/020_ai_unlimited_setup.png?raw=true)

Replace the value of `Service Base URL` with the aiUnlimitedPublicHttpAccess value and click save.

![ai_unlimited_setup_update_url](images/021_ai_unlimited_setup_update_url.png?raw=true)

to enable tls for the connection between AI Unlimited abd Jupyter or the workspacectl client, change the `Use TLS` to True.

![ai_unlimited_setup_use_tls](images/022_ai_unlimited_setup_use_tls.png?raw=true)

then add your own TLS certs or the click generate tls button.

![ai_unlimited_setup_gen_tls](images/023_ai_unlimited_setup_gen_tls.png?raw=true)

then click save changes before proceeding to the next section.

![ai_unlimited_setup_tls_save](images/024_ai_unlimited_setup_tls_save.png?raw=true)


In the Cloud Integrations section, select the Azure tab and provide values for the fields.

- `default region` is the region where new compute engines will be created by default.
- `default network resource group` is the resource group where the network is created from resources.json
- `default network` is the name of the network created from resources.json
- `default subnet` is the name of the subnet created from resources.json
- `default key vault` is the resource group where the key vault created from resources.json
- `default key vault resource group` is the name of the key vault is created from resources.json
- `default CIDRs` are the network address ranges that will be allowed access to the compute engines.
- `default security groups` are the security groups that will be allowed access to the compute engines.
- `resource tag` are the tags to place on the new compute engines

In this example we are only setting the default region to westus (or "West US") and allowing access from all address ranges.
then click save changes before proceeding to the next section.

![ai_unlimited_setup_azure](images/025_ai_unlimited_setup_azure.png?raw=true)

then in the Git Integrations section provide your GitHub OAuth client ID and Client Secret and click Authenticate

![ai_unlimited_setup_github](images/026_ai_unlimited_setup_github.png?raw=true)

If you need to setup a Github Oauth first, proceed to your Github endpoint, and under your user, navigate to settings -> developer settings -> OAuth Apps, and create a new OAuth app.

Set the `Application Name` field to whatever you'd like to identify your workspace
Set the `Homepage URL` to the value of aiUnlimitedPublicHttpAccess from the deployment template output
Set the `Authorization callback URL` to the same value as `Application Name` with `/auth/github/callback` appended
and check the Enable Device Flow checkbox

![ai_unlimited_setup_github_oauth](images/027_ai_unlimited_setup_github_oauth.png?raw=true)

back in the Workspace UI, click authenticate and then Accept the permissions presented by github Oauth.
If successful you will be returned to your Workspace user page and presented with an API key for Workspace use.

![ai_unlimited_setup_api_key_and_restart](images/028_ai_unlimited_setup_api_key_and_restart.png?raw=true)

To ensure all settings are finalized and TLS is enabled on the client interface, click restart to finsh the workspace configuration.

## Configuring Jupyter

Using the value of JupyterLabPublicHttpAccess from the Custom Deployment output tab, connect to the Jupyter Lab UI in you browser. The output includes the access token, but you can also provide the token value directly you see the login page.

![jupyter_setup](images/030_jupyter_setup.png?raw=true)

Navigate to the Regulus Folder

![jupyter_setup_regulus_folder](images/031_jupyter_setup_regulus_folder.png?raw=true)

Open the Getting Started Notebook

![jupyter_setup_get_started](images/032_jupyter_setup_get_started.png?raw=true)

Set the `%workspaces_config` `host` to the value of AiUnlimitedPublicAPIAccess from the Custom Template outputs.

Set the `%workspaces_config` `apiKey` to the API key provided by AI Unlimited

Set the `%workspaces_config` `withtls` to `T` as we have enabled tls on AI Unlimited

![jupyter_setup_select_host](images/033_jupyter_setup_select_host.png?raw=true)

with the same text box selected, press shift+enter or click the play button on the menu bar.

Jupyter is now configured to communicate with the Workspace service.

![jupyter_setup_updated_host](images/034_jupyter_setup_updated_host.png?raw=true)

Now on the `%project_create` line, set a project name in the `project=` field and set the `env=` field to azure
with the same text box selected, press shift+enter or click the play button on the menu bar.

If github OAuth has been correctly configured, a project will be created in your github repo.

![jupyter_setup_project_create](images/035_jupyter_setup_project_create.png?raw=true)

Now on the `%project_list` line, press shift+enter or click the play button on the menu bar.

You should see your project included in the output table and have a working link back to the source repo.

![jupyter_setup_list](images/036_jupyter_setup_list.png?raw=true)

Now on the `%project_auth_create` line, set an authorization name in the `name=` field, set the `project=` field to your project name, set the `key=` field to your objectstore access key, set the `secret=` field to your objectstore access secret, and set the `region=` field to the region of your object store. Press shift+enter or click the play button on the menu bar to create the objectstore authorization.

![jupyter_setup_create_auth](images/037_jupyter_setup_create_auth.png?raw=true)

Verify the authorization using the `%project_auth_list` command, setting the `project=` field to your project name and pressing shift+enter or clicking the play button on the menu bar.

![jupyter_setup_auth_list](images/038_jupyter_setup_auth_list.png?raw=true)

Deploy your first engine with the `%project_engine_deploy` command, setting the `project=` field to your project name and pressing shift+enter or clicking the play button on the menu bar.

![jupyter_setup_start_deploy](images/039_jupyter_setup_start_deploy.png?raw=true)

### ARM use CLI

TODO: Pending updates for use with Deployment Manager


## Using a Persistent Volume
The default behavior is to use the root volume of the instace for storage. This will persist any Jupyter notebook data saved under the userdata folder and the AI Unlimited database and configuration files. If the instance is rebooted, shutdown and restarted, or snapshot and relaunched, your data will persist. If the instance is terminated, your Jupyter notebook data and/or AI Unlimited database will be lost. 
This can be especially problematic if running on spot instances which may be terminated without warning. If greater persistency is desired,
You can enable the UsePersistentVolume parameter to move the Jupyter notebook data and/or AI Unlimited database to a separate volume.

### Suggested Persistent Volume Flow
1. Create a new deployment with UsePersistentVolume=New
2. Configure and use the instance until the instance is terminated.
3. On the next deployment, use UsePersistentVolume=New, ExistingPersistentVolumeId to the volume-id from the first deploy

This will remount the volume, and the instance will have the previous data available. This template can be relaunched with the same config whenever you need to recreate the instance with the previous data.

## Example Role Policies 
If the account deploying AI Unlimited does not have sufficient IAM permissions to create the roles,
The roles and can be defined prior to deployment and passed into the AI Unlimited template.

For AI Unlimited, a Role would need the following policies:
### [ai-unlimited.json](policies/ai-unlimited.json)
which includes the permissions needed to create ai-unlimited instances and grants AI Unlimited the
permissions to create cluster specific IAM roles and policies for the AI Unlimited Engines it 
will deploy.
```
{
  "properties": {
    "roleName": "Teradata AI-Unlimited Workspace Deployment Permissions",
    "description": "Subscription level permissions for the Workspace service to create AI-Unlimited Engine deployments with their own resource groups",
    "assignableScopes": [
      "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
    ],
    "permissions": [
      {
        "actions": [
          "Microsoft.Compute/disks/read",
          "Microsoft.Compute/disks/write",
          "Microsoft.Compute/disks/delete",
          "Microsoft.Compute/sshPublicKeys/read",
          "Microsoft.Compute/sshPublicKeys/write",
          "Microsoft.Compute/sshPublicKeys/delete",
          "Microsoft.Compute/virtualMachines/read",
          "Microsoft.Compute/virtualMachines/write",
          "Microsoft.Compute/virtualMachines/delete",
          "Microsoft.KeyVault/vaults/read",
          "Microsoft.KeyVault/vaults/write",
          "Microsoft.KeyVault/vaults/delete",
          "Microsoft.KeyVault/vaults/accessPolicies/write",
          "Microsoft.KeyVault/locations/operationResults/read",
          "Microsoft.KeyVault/locations/deletedVaults/purge/action",
          "Microsoft.ManagedIdentity/userAssignedIdentities/delete",
          "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
          "Microsoft.ManagedIdentity/userAssignedIdentities/listAssociatedResources/action",
          "Microsoft.ManagedIdentity/userAssignedIdentities/read",
          "Microsoft.ManagedIdentity/userAssignedIdentities/write",
          "Microsoft.Network/applicationSecurityGroups/read",
          "Microsoft.Network/applicationSecurityGroups/write",
          "Microsoft.Network/applicationSecurityGroups/joinIpConfiguration/action",
          "Microsoft.Network/applicationSecurityGroups/delete",
          "Microsoft.Network/virtualNetworks/read",
          "Microsoft.Network/virtualNetworks/write",
          "Microsoft.Network/virtualNetworks/delete",
          "Microsoft.Network/virtualNetworks/subnets/read",
          "Microsoft.Network/virtualNetworks/subnets/write",
          "Microsoft.Network/virtualNetworks/subnets/delete",
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/networkInterfaces/read",
          "Microsoft.Network/networkInterfaces/write",
          "Microsoft.Network/networkInterfaces/delete",
          "Microsoft.Network/networkInterfaces/join/action",
          "Microsoft.Network/networkSecurityGroups/read",
          "Microsoft.Network/networkSecurityGroups/write",
          "Microsoft.Network/networkSecurityGroups/delete",
          "Microsoft.Network/networkSecurityGroups/securityRules/read",
          "Microsoft.Network/networkSecurityGroups/securityRules/write",
          "Microsoft.Network/networkSecurityGroups/securityRules/delete",
          "Microsoft.Network/networkSecurityGroups/join/action",
          "Microsoft.Network/publicIPAddresses/read",
          "Microsoft.Network/publicIPAddresses/write",
          "Microsoft.Network/publicIPAddresses/join/action",
          "Microsoft.Network/publicIPAddresses/delete",
          "Microsoft.Resources/subscriptions/resourcegroups/read",
          "Microsoft.Resources/subscriptions/resourcegroups/write",
          "Microsoft.Resources/subscriptions/resourcegroups/delete",
          "Microsoft.Resources/deployments/read",
          "Microsoft.Resources/deployments/write",
          "Microsoft.Resources/deployments/delete",
          "Microsoft.Resources/deployments/operationStatuses/read",
          "Microsoft.Resources/deploymentStacks/read",
          "Microsoft.Resources/deploymentStacks/write",
          "Microsoft.Resources/deploymentStacks/delete"
        ],
        "notActions": [],
        "dataActions": [],
        "notDataActions": []
      }
    ]
  }
}
```
