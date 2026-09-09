resource "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.aks_cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = true
    min_count            = var.node_count_min
    max_count            = var.node_count_max
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  role_based_access_control_enabled = true

  tags = var.tags
}

# Lets the AKS kubelet identity pull images from ACR without storing registry credentials.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}


resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Bootstraps ArgoCD in-cluster; it then syncs application manifests from GitLab (source of truth).
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "configs.params.server\\.insecure"
    value = "false"
  }
}

# Registers the private GitLab repo with ArgoCD so it can authenticate when syncing.
resource "kubernetes_secret" "gitlab_repo_creds" {
  metadata {
    name      = "gitlab-repo-creds"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.gitlab_repo_url
    username = var.gitlab_username
    password = var.gitlab_token
  }

  depends_on = [helm_release.argocd]
}
