module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5" # current version is 5.8.1

  name = var.app_name
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"] # Just need to demonstrate HA functionality, so 2 az's are sufficient.
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_security_group" "allow_all" {
  name = local.app_name
  description = "Allow inbound and outbound traffic to dev."
  vpc_id = module.vpc.vpc_id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["98.31.45.235/32"]
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20" # current version is 20.11.0
  cluster_name    = local.app_name
  cluster_version = "1.29"

  iam_role_name = local.app_name
  iam_role_use_name_prefix = false

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_additional_security_group_ids = [aws_security_group.allow_all.id]

  # EKS Managed Node Group(s)
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns = { # enable latest version of coredns, the dns service for k8s
      most_recent = true
    }
    kube-proxy = { # enable latest version of kube-proxy, the network proxy and management service for k8s
      most_recent = true
    }
    vpc-cni = { # enable latest version of vpc-cni, the network plugin for k8s integrating the host(s) with AWS VPC network interfaces
      most_recent = true
    }
  }
  # # Cluster access entry - Moved to manual entries outside of module, just for fun.
  # # To add the current caller identity as an administrator
  # enable_cluster_creator_admin_permissions = true

  # access_entries = {
  #   # One access entry with a policy associated
  #   admin = {
  #     kubernetes_groups = []
  #     principal_arn     = data.aws_caller_identity.this.arn

  #     policy_associations = {
  #       admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #         access_scope = {
  #           namespaces = ["default"]
  #           type       = "cluster"
  #         }
  #       }
  #     }
  #   }
  # }

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
    ami_type       = "AL2_x86_64"
    disk_size      = 20
  }
  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }
}

resource "aws_eks_access_entry" "this" {
  cluster_name = module.eks.cluster_name
  principal_arn = data.aws_caller_identity.this.arn
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  for_each = toset(["AmazonEKSAdminPolicy", "AmazonEKSClusterAdminPolicy"])
  cluster_name = module.eks.cluster_name
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/${each.value}"
  principal_arn = data.aws_caller_identity.this.arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "jenkins" {
  for_each = toset(["AmazonEKSAdminPolicy", "AmazonEKSClusterAdminPolicy"])
  cluster_name = module.eks.cluster_name
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/${each.value}"
  principal_arn = "arn:aws:iam::909307856304:role/k8s-testing"

  access_scope {
    type = "cluster"
  }
}
