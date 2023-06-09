﻿function Show-Demo
{
    <#
    .SYNOPSIS
        Shows a Demo
    .DESCRIPTION
        Shows a PowerShell Demo Script.
    .EXAMPLE
        Show-Demo
    .LINK
        Get-Demo
    #>
    [Alias('Start-Demo')]
    [CmdletBinding(DefaultParameterSetName='LoadedDemos')]
    param(
    # The name of the demo
    [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='LoadedDemos')]
    [string]
    $DemoName,

    # The path to the demo file.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='DemoFile')]
    [Alias('FullName', 'DemoFile', 'File', 'Source')]
    $DemoPath,

    # A Demo Script block.
    [Parameter(Mandatory,ValueFromPipeline,ParameterSetName='DemoScript')]
    [scriptblock]
    $DemoScript,

    # The name of the chapter
    [string]
    $Chapter,

    # The current step (within -Chapter)
    [ValidateRange(1,10000)]
    [int]
    $Step,

    # The typing style.  Can be letters, words, or none.
    [ValidateSet('Letters','Words','None')]
    [string]
    $TypeStyle = 'Letters',

    # If this is an integer less than 10000, it will be considered 'words per minute'
    # Otherwise, this will be the timespan to wait between words / letters being displayed.
    [timespan]
    $TypeSpeed,

    # If set, will make the demo noniteractive.
    [switch]
    $NonInteractive
    )

    process {
        $demoFile =
            if ($DemoPath) {
                Get-Demo -DemoPath $DemoPath
            }
            elseif ($DemoScript) {
                Get-Demo -DemoScript $DemoScript
            }
            elseif ($DemoName) {
                Get-Demo -DemoName $DemoName
            }
            else {
                $allDemos = Get-Demo
                $justNamedDemo = $allDemos |
                    Where-Object Name -eq 'Demo' |
                    Select-Object -First 1
                if (-not $justNamedDemo) {
                    $allDemos | Select-Object -First 1
                } else {
                    $justNamedDemo
                }
            }

        if (-not $demoFile) {
            Write-Error "No demo to show"
        }

        if ($chapter) {
            $demoFile | Add-Member CurrentChapter $Chapter -Force
        }
        if ($step) {
            $demoFile | Add-Member CurrentStep $step -Force
        }

        $demoFile | Add-Member TypeStyle $TypeStyle -Force
        if ($TypeStyle -eq 'Letters' -and -not $TypeSpeed) {
            $TypeSpeed = [timespan]::FromMilliseconds(1)
        }
        elseif ($TypeStyle -eq 'Words' -and -not $TypeSpeed) {
            $TypeSpeed = [timespan]::FromMilliseconds(30)
        }
        $demoFile | Add-Member TypeSpeed $TypeSpeed -Force
        if ($NonInteractive -or
            ($Host.Name -eq 'Default Host') -or
            $env:BUILD_ID -or
            $env:GITHUB_WORKSPACE
        ) {
            $demoFile | Add-Member Interactive $false -Force
        } else {
            $demoFile | Add-Member Interactive $true -Force
        }

        if ($NonInteractive) {
            $demoFile | Format-Custom | Out-String -Width 1mb
        } else {
            $demoFile | Format-Custom
        }        
    }
}
