terraform {
  backend "local" {
    path = "terraform.tfstate"
  }


}




provider "aws" {
  alias   = "dev"
  version = "~> 2.0"
  region  = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::199678402132:role/cross-account"
    session_name = "terraform-deploy"
  }

}



resource "aws_codecommit_repository" "app-terraform" {
  repository_name = "wilbur-infrastructure"
  description     = "terraform for wilbur"
  provider = "aws.dev"
  provisioner "local-exec" {
    command = "${path.module}/wilbur-tf-branch.sh wilbur-infrastructure"
  }
}

