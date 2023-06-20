# Copyright 2023 Google LLC

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

###### Project-independent resources

# Create a four-byte (eight hex digit) random suffix to make Google resource
# names unique.

resource "random_id" rand {
  byte_length = 4
}

locals {
  random_suffix = lower(random_id.rand.hex)
}

###### Hub project

data "google_project" "hub_project" {
  provider = google

  depends_on = [
    google_project_service.hub_resourcemanager_service
  ]
}

resource "google_project_service" "hub_iam_service" {
  provider = google

  service = "iam.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "hub_resourcemanager_service" {
  provider = google

  service = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

# We must not enforce the Disable Cross Project Service ACcount Usage
# constraint so the spoke project instance can use the service account
# from the hub project.

resource "google_service_account" "hub_secret_admin_sa" {
  provider = google

  account_id = "secret-admin-sa-${local.random_suffix}"
  display_name = "secret-admin-sa-${local.random_suffix}"

  depends_on = [
    google_project_service.hub_iam_service,
  ]
}

# For a Compute Engine instance in the spoke project to attach a service
# account from the hub project, the spoke project Compute Engine Service Agent
# needs to be granted Service Account Token Creator and Service Account User
# permissions on the hub project service account.
#
# Additionally, use depends_on to make sure the IAM service is running before
# creating an IAM binding.  

resource "google_service_account_iam_binding" "hub_serviceaccountuser_binding" {
  provider = google

  service_account_id = google_service_account.hub_secret_admin_sa.name
  role = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:service-${data.google_project.spoke_project.number}@compute-system.iam.gserviceaccount.com"
  ]
}

resource "google_service_account_iam_binding" "hub_serviceaccounttokencreator_binding" {
  provider = google

  service_account_id = google_service_account.hub_secret_admin_sa.name
  role = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:service-${data.google_project.spoke_project.number}@compute-system.iam.gserviceaccount.com"
  ]
}

resource "time_sleep" "wait_3_minutes" {
  depends_on=[
    google_service_account_iam_binding.hub_serviceaccountuser_binding,
    google_service_account_iam_binding.hub_serviceaccounttokencreator_binding
  ]

  create_duration = var.iam_role_binding_duration
}

###### Spoke Project

data "google_project" "spoke_project" {
  provider = google.spoke_project

  depends_on = [
    google_project_service.spoke_resourcemanager_service
  ]
}

resource "google_project_service" "spoke_compute_engine_service" {
  provider = google.spoke_project

  service = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "spoke_resourcemanager_service" {
  provider = google.spoke_project

  service = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "spoke_iam_service" {
  provider = google.spoke_project

  service = "iam.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

resource "google_project_service" "spoke_secretmanager_service" {
  provider = google.spoke_project

  service = "secretmanager.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy = false
}

# Set up the VPC network and subnet resources

resource "google_compute_network" "spoke_vpc_network" {
  provider = google.spoke_project

  name = "demo-vpc-${local.random_suffix}"
  description = "VPC for the resources for the IAP demo"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.spoke_compute_engine_service
  ]
}

resource "google_compute_subnetwork" "spoke_vpc_subnet" {
  provider = google.spoke_project

  name = "demo-subnet-${local.random_suffix}"
  description = "Subnet for the server for the demo VPC"
  ip_cidr_range = "10.0.0.0/24"
  network = google_compute_network.spoke_vpc_network.id
}

# Allow IAP TCP ssh connections

resource "google_compute_firewall" "spoke_fw_tunneled_ssh_traffic" {
  provider = google.spoke_project

  name = "fw-tunneled-ssh-traffic-${local.random_suffix}"
  description = "Firewall to allow tunneled SSH traffic"

  network = google_compute_network.spoke_vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = [ "35.235.240.0/20" ]
}

# Set up the NAT gateway and cloud router

resource "google_compute_router" "spoke_router" {
  provider = google.spoke_project

  name = "nat-router-${local.random_suffix}"
  network = google_compute_network.spoke_vpc_network.id
  region = var.spoke_region
}

resource "google_compute_router_nat" "spoke_nat" {
  provider = google.spoke_project

  name = "nat-${local.random_suffix}"
  router = google_compute_router.spoke_router.name
  region = var.spoke_region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_project_iam_binding" "spoke_secret_admin_sa_binding" {
  provider = google.spoke_project

  project = var.spoke_project_id
  role = "roles/secretmanager.admin"

  members = [
    "serviceAccount:${google_service_account.hub_secret_admin_sa.email}"
  ]
}

# Set up the server instance.  Use startup script from the external file.
#
# depends_on is needed for these reasosns:
#
# (1) We need to  wait for the NAT gateway go be available so the startup
#     script can download jq for the utility shell scripts.
#
# (2) to wait for the availabiity of the Service Account Token creator and
#     Service Account User bindings to be installed on the service account
#     in the hub project before attaching the service account from the
#     hub project to the instance.

resource "google_compute_instance" "spoke_server" {
  provider = google.spoke_project

  name = "server-spoke-project-${local.random_suffix}"
  machine_type = "e2-medium"
  zone = var.spoke_zone

  boot_disk {
    initialize_params {
      image = var.spoke_compute_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.spoke_vpc_subnet.self_link
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
      secret_admin_sa_email="${google_service_account.hub_secret_admin_sa.email}"
      secret_name="secret-${local.random_suffix}"
    }
  )

  service_account {
    email  = google_service_account.hub_secret_admin_sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_compute_router_nat.spoke_nat,
    time_sleep.wait_3_minutes
  ]
}
