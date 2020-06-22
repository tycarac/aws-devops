/* Bootstrap terraform with creating the AWS S3 resources needed for tracking/maintaining state.
 */
terraform {
  required_version = "~> 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.67"
    }
  }
}

provider "aws" {
  region = var.deploy_region
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket              = aws_s3_bucket.terraform_state.id
  block_public_acls   = true
  block_public_policy = true
}

resource "aws_s3_bucket_public_access_block" "log_sink" {
  bucket              = aws_s3_bucket.log-sink.id
  block_public_acls   = true
  block_public_policy = true
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tycarac-devops"
  acl    = "private"
  lifecycle {
    prevent_destroy = true
  }
  versioning {
    enabled    = true
    mfa_delete = false
  }
  logging {
    target_bucket = aws_s3_bucket.log-sink.id
    target_prefix = "log/"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "log-sink" {
  bucket = "tycarac-logging"
  acl    = "log-delivery-write"
  lifecycle {
    prevent_destroy = true
  }
  lifecycle_rule {
    id      = "log"
    enabled = true
    prefix  = "log/"
    expiration {
      days = 65
    }
    tags = {
      product   = "devops"
      autoclean = true
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


