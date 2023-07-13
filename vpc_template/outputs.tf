output "ubuntu_public_ip" {
  value = aws_eip.ubuntu_eip.*.public_ip
}

output "centos_public_ip" {
  value = aws_eip.centos_eip.*.public_ip
}

output "windows_public_ip" {
  value = aws_eip.windows_eip.*.public_ip
}