resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "${var.project_name}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  acl           = "private"

  force_destroy = true
  tags          = local.tags
}

resource "aws_iam_role" "codepipeline_role" {
  name       = "${var.project_name}-codepipeline"
  tags       = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  inline_policy {
    name   = "inline_policy_for_codepipeline"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Action": [
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:Decrypt"
      ],
      "Resource": "${aws_kms_key.pipeline.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}
}

locals {
  checkov_action_run_order = var.run_tf_static_checks_parallely ? 1 : 2
}

resource "aws_codepipeline" "codepipeline" {
  name       = var.project_name
  role_arn   = aws_iam_role.codepipeline_role.arn
  tags       = local.tags

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id     = aws_kms_alias.pipeline.arn
      type   = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["Source_output"]

      configuration = {
        RepositoryName       = "${var.project_name}"
        BranchName           = "${var.repo_default_branch}"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "StaticChecks"

    action {
      name             = "TerraformLinters"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_output"]
      output_artifacts = ["StaticChecks_output"]
      version          = "1"
      run_order        = 1

      configuration = {
        ProjectName = "${aws_codebuild_project.tf_linters.name}"
      }
    }
    action {
      name             = "Checkov"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_output"]
      output_artifacts = ["Checkov_output"]
      version          = "1"
      run_order        = local.checkov_action_run_order

      configuration = {
        ProjectName = "${aws_codebuild_project.checkov.name}"
      }
    }
  }



  stage {
    name = "Testing"

    action {
      name             = "TerraformPlan"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_output"]
      output_artifacts = ["TestingTerraformPlan_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.tf_plan.name}"
        # example from:
        # https://docs.aws.amazon.com/codebuild/latest/APIReference/API_EnvironmentVariable.html
        EnvironmentVariables = jsonencode([
          {
            name  = "MY_ENVIRONMENT"
            value = "testing"
            type  = "PLAINTEXT"
          }
        ])
      }
      run_order = 1
    }
    action {
      name             = "TerraformApply"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_output", "TestingTerraformPlan_output"]
      output_artifacts = ["TestingTerraformApply_output"]
      version          = "1"

      configuration = {
        ProjectName   = "${aws_codebuild_project.tf_apply.name}"
        PrimarySource = "Source_output"
        EnvironmentVariables = jsonencode([
          {
            name  = "MY_ENVIRONMENT"
            value = "testing"
            type  = "PLAINTEXT"
          }
        ])
      }
      run_order = 2
    }
    action {
      name             = "Test"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_output"]
      output_artifacts = ["TestingTest_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.test.name}"
        EnvironmentVariables = jsonencode([
          {
            name  = "MY_ENVIRONMENT"
            value = "testing"
            type  = "PLAINTEXT"
          }
        ])
      }
      run_order = 3
    }
  }

  stage {
    name = "Production"

    action {
      name             = "TerraformPlan"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_output"]
      output_artifacts = ["ProductionTerraformPlan_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.tf_plan.name}"
        EnvironmentVariables = jsonencode([
          {
            name  = "MY_ENVIRONMENT"
            value = "production"
            type  = "PLAINTEXT"
          }
        ])
      }
      run_order = 1
    }
    action {
      name             = "TerraformApply"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_output", "ProductionTerraformPlan_output"]
      output_artifacts = ["ProductionTerraformApply_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.tf_apply.name}"
        # https://docs.aws.amazon.com/codebuild/latest/userguide/sample-pipeline-multi-input-output.html
        PrimarySource = "Source_output"
        EnvironmentVariables = jsonencode([
          {
            name  = "MY_ENVIRONMENT"
            value = "production"
            type  = "PLAINTEXT"
          }
        ])
      }
      run_order = 2
    }
    action {
      name             = "Test"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Source_output"]
      output_artifacts = ["ProductionTest_output"]
      version          = "1"

      configuration = {
        ProjectName = "${aws_codebuild_project.test.name}"
        EnvironmentVariables = jsonencode([
          {
            name  = "MY_ENVIRONMENT"
            value = "production"
            type  = "PLAINTEXT"
          }
        ])
      }
      run_order = 3
    }
  }

}
