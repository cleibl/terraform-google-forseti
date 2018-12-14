# Terraform Forseti Install

The Terraform Forseti module can be used to quickly install and configure [Forseti](https://forsetisecurity.org/) in a fresh cloud project.

## Usage
A simple setup is provided in the examples folder; however, the usage of the module within your own main.tf file is as follows:

```hcl
    /******************************************
      Forseti Module Install
     *****************************************/
    module "forseti-install-simple" {
      source                       = "terraform-google-modules/forseti/google"
      org_id                       = "395176825394"
      gsuite_admin_email           = "superadmin@yourdomain.com"
      project_id                   = "my-forseti-project"
      sendgrid_api_key             = "345675432456743"
      notification_recipient_email = "admins@yourdomain.com"
    }
```

Then perform the following commands on the config folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure

[^]: (autogen_docs_start)


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| forseti_repo_branch | Forseti repository branch | string | `stable` | no |
| forseti_repo_url | Foresti git repository URL | string | `https://github.com/GoogleCloudPlatform/forseti-security.git` | no |
| region | The location of resources | string | `us-east1` | no |
| gsuite_admin_email | The email of a GSuite super admin, used for pulling user directory information. | string | - | yes |
| notification_recipient_email | Notification recipient email | string | - | yes |
| project_id | The ID of the project where Forseti will be installed | string | - | yes |
| sendgrid_api_key | The Sendgrid api key for notifier | string | `` | no |
| storage_class | The Storage Class for the Forseti Buckets | string | `regional` | no |
| org_id | The ID of the Organization to provision resources | string | - | yes |
| force_destroy | When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run | boolean | true | no |
| lifecycle_rules | The bucket's Lifecycle Rules configuration. Multiple blocks of this type are permitted. Structure is documented below. | list | [] | no |
| versioning  | The bucket's Versioning configuration | string | `` | no |
| routing_mode | Sets the network-wide routing mode for Cloud Routers to use. Accepted values are 'GLOBAL' or 'REGIONAL'. Defaults to 'REGIONAL'. | string | `regional` | no |
| public_subnet_ip_cidr_range | The Public Subnet CIDR Range | string | `10.0.1.0/24` | no |
| private_subnet_ip_cidr_range | The Private Subnet CIDR Range | string | `10.0.2.0/24` | no |
| source_ssh_ranges            | The Source Ranges to Allow SSH Traffic to Forseti VM's | string | `0.0.0.0/0` | no |
| sql_port | The Port to connect to the cloudsql instance on | string | `3306` | no |
| machine_type | The Machine Type for the Forseti VM | string |  `n1-standard-n2` | no |
| compute_image | The Compute Image to use for the Forseti VM.  Note only Ubuntu 18.04-LTS has been tested | string | `ubuntu-os-cloud/ubuntu-1804-lts` | no |
| server_ip | Override the internal IP of the Forseti Server. If not provided, an internal IP will automatically be assigned. | string | `` | no |
| client_ip | Override the internal IP of the Forseti Client. If not provided, an internal IP will automatically be assigned. | string | `` | no |
| metadata | Metadata to be attached to the Forseti instance | map | { enable_oslogin = `TRUE`} | no |
| forseti_server_service_account_org_iam_roles | The Roles to assign to the Forseti Server Service Account at the Organization Level.  Note these are already least privlidge | list | `see variables.tf` | no |
| forseti_server_service_account_iam_roles | The Roles to assign to the Forseti Server Service Account at the Project Level | list | `see variables.tf` | no |
| forseti_client_service_account_iam_roles | The Roles to assign to the Forseti Client Service Account at the Project Level | list | `see variables.tf` | no |
| forseti-server-sa-scopes | The Service Account Scopes to Enable on the Forseti Server VM | list | `see variables.tf` | no |
| forseti-client-sa-scopes | The Service Account Scopes to Enable on the Forseti Client VM | list | `see variables.tf` | no |
| cron_schedule | The Cron Schedule Expression to tell forseti how often to run | string | `33 */2 * * *` | no

## Outputs

| Name | Description |
|------|-------------|
| forseti-server-bucket | The URL of the bucket for the forseti server |
| forseti-client-bucket | The URL of the bucket for the forseti client |
| forseti-server-external-ip | The External IP of the Forseti Server |
| forseti-client-external-ip | The External IP of the Forseti Client |
| forseti-mysql-instance-name | The Instance Name of the Forseti MySQL Server |
| forseti-mysql-instance-address | The external address of the mysql instance |
| forseti-mysql-database-name    | The Name of the Database used by Forseti   | 


[^]: (autogen_docs_end)

## Requirements
### Installation Dependencies
- [Terraform](https://www.terraform.io/downloads.html) 0.11.x
- [terraform-provider-google](https://github.com/terraform-providers/terraform-provider-google) plugin v1.12.0
- [jq](https://stedolan.github.io/jq/)
- [Python 2.7.x](https://www.python.org/getit/)
- [terraform-docs](https://github.com/segmentio/terraform-docs/releases) 0.3.0

### Service Account
In order to execute this module you must have a Service Account with the following roles assigned. There is a helpful setup script documented below which can automatically create this account for you.

**Organization Roles**:
- roles/resourcemanager.organizationAdmin

**Project Roles** on the Forseti install project:
- roles/compute.instanceAdmin
- roles/compute.networkViewer
- roles/compute.securityAdmin
- roles/deploymentmanager.editor
- roles/iam.serviceAccountAdmin
- roles/iam.serviceAccountUser
- roles/serviceusage.serviceUsageAdmin
- roles/storage.admin

### GSuite Admin
To use the IAM exploration functionality of Forseti, you will need a Super Admin on the Google Admin console. This admin's email must be passed in the `gsuite_admin_email` variable.

## Install
### Create the Service Account
You can create the service account manually, 
or by running the following command: 

```bash
./helpers/setup.sh <project_id>
```



Alternatively, you can [use Terraform](https://github.com/terraform-google-modules/terraform-google-forseti/blob/master/helpers/forseti-setup.tf) to create the Service Account and give it the proper permissions:

```bash
gcloud auth application-default login
cd helpers/
terraform plan
terraform apply
```

This will create a service account called `cloud-foundation-forseti-<random_numbers>`, give it the proper roles, and download it to your current directory. Note, that using this script assumes that you are currently authenticated as a user that can create/authorize service accounts at both the organization and project levels.

### Terraform
Be sure you have the correct Terraform version (0.11.x), you can choose the binary here:
- https://releases.hashicorp.com/terraform/

Additionally, you will need to export `TF_WARN_OUTPUT_ERRORS=1` to work around a [known issue](https://github.com/hashicorp/terraform/issues/17862) with Terraform when running terraform destroy.

### Manual steps
The following steps need to be performed manually/outside of this module.

#### Domain Wide Delegation
Remember to activate the Domain Wide Delegation on the Service Account that Forseti creates for the server operations.

The service account has the form `forseti-server-gcp-<number>@<project_id>.iam.gserviceaccount.com`.

Please refer to [the Forseti documentation](https://forsetisecurity.org/docs/howto/configure/gsuite-group-collection.html) for step by step directions.

More information about Domain Wide Delegation can be found [here](https://developers.google.com/admin-sdk/directory/v1/guides/delegation).

### Cleanup
Remember to cleanup the service account used to install Forseti either manually, or by running the command:

```bash
terraform destroy
```

## Autogeneration of documentation from .tf files
Run
```
make generate_docs
```

## File structure
The project has the following folders and files:

- /: root folder
- /examples: examples for using this module
- /main.tf: main file for this module, contains all the resources to create
- /variables.tf: all the variables for the module
- /README.md: this file
