output "kubeconfig" {
  value = data.external.rosa.result.kubeconfig
}

output "api_url" {
  value = trimprefix(data.external.rosa.result.api_url, "https://")
}

output "rosa_cluster_name" {
  value = var.rosa_cluster_name
}
