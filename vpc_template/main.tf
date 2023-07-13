data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "aws_ami" "centos" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["CentOS-7-2111-20220825_1.x86_64*"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["801119661308"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "net" {
  cidr_block = var.cidr_block

  tags = {
    Name = "${var.name_prefix}vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.net.id

  tags = {
    Name = "${var.name_prefix}igw"
  }
}

resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.net.default_route_table_id

  route {
    cidr_block = var.ipv4_default
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name_prefix}default-rtb"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.net.id
  cidr_block        = var.cidr_block
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.name_prefix}public-subnet"
  }
}

resource "aws_default_network_acl" "rules" {
  default_network_acl_id = aws_vpc.net.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.ipv4_default
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.ipv4_default
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.name_prefix}default-acl"
  }
}

resource "aws_security_group" "windows_public" {
  name        = "${var.name_prefix}windows-public-sg"
  description = "allow windows public access"
  vpc_id      = aws_vpc.net.id

  ingress {
    description = "allow all rdp in"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.ipv4_default]
  }

  egress {
    description = "allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.ipv4_default]
  }

  tags = {
    Name = "${var.name_prefix}windows-public-sg"
  }
}

resource "aws_security_group" "linux_public" {
  name        = "${var.name_prefix}linux-public-sg"
  description = "allow linux public access"
  vpc_id      = aws_vpc.net.id

  ingress {
    description = "allow all ssh in"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ipv4_default]
  }

  egress {
    description = "allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.ipv4_default]
  }

  tags = {
    Name = "${var.name_prefix}linux-public-sg"
  }
}

resource "aws_security_group" "ec2_private" {
  name        = "${var.name_prefix}ec2-private-sg"
  description = "allow ec2 private access"
  vpc_id      = aws_vpc.net.id

  ingress {
    description = "allow all private in"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.private_ips
  }

  tags = {
    Name = "${var.name_prefix}ec2-private-sg"
  }
}

resource "aws_network_interface" "ubuntu_public_eni" {
  count             = var.ubuntu_count
  subnet_id         = aws_subnet.public_subnet.id
  source_dest_check = false

  security_groups = [
    "${aws_security_group.linux_public.id}",
    "${aws_security_group.ec2_private.id}"
  ]

  private_ips = [
    cidrhost("${var.cidr_block}", 256 + count.index)
  ]

  tags = {
    Name = "${var.name_prefix}ubuntu-public-eni-${count.index}"
  }
}

resource "aws_network_interface" "centos_public_eni" {
  count             = var.centos_count
  subnet_id         = aws_subnet.public_subnet.id
  source_dest_check = false

  security_groups = [
    "${aws_security_group.linux_public.id}",
    "${aws_security_group.ec2_private.id}"
  ]

  private_ips = [
    cidrhost("${var.cidr_block}", 512 + count.index)
  ]

  tags = {
    Name = "${var.cidr_block}centos-public-eni-${count.index}"
  }
}

resource "aws_network_interface" "windows_public_eni" {
  count             = var.windows_count
  subnet_id         = aws_subnet.public_subnet.id
  source_dest_check = false

  security_groups = [
    "${aws_security_group.windows_public.id}",
    "${aws_security_group.ec2_private.id}"
  ]

  private_ips = [
    cidrhost("${var.cidr_block}", 768 + count.index)
  ]

  tags = {
    Name = "${var.name_prefix}windows-public-eni"
  }
}

resource "time_sleep" "delay_30_seconds" {
  create_duration = "30s"
  depends_on      = [aws_internet_gateway.igw]
}

resource "aws_eip" "ubuntu_eip" {
  count             = var.ubuntu_count
  network_interface = element(aws_network_interface.ubuntu_public_eni.*.id, count.index)
  depends_on        = [time_sleep.delay_30_seconds]

  tags = {
    Name = "${var.name_prefix}ubuntu-eip-${count.index}"
  }
}

resource "aws_eip" "centos_eip" {
  count             = var.centos_count
  network_interface = element(aws_network_interface.centos_public_eni.*.id, count.index)
  depends_on        = [time_sleep.delay_30_seconds]

  tags = {
    Name = "${var.name_prefix}centos-eip-${count.index}"
  }
}

resource "aws_eip" "windows_eip" {
  count             = var.windows_count
  network_interface = element(aws_network_interface.windows_public_eni.*.id, count.index)
  depends_on        = [time_sleep.delay_30_seconds]

  tags = {
    Name = "${var.name_prefix}windows-eip-${count.index}"
  }
}

resource "aws_key_pair" "public_key" {
  key_name   = "${var.name_prefix}public-key"
  public_key = var.public_key

  tags = {
    Name = "${var.name_prefix}public-key"
  }
}

resource "aws_instance" "ubuntu" {
  count         = var.ubuntu_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ubuntu_type
  key_name      = aws_key_pair.public_key.key_name

  network_interface {
    network_interface_id = element(aws_network_interface.ubuntu_public_eni.*.id, count.index)
    device_index         = 0
  }

  tags = {
    Name = "${var.name_prefix}ubuntu-${count.index}"
  }
}

resource "aws_instance" "centos" {
  count         = var.centos_count
  ami           = data.aws_ami.centos.id
  instance_type = var.centos_type
  key_name      = aws_key_pair.public_key.key_name

  network_interface {
    network_interface_id = element(aws_network_interface.centos_public_eni.*.id, count.index)
    device_index         = 0
  }

  tags = {
    Name = "${var.name_prefix}centos-${count.index}"
  }
}

resource "aws_instance" "windows" {
  count         = var.windows_count
  ami           = data.aws_ami.windows.id
  instance_type = var.windows_type
  key_name      = aws_key_pair.public_key.key_name

  network_interface {
    network_interface_id = element(aws_network_interface.windows_public_eni.*.id, count.index)
    device_index         = 0
  }

  user_data = templatefile("${path.module}/templates/windows_bootstrap.tftpl", {})

  tags = {
    Name = "${var.name_prefix}windows-${count.index}"
  }
}
