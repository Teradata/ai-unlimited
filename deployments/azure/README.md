# Workspaces and Jupyter Deployments for Azure

This directory contains sample Azure Resource Manager templates to deploy Workspaces and Jupyter.

## Azure Resource Manager (ARM) Templates

### Workspaces Template
The all in one template deploys a single instance with Workspaces running in a container controlled by systemd.
- [workspaces.json](workspaces.json) cloudformation template 
- [parameters/workspaces.json](workspaces.json) parameter file

![arm_visualization](images/900_workspaces_arm_visualization.png?raw=true)

### Jupyter Template
The all in one template deploys a single instance with Jupyter Lab running in a container controlled by systemd.
- [jupyter.json](jupyter.json) cloudformation template 
- [parameters/jupyter.json](jupyter.json) parameter file

![arm_visualization](images/901_jupyter_arm_visualization.png?raw=true)


### All-In-One Template
The all in one template deploys a single instance with both Workspaces and Jupyter running on the same instance.
It uses all the common parameters, as well as the addiitonal parameters from Workspaces and Jupyter.

If deploying the all in one, it is possible to use the embedded Jupyter Lab service, or connect external Jupyter labs as well.
You must set the appropriate connection address in the Jupyter notebook, 127.0.0.1 if connecting from the embedded Jupyter service,
or appropriate public,private ip or dns name when connecting from external clients.
- [all-in-one.json](all-in-one.yaml) cloudformation template 
- [parameters/all-in-one.json](all-in-one.json) parameter file

![arm_visualization](images/900_workspaces_arm_visualization.png?raw=true)


### Resources Template
The resources template deploys a simple resource group, a role with permissions policy, a network and subnet. This is intended only for quick demonstration purposes and production deployments should use existing well defined and secure network best practices.
- [resources.json](jupyter.json) cloudformation template 
- [parameters/resources.json](jupyter.json) parameter file

![arm_visualization](images/902_resources_arm_visualization.png?raw=true)


### Role-Policy Template
The role-policy template creates the role with the required permissions for ai unlimited workspace.
- [resources.json](jupyter.json) cloudformation template 
- [parameters/resources.json](jupyter.json) parameter file

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

in the Custom deployment Dialog, select your Subcription.
Also set:
- The region to deploy in.
- The name to use for the created resources ( the resouce group, network, subnet and role will use this value as their name )
- The location to deploy in.
- The CIDR to use for the Network
- the CIDR to use for the Subnet in the new network

Then select review and create

![arm_create_new_resources_project_details](images/006_arm_create_new_resources_project_details.png?raw=true)

review the information, confirm your settigns, and select the create button.

![arm_create_new_resources_review_create](images/007_arm_create_new_resources_review_create.png?raw=true)

The template will proceed to deploy

![arm_create_new_resources_deployment_complete](images/008_arm_create_new_resources_deployment_complete.png?raw=true)

After the template has completed, select the ouput tab and make note of the network names and the `RoleDefinitionId`. 
These value will be needed by the workspace deployment

![arm_create_new_resources_outputs](images/009_arm_create_new_resources_outputs.png?raw=true)

### Creating the All In One Deployment via ARM Custom Template Deployment

This template creates a single instance containing both AI Unlimited Workspace and Jupyter.
Note: The process for deploying AI Unlimited Workspace or Jupyter separately using their respective templates is nearly the same. 

In the Azure Console,Search for "Deploy a Custom Template" and select the service icon.

![arm_create_new_all_in_one](images/010_arm_create_new_all_in_one.png?raw=true)

Select the "build your own template" link 

![arm_create_new_all_in_one_custom_deployment](images/011_arm_create_new_all_in_one_custom_deployment.png?raw=true)

In the edit the template dialog, select the "Load file" option.

![arm_create_new_all_in_one_edit_template](images/012_arm_create_new_all_in_one_edit_template.png?raw=true)

and select the all-in-one.json template from the file picker dialog.

![arm_create_new_all_in_one_file_picker](images/013_arm_create_new_all_in_one_file_picker.png?raw=true)

With the file content loaded into the edit template dialog, select "Save"

![arm_create_new_all_in_one_loaded_file](images/014_arm_create_new_all_in_one_loaded_file.png?raw=true)

in the Custom deployment Dialog, set values for 
- The Resource Group
- The Name to use for the created resources
- The ssh public key, ( this should start with "ssh-rsa" )
- The name of the network to deploy into
- The name of the subnet to deploy into
- The name of the security group we will create for the workspace instance
- The CIDRs that have permission to connect to the workspace instance
- The Source Application Security Groups that have permission to connect to the workspace instance
- The Destination Application Security Groups that have permission to connect to the workspace instance
- The Ports for Workspaces HTTP and GRPC Access, and the Port used fro HTTP to Jupyter
- The RoleDefinitionId of the role to use with workspaces
- Will you Allow ssh from the firewall?
- Will you use a persistent volume for storing the workspace and jupyter data?
- If using a persistent volume, what size should it be.
- if you are using an existing persistent volume, what is the volume Id.
- the version of Workspaces
- the version of Jupyter
- the token to use for Jupyter authentication

Then select review and create

[arm_create_new_all_in_one_project_details](images/015_arm_create_new_all_in_one_project_details.png?raw=true)

review the information, confirm your settigns, and select the create button.

[arm_create_new_all_in_one_review_create](images/016_arm_create_new_all_in_one_review_create.png?raw=true)

The template will proceed to deploy

[arm_create_new_all_in_one_deployment_complete](images/017_arm_create_new_all_in_one_deployment_complete.png?raw=true)

After the template has completed, select the ouput tab and make note of the network names and the `RoleDefinitionId`. 
These value will be needed by the workspace deployment

[arm_create_new_all_in_one_ouputs](images/018_arm_create_new_all_in_one_ouputs.png?raw=true)

## Configuring Workspaces

![workspaces_setup](images/020_workspaces_setup.png?raw=true)

![workspaces_setup_update_url](images/021_workspaces_setup_update_url.png?raw=true)

![workspaces_setup_use_tls](images/022_workspaces_setup_use_tls.png?raw=true)

![workspaces_setup_gen_tls](images/023_workspaces_setup_gen_tls.png?raw=true)

![workspaces_setup_tls_save](images/024_workspaces_setup_tls_save.png?raw=true)

![workspaces_setup_azure](images/025_workspaces_setup_azure.png?raw=true)

![workspaces_setup_github](images/026_workspaces_setup_github.png?raw=true)

![workspaces_setup_github_oauth](images/027_workspaces_setup_github_oauth.png?raw=true)

![workspaces_setup_api_key_and_restart](images/028_workspaces_setup_api_key_and_restart.png?raw=true)

## Configuring Jupyter

![jupyter_setup](images/030_jupyter_setup.png?raw=true)

![jupyter_setup_regulus_folder](images/031_jupyter_setup_regulus_folder.png?raw=true)

![jupyter_setup_get_started](images/032_jupyter_setup_get_started.png?raw=true)

![jupyter_setup_select_host](images/033_jupyter_setup_select_host.png?raw=true)

![jupyter_setup_updated_host](images/034_jupyter_setup_updated_host.png?raw=true)

![jupyter_setup_project_create](images/035_jupyter_setup_project_create.png?raw=true)

![jupyter_setup_list](images/036_jupyter_setup_list.png?raw=true)

![jupyter_setup_create_auth](images/037_jupyter_setup_create_auth.png?raw=true)

![jupyter_setup_auth_list](images/038_jupyter_setup_auth_list.png?raw=true)

![jupyter_setup_start_deploy](images/039_jupyter_setup_start_deploy.png?raw=true)

### ARM use CLI

TODO: Pending updates for use with Deployment Manager


## Using a Persistent Volume
The default behavior is to use the root volume of the instace for storage. This will persist any Jupyter notebook data saved under the userdata folder and the Workspaces database and configuration files. If the instance is rebooted, shutdown and restarted, or snapshot and relaunched, your data will persist. If the instance is terminated, your Jupyter notebook data and/or Workspaces database will be lost. 
This can be especially problematic if running on spot instances which may be terminated without warning. If greater persistency is desired,
You can enable the UsePersistentVolume parameter to move the Jupyter notebook data and/or Workspaces database to a seperate volume.

### Suggested Persistent Volume Flow
1. Create a new deployment with UsePersistentVolume=New
2. Configure and use the instance until the instance is terminated.
3. On the next deployment, use UsePersistentVolume=New, ExistingPersistentVolumeId to the volume-id from the first deploy

This will remount the volume and the instance will have the previous data available. This template can be relaunced with the same config whenever you need to recreate the instance with the previous data.

## Example Role Policies 
If the account deploying Workspaces does not have sufficient IAM permissions to create the roles,
The roles and can be defined prior to deployment and passed into the Workspaces template.

For Workspaces, a Role would need the following policies:
### [workspaces.json](policies/workspaces.json)
which includes the permissions needed to create ai-unlimited instances and grants Workspaces the
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
          "Microsoft.Resources/subscriptions/resourcegroups/delete"
        ],
        "notActions": [],
        "dataActions": [],
        "notDataActions": []
      }
    ]
  }
}
```
