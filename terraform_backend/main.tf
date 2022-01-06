locals {
  tags = {
    creationMethod  = "terraform"
    creationProject = var.project_name
    terraformSetup  = "true"
  }
}

resource "aws_s3_bucket" "terraform_setup" {
  bucket        = "${var.project_name}-terraform-states-${data.aws_caller_identity.current.account_id}"
  acl           = "private"
  tags          = local.tags
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_setup" {
  bucket                  = aws_s3_bucket.terraform_setup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_setup" {
  name           = "${var.project_name}-terraform-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = local.tags
}

resource "local_file" "terraform_states_s3_bucket_name" {
  content  = aws_s3_bucket.terraform_setup.id
  filename = "terraform_states_s3_bucket_name.txt"
}
