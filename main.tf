terraform {
#aws conf
  required_providers {
    aws = {
    source  = "hashicorp/aws"

    version = "~> 3.27"

    }
  }


  required_version = ">= 0.14.9"

}

provider "aws" {

  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

}
resource "tls_private_key" "sskeygen_execution" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


# Below are the aws key pair
resource "aws_key_pair" "prometheus_key_pair" {
  depends_on = [tls_private_key.sskeygen_execution]
  key_name   = var.aws_public_key_name
  public_key = tls_private_key.sskeygen_execution.public_key_openssh
}
#creating the webserver
resource "aws_instance" "webserver" {

  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = aws_key_pair.prometheus_key_pair.id
  subnet_id = var.subnet_id 
  vpc_security_group_ids = [aws_security_group.iac-task-sg.id]
  associate_public_ip_address = true
  root_block_device {
    volume_type = "gp2"
    volume_size = "30"
    delete_on_termination = false

}
# transferring conf files for monitoring of endpoint to server
connection {
    user        = "ubuntu"
    host = self.public_ip
    private_key = tls_private_key.sskeygen_execution.private_key_pem
  }
# Copy conf for ssmtp to instance
provisioner "file" {
    source      = "./ssmtp.conf"
    destination = "/tmp/ssmtp.conf"
  }
# Copy script for monitoring service to instance
provisioner "file" {
    source      = "./endpoint_monitoring.sh"
    destination = "/tmp/endpoint_monitoring.sh"
  }
# Copy script for monitoring service to instance
provisioner "file" {
    source      = "./endpoint_service.sh"
    destination = "/tmp/endpoint_service.sh"
  }
# Copy service to instance
provisioner "file" {
    source      = "./endpoint_monitoring.service"
    destination = "/tmp/endpoint_monitoring.service"
  }
# Start up script for the instance
user_data = <<-EOL
  #!/bin/bash -xe
#TASK 1
  sudo apt-get update
  sudo apt-get install nginx -y
  sudo systemctl restart nginx
  sudo chmod 777 -R /var/www/html/
# Fetching Instance id, mac address and local ipv4 address to be displayed on port 80
  cd /var/www/html/
  id=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" "Content-Type: application/html" http://169.254.169.254/latest/meta-data/instance-id)
  mac=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" "Content-Type: application/html" http://169.254.169.254/latest/meta-data/mac)
  ip=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" "Content-Type: application/html" http://169.254.169.254/latest/meta-data/local-ipv4)
 #static website html
  echo "<html><body><table border="1"><tr><th>Instance id</th><th>Mac Address</th><th>Private IP</th></tr><tr><td>$id</td><td>$mac</td><td>$ip</td></tr></table>" > /var/www/html/index.html  

#TASK 2
#Installing ssmtp to send alerts via mail
  sudo apt update -y
  sudo apt-get install ssmtp -y
  
#Placing conf files in config locations
  sudo mv /etc/ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf.bak
  sudo cp /tmp/ssmtp.conf /etc/ssmtp/
  
#Placing scripts for endpoint monitoring
  sudo cp /tmp/endpoint_service.sh /home/ubuntu/
  sudo cp /tmp/endpoint_monitoring.sh /home/ubuntu/
  sudo cp /tmp/endpoint_monitoring.service /etc/systemd/system/
  sudo chmod +x /home/ubuntu/endpoint_service.sh
  sudo chmod +x /home/ubuntu/endpoint_monitoring.sh
  sudo systemctl daemon-reload
  sudo systemctl start endpoint_monitoring.service
  sudo systemctl enable endpoint_monitoring.service
  sudo systemctl status endpoint_monitoring.service 

  EOL 
#Name of the instance which is taken as input from the user
  tags = {
   Name = var.name
  }
#This snippet plces the key for instance created in our terraform host machine (self)
provisioner "local-exec" {
    command = "echo '${tls_private_key.sskeygen_execution.private_key_pem}' >> ${aws_key_pair.prometheus_key_pair.id}.pem ; chmod 400 ${aws_key_pair.prometheus_key_pair.id}.pem"
  }

}

