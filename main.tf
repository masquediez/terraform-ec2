provider "aws" {
  region = "eu-central-1"
}

# Importiere die VPC-ID und die öffentlichen Subnet-IDs aus dem VPC-Deployment
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "vpcfuntions1"
    key    = "vpc-funtions-1/vpc.tfstate"
    region = "eu-central-1"
  }
}

# Erstelle eine Security Group, die HTTP-Zugriff zulässt
resource "aws_security_group" "http" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-http"
  }
}

# Erstelle eine EC2-Instance
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Sustituir por una AMI válida en eu-central-1
  instance_type = "t2.micro"
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  security_groups = [aws_security_group.http.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt upgrade -y
              sudo apt install docker.io -y
              sudo service docker start
              sudo usermod -a -G docker $(whoami)
              newgrp docker
              docker --version
              sudo docker volume create portainer_data
              sudo docker run -d -p 9000:9000 -p 8000:8000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
              EOF

  tags = {
    Name = "docker-portainer"
  }
}

# Output der Instance IP-Adresse
output "instance_ip" {
  value = aws_instance.web.public_ip
}
