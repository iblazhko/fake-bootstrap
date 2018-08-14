#r "paket:
nuget Fake.IO.FileSystem
nuget Fake.Core.Target
nuget Fake.DotNet
nuget Fake.DotNet.Cli //"
#load "./.fake/build.fsx/intellisense.fsx"

open System
open System.Diagnostics
open System.IO
open Fake.Core
open Fake.Core.TargetOperators
open Fake.DotNet
open Fake.IO
open Fake.IO.Globbing.Operators

module Properties =
    let buildRepositoryDir = Environment.environVar "Build_RepositoryDir"
    let buildConfiguration = Environment.environVarOrDefault "Build_Configuration" "Release"
    let buildRuntime = Environment.environVarOrDefault "Build_Runtime" "linux-x64"

    module Internal =
        // map configuration name to DotNet enum
        let buildConfigurationOption = DotNet.BuildConfiguration.fromString buildConfiguration

        // decrease verbosity
        let buildVerbosityOption = Some DotNet.Verbosity.Quiet

        // Absolute path to solution directories
        let repositoryDir = buildRepositoryDir
        let sourceDir = Path.Combine(repositoryDir, "src")
        let buildDir = Path.Combine(repositoryDir, "build")
        let buildReportsDir = Path.Combine(buildDir, "reports")

        // Absolute path to the main SLN file
        let solutionFile =
            DirectoryInfo.ofPath sourceDir
            |> DirectoryInfo.getMatchingFiles "*.sln"
            |> Seq.map (fun fi -> (fi.FullName))
            |> Seq.head

        // Tests
        let testsProjectPathPatternByLanguage = fun l -> sprintf @"%s\**\*.Tests.%sproj" sourceDir l
        let setTestParams = fun (p:DotNet.TestOptions) ->
            let commonOptions = { p.Common with Verbosity = buildVerbosityOption }
            {   p with
                    Common = commonOptions
                    Configuration = buildConfigurationOption
                    NoRestore = true
                    NoBuild = true
                    Logger = Some "trx"
                    ResultsDirectory = Some buildReportsDir
            }
        let runTestsInProject = fun p -> DotNet.test setTestParams p

module Targets =
    open Properties
    open Properties.Internal

    Target.create "Clean" (fun _ ->
        Trace.log " --- Clean --- "

        let setExecParams = fun (p:DotNet.Options) ->
            {   p with
                    Verbosity = buildVerbosityOption
            }
        DotNet.exec setExecParams "clean" solutionFile |> ignore
    )

    Target.create "Restore" (fun _ ->
        Trace.log " --- Restore --- "

        let setRestoreParams = fun (p:DotNet.RestoreOptions) ->
            let commonOptions = { p.Common with Verbosity = buildVerbosityOption }
            {   p with
                    Common = commonOptions
            }
        DotNet.restore setRestoreParams solutionFile |> ignore
    )

    Target.create "Build" (fun _ ->
        Trace.log " --- Build --- "

        let setBuildParams = fun (p:DotNet.BuildOptions) ->
            let commonOptions = { p.Common with Verbosity = buildVerbosityOption }
            {   p with
                    Configuration = buildConfigurationOption
                    Common = commonOptions
            }
        DotNet.build setBuildParams solutionFile
    )

    Target.create "Tests" (fun _ ->
        Trace.log " --- Tests --- "

        !! (testsProjectPathPatternByLanguage "cs")
        ++ (testsProjectPathPatternByLanguage "fs")
        |> Seq.iter runTestsInProject
    )

    Target.create "FullBuild" (fun _ ->
        Trace.log " --- Full build --- "
    )

// Dependencies
open Targets

"Build"
    ==> "Tests"
    ==> "FullBuild"

// *** Start Build ***
Target.runOrDefault "FullBuild"
