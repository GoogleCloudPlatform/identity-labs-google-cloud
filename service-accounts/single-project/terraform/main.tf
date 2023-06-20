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

# The IAM Service Account Credentials API is needed for service account
# impersonation.

resource "google_project_service" "iam_credentials_service" {
  provider = google

  service = "iamcredentials.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "secret_manager_service" {
  provider = google

  service = "secretmanager.googleapis.com"
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

# Set up service accounts

# The compute_viewer_sa service account will be attached to the instance.

resource "google_service_account" "compute_viewer_sa" {
  provider = google

  account_id = "compute-viewer-sa-${local.random_suffix}"
  display_name = "compute-viewer-sa-${local.random_suffix}"
}

resource "google_project_iam_binding" "compute_viewer_sa_binding" {
  provider = google

  project = var.project_id
  role = "roles/compute.viewer"

  members = [
    "serviceAccount:${google_service_account.compute_viewer_sa.email}"
  ]
}

# The secret_admin_sa service account will be impersonated by the
# compute_viewer_sa service account that is attached to the instance.

resource "google_service_account" "secret_admin_sa" {
  provider = google

  account_id = "secret-admin-sa-${local.random_suffix}"
  display_name = "secret-admin-sa-${local.random_suffix}"
}

resource "google_project_iam_binding" "secret_admin_sa_binding" {
  provider = google

  project = var.project_id
  role = "roles/secretmanager.admin"

  members = [
    "serviceAccount:${google_service_account.secret_admin_sa.email}"
  ]
}

resource "google_service_account_iam_binding" "secret_admin_token_creator_binding" {
  service_account_id = google_service_account.secret_admin_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${google_service_account.compute_viewer_sa.email}"
  ]
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

resource "google_compute_firewall" "allow_iap_ssh_traffic" {
  provider = google

  name = "allow-iap-ssh-${local.random_suffix}"
  description = "Firewall to allow tunneled SSH traffic"

  network = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = [ "35.235.240.0/20" ]
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

# Set up the server instance.  Use startup script from the external file.
# Use depends_on to wait for the NAT gateway go be available so the
# startup script can download packages.

resource "google_compute_instance" "server" {
  provider = google

  name = "demo-${local.random_suffix}"
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
    enable_oslogin = "TRUE"
  }

  metadata_startup_script = templatefile(
    "${path.module}/etc/startup-script",
    {
      secret_admin_sa_email="${google_service_account.secret_admin_sa.email}",
      secret_name="secret-${local.random_suffix}"
    }
  )

  service_account {
    email  = google_service_account.compute_viewer_sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_compute_router_nat.nat
  ]
}
