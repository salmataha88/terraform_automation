module "vm" {
  source = "../../modules/gce-vm"

  project_id            = var.project_id
  name                  = var.name
  zone                  = var.zone
  machine_type          = var.machine_type
  boot_disk             = var.boot_disk
  data_disks            = var.data_disks
  network_ip            = var.network_ip
  static_ip             = var.static_ip
  tags                  = var.tags
  metadata              = var.metadata
  service_account_email = var.service_account_email
  deletion_protection   = var.deletion_protection
}

output "vm" {
  value = module.vm
}
