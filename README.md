# Guide to is-terraform-aws-tfe-standalone-quick-install
Based on **Automated Installation of PTFE with External Services in AWS**.
Source: https://github.com/hashicorp/private-terraform-enterprise/tree/automated-aws-pes-installation

Stage 1: **TFE Standalone Prerequisites on AWS**
https://github.com/hashicorp/is-terraform-aws-tfe-standalone-prereqs

Stage 2: **TFE Standalone on AWS - Quick Install**
https://github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install/

## Overview 
This is a very long guide to deploying Terraform Enterprise using HashiCorp’s IS repo. The repo is close to, but not quite production-ready. It **should NOT** be used for an enterprise customer production deployment prior to some tweaking/customization. 

This repo contains Terraform configurations that:

* Do [automated installations](https://www.terraform.io/docs/enterprise/private/automating-the-installer.html) of [Terraform Enterprise](https://www.terraform.io/docs/enterprise/private/index.html) TFE in AWS
* Using either Ubuntu or Amazon Linux.
* The **Operational Mode** is **External Services**
* The **Installation Method** is **Online**. 
* Supports public and private networks. ::[pp] need to confirm::

See the  [examples](https://github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install/blob/master/examples)  section for detailed deployment scenarios & instructions. 

Several assumptions are made and default values are set for some of the resource arguments to reduce complexity and the amount of required inputs (see the  [Security Caveats](https://github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install/#%23Security-Caveats)  section).

[Guide to is-terraform-aws-tfe-standalone-quick-install - Required Inputs](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Required%20Inputs)
[Guide to is-terraform-aws-tfe-standalone-quick-install - Optional Inputs](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Optional%20Inputs)
[Guide to is-terraform-aws-tfe-standalone-quick-install - Outputs](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Outputs)

## Requirements
- Terraform >= 0.12.6
- TFE license file from Replicated (named `tfe-license.rli`) locally in Terraform working directory


## Prerequisites
- AWS account
- VPC with subnets that have outbound Internet connectivity
- One of the following, depending on the deployment scenario (see [examples](./examples) section) :
		- **Public** Route53 Hosted Zone (Hosted Zone type must be **Public** for DNS certificate validation to be fully automated with AWS Certificate Manager)
		- TLS/SSL certificate (imported into either **ACM** or **IAM**) with a Common Name matching the desired TFE hostname/FQDN (`tfe_hostname` required input)
 
Note: a [prereqs helper](https://github.com/hashicorp/is-terraform-aws-tfe-standalone-prereqs) module is available for reference and/or use if need be.

## Prerequisites

### Stage 2 Prerequisites
* You need to have an AWS account before running the **Stage 1** Terraform code in either the [network-public](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/network-public) or the [network-private](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/network-private) directory of this repository.

### Stage 2 Prerequisites
You need to have the following things before running the **Stage 2** Terraform code in the [aws](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws) directory of this repository:
* **AWS account**
* **VPC** - provisioned in stage 1
* at least two **Subnets** in that VPC like the ones provisioned in stage 1 
	* You can just use the same subnets for the EC2 instances, the PostgreSQL database, and the ALB or use separate subnets for these.
	* If you have more than two subnets, make sure that the two specified in the **alb_subnet_ids** variable include those containing the EC2 instances running PTFE.
* **Security group** - provisioned in **Stage 1**
* **S3 bucket** - provisioned in **Stage 1** - to be used as the TFE source bucket
* AWS **KMS key** - provisioned in **Stage 1**
* AWS **AMI** running a Ubuntu or Amazon Linux in the region in which you plan to deploy TFE
* AWS **key pair** that can be used to SSH to the EC2 instances that will be provisioned to run TFE.
* AWS **Route 53 zone** to host the Route 53 record set that will be provisioned.
	* This needs to be a public zone so that the ACM cert created can be validated against a record set created in that zone.
	* If you absolutely need to use a private zone, provide your own ACM cert and remove the code that provisions the additional ACM cert.
* **TFE license**
* If doing an airgap install, need a TFE airgap bundle and **replicated.tar.gz** installer bootstrapper that you can upload to the TFE **source bucket**.
	* Access to Docker and packages it requires so that you can upload them to the TFE source bucket.
* You can also provide the ARN of a certificate that you uploaded into or created within Amazon Certificate Manager (ACM).
		* This will be attached to the listeners created for the application load balancer that will be provisioned in front of the EC2 instances.
		* The **Stage 2** Terraform code actually creates an ACM certificate whether you provide one or not, but if you do provide your own, the generated one is associated with a fake domain consisting of "`fake-`" concatenated to your hostname.
		* If you set the `ssl_certificate_arn` variable to `""`, the generated ACM cert will be associated with your hostname.
		* We generate an ACM cert even if you provide your own in order to make the generation of an ACM cert optional in Terraform 0.11. (This will not be needed with Terraform 0.12.)


- - - -

## Explanation of the Two Stage Deployment Model

We deploy the *AWS infrastructure* and TFE in two stages using the open source flavor of Terraform.

### Stage 1
* Deploy **network** and **security group** resources that the EC2 instances will run in
* Deploy a private **S3 bucket** (source) to upload the PTFE software, license, and settings files ::[not used currently]::
* Deploy a **KMS key** to encrypt the S3 source bucket.
* If deploying a private network, then deploy an EC2 instance as a **bastion host**.
* **NOTE**: We provide two sets of Terraform code for Stage 1. One that provisions a public network and one that provisions a private network. ::[pp] Need to update based on IS prereqs helper.::

### Stage 2
* Deploy the external PostgreSQL database and S3 bucket (runtime) used in the [Production - External Services](https://www.terraform.io/docs/enterprise/private/preflight-installer.html#operational-mode-decision) operational mode of TFE.
* Deploy the **Auto Scaling Group** and **Launch Template** that will run TFE. 
* Deploy an **Application Load Balancer** and associated resources
* Deploy some required **IAM** resources.

* NOTE: We are creating an S3 bucket in both stages
	* The bucket created in **Stage 1** is the "**TFE source bucket**"
	* The bucket created in **Stage 2** is the "**TFE runtime bucket**".

### Why Two Stages?
There are two reasons for splitting the deployment into two stages:
* **Main reason**: Some users are not allowed to provision their own VPC, subnets, and security groups. They would would skip Stage 1. 
	* Users who are allowed to provision all required AWS resources, will perform Stage 1.
	* Deploy the network and security group resources and the TFE source bucket from the [network](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/network) directory
	* Copy the IDs of the VPC, subnets, and security groups into a **terraform.tfvars** file in the [aws](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws) directory
	* Then deploy the rest of the resources in Stage 2.
* **Second reason**: Some users want to be able to "repave" their TFE instances periodically. For example, they want to destroy the instances and recreate them (possibly with a new AMI).
	* These users need to create the TFE **source bucket** and then place the TFE software and license file in it before they run the Terraform code in **Stage 2**.

- - - -

## Usage
Follow these steps to deploy TFE in your AWS account.

### Deployment
See the [examples](./examples) section on how to properly source this module into a Terraform configuration under various deployment scenarios.

### Clone the Repo and Choose Deployment Scenario

* On your local computer, navigate to a directory such as **GitHub/hashicorp** into which you want to clone this repository. 
* Clone the repo. Go into repo folder

```
git clone https://github.com/phanclan/is-terraform-v4-examples.git
cd is-terraform-v4-examples
```

We will be using the using the Public Route53 and ACM scenario.

```
cd public-route53-and-acm
```

If you already have a VPC 

### Logging In
After the module has been deployed and the EC2 instance created by the Autoscaling Group has finished initializing, open a web browser and log in to the new TFE instance via the URL in the output value of `tfe_url`. 
* The username defaults to `admin` unless a value was specified for the input `tfe_initial_admin_username` input. 
* The **password** is the value set for the `tfe_initial_admin_pw` variable.
	* If not set, then it will be `random_password.tfe_initial_admin_pw.result` (found in the Terraform State file).
* The **console password** can be found here `terraform.tfstate > console_password`.


- - - -

# Example Scenarios
https://github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install/tree/master/examples

This section is intended to support multiple common deployment scenarios that have been encountered across various customers' cloud environments. The subdirectories within this section represent a single scenario. Each scenario will contain a "**best practice**" example that is more realistic to a customer use case, as well as a "**bare bones**" example that will include the absolute minimum amount of inputs. 

The most strategic architectural decisions that need to be addressed prior to deployment are as follows:

1. Where is the customer's Version Control System (VCS) hosted?  Public Internet (SaaS) / external or private / on-prem / internal?  This will dictate the following:
	- Whether the load balancer subnets will need to be public or private
	- Whether the load balancer expore will be external or internal
	- Whether the DNS record will need to be externally resolvable or not
	- Whether the TLS/SSL certificate will need to be signed by a Public CA or not
2. Which DNS service will the customer use?  Route53 or custom?
3. How will the customer issue the TLS/SSL certificate?  AWS Certificate Manager (ACM) or custom?

Go to  best practice scenario: [Scenario 1 - Public Route53 and AWS Certificate Manager (ACM)](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Scenario%201%20-%20Public%20Route53%20and%20AWS%20Certificate%20Manager%20%28ACM%29)

- [Prerequisites Helper](./prerequisites/README.md) 
- Scenario 1 - [Public Route53 and ACM](./public-route53-and-acm/README.md)
	- [Scenario 1 - Public Route53 and AWS Certificate Manager (ACM)](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Scenario%201%20-%20Public%20Route53%20and%20AWS%20Certificate%20Manager%20%28ACM%29)
- Scenario 2 - [Custom DNS and TLS/SSL](./custom-dns-and-tls/README.md)


### Notes on "Bare Bones" Examples

::This guide will not be using the Bare Bones examples.::

There are the ramifications to be aware of when not leveraging some of the other optional inputs listed below (starting with the two most important at the top):

- `route53_hosted_zone_name` - Route53 will not be used for Alias Record / CNAME (assumed that user is doing their own custom DNS), & module will not be able to create && validate AWS Certificate Manager (ACM) TLS/SSL certificate
- `tls_certificate_arn` - user does not have an existing TLS/SSL certificate imported into ACM or IAM, and prefers to have the module create & validate a new cert via **Route53** and **AWS Certfiicate Manager**
- `common_tags` - No "common" tags on AWS resources provisioned via this module (tagging resources is a best practice for most)
- `tfe_release_sequence` - TFE application version; defaults `""` via `locals.tf` - which means latest version available in Replicated (`""` can be unpredictable if the Autoscaling Group spawns a new EC2 instance, etc.)
- `tfe_initial_admin_username` - defaults to `admin` via `locals.tf`
- `tfe_initial_admin_email` - defaults to `admin@` + last portions of `tfe_hostname` FQDN via `locals.tf`
- `tfe_initial_admin_pw` - defaults to the value of `random_password.tfe_initial_admin_pw` (and can be found in the Terraform State post-deploy)
- `tfe_initial_org_name` - defaults to `"${var.friendly_name_prefix}-tfe-org"` via `locals.tf`
- `tfe_initial_org_email` - defaults to `tfe-admins@` + last portions `tfe_hostname` FQDN via `locals.tf`
- `load_balancer_is_internal` - default to `false`; if `alb_subnet_ids` contains private subnet IDs this input should be set to `true`
- `os_distro` - defaults to `amzn2`; other currently supported distro is `ubuntu`
- `ami_id` - defaults to `null`; only use if custom AMI is required (`os_distro` input value must match custom AMI Linux distro when used)
- `ssh_key_pair` - no SSH key pair will be added to Launch Template / EC2 instance
- `ingress_cidr_alb_allow` - defaults to `[0.0.0.0/0]`; Application Load Balancer (ALB) will be opened up to the world (_sometimes_ OK)
- `ingress_cidr_console_allow` - defaults to `null`; if not specified, CIDR ranges whitelisted for `ingress_cidr_alb_allow` will also be whitelisted for TFE Replicated Admin Console (port 8800)
- `ingress_cidr_ec2_allow` - defaults to `[]`; EC2 instance will not be accessible via SSH (_sometimes_ OK)
- `kms_key_arn` - KMS will NOT be used to encrypt S3 and RDS at the infrastructure layer (TFE already encrypts PostgreSQL and blob storage data via Vault Transit Encryption prior to writing to disk)


- - - -

## Scenario 1 - Public Route53 and AWS Certificate Manager (ACM)
This scenario, if achievable per the customer's environment && requirements, is generally the easiest approach to deploying TFE Standalone on AWS. This is because both DNS and TLS/SSL are fully automated. 

* A Route53 Alias record is created based on the `tfe_hostname` input with a target of the Application Load Balancer (ALB) resource DNS name. 
* A certificate is provisioned and signed via AWS Certificate Manager (ACM) with a Common Name of the `tfe_hostname` input, and is automatically validated via the DNS certificate validation method with Route53. 
* The Route53 Hosted Zone specified in the `route53_hosted_zone_name` input must be public for the DNS certificate validation to work properly.


### Ideal Use Case
- Customer's Version Control System (VCS) is hosted externally (SaaS)
- Customer wants to automate as much of the TFE Standalone infrastructure deployment as possible in a single Terraform configuration
- Customer is permitted to leverage Route53 Hosted Zone that is of the type **Public** for DNS
- Customer is permitted to leverage AWS Certificate Manager (ACM) to issue, provision, and validate TLS/SSL certificate


### Public vs. Private
As stated above, the Route53 Hosted Zone specified must be of the type **Public** in this scenario. However, customers can still specify either public subnet IDs or private subnet IDs for the `alb_subnet_ids` input. If the customer's VCS is externally hosted (SaaS), then the `alb_subnet_ids` input must contain public subnet IDs for the VCS integration to function properly. If `alb_subnet_ids` contains private subnet IDs, then the `load_balancer_is_internal` input should be set to `true`.


## Additional Required Input
- `route53_hosted_zone_name`

- - - -

## Provision Stage 1

[[Guide to is-terraform-aws-tfe-standalone-quick-install - Stage 1]]
https://github.com/hashicorp/is-terraform-aws-tfe-standalone-prereqs

Leverage one of the repos to deploy Stage 1 resources if you don’t already have them.


- - - -

## Provision Stage 2

> Provision Times - Items longer than 1 min  
> RDS - 12 minutes  
> ALB - 2-3 min  

Follow these steps to provision the **Stage 2** resources.

* Make sure you are in the `public-route53-and-acm` directory of the cloned repository.
* If you skipped **Stage 1**, do **steps 4-6** of that stage to export your AWS keys and default region.

### Set Variables
[Required Inputs](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Required%20Inputs)
[Compute Variables ](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Compute%20Variables)
[Database Variables ](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Database%20Variables)
[TFE Variables](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=TFE%20Variables)
[Network Variables](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Network%20Variables)

* I included the `ubuntu.auto.tfvars` file.

#### Common Variables
* Set `friendly_name_prefix` to the same namespace you set in [Stage 1](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Set%20Terraform%20Variables). ex: `"pphan"`
* Set `common_tags` as appropriate.
	* `Owner` and `TTL` are used within HashiCorp's own AWS account for resource reaping purposes.
```
common_tags = {
  Owner       = "pphan"
  Environment = "Test"
  Tool        = "Terraform"
  TTL         = "1day"
}
```

* Set `aws_region`.

#### Network Variables
* Set `vpc_id`, `ec2_subnet_ids`, `rds_subnet_ids`, `alb_subnet_ids`, and `security_group_id` to the corresponding **outputs** from [Stage 1](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Set%20Terraform%20Variables) or the IDs of the resources you created using other means.
```
vpc_id                    = "vpc-07b89518584abd90b"
# in format "[subnet-1,subnet-2]" (public or private, no space)
alb_subnet_ids            = ["subnet-04be8d0fe8aba96a4", "subnet-0b623ade19e6271c5"] 
# in format "subnet-1,subnet-2" (no space)
ec2_subnet_ids            = ["subnet-04be8d0fe8aba96a4", "subnet-0b623ade19e6271c5"] 
# in format "[subnet-1,subnet-2]" (no space)
rds_subnet_ids            = ["subnet-04be8d0fe8aba96a4", "subnet-0b623ade19e6271c5"] 
route53_hosted_zone_name  = "hashidemos.io"
load_balancer_is_internal = "false"
```
* Note on Subnets
	* The `*_subnet_ids` should be in the form `"[<subnet_1>","<subnet_2>"]`.
	* The `ec2` and `rds` subnets can be distinct or the same and can be public or private.
	* The `alb` subnets must be **public**.
* Set `public_ip` to
	* "`true`" if you want the EC2 instances to have public IPs (::pp::)
	* "`false`" if you don't want the EC2 instances to have public IPs.
* Set `load_balancer_is_internal` to
	* "`false`" if you want the ALB to not be internal [default]
	* "`true`" if you want the ALB to be internal
* Set `route53_hosted_zone_name` - ex `hashidemos.io` 

* Set `s3_sse_kms_key_id` to the `kms_id` output from [Stage 1](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Set%20Terraform%20Variables) or the ID of the KMS key you created using other means.
	* Example: ` 3740ade7-649c-4a3e-8f0e-7b524dd65db5`

Set the rest of the variables in the "`<linux_flavor>.auto.tfvars`" file.

#### Compute Variables 
* Set `instance_size` to
	* "`m5.large`" for demos and POCs. 
	* I use c5.xlarge (4 CPU) when demo'ing install for a customer. Is 2.5min faster than large.
	* 8 CPU does not seem to go any faster.
	* "`m5.large`", "`m5.xlarge`" or "`m5.2xlarge`" for production
* Set `os_distro` to
	* `ubuntu` or
	* `amzn2`  (::default::)

#### Database Variables 
* Set `rds_storage_capacity` to
	* "`10`" for demos
	* "**20**" for POCs
	* "**50**" for production  (::default::)
* Set `rds_instance_size` to
	* "`db.t2.medium`" for demos
	* "**db.m4.large**" for POCs (::default::)
	* "**db.m4.large**", "**db.m4.xlarge**" or "**db.m4.2xlarge**" for production.
* Set `rds_multi_az` to
	* "`false`" for demos (::default::)
	* "**true**" for POCs and production.
* Set `ssh_key_pair` to the name of your SSH keypair as it is displayed in the AWS Console.
	* `ssh_key_pair = "pphan-ptfe-ec2-key"`
	* [::pp::] I added a resource to create a `aws_key_pair` but you might already have one. Else you can manually create one in AWS console.
```
resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.namespace}-ec2-key"
  public_key = "<key>"
}
```

#### TFE Variables
* Set `tfe_hostname` - ex `"pphan-tfe.hashidemos.io"`
* Set `tfe_license_file_path` - ex `"./tfe-license.rli"`
	* I copy my Terraform license into my working directory and name it `tfe-license.rli`.
* Set `tfe_release_sequence`. Leave blank to default to latest version. 
	- [ ] [pp - add link to info why setting to specific version important and link to info on how to unset]
	* `tfe_release_sequence = ""`
* Set the following for the initial Terraform admin user and organization.
	* `tfe_initial_admin_username`. Default is `admin`.
	* `tfe_initial_admin_email`
	* `tfe_initial_admin_pw`
	* `tfe_initial_org_name` - example "`pphan-org`"
	* `tfe_initial_org_email`

* Set **ssl_certificate_arn** to the full ARN of the certificate you uploaded into or created within **Amazon Certificate Manager (ACM)**,
	* but if you want to use the ACM cert that Terraform will generate, set this to "" (blank).

* See [PTFE Automated Installation](https://www.terraform.io/docs/enterprise/private/automating-the-installer.html) for guidance on the various TFE settings that are passed into the `replicated.conf` and `ptfe-settings.json` files in the `*.tpl` files.

* The following values are usually manually entered running the TFE installer script.
- [ ] ::[pp] Currently this is dynamically set. Should allow setting with variables::
* The following values are automatically entered for you. Find them here: `data.template_file.tfe_user_data`
	* `enc_password`
	* `pg_dbname`
	* `pg_extra_params`
	* `pg_password`
	* `pg_user`
	* `s3_bucket`
	* `s3_region` (which would generally be the same as aws_region),
	* `s3_sse_kms_key_id`
	* `operational_mode`  - **online** or **airgapped** - IS is online only

### Modify the main.tf file to point to your copy of the repo.
You need to change the source of the "`tfe`" module. It is currently set to a private repo.

Your SE/TAM should have given an archive of the repo.
* Extract the archive.
* [optionally] Put into a VCS repo.
* Change the source reference to your local copy or to your repo.
```
module "tfe" {
  source = "github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install"
```

### Initialize and Apply
* Initialize the **Stage 2** Terraform configuration and download providers.
```
terraform init
```

* Provision the **Stage 2** resources.
```
terraform apply
```
	* Type "`yes`" when prompted.

* **NOTE**: The apply takes about **12 minutes**. 
	* Much of the time is spent creating the PostgreSQL database in RDS.

* Sample Output
```
Apply complete! Resources: 19 added, 0 changed, 0 destroyed.

Outputs:

db_endpoint = pphan-ptfe-db-instance.cflpqd1xguki.us-west-2.rds.amazonaws.com:5432
ptfe_fqdn = pphan-ptfe.hashidemos.io
ptfe_private_dns = [
    ip-10-110-1-73.us-west-2.compute.internal
]
ptfe_private_ip = [
    10.110.1.73
]
ptfe_public_dns = [
    ec2-54-184-113-93.us-west-2.compute.amazonaws.com
]
ptfe_public_ip = [
    54.184.113.93
]
```

- - - -

## SSH to EC2 instance
1. After you see outputs for the apply, go to the **AWS Console > EC2 > Auto Scaling Groups** page and find your ASG. You can filter by your `prefix`.
* Select your ASG.
	* My ASG is called: `pphan-tfe-asg`
	* Click **Instances** tab. Click the Instance ID link.
![](Guide%20to%20is-terraform-aws-tfe-standalone-quick-install/D041FA7D-FFF3-468F-8C5F-F16A21359F09.png)
* Click the **Connect** button and copy the SSH connection command.
* Type that command in a shell that contains your SSH private key from your AWS key pair and connect to your primary PTFE instance. (It might not be ready right away.)

Sample Output
```
ssh -i "pphan-tfe-ec2-key.pem" \
  ubuntu@ec2-54-186-193-174.us-west-2.compute.amazonaws.com
```

### Monitor the Install 
* Now, `tail` the `install-ptfe.log`.
* Tail `/var/log/cloud-init-output.log`
	`tail -f install-ptfe.log`
* NOTE: It is **ok** if you see multiple warnings in the log like:
`curl: (6) Could not resolve host: <ptfe_dns>`
	* This means that the script has run the installer and is currently testing the availability of the TFE application with `curl` every **5 seconds**.
	* You will also see this warning.
```
curl: (22) The requested URL returned error: 502 Bad Gatewayq
```
	* If this lasts for more than **5 minutes**, then something is wrong.
	* When the `install-ptfe.log`  or `/var/log/cloud-init-output.log` stops showing `curl` calls against the hostname and instead shows output related to the creation of the **initial admin user** and **organization**, then things should be good.

``` shell
+ curl -ksfS --connect-timeout 5 https://10.110.1.46/_health_check
OK+ '[' true == true ']'
+ echo 'Creating initial admin user and organization'
Creating initial admin user and organization
+ cat
++ replicated admin --tty=0 retrieve-iact
+ initial_token=OtzRwvj4yNNPSXfP9odg23JFcPtra84t
```

#### Check postgres
* Connect with `psql`
```
psql -h <db_endpoint> -d ptfe -U <pg_user>
psql -h pphan-tfe-rds-753646501470.cflpqd1xguki.us-west-2.rds.amazonaws.com \
  -d tfe -U tfe
```
	* `-h` is host. See `db_endpoint` from terraform output.
	* `-d` is database name. see `pg_dbname` value. IS default is `tfe`
	* `-U` is `tfe`
	* You will be asked for password. See `pg_password`.

Sample Output
```
tfe-> \dn
 List of schemas
   Name   | Owner 
----------+----------
 public   | postgres
 rails    | postgres
 registry | postgres
 vault    | postgres
(4 rows)

tfe=> \q
```

* Point a browser tab against:
	* `https://<tfe_admin_console_url:8800>`
	* `https://<tfe_url>`
	* ex https://pphan-tfe.hashidemos.io:8800
	* ex https://pphan-tfe.hashidemos.io


* Change your EC2 Security Group.
	* Restrict access to **22, 8800** to only your IP or subnets.
	* Consider the same for **80** and **443**.

## Log in to TFE
* Go to Load Balancer url: ex https://pphan-tfe.hashidemos.io
* Enter your username and your password and start using your new TFE server.
	* This is set in the `.tfvars` file.
* If you get any errors during the **Stage 2** apply related to the creation of the EC2 instances or the ALB, you can try running `terraform apply` a second time.
	* If the second apply is successful, then the user-data script on the primary EC2 instance should be able to get out of the curl loop and create the initial site admin user and organization.

* **NOTE: You do not need to visit the PTFE admin console at port 8800 when deploying TFE with the process given on this branch of this repository.**
	* Many of the tasks you would do in the admin console has been performed by bootstrap scripts using the TFE API.

* Destroy
		* `terraform destroy`
		* NOTE: Takes about 10 minutes


Add outputs
module.tfe.instances.

jq -r '.resources[].instances[].attributes.endpoint' terraform.tfstate | grep 5432
- - - -


## Best Practice

Set the following variables.
* `tfe_hostname`
* `tfe_release_sequence`
* `friendly_name_prefix`
* DB
	* rds_storage_capacity = "50"
	* `rds_instance_size = "db.t2.medium"`
	* `rds_multi_az = "false"`
* Network
```
vpc_id = "vpc-07b89518584abd90b"
```


https://github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install/blob/master/examples/public-route53-and-acm/main.tf

```hcl

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


- - - -

## Required Inputs
https://github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install/#required-inputs

| Name | Type | Description | Default Value |
| ———— | —— | ————— | —————— |
| `friendly_name_prefix` | string | String value for freindly name prefix for unique AWS resource names and tags | |
| `tfe_hostname` | string | Hostname of TFE instance | |
| `tfe_license_file_path` | string | Local file path to `tfe-license.rli` file including file name | |
| `vpc_id` | string | VPC ID that TFE will be deployed into | |
| `alb_subnet_ids` | list | List of Subnet IDs to use for Application Load Balancer (ALB) - can be public or private depending on scenario | |
| `ec2_subnet_ids` | list | List of Subnet IDs to use for EC2 instance - preferably private subnets | |
| `rds_subnet_ids` | list | Subnet IDs to use for RDS Database Subnet Group - preferably private subnets | |


- - - -

## Optional Inputs
https://github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install/#optional-inputs

| Name | Type | Description | Default Value |
| ———— | —— | ————— | —————— |
| `common_tags` | map | Map of common tags for taggable AWS resources | {} |
| `tfe_release_sequence` | string | TFE application version release sequence number within Replicated (leave blank for latest version) | null |
| `tfe_initial_admin_username` | string | Username for initial TFE local administrator account | null |
| `tfe_initial_admin_email` | string | Email address for initial TFE local administrator account | null |
| `tfe_initial_admin_pw` | string | Login password for TFE initial admin user created by this module - must be > 8 characters | null |
| `tfe_initial_org_name` | string | Name of initial TFE Organization created by bootstrap process / cloud-init script | null |
| `tfe_initial_org_email` | string | Email address of initial TFE Organization created by bootstrap process / cloud-init script | null |
| `route53_hosted_zone_name` | string | Route53 Hosted Zone where TFE Alias Record and Certificate Validation record will reside (required if `tls_certificate_arn` is not specified) | null |
| `load_balancer_is_internal` | boolean | Boolean value determining if Application Load Balancer (ALB) is internal or exteral | false |
| `ingress_cidr_alb_allow` | list | List of CIDR ranges to allow web traffic ingress to TFE Application Load Balancer | [0.0.0.0/0] |
| `ingress_cidr_console_allow` | list | List of CIDR ranges to allow TFE Replicated admin console (port 8800) traffic ingress to TFE LB | null |
| `ingress_cidr_ec2_allow` | list | List of CIDRs to allow SSH ingress to TFE EC2 instance | [] |
| `tls_certificate_arn` | string | ARN of ACM or IAM certificate to be used for Application Load Balancer HTTPS listeners (required if `route53_hosted_zone_name` is not specified) | `null` |
| `kms_key_arn` | string | ARN of KMS key to encrypt TFE S3 and RDS resources | `null` |
| `ssh_key_pair` | string | “Name of SSH key pair for TFE EC2 instance” | `null` |
| `os_distro` | string | Linux OS distribution for TFE EC2 instance | `amzn2` |
| `ami_id` | string | Optional custom AMI ID for TFE EC2 Launch Template | `null` |
| `instance_size` | string | EC2 instance type for TFE server | m5.large |
| `rds_storage_capacity` | string | Size capacity (GB) of RDS PostgreSQL database | 50 |
| `rds_engine_version` | string | Version of PostgreSQL for RDS engine | 11 |
| `rds_multi_az` | string | Set to true to enable multiple availability zone RDS | true |
| `rds_instance_size` | string | Instance size for RDS | `db.m4.large` |


- - - -

## Outputs
https://github.com/hashicorp/is-terraform-aws-tfe-standalone-quick-install/#outputs

| Name | Description |
| ———— | —— |
| `tfe_url` | URL to access TFE application |
| `tfe_admin_console_url` | URL to access TFE Replicated admin console |
| `tfe_alb_dns_name` | DNS name of TFE Application Load Balancer (ALB) |
| `tfe_s3_app_bucket_name` | TFE application S3 bucket name |


- - - -

## Idempotent Caveats
One reason for the disclaimer that this module is not considered 100% production-ready for an enterprise customer deployment is the _TFE application bootstrap_ logic within the end of the `user_data` scripts that leverage the [Initial Admin Creation Token](https://www.terraform.io/docs/enterprise/install/automating-initial-user.html#initial-admin-creation-token-iact-) to automatically create the initial admin user.  This token can only be used _once_ on the initial deployment.  On subsequent runs, a `401 unauthorized` error will be thrown and it will look like the `user_data` scripts did not complete successfully.  There is no detrimental impact from this aside from the error message the scripts will exit with.

Reference code:
```
# build payload for initial TFE admin user
cat > $tfe_config_dir/initial_admin_user.json <<EOF
{
	"username": "${tfe_initial_admin_username}",
	"email": "${tfe_initial_admin_email}",
	"password": "${tfe_initial_admin_pw}"
}
EOF

# retrieve Initial Admin Creation Token
iact=$(replicated admin --tty=0 retrieve-iact)

# HTTP POST to retrieve Initial Admin User Token
iaut=$(curl --header "Content-Type: application/json" --request POST --data @/opt/tfe/config/initial_admin_user.json "https://${tfe_hostname}/admin/initial-admin-user?token=$iact" | jq -r '.token')

# build payload for initial TFE Organization creation
cat > $tfe_config_dir/initial_org.json <<EOF
{
  "data": {
    "type": "organizations",
    "attributes": {
      "name": "${tfe_initial_org_name}",
      "email": "${tfe_initial_org_email}"
    }
  }
}
EOF


# HTTP POST to create initial TFE Organization
curl  --header "Authorization: Bearer $iaut" --header "Content-Type: application/vnd.api+json" --request POST --data @/opt/tfe/config/initial_org.json "https://${tfe_hostname}/api/v2/organizations"
```


- - - -

## Security Caveats
Another reason for the disclaimer that this module is not considered 100% production-ready for an enterprise customer deployment is related to how secrets are handled. It is a best practice to avoid having secrets as Terraform variables that will end up in Terraform state whenever possible. However, if the customer is protecting their Terraform Remote State properly (in a locked down, encrypted S3 bucket, for example), this may not be a concern at all. If that is the case, letting the module handle the secrets with a combination of `random_password` and Terraform input variables is the “easiest” approach.

### Secrets Management
There are mainly four sensitive values when fully automating a TFE Standalone deployment on AWS:

1. **RDS password** (`random_password.rds_password`) - this value has to go into Terraform state regardless, as it is a required arguement for the `aws_db_instance` Terraform resource. This module computes this value within Terraform via the `random_password` resource. Always make sure to appropriately protect Terraform state files. In order to achieve full automation, several RDS attribute values (including the RDS password) need to be placed in a `tfe-settings.json` file on the TFE instance. For the RDS password value specifically, the key name is `pg_password`. Again, since this value is going to be in Terraform state anyways, it is interpolated into the `template_file.tfe_user_data` data source for the user_data script. This one is more of an FYI.  
2. **Replicated console password** (`random_password.console_password`) - this is the password to unlock the Replicated admin console. In order to achieve full automation, this value needs to be placed in `/etc/replicated.conf` on the TFE instance, with a key name of `DaemonAuthenticationPassword`. It is possible to use LDAP here but I have not seen it in practice _(it may be more work than it’s worth)_. This module computes this value within Terraform via the `random_password` resource, which means this value will be in Terraform state. A better approach would be to have the `user_data` script retrieve the secret at build time from a proper secrets management system such as Vault, or even AWS Secrets Manager. Or, if the customer is comfortable with it, another approach could be to store the `replicated.conf` file in a highly locked down, encrypted S3 bucket.  
3. **Embedded Vault encryption password** (`random_password.enc_password`) - this only applies to deployments leveraging the embedded Vault _(which is the extremely highly recommended best practice at this point)_. This is considered _”secret zero”_ that encrypts the single Vault unseal key and Vault root token before they are written into the TFE PostgreSQL database. In order to achieve full automation, this value needs to be placed in a `tfe-settings.json` file on the TFE instance, with a key name of `enc_password`. This module computes this value within Terraform via the `random_password` resource, which means this value will be in Terraform state. A better approach would be to have the `user_data` script retrieve the secret at build time from a secrets management system such as Vault, or even AWS Secrets Manager. Or, if the customer is comfortable with it, another approach could be to store the `tfe-settings.json` file in a highly locked down, encrypted S3 bucket.  
4. **Initial admin user password** (`var.tfe_initial_admin_pw`) - one of the reasons this module is called “quick-install” is because as part of the bootsrap process, an initial admin user is created leveraging the [Initial Admin Creation Token](https://www.terraform.io/docs/enterprise/install/automating-initial-user.html#initial-admin-creation-token-iact-). In most cases, it is better to omit this functionality from an enterprise customer production deployment as they are more comfortable with setting up the initial admin user and organization in the TFE UI. This way, they can generate and store the password value in their own proper secrets management tool. This variable is optional; if left unspecified, the `random_password.tfe_initial_admin_pw` resource will take precedence.

### Other Security Hardening
Security and hardening largely depends on customers’ environments, existing/available tooling, internal practices/policies/procedures, and comfort level. 

Here are some other tweaks a customer may want to make:
- Disable/block SSH, and use something else like **AWS Systems Manager (SSM Agent)** for shell access to TFE instance
- Specify source CIDR block(s) for ingress traffic allowed to hit the TFE Application Load Balancer, instead of opening it up to `0.0.0.0/0`
- Enable **SELinux** ([only specific conditions are supported](https://www.terraform.io/docs/enterprise/before-installing/index.html#linux-instance))



- - - -

[Automated Installation of PTFE with External Services in AWS - Description of the User Data Script that Installs PTFE](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Description%20of%20the%20User%20Data%20Script%20that%20Installs%20PTFE)
[Automated Installation of PTFE with External Services in AWS - Example tfvars Files](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Example%20tfvars%20Files)
[Automated Installation of PTFE with External Services in AWS - Prerequisites](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Prerequisites)
[Automated Installation of PTFE with External Services in AWS - Installing PTFE](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Installing%20PTFE)
[Automated Installation of PTFE with External Services in AWS - Provision Stage 1](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Provision%20Stage%201)
[Automated Installation of PTFE with External Services in AWS - Provision Stage 2](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Provision%20Stage%202)
[Automated Installation of PTFE with External Services in AWS - Changes](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Changes)
[Automated Installation of PTFE with External Services in AWS - Troubleshooting](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Troubleshooting)
[Automated Installation of PTFE with External Services in AWS - Repaving Your PTFE Instances With Terraform](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Repaving%20Your%20PTFE%20Instances%20With%20Terraform)

[Automated Installation of PTFE with External Services in AWS - Resources](bear://x-callback-url/open-note?id=BE232B3D-94AE-49B6-9B33-B62095551C8C-66557-000513BBCB51AF13&header=Resources)


- - - -

## Description of the User Data Script that Installs PTFE

* During **Stage 2**, a user data script generated from one of six templates ([user-data-ubuntu-online.tpl](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/user-data-ubuntu-online.tpl), [user-data-ubuntu-airgapped.tpl](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/user-data-ubuntu-airgapped.tpl). [user-data-rhel-online.tpl](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/user-data-rhel-online.tpl), [user-data-rhel-airgapped.tpl](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/user-data-rhel-airgapped.tpl), [user-data-centos-online.tpl](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/user-data-centos-online.tpl), or [user-data-centos-airgapped.tpl](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/user-data-centos-airgapped.tpl) is run on each instance to install TFE on it and to initialize the PostgreSQL database and S3 bucket if that has not already been done.
	* The online scripts also install Docker.
	* Since the user data script is templated, all relevant TFE settings, whether entered in the **terraform.tfvars** file or computed by Terraform, are passed into it before it is run when the instances are deployed.
* The script does the following things:
	* Determines the private IP, private DNS, and public IP (in public networks) of each EC2 instance being deployed to run PTFE.
	* Writes out the **replicated.conf**, **ptfe-settings.json**, and **create_schemas.sql** files.
* At this point, different things happen depending on whether an "**online**" or "**airgapped**" installation is being done.

* In an an [online](https://www.terraform.io/docs/enterprise/private/install-installer.html#run-the-installer-online) installation, the script does the following:
	* Installs the AWS CLI and uses it to retrieve the TFE license file from the TFE **source bucket**.
	* Sets SELinux to permissive mode (except on RHEL).
	* Installs the `psql` utility and connects to the PostgreSQL database in order to create the three schemas needed by PTFE.
	* Downloads the PTFE installer using `curl` and then runs it to install both Docker and PTFE.
* In an [airgapped](https://www.terraform.io/docs/enterprise/private/install-installer.html#run-the-installer-airgapped) installation, we use AMIs that already have the aws CLI, psql, and Docker pre-installed. So, the script only does the following:
	* Downloads the PTFE license, airgap bundle, and the replicated bootstrapper (replicated.tar.gz) from the PTFE source bucket.
	* Runs the installer in airgapped mode to install PTFE.
* In either case, the installer uses the **replicated.conf**, **ptfe-settings.json**, **create_schemas.sql**, and **ptfe-license.rli** files that the script previously wrote to disk.
* The script then enters a loop, testing the availability of the TFE app with a `curl` command until it is ready.
* Finally, the script uses the `TFE API` to create
	* the first **site admin user**
	* a TFE API token for this user
	* the first organization.
	* This leverages the [Initial Admin Creation Token](https://www.terraform.io/docs/enterprise/private/automating-initial-user.html) (IACT).
	* At this point, the generated API token could be used to automate additional PTFE configuration if desired.

- - - -

## Example tfvars Files

* There are five example `tfvars` files that you can use with the Terraform configurations in this branch:
	* [public `network.auto.tfvars.example`](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/network-public/network.auto.tfvars.example) for use in **Stage 1** when deploying a public network.
	* [private `network.auto.tfvars.example`](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/network-private/network.auto.tfvars.example) for use in **Stage 1** when deploying a private network.
	* [ubuntu.auto.tfvars.example](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/ubuntu.auto.tfvars.example) for use in Stage 2 when deploying to Ubuntu.
	* [rhel.auto.tfvars.example](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/rhel.auto.tfvars.example) for use in Stage 2 when deploying to RHEL.
	* [centos.auto.tfvars.example](https://github.com/hashicorp/private-terraform-enterprise/blob/automated-aws-pes-installation/examples/aws/centos.auto.tfvars.example) for use in Stage 2 when deploying to CentOS.
* These files assume you are provisioning to the **us-west-2** region.
	* If you change this, make sure you select AMI IDs that exist in your region.
	* We have built Ubuntu, RHEL, and CentOS AMIs that have Docker, the `aws` CLI, and the `psql` client pre-installed; these are suitable for use with the **airgapped** installation option.
	* However, while we were able to make the Ubuntu and RHEL AMIs public, we were not able to make the CentOS AMI public.
	* See the `tfvars` files for the AMI IDs.
* Be sure to adjust the following variables if deploying for a POC or in production.
		* `aws_instance_type`
		* `database_storage`
		* `database_instance_class`
		* `database_multi_az`
		* Also set `create_second_instance` to "`1`" if you want to provision a secondary TFE instance in case the first one fails.
* The last three files (ubuntu, rhel, and centos) can be used with both online and airgapped installations.
		* If doing an **online** installation, set `operational_mode` to "**online**".
		* If doing an **airgapped** installation, set `operational_mode` to "**airgapped**".
* After doing an initial deployment, you should change `create_first_user_and_org` to "**false**" since the initial site admin user can only be created once.

- - - -


# Troubleshooting

* You can tail the audit log and watch it as you click around the TFE UI.  Just log into your server and run
`docker logs -f ptfe_atlas | grep "Audit Log"`
`docker logs ptfe_atlas --since 5m | grep “Audit Log”`

* The install script dumps the out to install-ptfe.log. You can view or tail it to see the bootstrap logs and `curl` test against TFE. 
```
tail -f install-ptfe.log
less install-ptfe.log
```

* To monitor the progress of the install process (cloud-init), 
	* SSH into the EC2 instance
	* Tail the logs. 
```
journalctl -xu cloud-final -f
```

* To review the logs once the cloud-init process has finished, 
```
journalctl -xu cloud-final -o cat`
```

* Consider leveraging a Bastion host in the VPC for SSH connectivity to the EC2 instance when deployed on private subnets (recommended).


- - - -

# A Comment About Certs

* The Terraform code in this branch of this repository uses self-signed certs generated by TFE on the EC2 instances and an ACM certificate on the listeners associated with the Application Load Balancer that it creates.
		* As mentioned above, you can provide your own cert or let the Terraform code generate one for you.
		* If you provide your own cert, it would ideally be a cert signed by a public certificate authority to better support integration with version control systems.
		* It is possible to use a cert signed by a private certificate authority, but you then need to make sure that your VCS system (if using one of our [supported VCS integrations](https://www.terraform.io/docs/enterprise/vcs/index.html) trusts that certificate authority.

# A Comment About Proxies

* While the code includes the `extra_no_proxy` variable and passes it into the generated `ptfe-settings.json` file through the template (`*.tpl`) files, it does not currently support proxies at this time since the commands used to run the TFE installer include the `no-proxy` flag.
		* If you need to use a proxy server, you could change those install commands to use `http-proxy=<proxy_server>:<port>` instead of `no-proxy` and also add `additional-no-proxy=<comma-separated-list>` to list the addresses that should bypass the proxy in a comma-delimited list without any spaces.
		* Also change the default value of `extra_no_proxy` to include those same addresses.

- - - -

# Repaving Your PTFE Instances With Terraform

* You can replace or "repave" the EC2 instance(s) running TFE with Terraform at any time by following this process:
	* Terminate the EC2 instance(s) in the AWS Console
* This will cause the EC2 instance(s) to be destroyed and recreated.
* In addition, it will cause the `aws_lb_target_group_attachment` resources associated with the application load balancer to be destroyed and recreated.
* This ensures that the ALB will always point to the primary TFE instance.
* ::WARNING::: When repaving instances, you will get errors when the script tries to create your first admin user and org, since you have already created the first site admin user and organization.


- - - -

# Resources
https://github.com/hashicorp/IS-TFE-Methodology

* SG Name
	* <prefix>-tfe-ec2-allow
	* tfe-lb-allow
	* <prefix>-tfe-outbound-allow
	* tfe-outbound-allow
* VPC
	* tfe-vpc
	* CIDR: 10.110.0.0/16
* Subnets:
	* -tfe-subnet-us-west-2a - 10.110.1.0/24
	* -tfe-subnet-us-west-2b - 10.110.2.0/24
* Route Table
	* -tfe-route-table
* IAM Role
	* <prefix>-tfe-instance-role-<region>
* ASG
	* -tfe-asg
* Launch Template
	* -tfe-ec2-asg-lt-primary
* Instances
	* -tfe-ec2-asg-lt-primary
* LB
	* -tfe-web-alb


- - - -

# Changes
		* I added a resource to create a `aws_key_pair` in `custom.tf` in root module.
```
resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.namespace}-ec2-key"
  public_key = "<pub_key>"
}
```

		* Added the following to `database/main.tf` resource `aws_db_instance.ptfe`.
			* This allows me to easily destroy the environment. Do **NOT** do this in production.
```
  # changes
  skip_final_snapshot       = "true"
  backup_retention_period   = "0" # disable backup
```

cloud_init to support ASG.
https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchTemplates.html
https://github.com/hashicorp/is-terraform-aws-ptfe-v4-prod/blob/master/templates/tfe_ubuntu_user_data.sh

* Checking ASG
	* Check Instances: https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances:search=phan
	* Check Target Groups: **Load Balancing > Target Groups**


- - - -



#hashicorp/products/terraform