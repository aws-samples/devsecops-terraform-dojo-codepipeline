# Roles assumed in CICD server (CodePipeline/CodeBuild) and also assumed when locally running the deployment
# https://aws.amazon.com/premiumsupport/knowledge-center/codebuild-temporary-credentials-docker/

resource "aws_iam_role" "automation_testing" {
  name = "automation_testing"
  tags = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com",
        "AWS": [ "${data.aws_caller_identity.current.account_id}", "${aws_iam_role.codebuild_assume_role.arn}" ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Allow read only access to any AWS resource
data "aws_iam_policy" "automation_readonly" {
  name = "SecurityAudit"
}

# Prefer aws_iam_role_policy_attachment over aws_iam_policy_attachment here, because aws_iam_policy_attachment resource creates exclusive attachments of IAM policies. Here we are using the AWS managed IAM policy, and we want to attach that policy to 2 IAM roles. Using aws_iam_policy_attachment here leads to Terraform attaching and detaching this policy on subsequent Terraform runs.
# Details: https://github.com/hashicorp/terraform/issues/6045
# and the warning at: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment
resource "aws_iam_role_policy_attachment" "automation_testing_readonly" {
  role      = aws_iam_role.automation_testing.name
  policy_arn = data.aws_iam_policy.automation_readonly.arn
}

# Allow write access to any AWS resource, based on tags
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/amazon-s3-policy-keys.html
# https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition_operators.html
# https://aws.amazon.com/premiumsupport/knowledge-center/iam-tag-based-restriction-policies/
resource "aws_iam_policy" "automation_testing_limit" {
  name   = "automation_testing_limit"
  tags   = local.tags
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
        "Sid": "AllowOnlyForChosenEnvironment",
        "Effect": "Allow",
        "Action": [ "*" ],
        "Resource": "*",
        "Condition": {
            "StringNotLike": {
                "aws:ResourceTag/environment": [ "production" ]
            }
        }
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "automation_testing_limit" {
  name       = "automation_testing_limit"
  roles      = [aws_iam_role.automation_testing.name]
  policy_arn = aws_iam_policy.automation_testing_limit.arn
}


resource "aws_iam_role" "automation_production" {
  name = "automation_production"
  tags = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com",
        "AWS": [ "${data.aws_caller_identity.current.account_id}", "${aws_iam_role.codebuild_assume_role.arn}" ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "automation_production_readonly" {
  role       = aws_iam_role.automation_production.name
  policy_arn = data.aws_iam_policy.automation_readonly.arn
}

resource "aws_iam_policy" "automation_production_limit" {
  name   = "automation_production_limit"
  tags   = local.tags
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
        "Sid": "AllowOnlyForChosenEnvironment",
        "Effect": "Allow",
        "Action": [ "*" ],
        "Resource": "*",
        "Condition": {
            "StringNotLike": {
                "aws:ResourceTag/environment": [ "testing" ]
            }
        }
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "automation_production_limit" {
  name       = "automation_production_limit"
  roles      = [aws_iam_role.automation_production.name]
  policy_arn = aws_iam_policy.automation_production_limit.arn
}
