#resource "aws_s3_bucket" "codepipeline_bucket" {
#  bucket        = "codepipeline-builds-${var.environment}-${data.terraform_remote_state.vpc.outputs.random_id}"
#  force_destroy = false
#}
#
#resource "aws_s3_bucket_public_access_block" "codepipeline_bucket" {
#  bucket                  = aws_s3_bucket.codepipeline_bucket.bucket
#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}
