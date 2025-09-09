#!/bin/bash

PROFILE_NAME=eks-demo-profile
AWS_REGION=us-east-1
CLUSTER_NAME=my-eks

# Load environment variables from .env file
if [ -f ../.env ]; then
    export $(cat ../.env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found. Please create a .env file with the required credentials."
    echo "Example .env file:"
    echo "AWS_ACCESS_KEY_ID=your_access_key"
    echo "AWS_SECRET_ACCESS_KEY=your_secret_key"
    exit 1
fi

# Verify required environment variables
required_vars=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# Configure AWS CLI with the new IAM user's credentials
echo "Configuring AWS CLI profile: $PROFILE_NAME"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $PROFILE_NAME
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $PROFILE_NAME
aws configure set region $AWS_REGION --profile $PROFILE_NAME

# Generate kubeconfig for the EKS cluster
echo "Generating kubeconfig for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION --profile $PROFILE_NAME

# Verify access (optional: lists pods in the default namespace)
echo "Testing kubectl access (listing pods in default namespace)"
kubectl get pods

echo "Setup complete. You can now use kubectl with your EKS cluster."
