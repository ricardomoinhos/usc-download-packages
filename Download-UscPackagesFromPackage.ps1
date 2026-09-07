<#
    Pre-downloads package files for a single Update Service package + version,
    so it can be installed later without hitting the network.

    Pipeline:
      1. Get-UscPackageVersion -PackageId -Version -IncludeDependencies -> Dependencies
         (each entry has Id + VersionQuery, but no resolved Version)
      2. Get-UscUpdates -PackageId -VersionQuery -> resolves the actual Version for each dependency
      3. Get-UscPackageVersionFile -PackageId -Version -Download -> downloads the package files locally

    Pass -DryRun to resolve and report what would be downloaded without transferring any
    files: Get-UscPackageVersionFile is called without -Download in that case.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PackageId,

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [switch]$DryRun
)

if (-not $DryRun -and -not (Test-Path -LiteralPath $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
}

. (Join-Path $PSScriptRoot 'Common.ps1')

# Tracks PackageId|Version already downloaded, so a dependency shared by
# multiple packages (e.g. the same .NET hosting bundle) is only fetched once.
$downloaded = @{}

Write-Host "Retrieving dependencies for package '$PackageId' v$Version ..."
$packageVersion = Get-UscPackageVersion -PackageId $PackageId -Version $Version -IncludeDependencies

Write-Host "Package '$PackageId' -> Version $Version."
Save-UscPackage -PackageId $PackageId -Version $Version -OutputRoot $OutputRoot -Downloaded $downloaded -DryRun:$DryRun

foreach ($dep in $packageVersion.Dependencies) {

    Write-Host "`nResolving version for dependency '$($dep.Id)' (VersionQuery: '$($dep.VersionQuery)') ..."

    # Get-UscUpdates returns the whole dependency set for the requested package,
    # so filter on Id to pick out the entry that actually matches the dependency.
    # (Do NOT pipe into Select-Object -First 1 directly on the cmdlet call: that stops
    # the pipeline early and this cmdlet throws PipelineStoppedException when that happens.)
    $allUpdates = Get-UscUpdates -PackageId $dep.Id -VersionQuery $dep.VersionQuery
    $resolved = $allUpdates | Where-Object { $_.Id -eq $dep.Id } | Select-Object -First 1

    if (-not $resolved -or -not $resolved.Version) {
        Write-Warning "Could not resolve a version for dependency '$($dep.Id)'. Skipping."
        continue
    }

    Write-Host "Dependency '$($dep.Id)' -> Version $($resolved.Version)."
    Save-UscPackage -PackageId $dep.Id -Version $resolved.Version -OutputRoot $OutputRoot -Downloaded $downloaded -DryRun:$DryRun
}

if ($DryRun) {
    Write-Host "`nDry run complete. No files were downloaded."
}
else {
    Write-Host "`nAll packages processed. Files are under: $OutputRoot"
}
