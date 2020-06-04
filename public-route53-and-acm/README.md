# Scenario 1 - Public Route53 and AWS Certificate Manager (ACM)
This scenario, if achievable per the customer's environment && requirements, is generally the easiest approach to deploying TFE Standalone on AWS. This is because both DNS and TLS/SSL are fully automated. A Route53 Alias record is created based on the `tfe_hostname` input with a target of the Application Load Balancer (ALB) resource DNS name. A certificate is provisioned and signed via AWS Certificate Manager (ACM) with a Common Name of the `tfe_hostname` input, and is automatically validated via the DNS certificate validation method with Route53. The Route53 Hosted Zone specified in the `route53_hosted_zone_name` input must be public for the DNS certificate validation to work properly.
<p>&nbsp;</p>


## Ideal Use Case
 - Customer's Version Control System (VCS) is hosted externally (SaaS)
 - Customer wants to automate as much of the TFE Standalone infrastructure deployment as possible in a single Terraform configuration
 - Customer is permitted to leverage Route53 Hosted Zone that is of the type **Public** for DNS
 - Customer is permitted to leverage AWS Certificate Manager (ACM) to issue, provision, and validate TLS/SSL certificate
<p>&nbsp;</p>


## Public vs. Private
As stated above, the Route53 Hosted Zone specified must be of the type **Public** in this scenario. However, customers can still specify either public subnet IDs or private subnet IDs for the `alb_subnet_ids` input. If the customer's VCS is externally hosted (SaaS), then the `alb_subnet_ids` input must contain public subnet IDs for the VCS integration to function properly. If `alb_subnet_ids` contains private subnet IDs, then the `load_balancer_is_internal` input should be set to `true`.
<p>&nbsp;</p>


## Additional Required Input
 - `route53_hosted_zone_name`
<p>&nbsp;</p>


## Best Practice
```hcl
terraform {
  required_providers {
    aws      = "~> 2.53.0"
    random   = "~> 2.2.0"
    template = "~> 2.1.2"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "tfe" {
  source = "github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install"

  friendly_name_prefix       = "my-unique-prefix"
  common_tags                = {
                                 "Environment" = "Test"
                                 "Tool"        = "Terraform"
                                 "Owner"       = "YourName"
                               }
  
  tfe_hostname               = "my-tfe-instance.whatever.com"
  tfe_license_file_path      = "./tfe-license.rli"
  tfe_release_sequence       = "421"
  tfe_initial_admin_username = "tfe-local-admin"
  tfe_initial_admin_email    = "tfe-admin@whatever.com"
  tfe_initial_admin_pw       = "ThisAintSecure123!"
  tfe_initial_org_name       = "whatever-org"
  tfe_initial_org_email      = "tfe-admins@whatever.com"
  
  vpc_id                     = "vpc-00000000000000000"
  alb_subnet_ids             = ["subnet-00000000000000000", "subnet-11111111111111111", "subnet-22222222222222222"] # public or private subnet IDs
  ec2_subnet_ids             = ["subnet-33333333333333333", "subnet-44444444444444444", "subnet-55555555555555555"] # private subnet IDs
  rds_subnet_ids             = ["subnet-33333333333333333", "subnet-44444444444444444", "subnet-55555555555555555"] # private subnets IDs

  route53_hosted_zone_name   = "whatever.com"
  
  os_distro                  = "amzn2"
  ssh_key_pair               = "my-key-pair-us-east-1"
  ingress_cidr_alb_allow     = ["0.0.0.0/0"]
  ingress_cidr_ec2_allow     = ["1.1.1.1/32", "2.2.2.2/32"] # my workstation IP, my Bastion host IP
  kms_key_arn                = "arn:aws:kms:us-east-1:000000000000:key/00000000-1111-2222-3333-444444444444"
  
output "tfe_url" {
  value = module.tfe.tfe_url
}

output "tfe_admin_console_url" {
  value = module.tfe.tfe_admin_console_url
}
```
<p>&nbsp;</p>


## Bare Bones
```hcl
provider "aws" {
  region = "us-east-1"
}

module "tfe" {
  source = "github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install"

  friendly_name_prefix       = "my-unique-prefix"
  tfe_hostname               = "my-tfe-instance.whatever.com"
  tfe_license_file_path      = "./tfe-license.rli"
  vpc_id                     = "vpc-00000000000000000"
  alb_subnet_ids             = ["subnet-00000000000000000", "subnet-11111111111111111", "subnet-22222222222222222"] # public subnet IDs
  ec2_subnet_ids             = ["subnet-33333333333333333", "subnet-44444444444444444", "subnet-55555555555555555"] # private subnets IDs
  rds_subnet_ids             = ["subnet-33333333333333333", "subnet-44444444444444444", "subnet-55555555555555555"] # private subnets IDs
  route53_hosted_zone_name   = "whatever.com"
}

output "tfe_url" {
  value = module.tfe.tfe_url
}

output "tfe_admin_console_url" {
  value = module.tfe.tfe_admin_console_url
}
```
