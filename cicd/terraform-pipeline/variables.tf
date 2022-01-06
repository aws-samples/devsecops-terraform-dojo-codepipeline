variable "project_name" {
  type = string
}

variable "build_timeout" {
  description = "The time to wait for a CodeBuild to complete before timing out in minutes (default: 5)"
  default     = "5"
}

variable "build_compute_type" {
  description = "The build instance type for CodeBuild (default: BUILD_GENERAL1_SMALL)"
  default     = "BUILD_GENERAL1_SMALL"
}

# https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
variable "build_image" {
  description = "The build image for CodeBuild to use"
  default     = "aws/codebuild/standard:5.0"
}

variable "build_privileged_override" {
  description = "If you want to run Docker in Docker, set this to true"
  default     = "true"
}

variable "buildspec_tf_linters" {
  default = "cicd/buildspec_tf_linters.yml"
}

variable "codebuild_image" {
  default = "aws/codebuild/standard:5.0"
}

variable "codebuild_checkov_image" {
  default = "aws/codebuild/standard:5.0"
}

variable "buildspec_checkov" {
  default = "cicd/buildspec_checkov.yml"
}

variable "repo_default_branch" {
  type    = string
  default = "main"
}

variable "buildspec_tf_plan" {
  default = "cicd/buildspec_tf_plan.yml"
}

variable "buildspec_tf_apply" {
  default = "cicd/buildspec_tf_apply.yml"
}

variable "buildspec_test" {
  default = "cicd/buildspec_test.yml"
}

variable "run_tf_static_checks_parallely" {
  default = false
}
