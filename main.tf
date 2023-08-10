module "bastion" {
  #source = "../modules/vmclone"
  source = "git::git@github.com:mesosphere/vcenter-tools.git//modules/vmclone"

  node_name                   = "kib-ha-proxy"
  ssh_public_key              = file("~/.ssh/d2iq_templates.pub")
  vsphere_network             = "VMs"
  vm_template_name            = "d2iq-base-Ubuntu-20.04"
  num_cpus                    = 4
  memory                      = 8192
  root_volume_size            = 250
  resource_pool_name          = var.resource_pool_name
  vsphere_folder              = var.vsphere_folder
  datastore_name              = var.datastore_name
  custom_attribute_owner      = var.custom_attribute_owner
  custom_attribute_expiration = var.custom_attribute_expiration
  ssh_user                    = var.ssh_user
  datastore_is_cluster        = false
}

output "bastion_default_ip_address" {
  value = module.bastion.default_ip_address
}

output "bastion_ssh_nat_address" {
  value = "${module.bastion.nat_address}:${module.bastion.nat_ssh_port}"
}


module "dkp-cp" {
  #source = "../modules/vmclone"
  source = "git::git@github.com:mesosphere/vcenter-tools.git//modules/vmclone"

  node_name                   = "sortega-dkp-cp${count.index}"
  count                       = 3
  ssh_public_key              = file("~/.ssh/d2iq_templates.pub")
  vsphere_network             = "VMs"
  num_cpus                    = 4
  memory                      = 8192
  root_volume_size            = 40
  vm_template_name            = var.vm_template_name
  resource_pool_name          = var.resource_pool_name
  vsphere_folder              = var.vsphere_folder
  datastore_name              = var.datastore_name
  custom_attribute_owner      = var.custom_attribute_owner
  custom_attribute_expiration = var.custom_attribute_expiration
  ssh_user                    = var.ssh_user
}

output "dkp-cp_default_ip_address" {
  value = [replace(join(", " , module.dkp-cp[*].default_ip_address), ",", "")]
}

module "dkp-worker" {
  #source = "../modules/vmclone"
  source = "git::git@github.com:mesosphere/vcenter-tools.git//modules/vmclone"

  node_name                   = "sortega-dkp-worker${count.index}"
  count                       = 4
  ssh_public_key              = file("~/.ssh/d2iq_templates.pub")
  vsphere_network             = "VMs"
  num_cpus                    = 8
  memory                      = 16384
  root_volume_size            = 40
  vsphere_additional_disks    = [{"size" : 100, "type" : "thin"}]
  vm_template_name            = var.vm_template_name
  resource_pool_name          = var.resource_pool_name
  vsphere_folder              = var.vsphere_folder
  datastore_name              = var.datastore_name
  custom_attribute_owner      = var.custom_attribute_owner
  custom_attribute_expiration = var.custom_attribute_owner
  ssh_user                    = var.ssh_user
}

output "dkp-worker_default_ip_address" {
  value = [replace(join(", " , module.dkp-worker[*].default_ip_address), ",", "")]
}