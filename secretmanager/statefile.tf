###################################### Dev  ####################################################
terraform {
  backend "s3" {}
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "rds/rds-state.tfstate"
    region = var.remote_state_region
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "s3/s3-state.tfstate"
    region = var.remote_state_region
  }
}
