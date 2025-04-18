output "public_ip" {
  value       = azurerm_public_ip.public_ip.ip_address
  depends_on  = [azurerm_linux_virtual_machine.vm]
}