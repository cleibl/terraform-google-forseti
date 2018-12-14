resource "google_compute_network" "network" {
  name                    = "${var.name}-network"
  project                 = "${var.project}"
  routing_mode            = "${var.routing_mode}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "public_subnetwork" {
  name                     = "${var.name}-public-subnetwork"
  project                  = "${var.project}"
  ip_cidr_range            = "${var.public_subnet_ip_cidr_range}"
  region                   = "${var.region}"
  network                  = "${google_compute_network.network.self_link}"
  enable_flow_logs         = true
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private_subnetwork" {
  name                     = "${var.name}-private-subnetwork"
  project                  = "${var.project}"
  ip_cidr_range            = "${var.private_subnet_ip_cidr_range}"
  region                   = "${var.region}"
  network                  = "${google_compute_network.network.self_link}"
  enable_flow_logs         = true
  private_ip_google_access = true
}

resource "google_compute_firewall" "forseti-server-deny-all" {
  // Create a firewall rule to block out all ingress traffic
  name           = "forseti-server-deny-all"
  project        = "${var.project}"
  network        = "${google_compute_network.network.self_link}"
  enable_logging = true
  priority       = 2

  target_service_accounts = ["${var.forseti_server_sa}"]

  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "forseti-server-allow-grpc" {
  // Create a firewall rule to open only port tcp:50051 within the internal network
  name           = "forseti-server-allow-grpc"
  project        = "${var.project}"
  network        = "${google_compute_network.network.self_link}"
  enable_logging = true // Best Practice is to enable logging of firewall rules
  priority       = 1

  source_ranges           = ["${var.public_subnet_ip_cidr_range}"]
  target_service_accounts = ["${var.forseti_server_sa}"]

  allow {
    protocol = "tcp"
    ports    = ["50051"]
  }
}

resource "google_compute_firewall" "forseti-server-allow-ssh-external" {
  // Create a firewall rule to open only port tcp:50051 within the internal network
  name           = "forseti-server-allow-ssh-external"
  project        = "${var.project}"
  network        = "${google_compute_network.network.self_link}"
  enable_logging = true // Best Practice is to enable logging of firewall rules
  priority       = 1

  source_ranges           = ["${var.ssh_source_ranges}"]
  target_service_accounts = ["${var.forseti_server_sa}"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "forseti-client-allow-ssh-external" {
  // Create a firewall rule to open only port tcp:50051 within the internal network
  name           = "forseti-client-allow-ssh-external"
  project        = "${var.project}"
  network        = "${google_compute_network.network.self_link}"
  enable_logging = true // Best Practice is to enable logging of firewall rules
  priority       = 1

  source_ranges           = ["${var.ssh_source_ranges}"]
  target_service_accounts = ["${var.forseti_client_sa}"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}