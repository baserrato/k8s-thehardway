output "public-ip" {
  value = azurerm_public_ip.kubernetes-pip.ip_address
}

output "controller-pip" {
  value = [azurerm_public_ip.kubernetes-pip-controllers.*.ip_address]
}

output "worker-pip" {
  value = [azurerm_public_ip.kubernetes-pip-workers.*.ip_address]
}
