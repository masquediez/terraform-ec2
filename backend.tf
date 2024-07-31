terraform {
  backend "s3" {
    bucket = "vpcfuntions1"
    key    = "vpc-funtions-1/ec2-example.tfstate"
    region = "eu-central-1"
  }
}