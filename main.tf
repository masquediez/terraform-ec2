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
  ami                    = "ami-01e444924a2233b07" # Ubuntu Server 20.04 LTS für eu-central-1
  instance_type          = "t2.micro"
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnet_id_1a # Nutzt ein öffentliches Subnetz
  vpc_security_group_ids = [aws_security_group.http.id]                                # Nutzt VPC-Security-Gruppen
  key_name               = "llave1"

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              echo "<html><body><h1>Hello, World</h1></body></html>" > /var/www/html/index.html
              systemctl enable apache2
              systemctl start apache2
              EOF

  tags = {
    Name = "web-server"
  }
}

# Output der Instance IP-Adresse
output "instance_ip" {
  value = aws_instance.web.public_ip
}