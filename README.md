# usc-download-packages

Demonstration scripts showing how to pre-download Update Service (USC) packages and their dependencies, by installer or by package/bundle, so they can be installed later without hitting the network.

**Additional context:** For background on the challenge and the motivation behind these scripts, see the [related blog post](https://example.com/my-blog-post](https://ricardomoinhos.com/pre-downloading-packages-before-upgrading-pos-terminals-with-update-service/)).

## Scripts

- [`Download-UscPackagesFromInstaller.ps1`](Download-UscPackagesFromInstaller.ps1) resolves every package in an installer and downloads the selected package versions. Use `-IncludeDependencies` to download the dependencies reported for those packages as well.
- [`Download-UscPackagesFromPackage.ps1`](Download-UscPackagesFromPackage.ps1) downloads one explicitly versioned package or bundle and all dependencies declared by that package.

Both scripts store each package in a subfolder named after its `PackageId`. They also skip a package/version that has already been processed during the current run, so a shared dependency is downloaded only once. Use `-DryRun` to resolve and report the files without downloading them.

For complete command examples, see [`Examples.md`](Examples.md).

## Download packages from an installer

### How it works

An installer (identified by its `InstallerId`) is made up of several packages (for example, `ls-update-service-server`, `ls-central-hcc-project`, and `ls-dd-service`). To download those packages' files, the script chains three Update Service cmdlets:

1. **[`Get-UscInstallerPackage`](https://help.updateservice.lsretail.com/docs/clients/cmdlets/Get-UscInstallerPackage.html) `-InstallerId`** lists the packages that belong to the installer. It returns a `PackageId` and sometimes a `VersionQuery` (for example, `!^`) for each package, but no concrete version number.
2. **[`Get-UscUpdates`](https://help.updateservice.lsretail.com/docs/clients/cmdlets/Get-UscUpdates.html) `-PackageId -VersionQuery`** resolves the actual `Version` that would be installed. The package's own `VersionQuery`, when present, is passed through so the script resolves the same version the installer would pick, rather than simply the latest version.
3. **[`Get-UscPackageVersionFile`](https://help.updateservice.lsretail.com/docs/clients/cmdlets/Get-UscPackageVersionFile.html) `-PackageId -Version -Download -OutputDir`** downloads that package version's files into its local output folder.

By default, only the main packages returned by `Get-UscInstallerPackage` are downloaded. Each `Get-UscUpdates` result also contains the dependency set needed for that package, such as `ms-dotnet-9-hosting`, `ms-iis-web-sockets`, and `ms-iis-rewrite-module`. Pass `-IncludeDependencies` to download those packages too.

### Usage

```powershell
.\Download-UscPackagesFromInstaller.ps1 -InstallerId <InstallerId Guid> -OutputRoot <path> [-IncludeDependencies] [-DryRun]
```

### Parameters

| Parameter | Required | Description |
|---|---|---|
| `InstallerId` | Yes | GUID of the installer, for example one shown by `Get-UscInstallerPackage`. |
| `OutputRoot` | Yes | Local folder where package files are stored. Created if it does not exist; skipped entirely in `-DryRun`. |
| `IncludeDependencies` | No | Also downloads every dependency package reported by `Get-UscUpdates` for each main package. |
| `DryRun` | No | Resolves and reports what would be downloaded without transferring files. |

## Download a package or bundle

Use this script when you already know the package or bundle ID and the exact version to download. Unlike installer mode, dependencies are always included; there is no `-IncludeDependencies` switch.

### How it works

The script uses the following cmdlets:

1. **`Get-UscPackageVersion -PackageId -Version -IncludeDependencies`** gets the selected package version and its declared dependencies. Dependency entries contain an `Id` and `VersionQuery`, but not necessarily a resolved version.
2. **[`Get-UscUpdates`](https://help.updateservice.lsretail.com/docs/clients/cmdlets/Get-UscUpdates.html) `-PackageId -VersionQuery`** resolves the concrete version for each dependency.
3. **[`Get-UscPackageVersionFile`](https://help.updateservice.lsretail.com/docs/clients/cmdlets/Get-UscPackageVersionFile.html) `-PackageId -Version -Download -OutputDir`** downloads the package and dependency files.

### Usage

```powershell
.\Download-UscPackagesFromPackage.ps1 -PackageId <PackageId> -Version <Version> -OutputRoot <path> [-DryRun]
```

### Parameters

| Parameter | Required | Description |
|---|---|---|
| `PackageId` | Yes | ID of the package or bundle, for example `ls-central-app` or `bundle/cronus-pos`. |
| `Version` | Yes | Exact version of the package or bundle to download. |
| `OutputRoot` | Yes | Local folder where package files are stored. Created if it does not exist; skipped entirely in `-DryRun`. |
| `DryRun` | No | Resolves and reports what would be downloaded without transferring files. |

To download multiple packages or bundles, invoke the script once for each package/version pair using the same `OutputRoot`. Each invocation tracks duplicates within that run, and existing files are overwritten because `-Force` is passed to `Get-UscPackageVersionFile`.
