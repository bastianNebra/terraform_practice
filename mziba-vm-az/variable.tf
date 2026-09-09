variable "subscription_id" {
  description = "Azure subscription ID to deploy into"
  type        = string
}

variable "project" {
  description = "Project short name used for resource naming"
  type        = string
  default     = "mziba"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "prod"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "rg-mziba-prod"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "francecentral"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project     = "mziba"
    environment = "prod"
    managed_by  = "terraform"
  }
}

# --- Networking ---

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.10.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS node subnet"
  type        = string
  default     = "10.10.1.0/24"
}

# --- ACR ---

variable "acr_name" {
  description = "Globally unique ACR name (alphanumeric only, no dashes)"
  type        = string
  default     = "acrmzibaprod"
}

variable "acr_sku" {
  description = "ACR SKU"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "acr_sku must be one of Basic, Standard, Premium."
  }
}

# --- AKS ---

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-mziba-prod"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster (leave null to use latest supported by Azure)"
  type        = string
  default     = null
}

variable "node_vm_size" {
  description = "VM size for the default AKS node pool"
  type        = string
  default     = "Standard_D2ads_v7"
}

variable "node_count_min" {
  description = "Minimum node count for the default node pool autoscaler"
  type        = number
  default     = 1
}

variable "node_count_max" {
  description = "Maximum node count for the default node pool autoscaler"
  type        = number
  default     = 3
}

# --- ArgoCD ---

variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the argo-cd Helm chart"
  type        = string
  default     = "7.6.12"
}

# --- GitLab ---

variable "gitlab_username" {
  type      = string
  sensitive = true
}

variable "gitlab_token" {
  type      = string
  sensitive = true
}

variable "gitlab_repo_url" {
  description = "HTTPS URL of the GitLab repo ArgoCD syncs from (must match argocd-bootstrap-app.yaml)"
  type        = string
  default     = "https://gitlab.com/mziba1/mziba-backend.git"
}
