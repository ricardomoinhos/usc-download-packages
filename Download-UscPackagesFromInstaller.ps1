<#
    Pre-downloads package files for a given Update Service installer,
    so the installer can run later without hitting the network.

    Pipeline:
      1. Get-UscInstallerPackage -InstallerId  -> PackageId (+ VersionQuery) per package in the installer
      2. Get-UscUpdates -PackageId -VersionQuery -> resolves the actual Version to install (and, for each
         package, its full dependency set - e.g. .NET hosting bundle, IIS URL Rewrite, ...)
      3. Get-UscPackageVersionFile -PackageId -Version -Download -> downloads the package files locally

    By default, only the main packages listed by Get-UscInstallerPackage are downloaded.
    Pass -IncludeDependencies to also pre-download every dependency Get-UscUpdates reports
    for those packages (e.g. ms-dotnet-9-hosting, ms-iis-web-sockets, ...).

    Pass -DryRun to resolve and report what would be downloaded without transferring any
    files: Get-UscPackageVersionFile is called without -Download in that case.
#>

param(
    [Parameter(Mandatory = $true)]
    [Guid]$InstallerId,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [switch]$IncludeDependencies,

    [switch]$DryRun
)

if (-not $DryRun -and -not (Test-Path -LiteralPath $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
}

. (Join-Path $PSScriptRoot 'Common.ps1')

# Tracks PackageId|Version already downloaded, so a dependency shared by
# multiple packages (e.g. the same .NET hosting bundle) is only fetched once.
$downloaded = @{}

Write-Host "Retrieving packages for installer $InstallerId ..."
$packages = Get-UscInstallerPackage -InstallerId $InstallerId

foreach ($pkg in $packages) {

    Write-Host "`nResolving version for package '$($pkg.PackageId)' (VersionQuery: '$($pkg.VersionQuery)') ..."

    $updateParams = @{ PackageId = $pkg.PackageId }
    if (-not [string]::IsNullOrWhiteSpace($pkg.VersionQuery)) {
        $updateParams['VersionQuery'] = $pkg.VersionQuery
    }

    # Get-UscUpdates returns the whole dependency set for the requested package
    # (e.g. ms-dotnet-9-hosting, ms-iis-web-sockets, ...), not just the package itself,
    # so filter on Id to pick out the entry that actually matches PackageId.
    # (Do NOT pipe into Select-Object -First 1 directly on the cmdlet call: that stops
    # the pipeline early and this cmdlet throws PipelineStoppedException when that happens.)
    $allUpdates = Get-UscUpdates @updateParams
    $mainUpdate = $allUpdates | Where-Object { $_.Id -eq $pkg.PackageId } | Select-Object -First 1

    if (-not $mainUpdate -or -not $mainUpdate.Version) {
        Write-Warning "Could not resolve a version for package '$($pkg.PackageId)'. Skipping."
        continue
    }

    $updatesToDownload = if ($IncludeDependencies) { $allUpdates } else { @($mainUpdate) }

    Write-Host "Package '$($pkg.PackageId)' -> Version $($mainUpdate.Version)."
    if ($IncludeDependencies -and $allUpdates.Count -gt 1) {
        Write-Host "  Including $($allUpdates.Count - 1) dependency package(s)."
    }

    foreach ($u in $updatesToDownload) {
        if (-not $u.Version) {
            Write-Warning "  No version available for dependency '$($u.Id)'. Skipping."
            continue
        }
        Save-UscPackage -PackageId $u.Id -Version $u.Version -OutputRoot $OutputRoot -Downloaded $downloaded -DryRun:$DryRun
    }
}

if ($DryRun) {
    Write-Host "`nDry run complete. No files were downloaded."
}
else {
    Write-Host "`nAll packages processed. Files are under: $OutputRoot"
}
