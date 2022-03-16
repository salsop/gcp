provider "google" {
  region  = "europe-west1"
  zone    = "europe-west1-b"
  project = "gcs-gcp-access"
}
provider "google-beta" {
  region  = "europe-west1"
  zone    = "europe-west1-b"
  project = "gcs-gcp-access"
}

resource "google_compute_network" "mgmt" {
  name                    = "${var.name}-mgmt"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "mgmt" {
  name          = "${var.name}-mgmt-s"
  ip_cidr_range = var.mgmt_cidr
  network       = google_compute_network.mgmt.id
}

resource "google_compute_network" "data_nets" {
  count                   = var.vpc_count
  name                    = "${var.name}-data-n${count.index}"
  auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "data_subnets" {
  count         = var.vpc_count
  name          = "${var.name}-data-ns${count.index}"
  ip_cidr_range = cidrsubnet(var.data_cidr, 3, count.index)
  network       = google_compute_network.data_nets[count.index].id
}

resource "google_compute_router" "router" {
  name    = "${var.name}-rtr-mgmt"
  network = google_compute_network.mgmt.id
}

resource "google_compute_address" "cloud_nat" {
  name   = "${var.name}-nat-ip"
  region = google_compute_subnetwork.mgmt.region
}

resource "google_compute_router_nat" "router_nat" {
  name   = "${var.name}-rtr-nat"
  router = google_compute_router.router.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.cloud_nat.self_link]

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_router" "router_data" {
  name    = "${var.name}-rtr-data"
  network = google_compute_network.data_nets[0].id
}

resource "google_compute_router_nat" "router_data_nat" {
  name   = "${var.name}-rtr-dnat"
  router = google_compute_router.router_data.name

  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}





resource "google_compute_firewall" "mgmt-i" {
  name      = "${var.name}-mgmt-i"
  network   = google_compute_network.mgmt.id
  direction = "INGRESS"
  source_ranges = concat(
    ["172.16.0.0/12"],
    [for r in var.mgmt_ips : "${r.cidr}"]
  )
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "mgmt-e" {
  name      = "${var.name}-mgmt-e"
  network   = google_compute_network.mgmt.id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "hc" {
  name      = "${var.name}-health-i"
  direction = "INGRESS"
  network   = google_compute_network.mgmt.id
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
    "35.235.240.0/20",
  ]
  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "data-i" {
  count     = var.vpc_count
  name      = "${var.name}-data-i-${count.index}"
  direction = "INGRESS"
  network   = google_compute_network.data_nets[count.index].id
  source_ranges = [
    "0.0.0.0/0",
  ]
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "data-e" {
  count     = var.vpc_count
  name      = "${var.name}-data-e-${count.index}"
  direction = "EGRESS"
  network   = google_compute_network.data_nets[count.index].id
  allow {
    protocol = "all"
  }
}


