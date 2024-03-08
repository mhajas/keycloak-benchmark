provider "kubernetes" {
  config_path    = var.config_path
}

provider "kubernetes" {
  config_path    = var.remote_config_path
  alias = "remote"
}

resource "kubernetes_namespace" "ispn" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "cross_dc_jgrp_ks_secret" {
  metadata {
    name      = var.cross_dc_jgrp_ks_secret
    namespace = var.namespace
  }
  binary_data = {
    "keystore.p12" = filebase64("${path.module}/../../infinispan/certs/keystore.p12")
  }
  data = {
    password     = "secret"
    type         = "pkcs12"
  }

}

resource "kubernetes_secret" "cross_dc_jgrp_ts_secret" {
  metadata {
    name      = var.cross_dc_jgrp_ts_secret
    namespace = var.namespace
  }
  binary_data = {
    "truststore.p12" = filebase64("${path.module}/../../infinispan/certs/truststore.p12")
  }
  data = {
    password       = "caSecret"
    type           = "pkcs12"
  }
}


resource "kubernetes_service_account" "ispn" {
  metadata {
    name = "xsite-sa"
    namespace = var.namespace
  }
}

resource "kubernetes_role_binding" "ispn" {
  metadata {
    name      = "view"
    namespace = var.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ispn.metadata.0.name
    namespace = var.namespace
  }
}

resource "kubernetes_secret" "sa_token" {
  metadata {
    name        = "ispn-xsite-sa-token"
    namespace   = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.ispn.metadata.0.name
    }
  }
  type = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

resource "kubernetes_secret" "ispn" {
  metadata {
    name        = var.cross_dc_sa_token_secret
    namespace   = var.namespace
  }

  data = {
    token = kubernetes_secret.sa_token.data["token"]
  }

  provider = kubernetes.remote
}

provider "helm" {
  kubernetes {
    config_path = var.config_path
  }
}

resource "helm_release" "ispn" {
  name      = "infinispan"
  chart     = "${path.module}/../../infinispan/ispn-helm"
  namespace = var.namespace

  set {
    name  = "namespace"
    value = var.namespace
  }
  set {
    name  = "replicas"
    value = var.cross_dc_ispn_replicas
  }
  set {
    name  = "cpu"
    value = var.cross_dc_cpu_requests
  }
  set {
    name  = "memory"
    value = var.cross_dc_memory_requests
  }
  set {
    name  = "jvmOptions"
    value = var.cross_dc_jvm_opts
  }
  set {
    name  = "crossdc.enabled"
    value = var.cross_dc_enabled
  }
  set {
    name  = "crossdc.local.name"
    value = var.cross_dc_local_site
  }
  set {
    name  = "crossdc.local.gossipRouterEnabled"
    value = var.cross_dc_local_gossip_router
  }
  set {
    name  = "crossdc.remote.name"
    value = var.cross_dc_remote_site
  }
  set {
    name  = "crossdc.remote.gossipRouterEnabled"
    value = var.cross_dc_remote_gossip_router
  }
  set {
    name  = "crossdc.remote.namespace"
    value = var.namespace
  }
  set {
    name  = "crossdc.remote.url"
    value = var.cross_dc_api_url
  }
  set {
    name  = "crossdc.remote.secret"
    value = var.cross_dc_sa_token_secret
  }
  set {
    name  = "crossdc.route.enabled"
    value = var.cross_dc_external_router_enabled
  }
  set {
    name  = "crossdc.route.tls.keystore.secret"
    value = var.cross_dc_jgrp_ks_secret
  }
  set {
    name  = "crossdc.route.tls.truststore.secret"
    value = var.cross_dc_jgrp_ts_secret
  }
  set {
    name  = "metrics.histograms"
    value = var.cross_dc_histograms
  }
  set {
    name  = "hotrodPassword"
    value = var.cross_dc_hot_rod_password
  }
  set {
    name  = "cacheDefaults.crossSiteMode"
    value = var.cross_dc_mode
  }
  set {
    name  = "cacheDefaults.stateTransferMode"
    value = var.cross_dc_state_transfer_mode
  }
  set {
    name  = "image"
    value = var.cross_dc_image
  }
  set {
    name  = "crossdc.fd.interval"
    value = var.cross_dc_fd_interval
  }
  set {
    name  = "crossdc.fd.timeout"
    value = var.cross_dc_fd_timeout
  }
}






