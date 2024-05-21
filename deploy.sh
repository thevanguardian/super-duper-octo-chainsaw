#!/bin/bash

export AWS_CONFIG_FILE="~/.aws/config"
export AWS_PROFILE="epic-geek"
export AWS_REGION="us-east-2"

# Execute terraform 
cd terraform && \
terraform init && terraform workspace select dev || terraform workspace new dev && \
terraform apply -auto-approve && \
aws eks update-kubeconfig --region "${AWS_REGION}" --name "$(terraform show -json | jq -r  '.values.root_module.child_modules[].resources[] | select(.address=="module.eks.aws_eks_cluster.this[0]").values.name')" && \
cd .. && \
# Deploy eks plugins and configs
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml && \
kubectl apply -f k8s/external-dns.yaml

# deploy jenkins via helm
helm repo add jenkins https://charts.jenkins.io && \
helm repo update && \
helm upgrade --install jenkins jenkins/jenkins --create-namespace -n jenkins -f k8s/jenkins.yaml

