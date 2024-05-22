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

# Setup the AWS Load Balancer Controller
# curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json && \
# aws iam create-policy \
#     --policy-name AWSLoadBalancerControllerIAMPolicy \
#     --policy-document file://iam_policy.json
# eksctl create iamserviceaccount \
#   --cluster=container-sorcerer-dev \
#   --namespace=kube-system \
#   --name=aws-load-balancer-controller \
#   --role-name AmazonEKSLoadBalancerControllerRole \
#   --attach-policy-arn=arn:aws:iam::909307856304:policy/AWSLoadBalancerControllerIAMPolicy \
#   --approve
# helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#   -n kube-system \
#   --set clusterName=container-sorcerer-dev \ 
#   --set serviceAccount.create=false \
#   --set serviceAccount.name=aws-load-balancer-controller


# deploy jenkins via helm
helm repo add jenkins https://charts.jenkins.io && \
helm repo update && \
helm upgrade --install jenkins jenkins/jenkins --create-namespace -n jenkins -f k8s/jenkins.yaml

# Delay to allow Jenkins to start up
while [ "$(curl -s -o /dev/null -w "%{http_code}" http://jenkins.epic-geek.net:8080)" != 403 ]; do
  echo "Zzzzz...."
  sleep 5
done

echo "Jenkins is ready!"
