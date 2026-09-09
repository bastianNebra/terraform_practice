output "resource_group_name" {
  description = "Name of the resource group holding all resources"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "acr_login_server" {
  description = "Login server (hostname) of the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "kube_config" {
  description = "Kubeconfig for the AKS cluster (use `az aks get-credentials` instead where possible)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}
