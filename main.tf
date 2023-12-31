resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

resource "azurerm_virtual_network" "vn" {
  name                = "internal-network"
  address_space       = ["10.0.0.0/24"]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
# Should determine why dynamic IPs won't work.... for some reason variables aren't referenced properly because the IP is created after the VM..
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "virtual-machine" {
  name                = "lightweight-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  # size                = "Standard_B1ls"
  # size                = "Standard_B1ms"
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  custom_data = base64encode(templatefile("./template.tmpl", {"public_ip" = data.azurerm_public_ip.connect_ip.ip_address}))
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("./hashicorp-azure-vm.pub")
  }

# Should be demoted to a HDD if using permanently
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

 }
  # provisioner "local-exec" {
  #   command = "ansible-playbook -i '${azurerm_virtual_machine.example.private_ip},' -u adminuser -e 'ansible_python_interpreter=/usr/bin/python3' install_ansible.yml"
  #   working_dir = path.module
  # }


resource "azurerm_public_ip" "public_ip" {
  name                = "PublicIP"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

# This was one way to define a template file. Not entirely sure how to base64 encode an element like this. 
# data "template_file" "cloud-init" {
#   template = file("./template.tmpl")
#    vars = {
#     "public_ip" = azurerm_public_ip.public_ip.ip_address
#   }
# }

# In an effort to fix https://github.com/hashicorp/terraform-provider-azurerm/issues/764
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip.html

data "azurerm_public_ip" "connect_ip" {
  name = azurerm_public_ip.public_ip.name
  resource_group_name = azurerm_resource_group.rg.name
}

# resource "azurerm_network_interface_security_group_association" "association" {
#   network_interface_id      = azurerm_network_interface.rg.id
#   network_security_group_id = azurerm_network_security_group.rg.id
# }

# resource "azurerm_network_security_group" "nsg" {
#   name                = "ssh_nsg"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   security_rule {
#     name                       = "allow_ssh_sg"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }