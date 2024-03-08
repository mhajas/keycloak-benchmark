variable "region" {
  default = "eu-west-2"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

# Aurora options
variable "aurora" {
  type = object({
    name = string
    region = optional(string)
  })
}



