provider "aws" {
  region     = "us-east-2"
  alias      = "ohio"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_token
  default_tags {
    tags = var.required_tags
  }
}

provider "aws" {
  region     = "us-west-2"
  alias      = "oregon"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_token
  default_tags {
    tags = var.required_tags
  }
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
