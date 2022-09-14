output "test" {
  value = data.aws_ami.ubuntu
}
output "IPAddress" {
  value = "${aws_instance.webserver.public_ip}"
}
