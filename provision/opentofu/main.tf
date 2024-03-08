provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module rosa_cluster_1 {
  source = "./rosa/"
  rosa_cluster_name = "gh-keycloak-a"
}
module rosa_cluster_2 {
  source = "./rosa/"
  rosa_cluster_name = "gh-keycloak-b"
}


module aurora {
  source = "./rds/"
  name = var.aurora.name
  region = var.aurora.region
#  depends_on = [module.rosa_cluster_1, module.rosa_cluster_2]
}

module ispn1 {
  source = "./infinispan/"
  config_path = module.rosa_cluster_1.kubeconfig
  namespace = "mhajas-keycloak"
  cross_dc_local_site = module.rosa_cluster_1.rosa_cluster_name
  cross_dc_remote_site = module.rosa_cluster_2.rosa_cluster_name
  cross_dc_hot_rod_password = "password" # TODO: Change
  cross_dc_api_url = "openshift://${module.rosa_cluster_2.api_url}"
  cross_dc_enabled = true
  cross_dc_external_router_enabled = true
  remote_config_path = module.rosa_cluster_2.kubeconfig
}

module ispn2 {
  source = "./infinispan/"
  config_path = module.rosa_cluster_2.kubeconfig
  namespace = "mhajas-keycloak"
  cross_dc_local_site = module.rosa_cluster_2.rosa_cluster_name
  cross_dc_remote_site = module.rosa_cluster_1.rosa_cluster_name
  cross_dc_hot_rod_password = "password" # TODO: Change
  cross_dc_api_url = "openshift://${module.rosa_cluster_1.api_url}"
  cross_dc_enabled = true
  cross_dc_external_router_enabled = true
  remote_config_path = module.rosa_cluster_1.kubeconfig
}











