resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku

  # No admin user: pulls are authorized via the AKS kubelet identity's AcrPull role assignment.
  admin_enabled = false

  tags = var.tags
}
