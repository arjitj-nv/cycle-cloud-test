variable "location" {
  default = "South Central US"
}

variable "resource_group_name" {
  default = "cyclecloud-rg"
}

variable "vm_name" {
  default = "cyclecloud-vm"
}

variable "admin_username" {
  default = "nautilus"
}

variable "admin_password" {
  default = "P@ssword1234!"
}

variable "cyclecloud_install_script_url" {
  default = "https://raw.githubusercontent.com/arjitj-nv/cycle-cloud-test/refs/heads/main/scripts/cyclecloud_install.py"
}

variable "cyclecloud_user_publickey" {
  description = "The public key for CycleCloud user"
  type        = string
}