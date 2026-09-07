# PowerShell Examples

## Downloading the packages for an installer

`53d43350-9881-434e-8b16-6db939d58385` is the ID for the "POS Offline POS with Web Repl. using Azure Storage" installer. You can get an installer ID from its URL after clicking the installer in the Update Service Console under **Installers**.

```powershell
.\Download-UscPackagesFromInstaller.ps1 -InstallerId "53d43350-9881-434e-8b16-6db939d58385" -OutputRoot "C:\UscDownloads" -DryRun -IncludeDependencies
```

```powershell
.\Download-UscPackagesFromInstaller.ps1 -InstallerId "53d43350-9881-434e-8b16-6db939d58385" -OutputRoot "C:\UscDownloads" -IncludeDependencies
```

```powershell
.\Download-UscPackagesFromInstaller.ps1 -InstallerId "53d43350-9881-434e-8b16-6db939d58385" -OutputRoot "C:\UscDownloads" -DryRun
```

```powershell
.\Download-UscPackagesFromInstaller.ps1 -InstallerId "53d43350-9881-434e-8b16-6db939d58385" -OutputRoot "C:\UscDownloads"
```

## Downloading a single package or bundle, including all its dependencies

Dependencies are included automatically by `Download-UscPackagesFromPackage.ps1`.

```powershell
.\Download-UscPackagesFromPackage.ps1 -PackageId 'ls-central-app' -Version 28.0.0 -OutputRoot "C:\UscDownloads"
```

```powershell
.\Download-UscPackagesFromPackage.ps1 -PackageId 'bundle/cronus-pos' -Version 3.0.3 -OutputRoot "C:\UscDownloads"
```

## Downloading multiple packages or bundles at once

```powershell
$LsCentralVersion = "28.0.0"
$Packages = @(
    @{ Id = 'ls-central-app'; Version = $LsCentralVersion }
    @{ Id = 'map/ls-central-to-bc'; Version = $LsCentralVersion }
)

foreach ($Package in $Packages) {
    .\Download-UscPackagesFromPackage.ps1 -PackageId $Package.Id -Version $Package.Version -OutputRoot "C:\UscDownloads"
}
```
