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

variable "network_ip" {
  description = "Internal IP. Kept on zone moves inside the same region/subnet."
  type        = string
  default     = null
}

variable "static_ip" {
  description = "Regional static external IP managed by this module. Survives zone moves inside the same region."
  type = object({
    name    = string
    address = string
  })
  default = null
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "metadata" {
  type    = map(string)
  default = {}
}

variable "service_account_email" {
  type = string
}

variable "deletion_protection" {
  description = "Set to false (and apply) before a zone move, since the move deletes the old VM."
  type        = bool
  default     = true
}
