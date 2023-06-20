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

variable "hub_project_id" {
  description = "The Google Cloud project ID for the hub project"
  type = string
}

variable "spoke_project_id" {
  description = "The Google Cloud project ID for the spoke project"
  type = string
}

variable "spoke_region" {
  description = "The Google Cloud region to use in the spoke project"
  type = string
  default = "us-central1"
}

variable "spoke_zone" {
  description = "The Google Cloud zone to use in the spoke project"
  type = string
  default = "us-central1-a"
}

variable "spoke_compute_image" {
  description = "The image project and family for instance builds in the spoke project"
  type = string
  default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "iam_role_binding_duration" {
  description = "Time to delay after IAM bindings to before creating instance"
  type = string
  default = "180s"
}
