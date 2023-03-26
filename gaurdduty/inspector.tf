data "aws_inspector_rules_packages" "rules" {}

resource "aws_inspector_resource_group" "inspector_resource_group" {
  tags = {
    Inspector = "true"
  }
}

resource "aws_inspector_assessment_target" "inspector_assessment_target" {
  name               = data.terraform_remote_state.vpc.outputs.eks_cluster_name
  resource_group_arn = aws_inspector_resource_group.inspector_resource_group.arn
}

resource "aws_inspector_assessment_template" "inspector_assessment_template" {
  name               = data.terraform_remote_state.vpc.outputs.eks_cluster_name
  target_arn         = aws_inspector_assessment_target.inspector_assessment_target.arn
  duration           = 3600
  #rules_package_arns = setsubtract(data.aws_inspector_rules_packages.rules.arns, [element(data.aws_inspector_rules_packages.rules.arns, 3)])
  rules_package_arns = data.aws_inspector_rules_packages.rules.arns
  ## https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html#us-east-2 ##
}

resource "aws_iam_role" "inspector_event_role" {
  name               = "inspector-event-${var.environment}-${data.terraform_remote_state.vpc.outputs.random_id}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "inspector_event_role_policy" {
  statement {
    sid = "StartAssessment"
    actions = [
      "inspector:StartAssessmentRun",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "inspector_event" {
  name   = "inspector-event-${var.environment}-policy-${data.terraform_remote_state.vpc.outputs.random_id}"
  role   = aws_iam_role.inspector_event_role.id
  policy = data.aws_iam_policy_document.inspector_event_role_policy.json
}

resource "aws_cloudwatch_event_rule" "inspector_event_schedule" {
  name                = "inspector-schedule-cloudwatch-event-${var.environment}-${data.terraform_remote_state.vpc.outputs.random_id}"
  description         = "Trigger an Inspector Assessment"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "inspector_event_target" {
  rule     = aws_cloudwatch_event_rule.inspector_event_schedule.name
  arn      = aws_inspector_assessment_template.inspector_assessment_template.arn
  role_arn = aws_iam_role.inspector_event_role.arn
}
