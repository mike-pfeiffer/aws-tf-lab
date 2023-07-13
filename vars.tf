variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "aws_token" {
  type = string
}

variable "required_tags" {
  type = map(any)
  default = {
    Environment = "AWS Terraform Lab"
  }
}
