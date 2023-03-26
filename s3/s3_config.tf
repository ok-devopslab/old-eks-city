data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket_config.bucket
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "AWSConsole-AccessLogs-Policy-1639567677416",
    "Statement" : [
      {
        "Sid" : "AWSConfigBucketPermissionsCheck",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "config.amazonaws.com"
        },
        "Action" : "s3:GetBucketAcl",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.s3_bucket_config.bucket}",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        "Sid" : "AWSConfigBucketExistenceCheck",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "config.amazonaws.com"
        },
        "Action" : "s3:ListBucket",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.s3_bucket_config.bucket}",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        "Sid" : "AWSConfigBucketDelivery",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "config.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.s3_bucket_config.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*",
        "Condition" : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control",
            "AWS:SourceAccount" : data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "s3_bucket_config" {
  bucket = "${var.environment}-config-${data.terraform_remote_state.vpc.outputs.random_id}"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_config" {
  bucket                  = aws_s3_bucket.s3_bucket_config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "aws_config" {
  source                                  = "registry.terraform.io/trussworks/config/aws"
  config_name                             = data.terraform_remote_state.vpc.outputs.eks_cluster_name
  config_logs_bucket                      = aws_s3_bucket.s3_bucket_config.bucket
  acm_days_to_expiration                  = 20
  check_acm_certificate_expiration_check  = true
  check_cloudtrail_enabled                = true
  check_ec2_volume_inuse_check            = true
  check_multi_region_cloud_trail          = true
  check_iam_group_has_users_check         = true
  check_iam_root_access_key               = true
  check_iam_password_policy               = true
  check_rds_public_access                 = true
  check_rds_snapshots_public_prohibited   = true
  check_rds_storage_encrypted             = true
  check_instances_in_vpc                  = true
  check_vpc_default_security_group_closed = true
  check_s3_bucket_public_write_prohibited = true
  check_cloud_trail_log_file_validation   = true
  check_ebs_snapshot_public_restorable    = true
  check_guard_duty                        = true
  #config_sns_topic_arn                    = aws_sns_topic.sns_topic.arn
}
