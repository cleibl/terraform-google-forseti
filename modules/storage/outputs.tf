output "forseti_bucket_url" {
   value = "${google_storage_bucket.forseti-bucket.url}"
}

output "forseti_bucket_name" {
   value = "${google_storage_bucket.forseti-bucket.name}"
}