resource "aws_kms_key" "pipeline" {
  description             = var.project_name
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_alias" "pipeline" {
  name          = "alias/${var.project_name}"
  target_key_id = aws_kms_key.pipeline.key_id
}
