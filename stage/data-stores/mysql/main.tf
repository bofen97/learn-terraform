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
resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running-ty1997"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  skip_final_snapshot = true
  db_name             = "example_database"

  # How should we set the username and password?
  username = var.db_username
  password = var.db_password
}