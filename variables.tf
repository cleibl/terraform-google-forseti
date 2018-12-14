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
variable "sendgrid_api_key" {
  description = "The Sendgrid api key for notifier"
}

variable "notification_recipient_email" {
  description = "Notification recipient email"
}

variable "gsuite_admin_email" {
  description = "The email of a GSuite super admin, used for pulling user directory information."
}

variable "project_id" {
  description = "The ID of the project where Forseti will be installed"
}

variable "org_id" {
  description = "The Organization ID to associate the Forseti Project to"
}

variable "region" {
  description = "The Region to deploy Forseti Into"
  default     = "us-east1"
 }

variable "storage_class" {
    description = "The Storage Class of the new bucket. Supported values include: MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE."
    default     = "REGIONAL"
 } 
variable "force_destroy" {
    description = "When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run."
    default     = "true"
 }
variable "lifecycle_rules" {
    description = "The bucket's Lifecycle Rules configuration. Multiple blocks of this type are permitted. Structure is documented below."
    default     = []
    type        = "list"
 }
variable "versioning" { 
    description = "The bucket's Versioning configuration."
    default     = ""
}
variable "routing_mode" {
    description = "Sets the network-wide routing mode for Cloud Routers to use. Accepted values are 'GLOBAL' or 'REGIONAL'. Defaults to 'REGIONAL'."
    default     = "REGIONAL"
 }

variable "public_subnet_ip_cidr_range" { 
  description = "The Public Subnet CIDR Range"
  default     = "10.0.1.0/24"
}

variable "private_subnet_ip_cidr_range" { 
  description = "The Public Subnet CIDR Range"
  default     = "10.0.2.0/24"
}

variable "source_ssh_ranges" {
  type        = "list"
  description = "List of CIDR Ranges to Allow SSH Access to Forseti VM"
  default     = ["0.0.0.0/0"]
}

variable "forseti_repo_url" {
  description = "Foresti git repository URL"
  default     = "https://github.com/GoogleCloudPlatform/forseti-security.git"
}

variable "forseti_repo_branch" {
  description = "Forseti repository branch"
  default     = "stable"
}

variable "sql_port" {
  description = "The SQL Port to Connect to Cloud SQL on"
  default     = "3306"
}

variable region_map {
  description = "Map of default zones and IPs for each region. Can be overridden using the `zone` variables."
  type        = "map"

  default = {
    asia-east1 = {
      zone1 = "asia-east1-a"
      zone2 = "asia-east1-b"
      zone3 = "asia-east1-c"
    }

    asia-east2 = {
      zone1 = "asia-east2-a"
      zone2 = "asia-east2-b"
      zone3 = "asia-east2-c"
    }

    asia-northeast1 = {
      zone1 = "asia-northeast1-a"
      zone2 = "asia-northeast1-b"
      zone3 = "asia-northeast1-c"
    }

    asia-south1 = {
      zone1 = "asia-south1-a"
      zone1 = "asia-south1-b"
      zone1 = "asia-south1-c"
    }

    asia-southeast1 = {
      zone = "asia-southeast1-a"
      zone = "asia-southeast1-b"
      zone = "asia-southeast1-c"
    }

    australia-southeast1 = {
      zone1 = "australia-southeast1-a"
      zone2 = "australia-southeast1-b"
      zone3 = "australia-southeast1-c"
    }

    europe-north1 = {
      zone1 = "europe-north1-a"
      zone2 = "europe-north1-b"
      zone3 = "europe-north1-c"
    }

    europe-west1 = {
      zone1 = "europe-west1-b"
      zone2 = "europe-west1-c"
      zone3 = "europe-west1-d"
    }

    europe-west2 = {
      zone1 = "europe-west2-a"
      zone2 = "europe-west2-b"
      zone3 = "europe-west2-c"
    }

    europe-west3 = {
      zone1 = "europe-west3-a"
      zone2 = "europe-west3-b"
      zone3 = "europe-west3-c"
    }

    europe-west4 = {
      zone1 = "europe-west4-a"
      zone2 = "europe-west4-b"
      zone3 = "europe-west4-c"
    }

    northamerica-northeast1 = {
      zone1 = "northamerica-northeast1-a"
      zone2 = "northamerica-northeast1-b"
      zone3 = "northamerica-northeast1-c"
    }

    southamerica-east1 = {
      zone1 = "southamerica-east1-a"
      zone2 = "southamerica-east1-b"
      zone3 = "southamerica-east1-c"
    }

    us-central1 = {
      zone1 = "us-central1-a"
      zone2 = "us-central1-b"
      zone3 = "us-central1-c"
      zone4 = "us-central1-d"
    }

    us-east1 = {
      zone1 = "us-east1-b"
      zone2 = "us-east1-c"
      zone3 = "us-east1-d"
    }

    us-east4 = {
      zone1 = "us-east4-a"
      zone2 = "us-east4-b"
      zone3 = "us-east4-c"

    }

    us-west1 = {
      zone1 = "us-west1-a"
      zone2 = "us-west1-b"
      zone3 = "us-west1-c"
    }

    us-west2 = {
      zone1 = "us-west2-a"
      zone2 = "us-west2-b"
      zone3 = "us-west2-c"
    }
  }
}

 variable "machine_type" {
   description = "The Machine Type for the Forseti Instances"
   default = "n1-standard-2"
  }

variable "compute_image" {
  description = "The Compute Image for the Forseti Instances"
  default     = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable server_ip {
  description = "Override the internal IP of the Forseti Server. If not provided, an internal IP will automatically be assigned."
  default     = ""
}

variable client_ip {
  description = "Override the internal IP of the Forseti Client. If not provided, an internal IP will automatically be assigned."
  default     = ""
}

variable metadata {
  description = "Metadata to be attached to the Forseti instance"
  type        = "map"
  default     = {
    enable-oslogin = "TRUE"
  }
}

variable "forseti_server_service_account_org_iam_roles" {
  description = "The Roles to assign to the Forseti Server Service Account at the Organization Level"
  default     = [
    "roles/appengine.appViewer",
    "roles/bigquery.dataViewer",
    "roles/browser",
    "roles/cloudasset.viewer",
    "roles/cloudsql.viewer",
    "roles/compute.networkViewer",
    "roles/compute.securityAdmin",
    "roles/iam.securityReviewer",
    "roles/orgpolicy.policyViewer",
    "roles/servicemanagement.quotaViewer",
    "roles/serviceusage.serviceUsageConsumer",
  ]
}

variable "forseti_server_service_account_iam_roles" {
  description = "The Roles to assign to the Forseti Server Service Account at the Project Level"
  default     = [
    "roles/cloudsql.client",
    "roles/logging.logWriter",
    "roles/storage.objectViewer",
    "roles/storage.objectCreator",
    "roles/iam.serviceAccountTokenCreator"
  ]
}

variable "forseti_client_service_account_iam_roles" {
  description = "The Roles to assign to the Forseti Client Service Account at the Project Level"
  default     = [
    "roles/logging.logWriter",
    "roles/storage.objectViewer",
  ]
 }

 variable "forseti-server-sa-scopes" {
   description = "The Service Account Scopes to Enable on the Forseti Server VM"
   default     = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/sqlservice.admin",
    "https://www.googleapis.com/auth/cloud-platform",
   ]
  }

   variable "forseti-client-sa-scopes" {
   description = "The Service Account Scopes to Enable on the Forseti Client VM"
   default     = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/cloud-platform",
   ]
  }

  variable "cron_schedule" {
    description = "The Cron Schedule Expression to tell forseti how often to run"
    default     = "33 */2 * * *"
  }