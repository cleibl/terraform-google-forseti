variable "name" {
    description = "Generic Name to prefix resources"
 }

variable "project" {
    description = "The Project to deploy the resources to"
 }

variable "region" {
    description = "The Region to deploy the resources to"
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

variable "forseti_server_sa" {
    description = "The Service Account Email for the Forseti Server VM"
 }

 variable "forseti_client_sa" {
    description = "The Service Account Email for the Forseti Client VM"
 }

variable "ssh_source_ranges" {
    type        = "list"
    description = "List of CIDR Ranges to Allow SSH Access to Forseti VM"
    default     = ["0.0.0.0/0"]
 }