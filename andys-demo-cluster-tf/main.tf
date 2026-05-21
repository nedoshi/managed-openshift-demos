locals {
  worker_node_replicas = var.multi_az ? 3 : 2
  pull_secret = var.pull_secret_path != null && var.pull_secret_path != "" ? file(pathexpand(var.pull_secret_path)) : null
}

module "rosa" {
  count                         = var.create_rosa ? 1 : 0
  source                        = "./rosa"
  create_vpc                    = var.create_vpc
  deploy_ai_machine_pool        = var.deploy_ai_machine_pool
  deploy_graviton_machine_pool  = var.deploy_graviton_machine_pool
  deploy_lokistack_machine_pool = var.deploy_lokistack_machine_pool
  deploy_virt_machine_pool      = var.deploy_virt_machine_pool
  private_cluster               = var.private_cluster
  cluster_name                  = var.cluster_name
  openshift_version             = var.rosa_openshift_version
}

module "aro" {
  count             = var.create_aro ? 1 : 0
  source            = "./aro"
  subscription_id   = var.subscription_id
  domain            = var.domain
  cluster_name      = var.cluster_name
  openshift_version = var.aro_openshift_version
  tags              = var.default_azure_tags
  pull_secret       = local.pull_secret
}
