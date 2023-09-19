#!/bin/bash

NAMES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
INSTANCE_TYPE=""
IMAGE_ID="ami-03265a0778a880afb"
SECURITY_GROUP_ID="sg-01459a3ce99313402"
for i in "${NAMES[@]}"
do
    if [$i == "mysql" || $i == "mongodb"]
    then
        INSTANCE_TYPE="t3.medium"
    else   
        INSTANCE_TYPE="t2.micro"
    fi
    echo "Creating $i instance"
    aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE  --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=webserver,Value=$i}]"
done