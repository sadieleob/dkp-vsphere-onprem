variable "vsphere_user" {
  description = "VSphere username"
  type        = string
  default     = "" 
}

variable "vsphere_password" {
  description = "VSphere password"
  type        = string
  default     = ""
}

variable "vsphere_url" {
  description = "VSphere URL"
  type        = string   
  default = ""
}

variable "node_name" {
  description = "Name of the node. Gets a suffix of var.node_count index ( name-%d )"
}

variable "ssh_public_key" {
  description = "SSH Public key string (only used when no cloud init is specified)"
  type        = string 
}


# Optional
variable "node_count" {
  description = "Number of nodes"
  default     = 1
}

variable "vsphere_datacenter" {
  description = "Name of the vSphere Datacenter"
  default     = "dc1"
}

variable "vsphere_cluster" {
  description = "Name of the vSphere Cluster"
  default     = "zone1"
}

variable "vsphere_network" {
  description = "Name of the vSphere Network"
  default     = "VMs"
}

variable "vsphere_folder" {
  description = "vSphere folder"
  default     = "users/users-support"
}

variable "datastore_name" {
  description = "Name of the shared datastore being used"
  default     = "users-support"
}

variable "datastore_is_cluster" {
  description = "Set true if the data store is a data store cluster"
  default     = false
}

variable "vm_template_name" {
  description = "Name of the vSphere Template to use"
  default     = "d2iq-base-templates/d2iq-base-RHEL-84"
}

variable "vsphere_additional_networks" {
  description = "List of names of the additional vSphere Networks"
  type        = list(string)
  default     = null
}

variable "vsphere_additional_disks" {
  description = "Additional disks to add. Mandantory fields: size ( [{'size': 20}])"
  type        = list(map(string))
  default     = null
}

variable "ssh_user" {
  description = "SSH Username"
  default     = "sortega"
}

variable "num_cpus" {
  description = "Number of CPUs"
  default     = 4
}

variable "memory" {
  description = "Memory in MB"
  default     = 16384
}

variable "root_volume_size" {
  description = "The root volume size"
  default     = 40
}

variable "root_volume_type" {
  description = "The root volume type. Should be thin, lazy or eagerZeroedThick"
  default     = "thin"
}

variable "custom_script" {
  description = "Custom Script for cloud-init extra steps"
  default     = []
  type        = list(string)
}

variable "custom_template_cloudinit_config" {
  description = "Custom cloud init script to be applied must be gziped. see data.template_cloudinit_config"
  default     = null
  type        = string
}

variable "custom_attribute_owner" {
  description = "Similar to cloud owner tag"
  type        = string
}

variable "custom_attribute_expiration" {
  description = "Similar to cloud expiration tag"
  type        = string
  default     = "8h"
}

variable "resource_pool_name" {
  description = "Resource pool to be used"
  type        = string
  default     = "users-support"
}

variable "linked_clone_enabled" {
  description = "Create the VM with linked clone disk"
  type        = bool
  default     = false
}

variable "extra_config" {
  type = map(string)
  default = null
}

variable "wait_for_guest_ip_timeout" {
  description = "The amount of time, in minutes, to wait for an available guest IP address on the virtual machine."
  default = 5
}
variable "wait_for_guest_net_timeout" {
  description = "The amount of time, in minutes, to wait for an available routable guest IP address on the virtual machine"
  default = 0
}
