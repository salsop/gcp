resource "google_compute_health_check" "fw" {
  name                = "${var.name}-healthcheck"
  check_interval_sec  = 20
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  https_health_check {
    request_path = "/php/login.php"
    port         = "443"
  }
}
resource "google_compute_region_health_check" "fw" {
  name                = "${var.name}-rhealthcheck"
  check_interval_sec  = 20
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  https_health_check {
    request_path = "/php/login.php"
    port         = "443"
  }
}

resource "google_compute_instance_template" "fw" {
  name_prefix    = var.name
  machine_type   = var.machine_type
  can_ip_forward = true
  metadata       = var.bootstrap_options

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/cloud.useraccounts.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
    email = "default"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
  }
  dynamic "network_interface" {
    for_each = google_compute_subnetwork.data_subnets
    content {
      subnetwork = network_interface.value["id"]
    }
  }

  disk {
    source_image = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-flex-byol-1013"
    disk_type    = "pd-ssd"
    auto_delete  = true
    boot         = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "fws" {
  name               = "${var.name}-igm"
  base_instance_name = "${var.name}-igm"

  version {
    instance_template = google_compute_instance_template.fw.id
  }

  target_size = var.fw_count

  named_port {
    name = "https"
    port = 443
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.fw.id
    initial_delay_sec = 1200
  }
}



resource "google_compute_region_backend_service" "bsvc" {
  count                 = var.vpc_count
  name                  = "${var.name}-bsvc-${count.index}"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_region_health_check.fw.id]
  session_affinity      = "CLIENT_IP"
  network               = google_compute_network.data_nets[count.index].id
  backend {
    group = google_compute_region_instance_group_manager.fws.instance_group
  }
}

resource "google_compute_forwarding_rule" "fwdrule" {
  count                 = var.vpc_count
  name                  = "${var.name}-fwdrule-${count.index}"
  backend_service       = google_compute_region_backend_service.bsvc[count.index].id
  load_balancing_scheme = "INTERNAL"
  ports                 = ["80"]
  network               = google_compute_network.data_nets[count.index].id
  subnetwork            = google_compute_subnetwork.data_subnets[count.index].id
  ip_address            = cidrhost(google_compute_subnetwork.data_subnets[count.index].ip_cidr_range, 250)
}


resource "google_compute_route" "route" {
  count        = var.vpc_count - 1
  name         = "${var.name}-dg-${count.index + 1}"
  dest_range   = "0.0.0.0/0"
  network      = google_compute_network.data_nets[count.index + 1].id
  next_hop_ilb = google_compute_forwarding_rule.fwdrule[count.index + 1].ip_address
  priority     = 10
}
