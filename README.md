# FAKE Bootstrapper for .NET Core

## Description

This is a set of simple bootstrapper scripts for .NET Core projects.
Build system is based on [FAKE](https://fake.build/), a DSL for build tasks.

This bootstrapper can be used as is with no modifications, or use this as a
starting point to create your own build system.

## Prerequisites

Solution is expected to have following structure:

    src\
        SolutionName.sln
        Project1\
            Project1.csproj
            Project1.cs
        Project1.Tests\
            Project1.Tests.csproj
            Project1Tests.cs
        Project2\
            Project2.fsproj
            Project2.fs
        Project2.Tests\
            Project2.Tests.fproj
            Project2Tests.fs

- source code is in the `src` directory
- project directory name matches project file name
- test projects have `Tests` suffix
- test projects are implemeted using `xUnit`
- test projects can use either C# or F#

.NET Core needs to be installed so that `dotnet` command is available.

If you are on Linux, it is recommended to install PowerShell Core:
<https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-powershell-core-on-linux>

## Installation

Copy `build` directory to the root of your solution, so that it at the same
level with `src`:

    \build\
        build.fsx
        build.ps1
        build.sh
    \src\
        Solution.sln
        ...

If you are on Linux, make build scripts executable:

```sh
chmod u+x ./build/*.sh
```

## Usage

### Platform-specific scripts

#### Windows

In PowerShell propmt:

```PowerShell
build\build.ps1 [-Target Target] \
                [-Configuration Configuration] \
                [-Runtime Runtime]
```

#### Linux

In shell propmt:

```bash
build/build.sh [-t|--target Target] \
               [-c|--configuration Configuration] \
               [-r|--runtime Runtime]
```

Alternatively, if you have PowerShell Core installed, run same command as for Windows in PowerShell prompt (via `pwsh`).

### Build parameters

- `Target`: name of the build target
  - `Clean`: run `dotnet clean`
  - `Restore`: run `dotnet restore`
  - `Build`: run `dotnet build`
  - `Tests`: run `dotnet test` for all `*.Tests` projects
  - `FullBuild` *(default)*: `Build` + `Tests`
  - `Purge`: special target (implemented as separate script) to perform full cleanup: remove `bin` and `obj` build output directories, Fake CLI and lockfiles
- `Configuration`: `Release`*(default)*|`Debug`
- `Runtime`: `linux-x64`*(default)*|`win-x64`
