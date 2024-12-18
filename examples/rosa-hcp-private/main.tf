locals {
  account_role_prefix  = "${var.cluster_name}-account"
  operator_role_prefix = "${var.cluster_name}-operator"
}

############################
# Cluster
############################
module "hcp" {
  source = "../../"

  cluster_name               = var.cluster_name
  openshift_version          = var.openshift_version
  machine_cidr               = module.vpc.cidr_block
  aws_subnet_ids             = module.vpc.private_subnets
  replicas                   = 2
  private                    = true
  create_admin_user          = true
  admin_credentials_username = "admin"
  admin_credentials_password = random_password.password.result
  ec2_metadata_http_tokens   = "required"

  // STS configuration
  create_account_roles  = true
  account_role_prefix   = local.account_role_prefix
  create_oidc           = true
  create_operator_roles = true
  operator_role_prefix  = local.operator_role_prefix
}

resource "random_password" "password" {
  length      = 14
  special     = true
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
}

############################
# VPC
############################
module "vpc" {
  source = "../../modules/vpc"

  name_prefix              = var.cluster_name
  availability_zones_count = 1
}

############################
# Bastion instance for connection to the cluster
############################
module "bastion_host" {
  source         = "../../modules/bastion-host"
  prefix         = var.cluster_name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = [module.vpc.public_subnets[0]]
}
