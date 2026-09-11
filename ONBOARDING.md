# Terraform onboarding — Mziba

Welcome to the Mziba infrastructure repository. This guide gets a new engineer
from access setup to a safe, reviewable Terraform plan.

## 1. What is here

| Directory | Purpose | Primary owner |
| --- | --- | --- |
| `mziba-vm-az/` | Azure production infrastructure: resource group, VNet, AKS, ACR, private PostgreSQL, and Argo CD | Platform / cloud owner |
| `mziba-vm-do/` | DigitalOcean registry, Droplet, and firewall stack | Platform / cloud owner |

The Azure stack is the current default for Mziba. The DigitalOcean stack is
separate: do not run Terraform commands from the repository root or mix state
between the two directories.

## 2. Access checklist

Ask the platform/cloud owner for the following before making changes:

- Azure subscription access with at least Contributor access to the target
  resource group, plus permission to create role assignments if your change
  needs it.
- Azure CLI login access to the Mziba subscription.
- GitLab access to `mziba1/mziba-backend` when working with the Argo CD
  bootstrap configuration.
- A GitLab service account/token approved for Argo CD repository access when
  managing the `gitlab_*` Terraform variables.
- Access to the approved secret manager for the PostgreSQL administrator
  password. Never put this value in Git or a `terraform.tfvars` file.
- For the DigitalOcean stack only: a scoped DigitalOcean API token.

## 3. Install and verify tooling

Install these command-line tools, then confirm they are available:

```bash
terraform version       # Terraform 1.6 or newer for the Azure stack
az version              # Azure CLI
kubectl version --client
helm version
git --version
```

For Azure work, authenticate and select the subscription:

```bash
az login
az account set --subscription "<subscription-id>"
az account show --query '{name:name,id:id,user:user.name}' -o yaml
```

The returned subscription ID must match the value you will provide to
Terraform. Do not continue if it is not the intended environment.

## 4. First safe Azure plan

Work from the Azure stack directory:

```bash
cd terraform/mziba-vm-az
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check -recursive
terraform validate
```

Edit only the non-secret values in your local `terraform.tfvars`. Keep unique
Azure names (notably `acr_name` and `postgres_server_name`) valid for the target
environment. Supply sensitive values through your shell or the approved secret
manager integration:

```bash
export TF_VAR_postgres_admin_password='<from-secret-manager>'
export TF_VAR_gitlab_username='<service-account-user>'
export TF_VAR_gitlab_token='<service-account-token>'
terraform plan -out=tfplan
```

Inspect the plan before requesting review. `tfplan`, `.terraform/`, state files,
and `terraform.tfvars` are local-only artifacts and must never be committed.
Clear exported secrets when you finish:

```bash
unset TF_VAR_postgres_admin_password TF_VAR_gitlab_username TF_VAR_gitlab_token
```

### Quick success milestone

By the end of your first session, you should be able to run `terraform validate`
and create a plan with **no unexpected destroy actions**. Share the text plan or
the expected resource changes with the platform/cloud owner for review; do not
run `terraform apply` independently in a shared environment.

## 5. How the Azure stack fits together

1. `main.tf` creates the resource group, VNet, and AKS subnet.
2. `acr.tf` creates the Azure Container Registry.
3. `aks.tf` creates AKS, gives its kubelet identity `AcrPull`, then installs
   Argo CD and its GitLab repository credentials.
4. `postgres.tf` creates a delegated private subnet, private DNS, PostgreSQL
   Flexible Server, and the application database.
5. `argocd-bootstrap-app.yaml` points Argo CD at the application deployment
   source of truth.

PostgreSQL has public network access disabled. Its FQDN is private and should
be used by workloads running in the VNet/AKS cluster. See
[`mziba-vm-az/doc/POSTGRES.md`](mziba-vm-az/doc/POSTGRES.md) for the application
secret hand-off.

## 6. Change workflow

1. Create a branch and make the smallest focused infrastructure change.
2. Run `terraform fmt -recursive`, `terraform validate`, and `terraform plan`.
3. Review every create, update, replace, and destroy action. Treat replacement
   of AKS, PostgreSQL, VNet, DNS, or a firewall as a change requiring explicit
   platform approval and a rollback plan.
4. Open a pull request with the intent, environment, plan summary, cost/risk
   impact, and rollback steps.
5. After approval, a designated operator applies the reviewed plan and records
   the result in the pull request.

## 7. State and secret rules

- The Azure backend is currently local state; `main.tf` explicitly marks moving
  it to an Azure Storage remote backend as required before team or CI use.
  Coordinate with the platform owner before two people work on the same stack.
- Never commit `terraform.tfstate`, `.terraform/`, `terraform.tfvars`, plan
  files, tokens, passwords, kubeconfig output, or Argo CD repository
  credentials.
- Use `terraform output` carefully: `kube_config` is sensitive. Prefer
  `az aks get-credentials` over exporting kubeconfig through Terraform.
- Use `terraform destroy` only with explicit written approval for the exact
  target environment.

## 8. First-week learning plan

| Day | Goal | Evidence of completion |
| --- | --- | --- |
| 1 | Set up access and tooling; read this guide and `POSTGRES.md`. | Successful `az account show` and `terraform validate`. |
| 2 | Trace the Azure resources and variables. | Explain the AKS → ACR and AKS → private PostgreSQL paths. |
| 3 | Make a documentation-only or tag-only change in a branch. | Reviewed plan with no unexpected changes. |
| 4 | Observe a reviewed deployment and validate outputs. | Confirm AKS/ACR/PostgreSQL outputs with the operator. |
| 5 | Propose a small, reversible infrastructure improvement. | PR includes plan, risk, cost, and rollback notes. |

## 9. Who to contact

Keep this table current as ownership changes.

| Topic | Contact / team | When to involve them |
| --- | --- | --- |
| Azure subscription, state, apply approval | Platform / cloud owner | Before access changes, applies, or state migration |
| AKS, Kubernetes, Argo CD | Platform / Kubernetes owner | Cluster, chart, namespace, or GitOps changes |
| PostgreSQL and application secrets | Database owner + security owner | Database changes, credentials, backup/restore planning |
| GitLab repository and deployment manifests | Backend / GitOps owner | Repository credential or bootstrap configuration changes |

Replace the role placeholders with named contacts and escalation channels during
your first team review.
