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

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}


variable "emails" {
  type    = list(string)
  default = ["sahil.bansal@xoriant.com", "citi-int-support@xoriant.com"]
}
