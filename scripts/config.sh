#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <cluster_name> <db_name> <db_server>"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Usage: $0 <cluster_name> <db_name> <db_server>"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Usage: $0 <cluster_name> <db_name> <db_server>"
    exit 1
fi

# Retrieve the cluster name from the command-line argument
CLUSTER_NAME="$1"
DB_NAME="$2"
DB_SERVER="$3"

# Describe the container instances to get ARNs
CONTAINER_INSTANCE_ARNS=$(aws ecs list-container-instances --cluster $CLUSTER_NAME --query 'containerInstanceArns[*]' --output text)

# Iterate over each container instance ARN
for ARN in $CONTAINER_INSTANCE_ARNS; do
    echo "Describing ECS container instance using ARN: $ARN"
    
    # Describe the ECS container instance using the ARN
    INSTANCE_DETAILS=$(aws ecs describe-container-instances --cluster $CLUSTER_NAME --container-instances $ARN)

    # Extract EC2 instance ID from the details
    EC2_INSTANCE_ID=$(echo $INSTANCE_DETAILS | jq -r '.containerInstances[].ec2InstanceId')

    # Retrieve the public DNS name of the instance
    PUBLIC_DNS=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query 'Reservations[].Instances[].PublicDnsName' --output text)
    PUBLIC_IP=$(ssh -i qrscanner.pem ec2-user@$PUBLIC_DNS "curl -s http://checkip.amazonaws.com")

    echo "Public DNS of instance $EC2_INSTANCE_ID: $PUBLIC_DNS"
    echo "Public IP of instance $EC2_INSTANCE_ID: $PUBLIC_IP"

    # Fetch Docker container IDs running MediaWiki images on the instance
    CONTAINER_IDS=$(ssh -i qrscanner.pem ec2-user@$PUBLIC_DNS "docker ps --filter \"ancestor=public.ecr.aws/docker/library/mediawiki:1.41.0\" --format '{{.ID}}'")

    # Update LocalSettings.php and execute command inside each container
    for CONTAINER_ID in $CONTAINER_IDS; do
        echo "Updating LocalSettings.php for container ID: $CONTAINER_ID"
        
        # Generate the server URL using the public IP address and host port
        SERVER_URL="http://${PUBLIC_IP}:$(ssh -i qrscanner.pem ec2-user@$PUBLIC_DNS "docker port $CONTAINER_ID 80 | cut -d':' -f2")"
        echo "Setting server URL to: $SERVER_URL"

        # Modify the php maintenance/install.php command with the appropriate server URL
      # INSTALL_COMMAND="php maintenance/install.php --dbname=new --dbserver=\"properdb-masterdb-gy7idc4sjgqr.cvu2eyysedhj.us-east-2.rds.amazonaws.com\" --installdbuser=root --installdbpass=october2023 --dbuser=root --dbpass=october2023 --server=\"$SERVER_URL\" --scriptpath=\"\" --lang=en --pass=Adminpassword \"Wiki Name\" \"Admin\""

        # Execute the modified command inside the container
        echo "Executing installation command inside container $CONTAINER_ID"
        ssh -i qrscanner.pem ec2-user@$PUBLIC_DNS "docker exec $CONTAINER_ID php maintenance/install.php --dbname=$DB_NAME --dbserver="$DB_SERVER" --installdbuser=$APP_DB_USER --installdbpass=$APP_DB_PASSWD --dbuser=$APP_DB_USER --dbpass=$APP_DB_PASSWD --server="$SERVER_URL" --scriptpath="" --lang=en --pass=Adminpassword "Wiki Name" "Admin""
    done
done

echo "Script execution completed."

