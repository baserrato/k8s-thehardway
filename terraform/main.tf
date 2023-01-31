resource "azurerm_resource_group" "kubernetes" {
  name     = "kubernetes"
  location = "westus"

  tags = {
    Client      = "Internal"
    Project     = "DOB"
    Owner       = "Benjamin Serrato"
    Application = "Demo"
  }
}

resource "azurerm_virtual_network" "kubernetes-vnet" {
  name                = "kubernetes-vnet"
  location            = azurerm_resource_group.kubernetes.location #grabs location from resource group
  resource_group_name = azurerm_resource_group.kubernetes.name     #grabs resource group name from itself
  address_space       = ["10.240.0.0/24"]

  tags = {
    Client      = azurerm_resource_group.kubernetes.tags.Client
    Project     = azurerm_resource_group.kubernetes.tags.Project
    Owner       = azurerm_resource_group.kubernetes.tags.Owner
    Application = azurerm_resource_group.kubernetes.tags.Application
  }
}

resource "azurerm_subnet" "kubernetes-subnet" {
  name                 = "kubernetes-subnet"
  resource_group_name  = azurerm_resource_group.kubernetes.name
  virtual_network_name = azurerm_virtual_network.kubernetes-vnet.name
  address_prefixes     = ["10.240.0.0/24"]
}

resource "azurerm_network_security_group" "kubernetes-nsg" {
  name                = "kubernetes-nsg"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name

  security_rule {
    name                       = "kubernetes-allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "kubernetes-allow-api-server"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Client      = azurerm_resource_group.kubernetes.tags.Client
    Project     = azurerm_resource_group.kubernetes.tags.Project
    Owner       = azurerm_resource_group.kubernetes.tags.Owner
    Application = azurerm_resource_group.kubernetes.tags.Application
  }
}

resource "azurerm_subnet_network_security_group_association" "kubernetes-subnetnsg" {
  subnet_id                 = azurerm_subnet.kubernetes-subnet.id
  network_security_group_id = azurerm_network_security_group.kubernetes-nsg.id
}

resource "azurerm_public_ip" "kubernetes-pip" {
  name                = "kubernetes-pip"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name
  allocation_method   = "Static"

  tags = {
    Client      = azurerm_resource_group.kubernetes.tags.Client
    Project     = azurerm_resource_group.kubernetes.tags.Project
    Owner       = azurerm_resource_group.kubernetes.tags.Owner
    Application = azurerm_resource_group.kubernetes.tags.Application
  }
}

resource "azurerm_lb" "kubernetes-lb" {
  name                = "kubernetes-lb"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.kubernetes-pip.name
    public_ip_address_id = azurerm_public_ip.kubernetes-pip.id
  }

  tags = {
    Client      = azurerm_resource_group.kubernetes.tags.Client
    Project     = azurerm_resource_group.kubernetes.tags.Project
    Owner       = azurerm_resource_group.kubernetes.tags.Owner
    Application = azurerm_resource_group.kubernetes.tags.Application
  }
}

resource "azurerm_lb_backend_address_pool" "kubernetes-lb-pool" {
  loadbalancer_id = azurerm_lb.kubernetes-lb.id
  name            = "kubernetes-lb-pool"
}

# Setting up controller nodes
resource "azurerm_availability_set" "controller-as" {
  name                = "controller-as"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name

  tags = {
    Client      = azurerm_resource_group.kubernetes.tags.Client
    Project     = azurerm_resource_group.kubernetes.tags.Project
    Owner       = azurerm_resource_group.kubernetes.tags.Owner
    Application = azurerm_resource_group.kubernetes.tags.Application
  }
}

resource "azurerm_public_ip" "kubernetes-pip-controllers" {
  count               = var.controller-count
  name                = "controller-${count.index}-pip"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name
  allocation_method   = "Static"

  tags = {
    Client      = azurerm_resource_group.kubernetes.tags.Client
    Project     = azurerm_resource_group.kubernetes.tags.Project
    Owner       = azurerm_resource_group.kubernetes.tags.Owner
    Application = azurerm_resource_group.kubernetes.tags.Application
  }
}

resource "azurerm_network_interface" "controller-nic" {
  count               = var.controller-count
  name                = "controller-${count.index}-nic"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kubernetes-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.240.0.1${count.index}"
    public_ip_address_id          = azurerm_public_ip.kubernetes-pip-controllers[count.index].id
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "kubernetes-lb-nic-association" {
  count                   = var.controller-count
  network_interface_id    = azurerm_network_interface.controller-nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.kubernetes-lb-pool.id
}

resource "azurerm_linux_virtual_machine" "controller-vm" {
  count                 = var.controller-count
  name                  = "controller-${count.index}"
  location              = azurerm_resource_group.kubernetes.location
  resource_group_name   = azurerm_resource_group.kubernetes.name
  network_interface_ids = [azurerm_network_interface.controller-nic[count.index].id]
  admin_username        = "kuberoot"
  availability_set_id   = azurerm_availability_set.controller-as.id

  size = "Standard_F2"
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "18.04.202301100"
  }

  admin_ssh_key {
    username   = "kuberoot"
    public_key = tls_private_key.kubernetes-controller-key[count.index].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "tls_private_key" "kubernetes-controller-key" {
  count     = var.controller-count
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "controller-private-key" {
  count           = var.controller-count
  content         = tls_private_key.kubernetes-controller-key[count.index].private_key_pem
  filename        = "../aks-keys/controller-${count.index}.pem"
  file_permission = "0600"
}

# Setting up Worker nodes
resource "azurerm_availability_set" "worker-as" {
  name                = "worker-as"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name

  tags = {
    Client      = azurerm_resource_group.kubernetes.tags.Client
    Project     = azurerm_resource_group.kubernetes.tags.Project
    Owner       = azurerm_resource_group.kubernetes.tags.Owner
    Application = azurerm_resource_group.kubernetes.tags.Application
  }
}


resource "azurerm_public_ip" "kubernetes-pip-workers" {
  count               = var.worker-count
  name                = "worker-${count.index}-pip"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name
  allocation_method   = "Static"

  tags = {
    Client      = azurerm_resource_group.kubernetes.tags.Client
    Project     = azurerm_resource_group.kubernetes.tags.Project
    Owner       = azurerm_resource_group.kubernetes.tags.Owner
    Application = azurerm_resource_group.kubernetes.tags.Application
  }
}

resource "azurerm_network_interface" "worker-nic" {
  count               = var.worker-count
  name                = "worker-${count.index}-nic"
  location            = azurerm_resource_group.kubernetes.location
  resource_group_name = azurerm_resource_group.kubernetes.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kubernetes-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.240.0.2${count.index}"
    public_ip_address_id          = azurerm_public_ip.kubernetes-pip-workers[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "worker-vm" {
  count                 = var.worker-count
  name                  = "worker-${count.index}"
  location              = azurerm_resource_group.kubernetes.location
  resource_group_name   = azurerm_resource_group.kubernetes.name
  network_interface_ids = [azurerm_network_interface.worker-nic[count.index].id]
  admin_username        = "kuberoot"
  availability_set_id   = azurerm_availability_set.worker-as.id

  size = "Standard_F2"
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "18.04.202301100"
  }

  admin_ssh_key {
    username   = "kuberoot"
    public_key = tls_private_key.kubernetes-worker-key[count.index].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  tags = {
    pod-cidr = "10.200.${count.index}.0/24"
  }
}

resource "tls_private_key" "kubernetes-worker-key" {
  count     = var.worker-count
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "worker-private-key" {
  count           = var.worker-count
  content         = tls_private_key.kubernetes-worker-key[count.index].private_key_pem
  filename        = "../aks-keys/worker-${count.index}.pem"
  file_permission = "0600"
}
