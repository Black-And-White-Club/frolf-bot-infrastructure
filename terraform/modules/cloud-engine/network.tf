# VPC Network
resource "google_compute_network" "frolf_bot_vpc" {
  name                    = "frolf-bot-vpc"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "frolf_bot_subnet" {
  name          = "frolf-bot-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.frolf_bot_vpc.id
}

# Firewall rule
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.frolf_bot_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
