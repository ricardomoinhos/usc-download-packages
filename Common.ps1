<#
    Shared helper for the Download-UscPackagesFrom*.ps1 scripts.
#>

function Save-UscPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [string]$OutputRoot,

        # Tracks PackageId|Version already downloaded, so a dependency shared by
        # multiple packages (e.g. the same .NET hosting bundle) is only fetched once.
        [Parameter(Mandatory = $true)]
        [hashtable]$Downloaded,

        [switch]$DryRun
    )

    $key = "$PackageId|$Version"
    if ($Downloaded.ContainsKey($key)) {
        Write-Host "  '$PackageId' v$Version already processed, skipping."
        return
    }

    if ($DryRun) {
        # No -Download: just resolves/lists the files, nothing is written to disk.
        Get-UscPackageVersionFile -PackageId $PackageId -Version $Version | Out-Null
        Write-Host "  [DryRun] Would download '$PackageId' v$Version"
    }
    else {
        $packageOutputDir = Join-Path $OutputRoot $PackageId
        if (-not (Test-Path -LiteralPath $packageOutputDir)) {
            New-Item -ItemType Directory -Path $packageOutputDir -Force | Out-Null
        }

        Get-UscPackageVersionFile -PackageId $PackageId -Version $Version -Download -OutputDir $packageOutputDir # -Force

        Write-Host "  Downloaded '$PackageId' v$Version to $packageOutputDir"
    }

    $Downloaded[$key] = $true
}
