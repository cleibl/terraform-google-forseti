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

 output "forseti-server-bucket" {
    value = "${module.server-storage-bucket.forseti_bucket_url}"
 }

  output "forseti-client-bucket" {
    value = "${module.client-storage-bucket.forseti_bucket_url}"
 }

 output "forseti-server-external-ip" {
    value = "${google_compute_address.forseti-server-ip.address}"
 }

 output "forseti-client-external-ip" {
    value = "${google_compute_address.forseti-client-ip.address}"
 }

 output "forseti-mysql-instance-name" {
    value = "${module.mysql-db.instance_name}"
 }

 output "forseti-mysql-instance-address" {
    value = "${module.mysql-db.instance_address}"
 }
 output "forseti-mysql-database-name" {
    value = "${module.mysql-db.database_name}"
 }


