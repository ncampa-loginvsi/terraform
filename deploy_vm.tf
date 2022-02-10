terraform {
  required_version = ">= 1.1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.94"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_location
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-Vnet"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_location
}

# Create Subnet inside Vnet
resource "azurerm_subnet" "sub" {
    name = "internal"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.2.0/24"]
}

# Create Network Interface to connect Vnet to Internet
resource "azurerm_network_interface" "nic" {
    name = "sample-nic"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    # Configure NIC to subnet
    ip_configuration {
        name = "internal"
        subnet_id = azurerm_subnet.sub.id
        private_ip_address_allocation = "Dynamic"
    }
}

# Creates Availability set to host machine
resource "azurerm_availability_set" "ex_aset" {
    name                = "example-aset"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "example" {
    name = "example-vm"
    computer_name = "testmachine"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    size = "Standard_F2"
    admin_username = "adminuser"
    admin_password = "P@assw0rd!"
    availability_set_id = azurerm_availability_set.ex_aset.id
    network_interface_ids = [azurerm_network_interface.nic.id, ]

    # Configure managed disk settings
    os_disk {
      caching = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }

    # Configure source image settings
    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer = "WindowsServer"
        sku = "2016-DataCenter"
        version = "latest"
    }
}