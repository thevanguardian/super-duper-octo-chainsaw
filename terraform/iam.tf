resource "aws_iam_role" "this" {
  name = "${local.app_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]

  inline_policy {
    name = "route53"
    policy = data.aws_iam_policy_document.this.json
  }

}