variable "environment" {
  type    = string
  default = "dev"
}

variable "remote_state_bucket" {
  type = string
}

variable "remote_state_region" {
  type = string
}

variable "aws_region" {
  type = string
}

#######################################################################################################################
#################################### DEV ##############################################################################
#######################################################################################################################

variable "aws_vpc_cidr_dev" {
  type    = string
  default = "10.10.0.0/16"
}

variable "aws_azs_dev" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "aws_cidrs_public_dev" {
  type    = list(string)
  default = ["10.10.0.0/21", "10.10.8.0/21", "10.10.16.0/21"]
}

variable "aws_cidrs_private_dev" {
  type    = list(string)
  default = ["10.10.24.0/21", "10.10.32.0/21", "10.10.48.0/21"]
}

variable "aws_cidrs_db_dev" {
  type    = list(string)
  default = ["10.10.56.0/21", "10.10.64.0/21", "10.10.72.0/21"]
}

#######################################################################################################################
#################################### stage ##############################################################################
#######################################################################################################################

variable "aws_vpc_cidr_stage" {
  type    = string
  default = "30.30.0.0/16"
}

variable "aws_azs_stage" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "aws_cidrs_public_stage" {
  type    = list(string)
  default = ["30.30.0.0/21", "30.30.8.0/21", "30.30.16.0/21"]
}

variable "aws_cidrs_private_stage" {
  type    = list(string)
  default = ["30.30.24.0/21", "30.30.32.0/21", "30.30.48.0/21"]
}

variable "aws_cidrs_db_stage" {
  type    = list(string)
  default = ["30.30.56.0/21", "30.30.64.0/21", "30.30.72.0/21"]
}


#######################################################################################################################
#################################### PROD ########################################################
#######################################################################################################################



variable "aws_vpc_cidr_prod" {
  type    = string
  default = "20.20.0.0/16"
}

variable "aws_azs_prod" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "aws_azs_prod_dr" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "aws_cidrs_public_prod" {
  type    = list(string)
  default = ["20.20.0.0/21", "20.20.8.0/21", "20.20.16.0/21"]
}

variable "aws_cidrs_private_prod" {
  type    = list(string)
  default = ["20.20.24.0/21", "20.20.32.0/21", "20.20.48.0/21"]
}

variable "aws_cidrs_db_prod" {
  type    = list(string)
  default = ["20.20.56.0/21", "20.20.64.0/21", "20.20.72.0/21"]
}
