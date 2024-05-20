#!/bin/bash

export AWS_CONFIG_FILE="~/.aws/config"
export AWS_PROFILE="epic-geek"
export AWS_REGION="us-east-2"

cd terraform && \
terraform init && terraform workspace select dev || terraform workspace new dev && \
terraform apply -auto-approve && \
aws eks update-kubeconfig --region "${AWS_REGION}" --name "$(terraform show -json | jq -r  '.values.root_module.child_modules[].resources[] | select(.address=="module.eks.aws_eks_cluster.this[0]").values.name')" && \
cd .. && \
helm repo add jenkins https://charts.jenkins.io && \
helm repo update && \
kubectl create namespace jenkins
helm install jenkins/jenkins -n jenkins -f jenkins/values.yaml

cluster_endpoint=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")