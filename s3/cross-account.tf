resource "aws_iam_role" "aws_iam_role_cross_account" {
  count              = var.environment == "prod" ? 1 : 0
  name               = "prod-cross-account-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "AWS": "arn:aws:iam::${var.dev_account_id}:role/dev-ccb-cua"
            },
            "Condition": {}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "aws_iam_role_policy_cross-account" {
  count  = var.environment == "prod" ? 1 : 0
  role   = aws_iam_role.aws_iam_role_cross_account[0].name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*",
        "ssm:GetParameter",
        "secretsmanager:GetSecretValue",
        "eks:*",
        "iam:DeletePolicyVersion"
      ],
      "Resource": ["*"]
    }
  ]
}
POLICY
}

output "cross_account_role_arn" {
  value = var.environment == "prod" ? aws_iam_role.aws_iam_role_cross_account[0].arn : null
}
