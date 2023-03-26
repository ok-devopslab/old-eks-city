###################################### Dev  ####################################################
terraform {
  backend "s3" {}
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "vpc/vpc-state.tfstate"
    region = var.remote_state_region
  }
}

data "terraform_remote_state" "vpc-dr" {
  backend = "s3"
  config = {
    bucket = "ccb-cua-prod-dr-terraform-329956689239"
    key    = "vpc/vpc-state.tfstate"
    region = "us-west-2"
  }
}
