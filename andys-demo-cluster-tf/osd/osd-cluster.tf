resource "osdgoogle_cluster" "example" {
  name                 = "my-osd-cluster"
  cloud_region         = "us-central1"
  gcp_project_id       = var.gcp_project_id
  version              = "4.16.1"
  compute_nodes        = 3
  compute_machine_type = "custom-4-16384"
}

