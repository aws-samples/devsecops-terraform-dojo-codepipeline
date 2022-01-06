locals {
  tags = {
    creationMethod  = "terraform"
    creationProject = var.project_name
    cicdSetup       = "true"
  }
}
