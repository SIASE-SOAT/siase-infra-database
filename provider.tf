provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Component   = "database"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/siase/${var.environment}/vpc-id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/siase/${var.environment}/private-subnet-ids"
}

data "aws_ssm_parameter" "eks_node_sg_id" {
  name = "/siase/${var.environment}/eks-node-sg-id"
}

data "aws_caller_identity" "current" {}
