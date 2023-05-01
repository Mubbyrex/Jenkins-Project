provider "aws" {
  region = "us-east-1"
}

# data for amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = [var.ami_name]
    }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "single-instance"

  instance_type          = "t2.micro"
  key_name               = "Terraform_hands_on"
  monitoring             = true
  vpc_security_group_ids = modulw.myapp-vpc.default_security_group_id
  subnet_id              = module.myapp-vpc.public_subnets[0]
  associate_public_ip_address = true
  availability_zone = var.availability_zone
  ami = data.aws_ami.amazon_linux_2.id

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

variable vpc_cidr_block {
  vpc_cidr_block = "10.0.0.0/24"
}
variable public_subnet_cidr_blocks {
  public_subnet_cidr_blocks = ["10.0.10.0/24"]
}
variable private_subnet_cidr_blocks {
  private_subnet_cidr_blocks = ["10.0.20.0/24"]
}

data "aws_availability_zones" "available" {}

module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

    name = "myapp-vpc"
    cidr = var.vpc_cidr_block
    private_subnets = var.private_subnet_cidr_blocks
    public_subnets = var.public_subnet_cidr_blocks
    azs = data.aws_availability_zones.available.names 
    
    enable_nat_gateway = true
    # allows all subnet to access internet through a single NAT Gateway
    single_nat_gateway = true
    enable_dns_hostnames = true

    tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    }

    public_subnet_tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
        "kubernetes.io/role/elb" = 1 
    }

    private_subnet_tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
        "kubernetes.io/role/internal-elb" = 1 
    }

}

output "ec2_public_ip" {
  value = module.ec2_instance.public_ip
}