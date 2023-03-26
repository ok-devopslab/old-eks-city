data "aws_elb_service_account" "main" {}

data "aws_iam_policy_document" "s3_bucket_lb_write" {
  policy_id = "s3_bucket_lb_logs"
  statement {
    actions = [
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.s3_bucket_alb_logs.arn}/*",
    ]

    principals {
      identifiers = ["${data.aws_elb_service_account.main.arn}"]
      type        = "AWS"
    }
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.s3_bucket_alb_logs.arn}/*"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    actions = [
      "s3:GetBucketAcl"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.s3_bucket_alb_logs.arn}"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket_alb_logs.bucket
  policy = data.aws_iam_policy_document.s3_bucket_lb_write.json
}

resource "aws_s3_bucket" "s3_bucket_alb_logs" {
  bucket        = "${var.environment}-alb-logs-${data.terraform_remote_state.vpc.outputs.random_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_alb_access" {
  bucket                  = aws_s3_bucket.s3_bucket_alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
