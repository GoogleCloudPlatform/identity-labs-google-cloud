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

# Define the Google providers
#
# There are two providers:
#
# google - For provisioning most resources in the hub project.
#
# spoke_project - For provisioning resources in the spoke project.

provider "google" {
  project = var.hub_project_id
}

provider "google" {
  alias = "spoke_project"

  project = var.spoke_project_id
  region = var.spoke_region
  zone = var.spoke_zone
}
