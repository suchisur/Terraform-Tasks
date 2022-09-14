# Terraform-Tasks
Task 1 :
Get IP address, MAC Address and Instance ID in the form of a table for the virtual machine created as a static website

Task 2 :
Custom Monitoring Service created to monitor given endpoint


Configuration :
We need to configure creds.tfvars with credentials for AWS, existing VPC id and subnet ID. The instance type can also be configgured. Region and machine name are taken as inputs while running the Terraform script.

Configuration of endpoint_service.sh is also required for endpoint monitoring wherein we can configure the health check we want to conduct. This includes values like endpoint value, interval between consecutive checks, connection timeout.

Lastly, we need to configure ssmtp.conf with SMTP Server credentials to be able to send alerts to teams based on health checks conducted by the monitoring setup.

Usage:
terraform init
terraform validate
terraform apply -var-file=creds.tfvars
