output mgmt_nat {
  value = google_compute_address.cloud_nat.address 
}
output jump_host {
  value = google_compute_address.jumphost.address 
}
