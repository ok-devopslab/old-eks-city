variable "environment" {
  type    = string
  default = "stage"
}
variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}
variable "cluster_version" {
  type    = string
  default = "1.23"
}
variable "remote_state_bucket" {
  type = string
}

variable "remote_state_region" {
  type = string
}
