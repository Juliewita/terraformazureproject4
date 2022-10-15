terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraformaz-rg" {
  name     = "terraformaz-resources"
  location = "East Us"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "terraformaz-vn" {
  name                = "terraformaz-network"
  location            = azurerm_resource_group.terraformaz-rg.location
  resource_group_name = azurerm_resource_group.terraformaz-rg.name
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "terraformaz-subnet" {
  name                 = "terraformaz-subnet"
  resource_group_name  = azurerm_resource_group.terraformaz-rg.name
  virtual_network_name = azurerm_virtual_network.terraformaz-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "terraformaz-sg" {
  name                = "terraformaz-sg"
  location            = azurerm_resource_group.terraformaz-rg.location
  resource_group_name = azurerm_resource_group.terraformaz-rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "terraformaz-dev-rule" {
  name                        = "mtc-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.terraformaz-rg.name
  network_security_group_name = azurerm_network_security_group.terraformaz-sg.name
}

resource "azurerm_subnet_network_security_group_association" "terraformaz-sga" {
  subnet_id                 = azurerm_subnet.terraformaz-subnet.id
  network_security_group_id = azurerm_network_security_group.terraformaz-sg.id
}

resource "azurerm_public_ip" "terraformaz-ip" {
  name                = "terraformaz-ip"
  resource_group_name = azurerm_resource_group.terraformaz-rg.name
  location            = azurerm_resource_group.terraformaz-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "terraformaz-nic" {
  name                = "terraformaz-nic"
  location            = azurerm_resource_group.terraformaz-rg.location
  resource_group_name = azurerm_resource_group.terraformaz-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terraformaz-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraformaz-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "terraformaz-vm" {
  name                  = "terraformaz-vm"
  resource_group_name   = azurerm_resource_group.terraformaz-rg.name
  location              = azurerm_resource_group.terraformaz-rg.location
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.terraformaz-nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/terraformazkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}