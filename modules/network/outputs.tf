output "network_self_link" {
   value       = "${google_compute_network.network.self_link}"
   description = "The URI of the created resource."
}

output "public_subnet_self_link" {
   value       = "${google_compute_subnetwork.public_subnetwork.self_link}"
   description = "The URI of the public subnet"
}