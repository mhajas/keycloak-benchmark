provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module aurora {
  source = "./rds/"
  name = var.aurora.name
  region = var.aurora.region
}



