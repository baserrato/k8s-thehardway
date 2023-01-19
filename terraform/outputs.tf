output "public-ip" {
  value = azurerm_public_ip.kubernetes-pip.ip_address
}

output "controller-pip" {
  value = [azurerm_public_ip.kubernetes-pip-controllers.*.ip_address]
}
