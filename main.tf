provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "demo" {
  ami           = var.ami
  instance_type = var.instance_type
  #key_name      = var.ssh_key_name != "" ? var.ssh_key_name : null
  key_name     = "Project-Key"  ##Make sure to replace with your key pair name

  tags = {
    Name = "jenkins-terraform-demo"
    Owner = "sree"
  }
}
