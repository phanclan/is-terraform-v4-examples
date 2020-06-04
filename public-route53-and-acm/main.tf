terraform {
  required_providers {
    aws      = "~> 2.53.0"
    random   = "~> 2.2.0"
    template = "~> 2.1.2"
  }
}

provider "aws" {
  region = var.aws_region
}

module "tfe" {
  source = "github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install"

  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  tfe_hostname               = var.tfe_hostname
  tfe_license_file_path      = var.tfe_license_file_path
  tfe_release_sequence       = var.tfe_release_sequence
  tfe_initial_admin_username = var.tfe_initial_admin_username
  tfe_initial_admin_email    = var.tfe_initial_admin_email
  tfe_initial_admin_pw       = var.tfe_initial_admin_pw
  tfe_initial_org_name       = var.tfe_initial_org_name

  vpc_id         = var.vpc_id
  alb_subnet_ids = var.alb_subnet_ids
  ec2_subnet_ids = var.ec2_subnet_ids
  rds_subnet_ids = var.rds_subnet_ids

  route53_hosted_zone_name = var.route53_hosted_zone_name

  os_distro                  = var.os_distro
  ssh_key_pair               = var.ssh_key_pair
  ingress_cidr_alb_allow     = var.ingress_cidr_alb_allow
  ingress_cidr_console_allow = var.ingress_cidr_console_allow
  ingress_cidr_ec2_allow     = var.ingress_cidr_ec2_allow
  kms_key_arn                = var.kms_key_arn
}