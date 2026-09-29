[CmdletBinding()]
param(
    [string]$SubscriptionId = '6ab40698-3a04-40ef-aa51-2216ec149195',
    [string]$TenantId = 'e9c31ad7-4805-4f03-82eb-4c2b1fee07b8',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$bootstrap = Join-Path (Split-Path $PSScriptRoot -Parent) 'bootstrap'

function Invoke-Checked {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Executable failed with exit code $LASTEXITCODE."
    }
}

$objectId = & az ad signed-in-user show --query id --output tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($objectId)) {
    throw 'Sign in with az login first; bootstrap expects an Azure user with permission to create resources and role assignments.'
}

Invoke-Checked terraform @("-chdir=$bootstrap", 'init', '-input=false')
Invoke-Checked terraform @("-chdir=$bootstrap", 'validate')
Invoke-Checked terraform @(
    "-chdir=$bootstrap", 'plan', '-input=false', '-out=bootstrap.tfplan',
    "-var=subscription_id=$SubscriptionId", "-var=tenant_id=$TenantId",
    "-var=state_admin_object_id=$objectId"
)

if ($Apply) {
    Invoke-Checked terraform @("-chdir=$bootstrap", 'apply', '-input=false', 'bootstrap.tfplan')
} else {
    Write-Host 'Bootstrap plan only. Review it; rerun with -Apply to create the remote state resources.'
}