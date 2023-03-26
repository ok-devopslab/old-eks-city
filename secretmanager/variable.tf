variable "environment" {
  type    = string
  default = "stage"
}

variable "remote_state_bucket" {
  type = string
}

variable "remote_state_region" {
  type = string
}

variable "org_name" {
  type    = string
  default = "citi"
}

variable "aws_region" {
  type = string
}
