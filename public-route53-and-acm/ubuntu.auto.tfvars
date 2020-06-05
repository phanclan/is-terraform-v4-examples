#------------------------------------------------------------------------------
# COMMON
#------------------------------------------------------------------------------
# namespace = "pphan" # must match stage 1
friendly_name_prefix = "pphan"
common_tags = {
  Owner       = "pphan"
  Environment = "Test"
  Tool        = "Terraform"
  TTL         = "1day"
}
aws_region = "us-west-2"

###############################################################################
# ssl_certificate_arn = ""
# owner = "pphan"
# ttl = "24h"
# source_bucket_name = "pphan-tfe-source-bucket"

#------------------------------------------------------------------------------
# TFE
#------------------------------------------------------------------------------

tfe_hostname               = "pphan-tfe.hashidemos.io"
tfe_license_file_path      = "./tfe-license.rli"
tfe_release_sequence       = "" # leave blank to default to latest version (421)
tfe_initial_admin_username = "pphan"
tfe_initial_admin_email    = "pphan@hashicorp.com"
tfe_initial_admin_pw       = "super-secure"
tfe_initial_org_name       = "pphan-org"
tfe_initial_org_email      = "pphan@hashicorp.com"
# tfe_admin_password = "super-secure" # Randomly generated for console

# enc_password              = "super-secure"
# extra_no_proxy            = ""
# pg_dbname                 = "tfe"
# pg_extra_params           = ""
# pg_password               = "super-secure" # Randomly generated
# pg_user                   = "postgres"
# operational_mode          = "online" # online or airgapped - IS is online only
# airgap_bundle             = "tfe-384.airgap"
# replicated_bootstrapper   = "replicated.tar.gz"

#------------------------------------------------------------------------------
# NETWORK - data needs to be refreshed everytime - from Stage 1 outputs
#------------------------------------------------------------------------------

vpc_id                    = "vpc-07b89518584abd90b"
alb_subnet_ids            = ["subnet-04be8d0fe8aba96a4", "subnet-0b623ade19e6271c5"] # in format "[subnet-1,subnet-2]" (public or private, no space)
ec2_subnet_ids            = ["subnet-04be8d0fe8aba96a4", "subnet-0b623ade19e6271c5"] # in format "subnet-1,subnet-2" (no space)
rds_subnet_ids            = ["subnet-04be8d0fe8aba96a4", "subnet-0b623ade19e6271c5"] # in format "[subnet-1,subnet-2]" (no space)
route53_hosted_zone_name  = "hashidemos.io"
load_balancer_is_internal = "false"

#------------------------------------------------------------------------------
# SECURITY
#------------------------------------------------------------------------------

# security_group_id = "sg-09c976f059a876949" #IS version generates new one
ingress_cidr_alb_allow     = ["0.0.0.0/0"]
ingress_cidr_console_allow = ["0.0.0.0/0"]
ingress_cidr_ec2_allow     = ["1.1.1.1/32", "2.2.2.2/32", "0.0.0.0/0"] # my workstation IP, my Bastion host IP, test
# tls_certificate_arn
# kms_key_arn
ssh_key_pair = "pphan-tfe-ec2-key"

#------------------------------------------------------------------------------
# COMPUTE
#------------------------------------------------------------------------------

os_distro = "ubuntu" #amzn2
# aws_instance_ami = "ami-09c08e9cd8d9c1b93" # Online us-w-2
# aws_instance_ami = "ami-0565af6e282977273" # online us-e-1
# aws_instance_ami = "ami-02941105c56601b38" # airgapped us-e-1
# Use m5.large for POCs. t3.large is slow.
# Use m5.large, m5.xlarge or m5.2xlarge for production
instance_size = "c5.xlarge"

# public_ip = "true" #Roger

#------------------------------------------------------------------------------
# DATABASE
#------------------------------------------------------------------------------

# Use 10 for demo, 20 for POC, 50 for Production
rds_storage_capacity = "50"
# Use db.t2.medium for demo, db.m4.large for POC
# Use db.m4.large, db.m4.xlarge or db.m4.2xlarge for production
rds_instance_size = "db.t2.medium"
# Use "false" for demo, "true" for POC and Production
rds_multi_az = "false"
# ssh_key_name = "pphan-tfe-ec2-key"
# ssh_key_name = aws_key_pair.ec2_key.id

#------------------------------------------------------------------------------
# STORAGE
#------------------------------------------------------------------------------
# the following used in Rogers. Not in IS. IS creates without these variables.
# s3_bucket = "pphan-tfe-runtime-bucket"
# s3_region = "us-west-2"
# s3_sse_kms_key_id = "6dce1f8a-e603-4f9b-98e8-7aaed24a3ae9" # Needs to be refreshed
