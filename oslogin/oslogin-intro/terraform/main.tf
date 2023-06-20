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

# Enable APIs

resource "google_project_service" "compute_engine_service" {
  provider = google

  service = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "iam_service" {
  provider = google

  service = "iam.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

# Create a four-byte (eight hex digit) random suffix to make Google resource
# names unique.

resource "random_id" rand {
  byte_length = 4
}

locals {
  random_suffix = lower(random_id.rand.hex)
}

# Set up the VPC network and subnet resources

resource "google_compute_network" "vpc_network" {
  provider = google

  name = "demo-vpc-${local.random_suffix}"
  description = "VPC for the resources for the IAP demo"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.compute_engine_service
  ]
}

resource "google_compute_subnetwork" "vpc_subnet" {
  provider = google

  name = "demo-subnet-${local.random_suffix}"
  description = "Subnet for the server for the demo VPC"
  ip_cidr_range = "10.0.0.0/24"
  network = google_compute_network.vpc_network.id
}

# Allow IAP TCP ssh connections

resource "google_compute_firewall" "iap_oslogin_allow_ssh" {
  provider = google

  name = "iap-oslogin-allow-ssh-${local.random_suffix}"
  description = "Firewall to allow IAP SSH traffic to OS Login server"

  network = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = [ "35.235.240.0/20" ]
  target_tags = ["oslogin-server"]
}

# Set up the NAT gateway and cloud router

resource "google_compute_router" "router" {
  provider = google

  name = "nat-router-${local.random_suffix}"
  network = google_compute_network.vpc_network.id
  region = var.region
}

resource "google_compute_router_nat" "nat" {
  name = "nat-${local.random_suffix}"
  router = google_compute_router.router.name
  region = var.region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Set up the OS Login server instance.
#
# Use depends_on to wait for the NAT gateway go be available so the
# startup script can download packages.

resource "google_compute_instance" "oslogin_server" {
  provider = google

  name = "oslogin-${local.random_suffix}"
  machine_type = "e2-medium"
  zone = var.zone

  boot_disk {
    initialize_params {
      image = var.compute_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnet.self_link
  }

  shielded_instance_config {
    enable_secure_boot = true
    enable_vtpm = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  tags = ["oslogin-server"]

  depends_on = [
    google_compute_router_nat.nat
  ]
}

resource "google_project_iam_member" "admin_oslogin_member" {
  provider = google

  project = var.project_id
  role = "roles/compute.osAdminLogin"
  member = "user:${var.oslogin_admin_username}"
}

resource "google_project_iam_member" "admin_iap_member" {
  provider = google

  project = var.project_id
  role = "roles/iap.tunnelResourceAccessor"
  member = "user:${var.oslogin_admin_username}"
}

resource "google_project_iam_member" "regular_oslogin_member" {
  provider = google

  project = var.project_id
  role = "roles/compute.osLogin"
  member = "user:${var.oslogin_regular_username}"
}

resource "google_project_iam_member" "regular_iap_member" {
  provider = google

  project = var.project_id
  role = "roles/iap.tunnelResourceAccessor"
  member = "user:${var.oslogin_regular_username}"
}
