/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

terraform {
  backend "gcs" {
    bucket  = "forseti-tf-statefile"
    prefix  = "terraform/forseti-state"
  }
}

provider "google" {
  project = "${var.project_id}"
  region  = "${var.region}"
  zone    = "${lookup(var.region_map[var.region], "zone1")}"
}

/******************************************
  Locals configuration
 *****************************************/

locals {
  project_id           = "${var.project_id}"
  name                 = "forseti-${random_id.name.hex}"

  services_list = [
    "admin.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "bigquery-json.googleapis.com",
    "cloudbilling.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "compute.googleapis.com",
    "deploymentmanager.googleapis.com",
    "iam.googleapis.com",
  ]
}

/*******************************************
  Create Server and Client Configs
 *******************************************/

data "template_file" "forseti-server-config" {
  template = "${file("${format("%s/configs/forseti_server_conf.yaml.tpl", path.module)}")}"

  vars {
    email_recipient          = "${var.notification_recipient_email}"
    sendgrid_api_key         = "${var.sendgrid_api_key}"
    server_bucket_name       = "${module.server-storage-bucket.forseti_bucket_name}"
    domain_super_admin_email = "${var.gsuite_admin_email}"
    org_id                   = "${var.org_id}"
  }
}

data "template_file" "forseti-client-config" {
  template = "${file("${format("%s/configs/forseti_client_conf.yaml.tpl", path.module)}")}"

  vars {
    server_private_ip = "${google_compute_instance.forseti-server-vm.network_interface.0.network_ip}"
  }
}

/*******************************************
  Activate services
 *******************************************/
resource "google_project_service" "activate_services" {
  count   = "${length(local.services_list)}"
  project = "${local.project_id}"

  service = "${element(local.services_list, count.index)}"
  disable_on_destroy = false
}

/*******************************************
  Cloud Storage
 *******************************************/
module "client-storage-bucket" {
  source          = "./modules/storage"
  project_id      = "${local.project_id}"
  name            = "forseti-client"
  region          = "${var.region}"
  storage_class   = "${var.storage_class}"
  force_destroy   = "${var.force_destroy}"
  lifecycle_rules = "${var.lifecycle_rules}"
  versioning      = "${var.versioning}"
}

module "server-storage-bucket" {
  source          = "./modules/storage"
  project_id      = "${local.project_id}"
  name            = "forseti-server"
  region          = "${var.region}"
  storage_class   = "${var.storage_class}"
  force_destroy   = "${var.force_destroy}"
  lifecycle_rules = "${var.lifecycle_rules}"
  versioning      = "${var.versioning}"
}


/*******************************************
  Upload Server and Client Config to Bucket
 *******************************************/

resource "null_resource" "get_repo" {

  # Remove foresti existing repo
  provisioner "local-exec" {
    command = "rm -rf forseti-security"
  }

  # Clone repository
  provisioner "local-exec" {
    command = "git clone --single-branch -b ${var.forseti_repo_branch} ${var.forseti_repo_url}"
  }
}
resource "google_storage_bucket_object" "server-config" {
  name         = "configs/forseti_server_conf.yaml"
  content      = "${data.template_file.forseti-server-config.rendered}"
  bucket       = "${module.server-storage-bucket.forseti_bucket_name}"
}

resource "google_storage_bucket_object" "client-config" {
  name         = "configs/forseti_client_conf.yaml"
  content      = "${data.template_file.forseti-client-config.rendered}"
  bucket       = "${module.client-storage-bucket.forseti_bucket_name}"
}

/*******************************************
  Upload Rules to Bucket
 *******************************************/

resource "null_resource" "upload_rules" {
  depends_on = ["null_resource.get_repo"]

  # Upload Rules to Bucket
  provisioner "local-exec" {
    command = "gsutil cp forseti-security/rules/* ${module.server-storage-bucket.forseti_bucket_url}/rules/"
  }  
} 

/*******************************************
  Cloud SQL
 *******************************************/
resource "random_id" "name" {
  byte_length = 2
}
module "mysql-db" {
  source           = "./modules/cloudsql"
  name             = "forseti-server-db-${random_id.name.hex}"
  database_version = "MYSQL_5_7"
  region           = "${var.region}"
  db_name          = "forseti_security"
  user_name        = "root"
  user_password    = ""
}

/*******************************************
  Forseti Network
 *******************************************/
module "network" {
  source                       = "./modules/network"
  name                         = "${local.name}-network"
  project                      = "${local.project_id}"
  region                       = "${var.region}"
  routing_mode                 = "${var.routing_mode}"
  public_subnet_ip_cidr_range  = "${var.public_subnet_ip_cidr_range}"
  private_subnet_ip_cidr_range = "${var.private_subnet_ip_cidr_range}"
  forseti_server_sa            = "${google_service_account.forseti-server.email}"
  forseti_client_sa            = "${google_service_account.forseti-client.email}"
  ssh_source_ranges            = "${var.source_ssh_ranges}"
}

/*******************************************
  Forseti Server VM
 *******************************************/

resource "google_service_account" "forseti-server" {
  account_id   = "forseti-server-gcp-${random_id.name.hex}"
  display_name = "forseti-server-gcp-${random_id.name.hex}"
}


resource "google_service_account_iam_member" "admin-account-iam" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${google_service_account.forseti-server.account_id}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.forseti-server.email}"
}

resource "google_organization_iam_member" "forseti-server-account" {
  count   = "${length(var.forseti_server_service_account_org_iam_roles)}"
  org_id = "${var.org_id}"
  role    = "${element(var.forseti_server_service_account_org_iam_roles, count.index)}"
  member  = "serviceAccount:${google_service_account.forseti-server.email}"
}

resource "google_project_iam_member" "forseti-server-account" {
  count   = "${length(var.forseti_server_service_account_iam_roles)}"
  project = "${local.project_id}"
  role    = "${element(var.forseti_server_service_account_iam_roles, count.index)}"
  member  = "serviceAccount:${google_service_account.forseti-server.email}"
}

data "template_file" "forseti-server-startup-script" {
  template = "${file("${format("%s/scripts/forseti-server-install-script.sh", path.module)}")}"

  vars {
    FORSETI_SOURCE           = "${var.forseti_repo_url}"
    FORSETI_VERSION          = "${var.forseti_repo_branch}"
    SQL_PORT                 = "${var.sql_port}"
    FORSETI_STORAGE_BUCKET   = "${module.server-storage-bucket.forseti_bucket_name}"
    SQL_INSTANCE_CONN_STRING = "${var.project_id}:${var.region}:${module.mysql-db.instance_name}"
    FORSETI_DB_NAME          = "${module.mysql-db.database_name}"
    CRON_SCHEDULE            = "${var.cron_schedule}"
  }
}

resource "google_compute_instance" "forseti-server-vm" {
  name           = "forseti-server-vm"
  project        = "${local.project_id}"
  machine_type   = "${var.machine_type}"
  zone           = "${lookup(var.region_map[var.region], "zone1")}"
  can_ip_forward = false
  boot_disk {
    initialize_params {
      image = "${var.compute_image}"
    }
  }

  network_interface {
    subnetwork         = "${module.network.public_subnet_self_link}"
    access_config      = [
      {
        nat_ip = "${google_compute_address.forseti-server-ip.address}"
      }
    ]
    address            = "${var.server_ip}"
  }

  metadata = "${merge(
    map("startup-script", "${data.template_file.forseti-server-startup-script.rendered}"),
    var.metadata
  )}"

  service_account {
    email = "${google_service_account.forseti-server.email}"
    scopes = "${var.forseti-server-sa-scopes}"
  }
}

resource "google_compute_address" "forseti-server-ip" {
  name = "forseti-server-${random_id.name.hex}"
}

 /*******************************************
  Forseti Client VM
 *******************************************/

resource "google_service_account" "forseti-client" {
  account_id   = "forseti-client-gcp-${random_id.name.hex}"
  display_name = "forseti-client-gcp-${random_id.name.hex}"
}

resource "google_project_iam_member" "forseti-client-account" {
  count   = "${length(var.forseti_client_service_account_iam_roles)}"
  project = "${local.project_id}"
  role    = "${element(var.forseti_client_service_account_iam_roles, count.index)}"
  member  = "serviceAccount:${google_service_account.forseti-client.email}"
}

data "template_file" "forseti-client-startup-script" {
  template = "${file("${format("%s/scripts/forseti-client-install-script.sh", path.module)}")}"

  vars {
    FORSETI_SOURCE           = "${var.forseti_repo_url}"
    FORSETI_VERSION          = "${var.forseti_repo_branch}"
    FORSETI_CLIENT_BUCKET    = "${module.client-storage-bucket.forseti_bucket_name}"
  }
}

resource "google_compute_instance" "forseti-client-vm" {
  depends_on     = ["google_storage_bucket_object.client-config"]
  name           = "forseti-client-vm"
  project        = "${local.project_id}"
  machine_type   = "${var.machine_type}"
  zone           = "${lookup(var.region_map[var.region], "zone1")}"
  can_ip_forward = false
  boot_disk {
    initialize_params {
      image = "${var.compute_image}"
    }
  }

  network_interface {
    subnetwork         = "${module.network.public_subnet_self_link}"
    access_config      = [
      {
        nat_ip = "${google_compute_address.forseti-client-ip.address}"
      }
    ]
    address            = "${var.client_ip}"
  }

  metadata = "${merge(
    map("startup-script", "${data.template_file.forseti-client-startup-script.rendered}"),
    var.metadata
  )}"

  service_account {
    email = "${google_service_account.forseti-client.email}"
    scopes = "${var.forseti-client-sa-scopes}"
  }
}

resource "google_compute_address" "forseti-client-ip" {
  name = "forseti-client-${random_id.name.hex}"
}