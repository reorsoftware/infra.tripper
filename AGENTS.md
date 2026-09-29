# Task: Provision Azure infrastructure for Tripper with Terraform
## Context
This repo is the **infrastructure-only** counterpart to an application repo ("Reor.Software.Tripper") that is NOT
part of this repo. That app repo:
- Is a .NET 10 backend (ASP.NET Core minimal API), built via a Dockerfile, pushed to Azure Container Registry (ACR)
  by its own GitHub Actions workflow (`release.yml`) on tags matching `vX.Y.Z`.
- Reads its database connection string from the environment variable `Database__ConnectionString`.
- Uses PostgreSQL with the PostGIS extension (locally `postgis/postgis:17-3.5`), so the managed Postgres instance
  must have the `POSTGIS` extension enabled.
- Has a separate React frontend (its own build, not covered by this infra repo except for hosting).
- Uses EF Core migrations (applied via a migration bundle / job at deploy time, not by this Terraform repo).
**This repo's only job is provisioning ("what exists").** It must NOT:
- Build or push any application images.
- Set a specific container image tag on the Container App as a value that changes every release (see below).
- Run database migrations.
- Deploy frontend content.
All of the above ("what version is running") is owned by GitHub Actions workflows living in the *application*
repo(s), which call `az cli` against the resources this repo creates. Keep the two concerns fully decoupled.
## Goal
Single-environment (no dev/stage/prod split, no Terraform workspaces) Terraform configuration that provisions:
1. **Resource group** — single `azurerm_resource_group` containing everything below.
2. **Azure Container Registry** — either create it here, or (if it already exists, created manually or elsewhere)
   reference it via `data "azurerm_container_registry"` — confirm which with the user before assuming either.
3. **Log Analytics workspace** — required by Container Apps Environment.
4. **Container Apps Environment** (`azurerm_container_app_environment`).
5. **Container App** for the backend (`azurerm_container_app`):
   - Pulls from the ACR above using a **user-assigned managed identity** with the `AcrPull` role assigned on the
     registry (do not use registry admin username/password).
   - Exposes `Database__ConnectionString` as a Container App **secret** (Terraform variable marked `sensitive`),
     referenced by the container via `secret_name`, not a plain env var.
   - The container `image` field should either be omitted/ignored via
     `lifecycle { ignore_changes = [template[0].container[0].image] }`, or set to a fixed placeholder tag —
     because the actual release image tag is updated out-of-band by `az containerapp update` from the app repo's
     deploy pipeline. Do not let `terraform apply` fight over the image tag with the deploy pipeline.
6. **PostgreSQL Flexible Server** (`azurerm_postgresql_flexible_server`) + database
   (`azurerm_postgresql_flexible_server_database`):
   - Enable the PostGIS extension via `azurerm_postgresql_flexible_server_configuration`
     (`azure.extensions = POSTGIS`, and allow-list it in `azure.extensions.allow_list` if required by the SKU).
   - Network-restrict access: prefer VNet integration between the Postgres Flexible Server and the Container Apps
     Environment's subnet over public access + IP allow-listing. Set this up (delegated subnet, private DNS zone)
     rather than opening the server to the public internet.
7. **Azure Static Web App** (`azurerm_static_web_app`) for the frontend — provisioning only; do not configure
   build/deploy here (that's the frontend repo's GitHub Actions job using the SWA deployment token).
8. **Remote state** — an `azurerm` backend (storage account + blob container) for Terraform state. Bootstrap this
   with a small separate script/config that is applied once manually, NOT with the same Terraform config that then
   uses it as its backend (chicken-and-egg problem).
## Structure expectations
- No modules-per-environment, no Terraform workspaces — single `main.tf` (or a small set of topically-split
  `.tf` files) + one `terraform.tfvars` (git-ignored, real values) + `terraform.tfvars.example` (committed, documented
  placeholders).
- Use `variables.tf` for all inputs (subscription/tenant IDs, resource group name/location, Postgres admin
  credentials, SKU sizes, ACR name if referenced not created, etc.) and `outputs.tf` for anything the deploy
  pipeline needs to consume (ACR login server, Container App name/resource group, Container Apps Environment name,
  Postgres FQDN, Static Web App deployment token/name).
- Pin the `azurerm` provider version and Terraform required version explicitly.
- Add a `README.md` documenting: prerequisites, how to bootstrap remote state, how to run `terraform init/plan/apply`,
  and which outputs the application repo's CI needs and how to fetch them (e.g. `terraform output -raw ...`, or via
  a data source in the app repo's workflow using `az` after the fact).
## CI expectations for this repo
- A GitHub Actions workflow that runs `terraform fmt -check`, `terraform validate`, and `terraform plan` on pull
  requests, and `terraform apply` on merge to `main` (or on manual approval — ask the user which they prefer).
- Authenticate via OIDC federated credentials (`azure/login@v2` with `client-id`/`tenant-id`/`subscription-id`, no
  long-lived secret) if possible; otherwise a `AZURE_CREDENTIALS` service-principal JSON secret scoped to
  `Contributor` on the resource group.
- Trigger only on changes under this repo's Terraform paths (whole repo, since it's dedicated to infra).
## Explicit non-goals (do not implement these here)
- Building/pushing the backend Docker image.
- Building/publishing the npm API client.
- Running EF Core migrations.
- Setting the Container App's live image tag on every release.
- Deploying the Static Web App's content.
- Multiple environments, Terraform workspaces, or per-environment `.tfvars` files.
## Open questions to confirm with the user before/while implementing
1. Does the ACR already exist (created by the app repo's own setup) and should Terraform import/reference it via a
   data source, or should this repo create it from scratch?
2. Preferred Postgres Flexible Server SKU/tier and storage size for a low-traffic single-environment deployment?
3. Should Terraform CI auto-apply on merge to `main`, or require manual approval via a GitHub environment?
4. Any existing Azure subscription/resource-group naming convention to follow?