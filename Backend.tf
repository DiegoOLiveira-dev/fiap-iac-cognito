terraform {
  backend "s3" {
    bucket = "terraform-state-fiap"
    key    = "Prod/cognito/terraform.tfstate"
    region = "us-east-1"
  }
}