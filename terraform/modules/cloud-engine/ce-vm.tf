# Example VM instance - customize as needed
resource "google_compute_instance" "frolf_bot_vm" {
  name         = "frolf-bot-vm"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.frolf_bot_vpc.name
    subnetwork = google_compute_subnetwork.frolf_bot_subnet.name

    access_config {
      # Ephemeral public IP
    }
  }

  tags = ["frolf-bot"]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
  EOF
}
