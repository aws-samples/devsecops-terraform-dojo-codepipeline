resource "aws_cloudwatch_event_rule" "pipeline_trigger" {
  name        = "${var.project_name}-trigger"
  description = "Rule for triggering CodePipeline from CodeCommit ${var.project_name} repo"
  tags        = local.tags

  event_pattern = <<EOF
{
  "source": ["aws.codecommit"],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "resources": [
    "arn:aws:codecommit:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.project_name}"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ],
    "referenceType": [
      "branch"
    ],
    "referenceName": [
      "${var.repo_default_branch}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "pipeline" {
  rule      = aws_cloudwatch_event_rule.pipeline_trigger.name
  target_id = "TriggerPipeline-${aws_codepipeline.codepipeline.name}"
  arn       = aws_codepipeline.codepipeline.arn
  role_arn  = aws_iam_role.codepipeline_trigger.arn
}

resource "aws_iam_role" "codepipeline_trigger" {
  name = "${var.project_name}-codepipeline_trigger"
  tags = local.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_trigger" {
  name = "${var.project_name}-codepipeline_trigger"
  role = aws_iam_role.codepipeline_trigger.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "${aws_codepipeline.codepipeline.arn}"
            ]
        }
    ]
}
EOF
}
