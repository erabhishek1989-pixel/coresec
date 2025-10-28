locals {
  environment_identifier_shortcode_uksouth = "uk"
  environment_identifier_shortcode_ukwest  = "uk"

}

#resource "azurerm_windows_virtual_machine_scale_set" "windows_virtual_machine_scale_set" {
#  for_each = {
#    for i, vmss in var.virtual_machine_scale_set : vmss.name => vmss
#  }
#  name                 = "${var.environment_identifier}-vmss-${var.name}"
#  computer_name_prefix = "${var.environment_identifier}${each.value.computer_name_prefix}"
#  resource_group_name  = var.resource_group_name
#  location             = var.location
#  sku                  = each.value.sku
#  instances            = each.value.instances
#  admin_password       = var.secret_admin_password
#  admin_username       = var.secret_admin_username
#  license_type         = each.value.license_type
#  overprovision        = false
#
#  tags = var.tags
#
#
#  source_image_reference {
#    publisher = each.value.image_publisher
#    offer     = each.value.image_offer
#    sku       = each.value.image_sku
#    version   = each.value.image_version
#  }
#
#  os_disk {
#    storage_account_type = "Standard_LRS"
#    caching              = "ReadWrite"
#  }
#
#  network_interface {
#    name    = "${var.environment_identifier}-nic-${var.name}"
#    primary = true
#
#    ip_configuration {
#      name      = "internal"
#      primary   = true
#      subnet_id = var.subnet_id
#
#    }
#  }
#
#}

resource "azurerm_network_interface" "network_interface" {
  count               = var.instances
  name                = "${var.environment_identifier}-nic-vm-core-security-${var.computer_name}-00${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "avd-ipconf"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windows_virtual_machine" {

  count                 = var.instances
  name                  = "${var.environment_identifier}-vm-core-security-${var.computer_name}-00${count.index}"
  computer_name         = "${var.environment_identifier}${var.computer_name}-00${count.index}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.sku
  admin_password        = var.secret_admin_password
  admin_username        = var.secret_admin_username
  license_type          = var.license_type
  network_interface_ids = [azurerm_network_interface.network_interface[count.index].id]
  #overprovision        = false

  tags = var.tags


  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  #network_interface {
  #  name    = "${var.environment_identifier}-nic-${var.name}"
  #  primary = true
  #
  #  ip_configuration {
  #    name      = "internal"
  #    primary   = true
  #    subnet_id = var.subnet_id
  #
  #  }
  #}

}

resource "azurerm_virtual_machine_extension" "virtual_machine_extension_ads_join" {

  count                = var.instances
  name                 = "${var.environment_identifier}-vmssext-${var.name}-ads-join"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_virtual_machine[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = <<-SETTINGS
    {
      "Name": "${var.domain_name}",
      "OUPath": "${var.domain_ou_path}",
      "User": "${var.domain_name}\\${var.secret_res_ads_username}",
      "Restart": "${var.domain_restart}",
      "Options": "3"
    }
    SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "Password": "${var.secret_res_ads_password}"
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [azurerm_windows_virtual_machine.windows_virtual_machine]

}

resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                      = var.instances
  name                       = "${var.environment_identifier}-vmext-${var.name}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.windows_virtual_machine[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.virtual_desktop_host_pool.name}"
      }
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.virtual_desktop_host_pool_registration_info.token}"
    }
  }
  PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.virtual_machine_extension_ads_join,
    azurerm_virtual_desktop_host_pool.virtual_desktop_host_pool
  ]
}

resource "azurerm_virtual_desktop_host_pool" "virtual_desktop_host_pool" {
  name                     = "${var.environment_identifier}-vdhp-${var.name}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  type                     = var.type
  load_balancer_type       = var.load_balancer_type
  maximum_sessions_allowed = var.maximum_sessions_allowed
  description              = var.description
  start_vm_on_connect      = var.start_vm_on_connect

  tags = var.tags

  #depends_on = [azurerm_windows_virtual_machine_scale_set.windows_virtual_machine_scale_set]
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "virtual_desktop_host_pool_registration_info" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.virtual_desktop_host_pool.id
  expiration_date = var.host_pool_registration_expiration_date

  depends_on = [azurerm_virtual_desktop_host_pool.virtual_desktop_host_pool]


}

resource "azurerm_virtual_desktop_application_group" "virtual_desktop_application_group" {

  name                = "${var.environment_identifier}-vdag-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  type                         = "Desktop"
  host_pool_id                 = azurerm_virtual_desktop_host_pool.virtual_desktop_host_pool.id
  friendly_name                = "RSM Secure Workstation"
  description                  = "Secure workstation for Priviliged accounts"
  default_desktop_display_name = "RSM Secure Workstation"

}

resource "azurerm_virtual_desktop_workspace" "virtual_desktop_workspace" {
  name                = "${var.environment_identifier}-vdws-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = "RSM Security Team"
  description         = "RSM Security Team"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "virtual_desktop_workspace_application_group_association" {
  workspace_id         = azurerm_virtual_desktop_workspace.virtual_desktop_workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.virtual_desktop_application_group.id

}
#resource "azurerm_virtual_machine_scale_set_extension" "vmsse_domain_join" {
#  name                         = "DomainJoin"
#  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.windows_virtual_machine_scale_set.id
#  publisher                    = "Microsoft.Compute"
#  type                         = "JsonADDomainExtension"
#  type_handler_version         = "1.3"
#  settings                     = <<SETTINGS
#  {
#  "Name":"${var.domain_name}",
#  "OUPath":"${var.domain_ou_path}",
#  "User":"${var.domain_name}\\${var.secret_res_ads_username}",
#  "Restart":"${var.domain_restart}",
#  "Options":"3"
#  }
#  SETTINGS
#  protected_settings           = <<PROTECTED_SETTINGS
#  {
#  "Password":"${var.secret_res_ads_password}"
#  }
#  PROTECTED_SETTINGS
#}

#resource "azurerm_network_interface" "nic-windows-virtual-machine_scale_set" {
#  for_each = {
#    for i, nic in var.virtual_machine_scale_set : nic.name => nic
#  }
#
#  count               = each.value.count
#  name                = "${var.environment_identifier}-nic-${var.name}-${count.index}"
#  location            = var.location
#  resource_group_name = var.resource_group_name
#
#  ip_configuration {
#    name                          = "windows-virtual-machine_scale_set_ip_conf"
#    subnet_id                     = var.subnet_id
#    private_ip_address_allocation = "Dynamic"
#  }
#}
