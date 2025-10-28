variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "ami" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c02fb55956c7d316" ##Amazon Linux 2 AMI (HVM), SSD Volume Type - us-east-1
}

variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  default     = "t3.micro"
}