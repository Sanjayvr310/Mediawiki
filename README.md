This repo covers CloudFormations templates to install and configure mediawiki with MariaDB using AWS resources (VPC, subnets, LB, ASG, ECS, MariaDB, ...)

Infrastructure Diagram
![Mediawiki_AWS_Arch](https://github.com/Sanjayvr310/Mediawiki/assets/59363379/90333644-b4e9-4b90-9157-c8fe8e072cfb)

Architecture overview:

application architecture:
The mediawiki image which will be pushed in to AWS ECS cluster widespread between two availability zone using public subnet (private VPC) as frontend part of service and separated from private subnet as backend part of service (db). In front of them is ALB (application HTTP/HTTPS load balancer) who forward outside requests to frontend containers in ECS cluster.The RDS stack implements Multi-AZ deployment, which automatically replicates the database across different Availability Zones ,with synchronous replication, data integrity is maintained across primary and standby instances, ensuring continuous availability and minimal downtime - this can be set(as a optional in cf template) and also with read replica as a optional for better performance.The architecture also implements several security measures to safeguard the database. Secrets Manager securely manages database credentials, ensuring that sensitive information remains encrypted and only accessible to authorized entities. Additionally, security groups define firewall rules to control inbound and outbound traffic, limiting access to the database and enhancing network security.

Overview of the stacks:
1) vpc.yaml
Creates a VPC with two public subnets and two private subnets.
Establishes an internet gateway for the VPC.
Sets up routing tables for public and private subnets.
Configures NAT gateway with an Elastic IP for private subnet internet access.

2) secrets.yaml
Manages secrets using AWS Secrets Manager.
Creates secrets for RDS credentials and AMI IDs.
Allows parameters for specifying AMI IDs and credentials securely.

3) db.yaml
Sets up an RDS MariaDB instance with options for Multi-AZ deployment and read replicas.
Establishes a DB subnet group.
Defines parameters for the database, such as name, storage, instance type, etc.
Accesses resources from the networking stack (VPC and subnets).

4) sercvice.yaml
Sets up an ECS cluster with associated resources including security groups, load balancers, scaling policies, task definitions, and IAM roles.
Defines parameters for key pair, desired capacity, and maximum size of the ECS cluster.
Specifies mappings for instance types and AMI IDs based on AWS region.
Creates security groups, log groups, task definitions, load balancers, autoscaling groups, and IAM roles required for ECS service.
Sets up scaling policies and CloudWatch alarms for autoscaling.
Uses secrets from Secrets Manager for sensitive data like database credentials.


STEPS to run:
1)First create the network stack as it outputs the resources to be used with other stacks via cross stack refrence 
aws cloudformation create-stack \
    --stack-name NetworkStackName \
    --template-body file://vpc.yaml \
    --parameters ParameterKey=VPCName,ParameterValue=YourVPCName

2)Run the secrets stack as it also has depencies
aws cloudformation create-stack \
    --stack-name YourStackName \
    --template-body file://secrets.yaml \
    --parameters \
        ParameterKey=AMIVParam,ParameterValue=YourAMIVValue \
        ParameterKey=AMIOParam,ParameterValue=YourAMIOValue \
        ParameterKey=AMINCParam,ParameterValue=YourAMINCValue \
        ParameterKey=UsernameParam,ParameterValue=YourUsername \
        ParameterKey=PasswordParam,ParameterValue=YourPassword

3)Run the service.yaml as the rds needs the security group created from here(cross stack).This Ec2 should have created in network stack to avoid this dependency 
aws cloudformation create-stack \
    --stack-name YourStackName \
    --template-body file://service.yaml \
    --parameters \
        ParameterKey=KeyName,ParameterValue=YourKeyName \
        ParameterKey=DesiredCapacity,ParameterValue=2 \
        ParameterKey=NetworkStackName,ParameterValue=YourNetworkStackName \
        ParameterKey=MaxSize,ParameterValue=3

4)Create the rds.yaml with the options to enable multi-az and read-replica 
aws cloudformation create-stack \
    --stack-name YourStackName \
    --template-body file://rds_template.yaml \
    --parameters \
        ParameterKey=DBName,ParameterValue=YourDBName \
        ParameterKey=NetworkStackName,ParameterValue=YourNetworkStackName \
        ParameterKey=DBAllocatedStorage,ParameterValue=YourDBAllocatedStorage \
        ParameterKey=DBInstanceClass,ParameterValue=YourDBInstanceClass \
        ParameterKey=MultiAZ,ParameterValue=false \
        ParameterKey=EnableReadReplica,ParameterValue=true \
        ParameterKey=DBSubnetGroupName,ParameterValue=YourDBSubnetGroupName \
        ParameterKey=MediaWikiStackName,ParameterValue=YourMediaWikiStackName

If no role is available, CloudFormation uses a temporary session that is generated from your user credentials.
Make sure you have the AWS CLI configured properly with the iam user with the proper policy to deploy the above stacks or make sure the ec2 instace has the iam role with proper policy to deploy the resorces.

Note: These stack can be also be deployed using the cloudformation console .

5)After testing and setting up the media wiki in local, understood that the LocalSettings.php(database connections,server deatils and other mediawiki page configs etc) has to be updated once the mediawiki is up and should be placed in the directory where we will be have the index.php othwewise just the blank page of mediawiki will be displayed and also noticed that the $wgServer has to be set with the base URL of the server, including protocol(https://www.mediawiki.org) ,since there is no DNS, in the ec2 we get as instance $wgServer = "http://<public_ip>:<port>" when LocalSettings.php is manually installed in the browser and when we do it in the ECS cluster set up ,running behind the ALB we get the ALB DNS when manually installed from the browser ,when in production world we cant set up in the browser and so have automated using a custom shell script(config.sh in the script folder).

This bash script automates the setup and configuration of MediaWiki instances deployed on Amazon ECS-managed EC2 instances by installing and configuring the LocalSettings.php with running the php maintenance/install.php in the workdir of the mediawiki image. It iterates through each ECS container instance within a specified cluster, retrieves necessary details including EC2 instance IDs and public DNS names, and identifies MediaWiki Docker containers. It then updates the LocalSettings.php file and executes installation commands within each container, ensuring proper configuration and linkage to the specified database server with provided credentials(**the values are set in the mediawiki image already - this just runs it ensuring security**).Refer **next_steps** for what could be done better.

Usage: sh <cluster_name> <db_name> <db_server> (could automate more)


This stack has been tested and deployed in three aws regions and in the **output_images** folder can see the ouputs and the mediawiki up and running.Also kindly refer the **mission_mediawiki** file in the root dir for the steps followed to accomplish and also refer **next_steps**  file for what can be done to this arch to improve the efficiency 




