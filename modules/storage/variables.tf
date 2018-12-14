variable "project_id" {
    description = "The Project ID in which to deploy resources into"
 }
variable "name" {
    description = "A name in which to prefix resources with"
 }
variable "region" {
    description = "The region in which to deploy resources into"
 }
variable "storage_class" {
    description = "The Storage Class of the new bucket. Supported values include: MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE."
 } 
variable "force_destroy" {
    description = "When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run."
 }
variable "lifecycle_rules" {
    description = "The bucket's Lifecycle Rules configuration. Multiple blocks of this type are permitted. Structure is documented below."
    type        = "list"
 }
variable "versioning" { 
    description = "The bucket's Versioning configuration."
}