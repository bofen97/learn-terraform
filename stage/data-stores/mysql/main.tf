provider "aws" {
  region = "us-east-1"
}
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraform-up-and-running-state-ty1997"
    key            = "stage/data-stores/mysql/terraform.tfstate"
    region         = "us-east-1"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks-ty1997"
    encrypt        = true
  }
}
#get default vpc
data "aws_vpc" "default" {
  default = true
}

resource "aws_subnet" "rds_subnet_1" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = "172.31.48.0/20"  # 请确保这个CIDR块在你的VPC中是可用的
  availability_zone = "us-east-1a"  # 你可以根据需要更改可用区

  tags = {
    Name = "RDS Subnet 1"
  }
}

# 创建第二个子网（RDS需要至少两个子网）
resource "aws_subnet" "rds_subnet_2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.64.0/20"  # 确保这个CIDR块在你的VPC中是可用的，且与第一个子网不重叠
  availability_zone = "us-east-1b"

  tags = {
    Name = "RDS Subnet 2"
  }
}

# 创建DB子网组
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]

  tags = {
    Name = "RDS Subnet Group"
  }
}
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Security group for RDS"
  vpc_id      = data.aws_vpc.default.id

  # 允许所有入站MySQL流量
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 允许所有出站流量
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS Security Group"
  }
}

# 修改RDS实例配置
resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running-ty1997"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = "example_database"
  username            = var.db_username
  password            = var.db_password

  # 新增配置
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible    = true  # 允许公共访问

  tags = {
    Name = "Example RDS Instance"
  }
}