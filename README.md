This repo covers CloudFormations templates to install and configure mediawiki with MariaDB using AWS resources (VPC, subnets, LB, ASG, ECS, MariaDB, ...)

Infrastructure Diagram
![Mediawiki_AWS_Arch](https://github.com/Sanjayvr310/Mediawiki/assets/59363379/90333644-b4e9-4b90-9157-c8fe8e072cfb)

Architecture overview:

application architecture:
This concept presents application part using the mediawiki image which will be pushed in to AWS ECS cluster widespread between two availability zone using public subnet (private VPC) as frontend part of service and separated from private subnet as backend part of service (db). In front of them is ALB (application HTTP/HTTPS load balancer) who forward outside requests to frontend containers in ECS cluster.

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



