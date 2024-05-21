data "aws_caller_identity" "this" {} # To gather information on the current caller

data "aws_iam_policy_document" "trust" {
  statement {
    sid = ""
    principals {
      type = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${replace(module.eks.oidc_provider, "https://", "")}"]
    }
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    condition {
      test = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:aud"
      values = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = ""
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/*"
    ]
  }
  statement {
    sid = ""
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = [
      "*"
    ]
  }
}