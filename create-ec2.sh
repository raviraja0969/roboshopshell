#!/bin/bash

NAMES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
INSTANCE_TYPE=""
IMAGE_ID=ami-03265a0778a880afb
SECURITY_GROUP_ID=sg-01459a3ce99313402
DOMAIN_NAME=ravistarfuture.online
cmnd=""
ACTION="";
for i in "${NAMES[@]}"
do
    if [ $i == "mysql" || $i == "mongodb" ]
    then
        INSTANCE_TYPE="t3.medium"
    else   
        INSTANCE_TYPE="t2.micro"
    fi
    echo "Creating $i instance"
    IP_ADDRESS=$(aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE  --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" | jq -r '.Instances[0].PrivateIpAddress')

    cmnd="aws ec2 run-instances --image-id  ami-03265a0778a880afb --count 1 --instance-type t2.micro --security-group-ids sg-01459a3ce99313402 --tag-specifications \"ResourceType=instance,Tags=[{Key=Name,Value=$i}]\" | jq -r '.Instances[0].PrivateIpAddress'"
    echo "Cmd is $cmnd"
    echo "Created $i instance: $IP_ADDRESS"
    val=$(aws route53 list-resource-record-sets --hosted-zone-id Z051647517SIZ4RVTUOES  --query "ResourceRecordSets[?Name == '$i.$DOMAIN_NAME.']" | grep Name | wc -l)
    if [ $val -gt 0 ]
    then
        ACTION="UPDATE"
    else    
        ACTION="CREATE"
    fi
     aws route53 change-resource-record-sets --hosted-zone-id Z051647517SIZ4RVTUOES --change-batch '
     {
            "Changes": [{
            "Action": "'$ACTION'",
                        "ResourceRecordSet": {
                            "Name": "'$i.$DOMAIN_NAME'",
                            "Type": "A",
                            "TTL": 300,
                            "ResourceRecords": [{ "Value": "'$IP_ADDRESS'"}]
                        }}]
    }'
done