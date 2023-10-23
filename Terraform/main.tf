terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.77.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "MonitoringResources"
  location = "East US"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "MonitoringVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  computer_name  = "monitoringvm"
  admin_username = "azureuser"

  // Add a public key to the same folder as the main.tf script (we use Ansible to send the private key to the Jenkins machine)
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  disable_password_authentication = true
}


output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}
