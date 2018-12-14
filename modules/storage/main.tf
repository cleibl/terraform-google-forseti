data "google_client_config" "current" {}

locals {
  project_id           = "${var.project_id}"
  bucket_name          = "${var.name}-${local.project_id}"
  location             = "${var.region != "" ? var.region : data.google_client_config.current.region}"
}
resource "google_storage_bucket" "forseti-bucket" {
  name          = "${local.bucket_name}"
  location      = "${local.location}"
  project       = "${local.project_id}"
  storage_class = "${var.storage_class}"
  force_destroy = "${var.force_destroy}"

  lifecycle {
    // TODO Should be set to "${var.prevent_destroy}" once https://github.com/hashicorp/terraform/issues/3116 is fixed.
    prevent_destroy = false
  }

  lifecycle_rule = "${var.lifecycle_rules}"

  versioning {
    enabled = "${var.versioning}"
  }
}
