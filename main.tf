resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ec2.private_key_pem
  filename        = "ec2.pem"
  file_permission = "0600"
}

module "us_east_2" {
  source = "./vpc_template"

  providers = {
    aws = aws.ohio
  }

  public_key     = tls_private_key.ec2.public_key_openssh
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cidr_block     = "10.68.0.0/16"
  name_prefix    = "aws-tf-lab-"
  ubuntu_count   = 1
  ubuntu_type    = "t3.small"
  windows_count  = 1
  windows_type   = "t3.small"
  centos_count   = 1
  centos_type    = "t3.small"
}

module "us_west_2" {
  source = "./vpc_template"

  providers = {
    aws = aws.oregon
  }

  public_key     = tls_private_key.ec2.public_key_openssh
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  cidr_block     = "10.69.0.0/16"
  name_prefix    = "aws-tf-lab-"
  ubuntu_count   = 1
  ubuntu_type    = "t3.small"
  windows_count  = 1
  windows_type   = "t3.small"
  centos_count   = 1
  centos_type    = "t3.small"
}
