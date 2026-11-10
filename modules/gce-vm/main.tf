# ---------------------------------------------------------------------------
# Disks live as their own resources so replacing a VM never deletes the data.
# `image` / `snapshot` are ignored after creation: they only matter when a
# disk is (re)created, e.g. on a zone move.
# ---------------------------------------------------------------------------

resource "google_compute_disk" "boot" {
  project  = var.project_id
  name     = var.name
  zone     = var.zone
  size     = var.boot_disk.size_gb
  type     = var.boot_disk.type
  image    = var.boot_disk.snapshot == null ? var.boot_disk.image : null
  snapshot = var.boot_disk.snapshot

  lifecycle {
    ignore_changes = [image, snapshot]
  }
}

resource "google_compute_disk" "data" {
  for_each = var.data_disks

  project  = var.project_id
  name     = each.key
  zone     = var.zone
  size     = each.value.size_gb
  type     = each.value.type
  snapshot = each.value.snapshot

  lifecycle {
    ignore_changes = [snapshot]
  }
}

locals {
  region = join("-", slice(split("-", var.zone), 0, 2)) # us-central1-c -> us-central1
}

resource "google_compute_address" "external" {
  count = var.external_ip && var.static_ip != null ? 1 : 0

  project      = var.project_id
  name         = var.static_ip.name
  address      = var.static_ip.address
  region       = local.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

  lifecycle {
    prevent_destroy = true # losing the IP breaks whatever points at it
  }
}

# ---------------------------------------------------------------------------
# VM. No `desired_status` on purpose: the panel / scheduler own RUNNING vs
# TERMINATED, and `terraform apply` must never start or stop a VM.
# ---------------------------------------------------------------------------

resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = var.tags
  labels       = var.labels
  metadata     = var.metadata

  deletion_protection = var.deletion_protection

  # GCE default. Must be set explicitly: leaving it null forces a replacement on import.
  key_revocation_action_type = "NONE"

  shielded_instance_config {
    enable_secure_boot          = var.shielded_vm.secure_boot
    enable_vtpm                 = var.shielded_vm.vtpm
    enable_integrity_monitoring = var.shielded_vm.integrity_monitoring
  }

  boot_disk {
    source      = google_compute_disk.boot.self_link
    device_name = var.name
    interface   = var.boot_disk.interface
    auto_delete = false # disk is managed above; deleting the VM must not delete it
  }

  dynamic "attached_disk" {
    for_each = google_compute_disk.data
    content {
      source      = attached_disk.value.self_link
      device_name = attached_disk.key
      mode        = "READ_WRITE"
    }
  }

  dynamic "guest_accelerator" {
    for_each = var.gpu == null ? [] : [var.gpu]
    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    network_ip = var.network_ip

    dynamic "access_config" {
      for_each = var.external_ip ? [1] : []
      content {
        nat_ip       = one(google_compute_address.external[*].address)
        network_tier = "PREMIUM"
      }
    }
  }

  scheduling {
    on_host_maintenance = var.on_host_maintenance
    automatic_restart   = var.automatic_restart
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  lifecycle {
    # Schedules attached outside Terraform (start/stop policies) stay untouched.
    ignore_changes = [resource_policies]
  }
}
