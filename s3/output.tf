#output "codepipeline_s3_bucket" {
#  value = aws_s3_bucket.codepipeline_bucket.bucket
#}

output "alb_logs_s3_bucket" {
  value = aws_s3_bucket.s3_bucket_alb_logs.bucket
}
