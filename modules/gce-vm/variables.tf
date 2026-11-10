variable "project_id" {
  type = string
}

variable "name" {
  description = "Instance name. The boot disk has the same name."
  type        = string
}

variable "zone" {
  description = "Changing it replaces the VM and its disks (restored from the snapshots below)."
  type        = string
}

variable "machine_type" {
  type = string
}

variable "gpu" {
  description = "Only for machine types where the GPU is attached separately (e.g. n1 + T4). Leave null for g2/a2/a3, which come with their GPU."
  type = object({
    type  = string
    count = number
  })
  default = null
}

variable "boot_disk" {
  type = object({
    size_gb   = number
    type      = string           # pd-balanced / pd-ssd / hyperdisk-balanced ...
    image     = optional(string) # used only when the disk is created without a snapshot
    snapshot  = optional(string) # set this when moving zones
    interface = optional(string) # leave null for existing VMs; NVME/SCSI only when creating
  })
}

variable "data_disks" {
  description = "Extra disks keyed by disk name."
  type = map(object({
    size_gb  = number
    type     = string
    snapshot = optional(string) # set this when moving zones
  }))
  default = {}
}

variable "network" {
  type    = string
  default = "default"
}

variable "subnetwork" {
  type    = string
  default = "default"
}

variable "network_ip" {
  description = "Internal IP. Kept on zone moves inside the same region/subnet."
  type        = string
  default     = null
}

variable "external_ip" {
  description = "false = no public IP. true = public IP (static_ip if given, otherwise ephemeral)."
  type        = bool
  default     = true
}

variable "static_ip" {
  description = "Regional static external IP managed by this module. Survives zone moves inside the same region."
  type = object({
    name    = string
    address = string
  })
  default = null
}

variable "deletion_protection" {
  description = "Set to false (and apply) before a zone move, since the move deletes the old VM."
  type        = bool
  default     = true
}

variable "shielded_vm" {
  type = object({
    secure_boot          = bool
    vtpm                 = bool
    integrity_monitoring = bool
  })
  default = {
    secure_boot          = false
    vtpm                 = true
    integrity_monitoring = true
  }
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "metadata" {
  type    = map(string)
  default = {}
}

variable "service_account_email" {
  type = string
}

variable "service_account_scopes" {
  type = list(string)
  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
  ]
}

variable "on_host_maintenance" {
  description = "Must be TERMINATE for any VM with a GPU."
  type        = string
  default     = "TERMINATE"
}

variable "automatic_restart" {
  type    = bool
  default = true
}
