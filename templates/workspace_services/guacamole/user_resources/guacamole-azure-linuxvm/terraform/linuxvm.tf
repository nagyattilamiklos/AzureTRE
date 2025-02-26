resource "azurerm_network_interface" "internal" {
  name                = "internal-nic-${local.service_resource_name_suffix}"
  location            = data.azurerm_resource_group.ws.location
  resource_group_name = data.azurerm_resource_group.ws.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.services.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "random_string" "username" {
  length      = 4
  upper       = true
  lower       = true
  number      = true
  min_numeric = 1
  min_lower   = 1
  special     = false
}

resource "random_password" "password" {
  length           = 16
  lower            = true
  min_lower        = 1
  upper            = true
  min_upper        = 1
  number           = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "_%@"
}

resource "azurerm_linux_virtual_machine" "linuxvm" {
  name                            = local.vm_name
  location                        = data.azurerm_resource_group.ws.location
  resource_group_name             = data.azurerm_resource_group.ws.name
  network_interface_ids           = [azurerm_network_interface.internal.id]
  size                            = local.vm_size[var.vm_size].value
  disable_password_authentication = false
  admin_username                  = random_string.username.result
  admin_password                  = random_password.password.result

  custom_data = data.template_cloudinit_config.config.rendered

  source_image_reference {
    publisher = local.image_ref[var.image].publisher
    offer     = local.image_ref[var.image].offer
    sku       = local.image_ref[var.image].sku
    version   = local.image_ref[var.image].version
  }

  os_disk {
    name                 = "osdisk-${local.vm_name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    parent_service_id = var.parent_service_id
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.apt_sources_config.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.pypi_sources_config.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.vm_config.rendered
  }
}

data "template_file" "vm_config" {
  template = file("${path.module}/vm_config.sh")
  vars = {
    install_ui            = local.image_ref[var.image].install_ui ? 1 : 0
    shared_storage_access = tobool(var.shared_storage_access) ? 1 : 0
    resource_group_name   = data.azurerm_storage_account.stg.resource_group_name
    storage_account_name  = data.azurerm_storage_account.stg.name
    storage_account_key   = data.azurerm_storage_account.stg.primary_access_key
    http_endpoint         = data.azurerm_storage_account.stg.primary_file_endpoint
    fileshare_name        = data.azurerm_storage_share.shared_storage.name
    nexus_proxy_url       = local.nexus_proxy_url
    conda_config          = local.image_ref[var.image].conda_config ? 1 : 0
  }
}

data "template_file" "pypi_sources_config" {
  template = file("${path.module}/pypi_sources_config.sh")
  vars = {
    nexus_proxy_url = local.nexus_proxy_url
  }
}

data "template_file" "apt_sources_config" {
  template = file("${path.module}/apt_sources_config.yml")
  vars = {
    nexus_proxy_url = local.nexus_proxy_url
  }
}

resource "azurerm_key_vault_secret" "linuxvm_password" {
  name         = "${local.vm_name}-admin-credentials"
  value        = "${random_string.username.result}\n${random_password.password.result}"
  key_vault_id = data.azurerm_key_vault.ws.id
}
data "azurerm_storage_account" "stg" {
  name                = local.storage_name
  resource_group_name = data.azurerm_resource_group.ws.name
}

data "azurerm_storage_share" "shared_storage" {
  name                 = var.shared_storage_name
  storage_account_name = data.azurerm_storage_account.stg.name
}
