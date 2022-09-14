variable "aws_region" {
   type = string
}
variable "instance_type" {
   type = string  
   default   =  "t2.micro"
}

variable "aws_access_key" {
     type = string
}
 variable "aws_secret_key" {
     type = string
}
variable "subnet_id" {
     type = string
}
variable "vpc_id" {
     type = string
}
variable "name" {
     description = "Name of the EC2 instance"
     type = string
}
variable "aws_public_key_name" {
  description = "Name of the the key pair being created"
  default = "Generic-KP-03"
  type = string
}
