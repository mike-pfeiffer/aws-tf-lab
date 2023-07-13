variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "ipv4_default" {
  type    = string
  default = "0.0.0.0/0"
}

variable "private_ips" {
  type = list(any)
  default = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "100.64.0.0/10"
  ]
}

variable "windows_type" {
  type = string
}

variable "centos_type" {
  type = string
}

variable "ubuntu_type" {
  type = string
}

variable "public_key" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "ubuntu_count" {
  type = number
}

variable "windows_count" {
  type = number
}

variable "centos_count" {
  type = number
}