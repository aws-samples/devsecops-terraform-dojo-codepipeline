locals {
  tags = {
    environment     = var.environment
    creationMethod  = "terraform"
    creationProject = var.project_name
  }
}


resource "aws_kms_key" "my_key" {
  description             = "KMS key 1 in ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags                    = local.tags
}

resource "aws_kms_alias" "my_key" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.my_key.key_id
}

resource "aws_s3_bucket" "my_bucket" {
  # checkov:skip=CKV_AWS_144:no need for cross-region replication here
  # checkov:skip=CKV_AWS_18:no need for access logging here

  bucket        = "${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.environment}"
  acl           = "private"
  tags          = local.tags
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.my_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "object" {
  bucket      = aws_s3_bucket.my_bucket.id
  key         = "main.py"
  source      = "${path.module}/main.py"
  source_hash = filemd5("${path.module}/main.py")
  tags        = local.tags
}

resource "aws_ssm_parameter" "my_param1" {
  name  = "/${var.project_name}-${var.environment}/my_param1"
  type  = "String"
  value = var.my_param1
  tags  = local.tags
}
