data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_address" "jumphost" {
  name    = "${var.name}-jumphost"
}

resource "google_compute_instance" "jumphost" {
  name    = "${var.name}-mgmt"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmt.id
    access_config {
      nat_ip = google_compute_address.jumphost.address
    }
  }
}
