output "Public1_public_ip" {
  value = aws_instance.tf-public1.public_ip
}
output "Public2_public_ip" {
  value = aws_instance.tf-public2.public_ip
}
output "Backend_private_ip" {
  value = aws_instance.tf-backend1.private_ip

}

output "Database_private_ip" {
  value = aws_instance.tf-database.private_ip
}
output "lb_dns_name" {
  value = aws_lb.external-elb.dns_name
}