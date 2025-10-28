variable "aws_region" { type = string default = "us-east-1" }
variable "ami"        { type = string default = "ami-0c02fb55956c7d316" } # change to valid AMI in region
variable "instance_type" { type = string default = "t3.micro" }
variable "ssh_key_name" { type = string default = "" } # optional: AWS keypair name
