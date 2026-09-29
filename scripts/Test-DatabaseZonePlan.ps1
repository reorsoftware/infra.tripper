param(
    [string]$PlanPath = 'tripper.tfplan'
)

$ErrorActionPreference = 'Stop'
$planJson = terraform show -json $PlanPath
if ($LASTEXITCODE -ne 0) {
    throw 'Could not read the Terraform plan.'
}
$plan = $planJson | ConvertFrom-Json
$server = @($plan.resource_changes | Where-Object { $_.address -eq 'azurerm_postgresql_flexible_server.tripper' })
if ($server.Count -ne 1 -or $null -eq $server[0].change.before.zone) {
    throw 'The plan must include an existing PostgreSQL server with an assigned zone.'
}
if ($server[0].change.actions -contains 'delete' -or $server[0].change.after.zone -ne $server[0].change.before.zone) {
    throw 'The plan would replace PostgreSQL or change its assigned zone.'
}
Write-Host "PostgreSQL zone preserved: $($server[0].change.after.zone)."