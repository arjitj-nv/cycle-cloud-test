provider "azurerm" {
  features {}
  subscription_id = "6aa85cad-20c9-4a50-be45-b411c49391af"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "cyclecloud-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "cyclecloud-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                    = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
     public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}



resource "azurerm_linux_virtual_machine" "vm" {
  name                     = var.vm_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                 = var.location
  size                     = "Standard_DS2_v2"
  admin_username           = "azureuser"  # Keep consistent with SSH user
  network_interface_ids    = [azurerm_network_interface.nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Ensure this file exists
  }

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb      = 128
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }

  provision_vm_agent = true
}

resource "azurerm_managed_disk" "cyclecloud" {
  name                 = "${var.vm_name}-DataDisk1"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
}

resource "azurerm_virtual_machine_data_disk_attachment" "cyclecloud" {
  managed_disk_id    = azurerm_managed_disk.cyclecloud.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = "1"
  caching            = "ReadOnly"
}

resource "azurerm_virtual_machine_extension" "install_cyclecloud" {
  name                 = "CustomScriptExtension"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = [azurerm_linux_virtual_machine.vm]

  settings = <<SETTINGS
    {
        "commandToExecute": "echo \"Launch Time: \" > /tmp/launch_time && date >> /tmp/launch_time && curl -k -L -o /tmp/cyclecloud_install.py \"${var.cyclecloud_install_script_url}\" && python3 /tmp/cyclecloud_install.py --acceptTerms --useManagedIdentity --username='azureuser' --publickey='${var.cyclecloud_user_publickey}' --webServerMaxHeapSize=4096M --webServerPort=80 --webServerSslPort=443"
    }
SETTINGS
}

