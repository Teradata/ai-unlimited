# Workspaces and Jupyter Deployments for AWS

This directory contains sample CloudFormation templates to deploy Workspaces and Jupyter.

## Cloud Formations Templates

### AI Unlimited Templates
The ai-unlimited directory contains templates to deploys AI Unlimited in your AWS account.
It provides seperate template options for deploying with or without load balancers.
- [ai-unlimited/ai-unlimited-with-alb.yaml](templates/ai-unlimited/ai-unlimited-with-alb.yaml) cloudformation template.
- [ai-unlimited/ai-unlimited-with-nlb.yaml](templates/ai-unlimited/ai-unlimited-with-nlb.yaml) cloudformation template.
- [ai-unlimited/ai-unlimited-without-lb.yaml](templates/ai-unlimited/ai-unlimited-without-lb.yaml) cloudformation template.
- [parameters/ai-unlimited-with-alb.json](parameters/ai-unlimited-with-alb.json) parameter file.
- [parameters/ai-unlimited-with-nlb.json](parameters/ai-unlimited-with-nlb.json) parameter file.
- [parameters/ai-unlimited-without-lb.json](parameters/ai-unlimited-without-lb.json) parameter file.

### Jupyter Template
The jupyter directory contains templates to deploys a Jupyter Labs instance with the AI Unlimited Kernel in your AWS account.
It provides seperate template options for deploying with or without load balancers.
- [jupyter/jupyter-with-alb.yaml](templates/jupyter/jupyter-with-alb.yaml) cloudformation template.
- [jupyter/jupyter-with-nlb.yaml](templates/jupyter/jupyter-with-nlb.yaml) cloudformation template.
- [jupyter/jupyter-without-lb.yaml](templates/jupyter/jupyter-without-lb.yaml) cloudformation template.
- [parameters/jupyter-with-alb.json](parameters/jupyter-with-alb.json) parameter file.
- [parameters/jupyter-with-nlb.json](parameters/jupyter-with-nlb.json) parameter file.
- [parameters/jupyter-without-lb.json](parameters/jupyter-without-lb.json) parameter file.

### All-In-One Template
The all-in-one directory contains templates to deploys a AI Unlimited and Jupyter Labs on an single instance in your AWS account.
It provides seperate template options for deploying with or without load balancers.
- [all-in-one/all-in-one-with-alb.yaml](templates/all-in-one/all-in-one-with-alb.yaml) cloudformation template.
- [all-in-one/all-in-one-with-nlb.yaml](templates/all-in-one/all-in-one-with-nlb.yaml) cloudformation template.
- [all-in-one/all-in-one-without-lb.yaml](templates/all-in-one/all-in-one-without-lb.yaml) cloudformation template.
- [parameters/all-in-one-with-alb.json](parameters/all-in-one-with-alb.json) parameter file.
- [parameters/all-in-one-with-nlb.json](parameters/all-in-one-with-nlb.json) parameter file.
- [parameters/all-in-one-without-lb.json](parameters/all-in-one-without-lb.json) parameter file.

If deploying the all in one, it is possible to use the embedded Jupyter Lab service, or connect external Jupyter labs as well.

## Deployment via AWS Console
Create New CloudFormation Template Deployment
![Create New CloudFormation Template Deployment](images/001_cft_create_new.png?raw=true)
Upload New CloudFormation Template
![Upload New CloudFormation Template](images/002_cft_create_new_file_upload.png?raw=true)
Fill out the input dialog
![Fill out the input dialog](images/003_cft_create_dialog.png?raw=true)
Add tags and configure cloudformation options
![Add tags and configure cloudformation options](images/004_cft_create_second_dialog.png?raw=true)
Accept and capability requirements and submit the template
![Accept and capability requirements and submit the template](images/005_cft_create_submit.png?raw=true)

### Cloudformation use CLI

#### Cloudformation Commands

This stack can be deployed via aws cloudformation create-stack or aws cloudformation deploy,
Examples given here are for create-stack. Please reference aws cloudformation deploy help for syntax differences between create-stack and deploy.

##### Creating a new stack
With AWS credentials for an appropriatley permissioned user or service account, and an prepared parameters.json file. 
```
aws cloudformation create-stack --stack-name ai-unlimited-all-in-one \
  --template-body file://templates/all-in-one/all-in-one-with-alb.yaml \
  --parameters file://parameters/all-in-one-with-alb.json \
  --tags Key=ThisIsAKey,Value=AndThisIsAValue \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
```
**Note** CAPABILITY_IAM is required only if IamRole is set to New
**Note** CAPABILITY_NAMED_IAM is required only if IamRole is set to New and IamRoleName has been given a value

If you would prefer to pass in an existing role, the suggested policies for the role are listed in the Example IAM Policies section below.

##### Deleting a stack
With AWS credentials for an appropriatley permissioned user or service account, and an the target stack's name. 
```
aws cloudformation delete-stack --stack-name <stackname> 
```

##### Getting stack information
With AWS credentials for an appropriatley permissioned user or service account, and an the target stack's name.
```
aws cloudformation delete-stack --stack-name <stackname> 
aws cloudformation describe-stacks --stack-name <stackname> 
aws cloudformation describe-stack-events --stack-name <stackname> 
aws cloudformation describe-stack-instance --stack-name <stackname> 
aws cloudformation describe-stack-resource --stack-name <stackname> 
aws cloudformation describe-stack-resources --stack-name <stackname> 
```

##### Getting a stack's outputs
With AWS credentials for an appropriatley permissioned user or service account, and an the target stack's name. 
```
aws cloudformation describe-stacks --stack-name <stackname>  --query 'Stacks[0].Outputs' --output table
```

## Persistent Volume
The deployments use a persistent volume to store any Jupyter notebook data saved under the userdata folder and/or the Workspaces database and configuration files. If the instance is rebooted, shutdown and restarted, or snapshot and relaunched, your data will persist. If the instance is terminated, your Jupyter notebook data and/or Workspaces database will remain on the persitent volume. The volume may be reattached to new deployment providing greater persistency, or can be snapshotted as a back, or as the enabling means for migration over new CFT deployments.

### Suggested Persistent Volume Flow
1. Create a new deployment with UsePersistentVolume=New and PersistentVolumeDeletionPolicy=Retain.
2. In the stack outputs, note the volume-id for later.
3. Configure and use the instance until the instance is terminated.
4. On the next deployment, use UsePersistentVolume=New, PersistentVolumeDeletionPolicy=Retain and set ExistingPersistentVolumeId to the volume-id from the first deploy

This will remount the volume and the instance will have the previous data available. This template can be relaunced with the same config whenever you need to recreate the instance with the previous data.

### Common Parameters

| Parameter | Description | Required | Default | Notes |
| --------- | ----------- | -------- | ------- | ----- |
| **InstanceType** | The EC2 instance type to run the service on. | *required with default* | t3.small | t3.small should be suficent for most use cases. |
| **RootVolumeSize** | The size of the root disk to attach to the instance, in GB | *required with default* | 8 | supports values between 8 and 1000 |
| **TerminationProtection** | Enable instance termination protection. | *required with default* | false |  |
| **IamRole** | Should cloudformations create a new IAM role for the instance or use an exiting one. Allowed values are "New" or "existing" | *required with default* | New |  |
| **IamRoleName** | Name of an existing IAM Role to assign to the instance, or the name to give to the newly created role. Leave this blank to use an autogenerated name | *optional with default* | workspaces-iam-role | if naming a new IAM Role, cloudforamtions requires the CAPABILITY_NAMED_IAM capabilty |
| **IamPermissionsBoundary** | The arn of a permissions boundary to pass to the IAM role assigned to the instance. | *optional* |  |  |
| **AvailabilityZone** | Availability zone to deploy the instance to. | *required* |  |  This must match the subnet, the zone of any pre existing volumes if used, and the instance type must be available in the selected zone. |
| **LoadBalancing** | Will the instance be accessed via a NLB? | *required with default* | NetworkLoadBalancer | Allowed values are  NetworkLoadBalancer or None |
| **LoadBalancerScheme** | If using a LoadBalancer, will it be internal or internet-facing?  | *optional with default* | Internet-facing | The DNS name of an Internet-facing load balancer is publicly resolvable to the public IP addresses of the nodes.Therefore, Internet-facing load balancers can route requests from clients over the internet. The nodes of an internal load balancer have only private IP addresses. The DNS name of an internal load balancer is publicly resolvable to the private IP addresses of the nodes. Therefore, internal load balancers can route requests only\nfrom clients with access to the VPC for the load balancer. |
| **Private** | Will the service be deployed in a private network without public IPs? | *required* | false |  |
| **Session** | Should the instance be accessible via AWS Session Manager? | *required* | false |  |
| **Vpc** | Network to deploy the instance to |  | *required* |  |
| **Subnet** | Subnetwork to deploy the instance to | *required* |  |  |
| **KeyName** | Name of an existing EC2 KeyPair to enable SSH access to the instances | *optional* |  | leave empty if no ssh keys should be included |
| **AccessCIDR** | The IP address range that can be used to communicate with the instance | *optional* |  | Unless you are creating your own security group ingress rules, you should have at least on of AccessCIDR, PrefixList, or SecurityGroup defined. |
| **PrefixList** | The PrefixList that can be used to communicate with the instance | *optional* |  | Unless you are creating your own security group ingress rules, you should have at least on of AccessCIDR, PrefixList, or SecurityGroup defined. |
| **SecurityGroup** | The SecurityGroup that can be used to communicate with the instance | *optional* |  | Unless you are creating your own security group ingress rules, you should have at least on of AccessCIDR, PrefixList, or SecurityGroup defined. |
| **UsePersistentVolume** | Specify if you are using a a new persistent volume, or an existing one |  *optional with default* | New |  |
| **PersistentVolumeSize** | The size of the persistent volume to attach to the instance, in GB | *required with default* | 8 | supports values between 8 and 1000 |
| **ExistingPersistentVolumeId** | Id of the existing persistent volume to attach. Must be in the same availability zone as the workspaces instance | *required if UsePersistentVolume is set to Existing* |  |  |
| **PersistentVolumeDeletionPolicy** | Behavior for the Persistent Volume when deleting the cloudformations deployment | *required with default* | Delete | Allowed Values are Delete, Retain, RetainExceptOnCreate, and Snapshot |
| **LatestAmiId** | The image is to use for the SSM lookup | *required with defaults* |  | This deployment uses the latest ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 image available, Changing this value will likely break the stack. |

### AI Unlimited specific Parameters

| Parameter | Description | Required | Default | Notes |
| --------- | ----------- | -------- | ------- | ----- |
| **AiUnlimitedHttpPort** | The port to access the AI Unlimited service UI | *required with default* | 3000 |  |
| **AiUnlimitedGrpcPort** | The port to access the AI Unlimited service API | *required with default* | 3282 |  |
| **AiUnlimitedVersion** | Which version of AI Unlimited to deploy, uses container version tags | *required with default* | latest |  |

### Jupyter specific Parameters

| Parameter | Description | Required | Default | Notes |
| --------- | ----------- | -------- | ------- | ----- |
| **JupyterHttpPort** | The port to access the Jupyter service UI | *required with default* | 8888 |  |
| **JupyterToken** | The token or password equivalent used to access Jupyter from the UI |  |  | The token must begin with a letter and contain only alphanumeric characters. The allowed pattern is ^[a-zA-Z][a-zA-Z0-9-]* |
| **JupyterVersion** | Which version of Jupyter to deploy, uses container version tags | *required with default* | latest |  |

## Example IAM Policies 
If the account deploying AI Unlimited does not have sufficient IAM permissions to create IAM roles or IAM policies,
roles and policies can be defined prior to deployment and passed into the AI Unlimited template.

For AI Unlimited, a IAM role would need the following policies:
### [ai-unlimited-with-iam-role-permissions.json](policies/ai-unlimited.json)
which includes the permissions needed to create ai-unlimited instances and grants AI Unlimited the
permissions to create cluster specific IAM roles and policies for the Regulus systems it 
will deploy.
```
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "iam:PassRole",
              "iam:AddRoleToInstanceProfile",
              "iam:CreateInstanceProfile",
              "iam:CreateRole",
              "iam:DeleteInstanceProfile",
              "iam:DeleteRole",
              "iam:DeleteRolePolicy",
              "iam:GetInstanceProfile",
              "iam:GetRole",
              "iam:GetRolePolicy",
              "iam:ListAttachedRolePolicies",
              "iam:ListInstanceProfilesForRole",
              "iam:ListRolePolicies",
              "iam:PutRolePolicy",
              "iam:RemoveRoleFromInstanceProfile",
              "iam:TagRole",
              "iam:TagInstanceProfile",
              "ec2:TerminateInstances",
              "ec2:RunInstances",
              "ec2:RevokeSecurityGroupEgress",
              "ec2:ModifyInstanceAttribute",
              "ec2:ImportKeyPair",
              "ec2:DescribeVpcs",
              "ec2:DescribeVolumes",
              "ec2:DescribeTags",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribePlacementGroups",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DescribeLaunchTemplates",
              "ec2:DescribeLaunchTemplateVersions",
              "ec2:DescribeKeyPairs",
              "ec2:DescribeInstanceTypes",
              "ec2:DescribeInstanceTypeOfferings",
              "ec2:DescribeInstances",
              "ec2:DescribeInstanceAttribute",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeAvailabilityZones",
              "ec2:DescribeVpcAttribute",
              "ec2:DeleteSecurityGroup",
              "ec2:DeletePlacementGroup",
              "ec2:DeleteLaunchTemplate",
              "ec2:DeleteKeyPair",
              "ec2:CreateTags",
              "ec2:CreateSecurityGroup",
              "ec2:CreatePlacementGroup",
              "ec2:CreateLaunchTemplateVersion",
              "ec2:CreateLaunchTemplate",
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:AuthorizeSecurityGroupEgress",
              "secretsmanager:CreateSecret",
              "secretsmanager:DeleteSecret",
              "secretsmanager:DescribeSecret",
              "secretsmanager:GetResourcePolicy",
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
              "secretsmanager:TagResource"
          ],
          "Resource": "*",
          "Effect": "Allow"
      }
  ]
}
```
If account restrictions do will not allow AiUnlimited to create IAM Roles and IAM policies,
Then AiUnlimited should also be provided a IAM role with a Policy to pass to the Regulus clusters.
In this case, a modifed AiUnlimited policy can be used which does not include permissions to
create IAM Roles or IAM Policies.

### [ai-unlimited-without-iam-role-permissions.json](policies/ai-unlimited-without-iam-role-permissions.json)
which includes the permissions needed to create ai-unlimited instances
```
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "iam:PassRole",
              "iam:AddRoleToInstanceProfile",
              "iam:CreateInstanceProfile",
              "iam:DeleteInstanceProfile",
              "iam:GetInstanceProfile",
              "iam:GetRole",
              "iam:GetRolePolicy",
              "iam:ListAttachedRolePolicies",
              "iam:ListInstanceProfilesForRole",
              "iam:ListRolePolicies",
              "iam:PutRolePolicy",
              "iam:RemoveRoleFromInstanceProfile",
              "iam:TagRole",
              "iam:TagInstanceProfile",
              "ec2:TerminateInstances",
              "ec2:RunInstances",
              "ec2:RevokeSecurityGroupEgress",
              "ec2:ModifyInstanceAttribute",
              "ec2:ImportKeyPair",
              "ec2:DescribeVpcs",
              "ec2:DescribeVolumes",
              "ec2:DescribeTags",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribePlacementGroups",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DescribeLaunchTemplates",
              "ec2:DescribeLaunchTemplateVersions",
              "ec2:DescribeKeyPairs",
              "ec2:DescribeInstanceTypes",
              "ec2:DescribeInstanceTypeOfferings",
              "ec2:DescribeInstances",
              "ec2:DescribeInstanceAttribute",
              "ec2:DescribeImages",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeAvailabilityZones",
              "ec2:DescribeVpcAttribute",
              "ec2:DeleteSecurityGroup",
              "ec2:DeletePlacementGroup",
              "ec2:DeleteLaunchTemplate",
              "ec2:DeleteKeyPair",
              "ec2:CreateTags",
              "ec2:CreateSecurityGroup",
              "ec2:CreatePlacementGroup",
              "ec2:CreateLaunchTemplateVersion",
              "ec2:CreateLaunchTemplate",
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:AuthorizeSecurityGroupEgress",
              "secretsmanager:CreateSecret",
              "secretsmanager:DeleteSecret",
              "secretsmanager:DescribeSecret",
              "secretsmanager:GetResourcePolicy",
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
              "secretsmanager:TagResource"
          ],
          "Resource": "*",
          "Effect": "Allow"
      }
  ]
}
```

If you will be using AWS Session Manager to connect to the instance, an additional policy should be attached to
the IAM Role used.

### [session-manager.json](policies/session-manager.json)
which includes the permissions needed to interact with Session Manager
```
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "ssm:DescribeAssociation",
              "ssm:GetDeployablePatchSnapshotForInstance",
              "ssm:GetDocument",
              "ssm:DescribeDocument",
              "ssm:GetManifest",
              "ssm:ListAssociations",
              "ssm:ListInstanceAssociations",
              "ssm:PutInventory",
              "ssm:PutComplianceItems",
              "ssm:PutConfigurePackageResult",
              "ssm:UpdateAssociationStatus",
              "ssm:UpdateInstanceAssociationStatus",
              "ssm:UpdateInstanceInformation"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "ssmmessages:CreateControlChannel",
              "ssmmessages:CreateDataChannel",
              "ssmmessages:OpenControlChannel",
              "ssmmessages:OpenDataChannel"
          ],
          "Resource": "*",
          "Effect": "Allow"
      },
      {
          "Action": [
              "ec2messages:AcknowledgeMessage",
              "ec2messages:DeleteMessage",
              "ec2messages:FailMessage",
              "ec2messages:GetEndpoint",
              "ec2messages:GetMessages",
              "ec2messages:SendReply"
          ],
          "Resource": "*",
          "Effect": "Allow"
      }
  ]
}
```

If passing the Regulus Role to new ai-unlimited clusters instead of allowing AiUnlimited to create the cluster specific role,
the following policy can be used as a starting point to template your desired policy.
### [ai-unlimited-engine.json](policies/ai-unlimited-engine.json)

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "secretsmanager:GetSecretValue",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:compute-engine/*"
      ]
    }
  ]
}

```

**Note:** When AiUnlimited creates policies for ai-unlimited, they are restricted to the form of
```
"Resource": [ "arn:aws:secretsmanager:<AI-UNLIMITED_REGION>:<AI-UNLIMITED_ACCOUNT_ID>:secret:compute-engine/<AI-UNLIMITED_CLUSTER_NAME>/<SECRET_NAME>"]
```
If providing a IAM Role and Policy, the cluster name will not be predictable, so some level of wildcarding will be needed in the replacement policy,

such as 
```
"arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:compute-engine/*"
or
"arn:aws:secretsmanager:<REGION>:111111111111:secret:compute-engine/*"
or
"arn:aws:secretsmanager:us-west-2:111111111111:secret:compute-engine/*"
```
