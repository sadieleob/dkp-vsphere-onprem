/*
provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_url
  # If you have a self-signed cert
  allow_unverified_ssl = false
}
*/
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "sshkey" {
  content  = tls_private_key.key.private_key_openssh
  filename = "${path.module}/d2iq_bastion_sshkey"
  file_permission = 0600
}

resource "local_file" "sshpublickey" {
  content  = tls_private_key.key.public_key_openssh
  filename = "${path.module}/d2iq_bastion_sshkey.pub"
  file_permission = 0600
}

locals {
  bastion_cloudinit_config = <<EOF
  #cloud-config
  package_update: true
  package_upgrade: true
  repo_update: true
  repo_upgrade: all
  users:
    - name: ${var.ssh_user}
      sudo: ALL=(ALL) NOPASSWD:ALL
      groups: sudo, wheel
      lock_passwd: true
      ssh_authorized_keys:
        - ${tls_private_key.key.public_key_openssh}
  groups:
    - docker
  system_info:
    default_user:
      groups: [ docker ]
  apt:
    sources:
      docker.list:
        source: deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable
        keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
  packages:
  - docker-ce
  - docker-ce-cli
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - unattended-upgrades
  - zsh
  - git
  - haproxy
  bootcmd:
  - sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  - git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
  - git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
  - git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
  runcmd:
  - apt-get update
  - apt install ubuntu-desktop
  - systemctl enable --now docker
  - wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  - echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  - sudo apt update && sudo apt install terraform
  - sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
  - sudo systemctl enable --now haproxy
  - mv /root/.zshrc.pre-oh-my-zsh /root/.zshrc
  - sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  - git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
  - git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
  - git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

  write_files:
  - content: |
       export TERM="xterm-256color"
       export ZSH="$HOME/.oh-my-zsh"
       ZSH_THEME="powerlevel9k/powerlevel9k"
       POWERLEVEL9K_MODE="nerdfont-complete"
       POWERLEVEL9K_PROMPT_ON_NEWLINE=true
       POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context host dir)
       POWERLEVEL9K_CONTEXT_TEMPLATE='%n'
       POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND=249 # white
       POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status vcs load ram disk_usage time)
       POWERLEVEL9K_OS_ICON_BACKGROUND=024 #navyblue
       POWERLEVEL9K_OS_ICON_FOREGROUND=202 #orangered1
       POWERLEVEL9K_CUSTOM_OS_ICON="echo  "
       POWERLEVEL9K_LOAD_WHICH=1
       POWERLEVEL9K_DIR_HOME_FOREGROUND=249
       POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND=249
       POWERLEVEL9K_DIR_ETC_FOREGROUND=249
       POWERLEVEL9K_DIR_DEFAULT_FOREGROUND=249
       POWERLEVEL9K_DIR_HOME_BACKGROUND=024 #deepskyblue4a
       POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND=024 #deepskyblue4a
       POWERLEVEL9K_DIR_ETC_BACKGROUND=024 #deepskyblue4a
       POWERLEVEL9K_DIR_DEFAULT_BACKGROUND=024 #deepskyblue4a
       POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
       plugins=(git)
       plugins=(zsh-autosuggestions)
       plugins=(virtualenv $plugins)
       source $ZSH/oh-my-zsh.sh
       alias k="kubectl"
       export VSPHERE_SERVER="vcenter.ca1.ksphere-platform.d2iq.cloud"
       export VSPHERE_USERNAME=""
       export VSPHERE_USER=""
       export VSPHERE_PASSWORD=""
    owner: root:root
    path: /root/.zshrc
    permissions: '0644'
  - content: |
       global
           log /dev/log	local0
           log /dev/log	local1 notice
           chroot /var/lib/haproxy
           stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
           stats timeout 30s
           user haproxy
           group haproxy
           daemon
           # Default SSL material locations
           ca-base /etc/ssl/certs
           crt-base /etc/ssl/private
          # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
                     ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
                     ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
                     ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
       defaults
              log global
              mode http
              option httplog
              option dontlognull
                     timeout connect 5000
                     timeout client  50000
                     timeout server  50000
              errorfile 400 /etc/haproxy/errors/400.http
              errorfile 403 /etc/haproxy/errors/403.http
              errorfile 408 /etc/haproxy/errors/408.http
              errorfile 500 /etc/haproxy/errors/500.http
              errorfile 502 /etc/haproxy/errors/502.http
              errorfile 503 /etc/haproxy/errors/503.http
              errorfile 504 /etc/haproxy/errors/504.http
        frontend k8s-api
           bind 10.128.1.48:6443
           bind 127.0.0.1:6443
           mode tcp
           option tcplog
           timeout client 300000
           default_backend k8s-api
        backend k8s-api
           mode tcp
           option tcplog
           option tcp-check
           timeout server 300000
           balance roundrobin
           default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
               server apiserver1 192.168.2.141:6443 check
               server apiserver2 192.168.2.142:6443 check
               server apiserver3 192.168.2.143:6443 check
    owner: root:root
    path: /etc/haproxy/haproxy.cfg
    permissions: '0644'
  EOF
}

data "template_cloudinit_config" "bootstrap_cloudinit" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = local.bastion_cloudinit_config
  }
}

/*
data "template_cloudinit_config" "bastion_bootstrap_cloudinit" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = local.bastion_base_cloudinit
  }
}
*/

module "bastion" {
  #source = "../modules/vmclone"
  source = "git::git@github.com:mesosphere/vcenter-tools.git//modules/vmclone"

  node_name                   = "sortega-bastion"
  ssh_public_key              = tls_private_key.key.public_key_openssh
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
  custom_template_cloudinit_config = data.template_cloudinit_config.bootstrap_cloudinit.rendered
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
