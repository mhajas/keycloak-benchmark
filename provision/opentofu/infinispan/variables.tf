variable "config_path" {}
variable "namespace" {}
variable "cross_dc_local_site"  {}
variable "cross_dc_remote_site" {}
variable "cross_dc_api_url" {}
variable "remote_config_path" {}

variable "cross_dc_sa_token_secret" {
  default = "xsite-token-secret"
}
variable cross_dc_jgrp_ts_secret {
  default = "xsite-truststore-secret"
}
variable cross_dc_jgrp_ks_secret {
  default = "xsite-keytore-secret"
}
variable cross_dc_external_router_enabled {
  default = "false"
}
variable cross_dc_enabled {
  default = "false"
}
variable cross_dc_hot_rod_password {}
variable cross_dc_histograms {
  default = "false"
}
variable cross_dc_mode {
  default = "SYNC"
}
variable cross_dc_state_transfer_mode {
  default = "AUTO"
}
variable cross_dc_ispn_replicas {
  default = "3"
}
variable cross_dc_cpu_requests {
  default = ""
}
variable cross_dc_memory_requests {
  default = ""
}
variable cross_dc_jvm_opts {
  default = ""
}
variable cross_dc_local_gossip_router {
  default = "true"
}
variable cross_dc_remote_gossip_router {
  default = "true"
}
variable cross_dc_fd_interval {
  default = "2000"
}
variable cross_dc_fd_timeout {
  default = "10000"
}
variable cross_dc_image {
  default = ""
}
