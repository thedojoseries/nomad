#!/bin/bash

# Launch team1's stack
aws cloudformation create-stack --stack-name team1 --template-body file://dojo-infrastructure.yaml --parameters ParameterKey=Namespace,ParameterValue=team1 ParameterKey=TeamNumber,ParameterValue=1 --capabilities CAPABILITY_NAMED_IAM;

# Wait until stack finishes
aws cloudformation wait stack-create-complete --stack-name team1

# Gets the ID of the Security Group associated with the Cloud9 EC2 instance
sg_id=`aws cloudformation describe-stack-resources --stack-name $(aws cloudformation describe-stacks | jq -r ".Stacks[] | select(.StackName | contains(\"aws-cloud9-team1-\")) | .StackName") | jq -r '.StackResources[] | select(.ResourceType == "AWS::EC2::SecurityGroup") | .PhysicalResourceId'`

# Adds a rule to allow the Nomad client instance to communicate with the Cloud9 instance (where the Nomad server will be running)
aws ec2 authorize-security-group-ingress \
    --group-id $sg_id \
    --ip-permissions IpProtocol=tcp,FromPort=0,ToPort=65535,IpRanges="[{CidrIp=10.0.1.99/32,Description=\"Allow Nomad Client access for team 1\"}]"

# Adds a rule to allow access to the Nomad UI in the Cloud9 instance
#
# PS: I Strongly suggest you replace 0.0.0.0/0 with your own IP Address so only you can access it
aws ec2 authorize-security-group-ingress \
    --group-id $sg_id \
    --ip-permissions IpProtocol=tcp,FromPort=4646,ToPort=4646,IpRanges="[{CidrIp=0.0.0.0/0,Description=\"Allow access to the Nomad UI\"}]"

# Gets the password for the user
aws secretsmanager get-secret-value --secret-id /team1/password | jq -r .SecretString | xargs echo AWS Password for the \"team1\" user:
