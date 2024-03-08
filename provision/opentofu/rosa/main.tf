
# TODO: Load aws secret in Terraform

data "external" "rosa" {
  program = [
    "sh", "${path.module}/scripts/use-rosa.sh", var.rosa_cluster_name
  ]
}
