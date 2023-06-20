# Copyright 2023 Google LLC
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "Message-00" {
  value = "Please wait a few minutes for the compute instance to initialize."
}

output "random_suffix_for_cloud_resource_names" {
  value = "${local.random_suffix}"
}

output "hub_service_account" {
  value = "${google_service_account.hub_secret_admin_sa.email}"
}

output "ssh_command" {
  value = "gcloud compute ssh --zone ${var.spoke_zone} ${google_compute_instance.spoke_server.name} --tunnel-through-iap --project ${var.spoke_project_id}"
}
