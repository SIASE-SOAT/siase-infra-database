terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.52"
    }
  }

  backend "s3" {
    bucket         = "REPLACE_TF_STATE_BUCKET"
    key            = "siase-infra-database/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "REPLACE_TF_LOCK_TABLE"
  }
}
