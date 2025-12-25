resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_storage_account" "Ashish2" {
  name                     = "ashish1a"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
resource "azurerm_virtual_network" "vnet" {
  name                = "Ashish2-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#  Subnet
resource "azurerm_virtual_network" "main" {
  name                = "main-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "Ashish7" {
  name                 = "Ashish7-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 5️⃣ Network Security Group
resource "azurerm_network_security_group" "AshishNSG" {
  name                = "Ashish-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_public_ip" "publicip" {
  name                = "public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 7️⃣ NIC
resource "azurerm_network_interface" "nic" {
  name                = "Ashish-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Ashish7.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}
# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.AshishNSG.id
}
resource "azurerm_resource_group" "rgravi" {
  name     = var.resource_group_name
  location = var.location
}
# Public IP for Bastion
resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Bastion
resource "azurerm_bastion_host" "bastion" {
  name                = "MyBastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  #dns_name            = "mybastiondns"

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}

# Bastion Subnet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"

  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/27"]
}
# 8️⃣ Linux VM
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "AshishVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

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

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/Admin/.ssh/id_rsa.pub")
  }
}
output "public_ip_address" {
  description = "Public IP of the VM"
  value       = azurerm_public_ip.publicip.ip_address
}

output "ssh_command" {
  description = "SSH connect command"
  value       = "ssh azureuser@${azurerm_public_ip.publicip.ip_address}"
}