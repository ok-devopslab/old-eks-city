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
