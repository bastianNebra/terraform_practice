# PostgreSQL Azure

This Terraform stack provisions an Azure Database for PostgreSQL Flexible
Server on a delegated subnet inside the Mziba VNet. Public network access is
disabled; AKS reaches PostgreSQL through the private DNS zone.

## Plan and apply

Provide the administrator password through an environment variable. Never add
it to `terraform.tfvars` or commit it to Git:

```bash
export TF_VAR_postgres_admin_password='use-a-secret-password-manager-value'
terraform init
terraform plan
terraform apply
unset TF_VAR_postgres_admin_password
```

The server FQDN is available with:

```bash
terraform output -raw postgres_server_fqdn
```

Use that FQDN as `DB_HOST` in the `mziba-backend-env` Kubernetes secret. Create
the secret separately in each namespace; application credentials must not be
managed in this repository.

The default `10.10.2.0/24` subnet must not overlap the existing VNet or AKS
subnet. Override `postgres_subnet_cidr` if the address space is already used.
