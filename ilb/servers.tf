resource "google_compute_instance" "server" {
  count        = var.vpc_count - 1
  name         = "${var.name}-srv-${count.index+1}"
  machine_type = "f1-micro"

  metadata_startup_script = file("srv_startup.sh")

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.data_subnets[count.index+1].id
    network_ip =  cidrhost(google_compute_subnetwork.data_subnets[count.index+1].ip_cidr_range, 80)
  }
}
