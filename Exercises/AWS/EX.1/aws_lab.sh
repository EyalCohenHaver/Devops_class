#!/bin/bash

# Variables
VPC_CIDR="10.1.0.0/16"
PUBLIC_SUBNET_CIDR="10.1.1.0/24"
PRIVATE_SUBNET_CIDR="10.1.2.0/24"
ENV_NAME="prod"
VPC_NAME="$ENV_NAME-vpc"
PUBLIC_SUBNET_NAME="$ENV_NAME-public-subnet-1"
PRIVATE_SUBNET_NAME="$ENV_NAME-private-subnet-1"
PUBLIC_RT_NAME="$ENV_NAME-public-rt"
PRIVATE_RT_NAME="$ENV_NAME-private-rt"
IGW_NAME="$ENV_NAME-igw"
NAT_GW_NAME="$ENV_NAME-nat-gw"
WEB_SERVER_NAME="webserver"
BACKEND_NAME="backend"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-01b799c439fd5516a"
PUBLIC_SECURITY_GROUP_NAME="$ENV_NAME-public-sg"
PRIVATE_SECURITY_GROUP_NAME="$ENV_NAME-private-sg"
KEY_PAIR_NAME="vockey"
MY_IP=$(curl -s http://checkip.amazonaws.com)

USER_DATA_SCRIPT=$(base64 <<< "#!/bin/bash
# install httpd (Linux 2 version)
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo mkdir -p /var/www/html
sudo touch /var/www/html/index.html
sudo echo '<h1>Welcome from $(hostname -f)</h1>' > /var/www/html/index.html")

function init() {
    echo "Creating VPC..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text )
    aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME

    echo "Creating public subnet..."
    PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUBLIC_SUBNET_CIDR --query 'Subnet.SubnetId' --output text )
    aws ec2 create-tags --resources $PUBLIC_SUBNET_ID --tags Key=Name,Value=$PUBLIC_SUBNET_NAME

    echo "Creating private subnet..."
    PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIVATE_SUBNET_CIDR --query 'Subnet.SubnetId' --output text )
    aws ec2 create-tags --resources $PRIVATE_SUBNET_ID --tags Key=Name,Value=$PRIVATE_SUBNET_NAME

    echo "Creating and attaching Internet Gateway..."
    IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text )
    aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=$IGW_NAME
    aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

    echo "Creating public route table..."
    PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text )
    aws ec2 create-tags --resources $PUBLIC_RT_ID --tags Key=Name,Value=$PUBLIC_RT_NAME
    aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
    aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET_ID

    echo "Allocating Elastic IP for NAT Gateway..."
    EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text )

    echo "Creating NAT Gateway..."
    NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET_ID --allocation-id $EIP_ALLOC_ID --query 'NatGateway.NatGatewayId' --output text )
    aws ec2 create-tags --resources $NAT_GW_ID --tags Key=Name,Value=$NAT_GW_NAME

    echo "Waiting for NAT Gateway to become available..."
    aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

    echo "Creating private route table..."
    PRIVATE_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text )
    aws ec2 create-tags --resources $PRIVATE_RT_ID --tags Key=Name,Value=$PRIVATE_RT_NAME
    aws ec2 create-route --route-table-id $PRIVATE_RT_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
    aws ec2 associate-route-table --route-table-id $PRIVATE_RT_ID --subnet-id $PRIVATE_SUBNET_ID

    echo "Creating Public Security Group..."
    PUBLIC_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $PUBLIC_SECURITY_GROUP_NAME --description "Security group for web server" --vpc-id $VPC_ID --query 'GroupId' --output text )
    aws ec2 create-tags --resources $SECURITY_GROUP_ID --tags Key=Name,Value=$PUBLIC_SECURITY_GROUP_NAME

    echo "Creating Private Security Group..."
    PRIVATE_SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $PRIVATE_SECURITY_GROUP_NAME --description "Security group for backend server" --vpc-id $VPC_ID --query 'GroupId' --output text )
    aws ec2 create-tags --resources $SECURITY_GROUP_ID --tags Key=Name,Value=$PRIVATE_SECURITY_GROUP_NAME

    echo "Setting Public Security Group rules..."
    aws ec2 authorize-security-group-ingress --group-id $PUBLIC_SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $PUBLIC_SECURITY_GROUP_ID --protocol tcp --port 22 --cidr $MY_IP/32

    echo "Setting Private Security Group rules..."
    aws ec2 authorize-security-group-ingress --group-id $PRIVATE_SECURITY_GROUP_ID --protocol tcp --port 22 --cidr $PUBLIC_SUBNET_CIDR

    echo "Launching EC2 instances..."
    WEB_SERVER_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --subnet-id $PUBLIC_SUBNET_ID --security-group-ids $PUBLIC_SECURITY_GROUP_ID --associate-public-ip-address --user-data "$USER_DATA_SCRIPT" --key-name $KEY_PAIR_NAME --query 'Instances[0].InstanceId' --output text )
    aws ec2 create-tags --resources $WEB_SERVER_ID --tags Key=Name,Value=$WEB_SERVER_NAME

    BACKEND_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --subnet-id $PRIVATE_SUBNET_ID --security-group-ids $PRIVATE_SECURITY_GROUP_ID --key-name $KEY_PAIR_NAME --query 'Instances[0].InstanceId' --output text )
    aws ec2 create-tags --resources $BACKEND_ID --tags Key=Name,Value=$BACKEND_NAME

    echo "Setup complete!"
    echo " "

    echo "##### Outputs #####"
    echo "VPC ID: $VPC_ID"
    echo "Public Subnet ID: $PUBLIC_SUBNET_ID"
    echo "Private Subnet ID: $PRIVATE_SUBNET_ID"
    echo "Public Route Table ID: $PUBLIC_RT_ID"
    echo "Private Route Table ID: $PRIVATE_RT_ID"
    echo "Internet Gateway ID: $IGW_ID"
    echo "NAT Gateway ID: $NAT_GW_ID"
    echo "Web Server Instance ID: $WEB_SERVER_ID"
    echo "Backend Instance ID: $BACKEND_ID"
    echo "Public Security Group ID: $PUBLIC_SECURITY_GROUP_ID"
    echo "Private Security Group ID: $PRIVATE_SECURITY_GROUP_ID"
}

function delete() {
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text)
    PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PUBLIC_SUBNET_NAME" --query 'Subnets[0].SubnetId' --output text)
    PRIVATE_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$PRIVATE_SUBNET_NAME" --query 'Subnets[0].SubnetId' --output text)
    PUBLIC_RT_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=$PUBLIC_RT_NAME" --query 'RouteTables[0].RouteTableId' --output text)
    PRIVATE_RT_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=$PRIVATE_RT_NAME" --query 'RouteTables[0].RouteTableId' --output text)
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=$IGW_NAME" --query 'InternetGateways[0].InternetGatewayId' --output text)
    WEB_SERVER_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$WEB_SERVER_NAME" --query 'Reservations[0].Instances[0].InstanceId' --output text)
    BACKEND_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$BACKEND_NAME" --query 'Reservations[0].Instances[0].InstanceId' --output text)
    NAT_GW_ID=$(aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=$NAT_GW_NAME" --query 'NatGateways[0].NatGatewayId' --output text)
    EIP_ALLOC_ID=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[0].AllocationId' --output text)

    echo "Terminating EC2 instances..."
    aws ec2 terminate-instances --instance-ids $WEB_SERVER_ID $BACKEND_ID

    echo "Waiting for EC2 instances to terminate..."
    aws ec2 wait instance-terminated --instance-ids $WEB_SERVER_ID $BACKEND_ID

    echo "Deleting Private Security Group..."
    PRIVATE_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=$PRIVATE_SECURITY_GROUP_NAME" --query 'SecurityGroups[0].GroupId' --output text)
    aws ec2 delete-security-group --group-id $PRIVATE_SECURITY_GROUP_ID >/dev/null

    echo "Deleting Public Security Group..."
    PUBLIC_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=$PUBLIC_SECURITY_GROUP_NAME" --query 'SecurityGroups[0].GroupId' --output text)
    aws ec2 delete-security-group --group-id $PUBLIC_SECURITY_GROUP_ID >/dev/null

    echo "Deleting NAT Gateway..."
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_ID

    echo "Releasing Elastic IP..."
    aws ec2 release-address --allocation-id $EIP_ALLOC_ID

    echo "Waiting for NAT Gateway to delete..."
    aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

    echo "Deleting route table associations..."
    aws ec2 disassociate-route-table --association-id $(aws ec2 describe-route-tables --route-table-ids $PUBLIC_RT_ID --query 'RouteTables[0].Associations[0].RouteTableAssociationId' --output text)
    aws ec2 disassociate-route-table --association-id $(aws ec2 describe-route-tables --route-table-ids $PRIVATE_RT_ID --query 'RouteTables[0].Associations[0].RouteTableAssociationId' --output text)

    echo "Deleting route tables..."
    aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID
    aws ec2 delete-route-table --route-table-id $PRIVATE_RT_ID

    echo "Detaching and deleting Internet Gateway..."
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

    echo "Deleting subnets..."
    aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID
    aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID

    echo "Deleting VPC..."
    aws ec2 delete-vpc --vpc-id $VPC_ID

    echo "Cleanup complete!"
}

function main() {
    if [ "$1" = "init" ]; then
        init
    elif [ "$1" = "delete" ]; then
        delete
    else
        echo "Invalid argument provided!"
        echo "Usage:"
        echo "    aws_lab.sh init"
        echo "    (OR)"
        echo "    aws_lab.sh delete"
        exit 1
    fi
}


if [ $# -eq 0 ]; then
    echo "No arguments provided!"
    echo "Usage:"
    echo "    aws_lab.sh init"
    echo "    (OR)"
    echo "    aws_lab.sh delete"
    exit 1
else
    main $1
fi

