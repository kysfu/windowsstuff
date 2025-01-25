<#
.SYNOPSIS
    Determine network speed in MBps
.DESCRIPTION
    This script downloads a test file from a specified URL, keeps it in a temporary location for testing,
    and allows testing against multiple SMB shares in one session.
.INPUTS
    User-specified SMB share paths.
.OUTPUTS
    PSCustomObject
        Server          Name of Server
        TimeStamp       Time when script was run
        WriteTime       TimeSpan object of how long the write test took
        WriteMBps       MBps of the write test
        ReadTime        TimeSpan object of how long the read test took
        ReadMBps        MBps of the read test
.EXAMPLE
    Run the script, then follow the prompts to enter SMB share paths.
#>
#requires -Version 3.0

[CmdletBinding()]
Param ()

Begin {
    Write-Host "Welcome to the Network Speed Test Script!" -ForegroundColor Cyan

    # Set file download URL
    $TestFileUrl = "https://ash-speed.hetzner.com/1GB.bin"
    $TempFilePath = "$env:Temp\1GB.bin"

    # Download the file with progress
    Write-Host "Downloading test file from $TestFileUrl..." -ForegroundColor Yellow
    Try {
        Invoke-WebRequest -Uri $TestFileUrl -OutFile $TempFilePath -UseBasicParsing -Verbose -ErrorAction Stop
        Write-Host "Test file downloaded successfully to $TempFilePath." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to download the test file: $($_.Exception.Message)" -ForegroundColor Red
        Exit
    }
}

Process {
    # Loop to continue prompting for SMB share paths until the script is manually stopped
    while ($true) {
        # Prompt for SMB share path
        do {
            $RemotePath = Read-Host "Please enter the full UNC path of the SMB share (e.g., \\server\share)"
            if (-not ($RemotePath -match "^\\\\[a-zA-Z0-9_.-]+\\[a-zA-Z0-9_.-]+(\\.*)?$")) {
                Write-Host "The specified SMB share path is not in a valid UNC format. Please try again." -ForegroundColor Red
            }
        } while (-not ($RemotePath -match "^\\\\[a-zA-Z0-9_.-]+\\[a-zA-Z0-9_.-]+(\\.*)?$"))

        Write-Verbose "Selected Remote Path: $RemotePath"
        Write-Host "Initializing speed test for $RemotePath..." -ForegroundColor Green

        $RunTime = Get-Date
        $Target = "$RemotePath\SpeedTest"
        $TotalWriteSeconds = 0
        $TotalReadSeconds = 0
        $TotalSize = (Get-Item $TempFilePath).Length

        # Write test
        Try {
            if (-not (Test-Path $Target)) {
                New-Item -Path $Target -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }

            Write-Host "Starting write test..." -ForegroundColor Yellow
            $WriteTest = Measure-Command {
                Copy-Item $TempFilePath -Destination $Target -ErrorAction Stop
            }
            $TotalWriteSeconds = $WriteTest.TotalSeconds
        } Catch {
            Write-Host "Error during write test: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Read test
        Try {
            Write-Host "Starting read test..." -ForegroundColor Yellow
            $ReadTest = Measure-Command {
                Copy-Item "$Target\$(Split-Path $TempFilePath -Leaf)" -Destination $env:Temp -ErrorAction Stop
            }
            $TotalReadSeconds = $ReadTest.TotalSeconds
        } Catch {
            Write-Host "Error during read test: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Calculate MBps
        $WriteMBps = [Math]::Round(($TotalSize / $TotalWriteSeconds) / 1048576, 2)
        $ReadMBps = [Math]::Round(($TotalSize / $TotalReadSeconds) / 1048576, 2)

        # Output the results
        [PSCustomObject]@{
            TimeStamp = $RunTime
            Server = $RemotePath
            WriteTime = [TimeSpan]::FromSeconds($TotalWriteSeconds)
            WriteMBps = $WriteMBps
            ReadTime = [TimeSpan]::FromSeconds($TotalReadSeconds)
            ReadMBps = $ReadMBps
        } | Format-Table -AutoSize

        # Delete the test file from the SMB share after the test is complete
        Try {
            $TestFileOnShare = "$Target\$(Split-Path $TempFilePath -Leaf)"
            if (Test-Path $TestFileOnShare) {
                Remove-Item $TestFileOnShare -ErrorAction Stop
                Write-Host "Test file deleted from the SMB share." -ForegroundColor Green
            } else {
                Write-Host "Test file not found on the SMB share." -ForegroundColor Yellow
            }
        } Catch {
            Write-Host "Failed to delete test file from the SMB share: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Delete the SpeedTest folder from the SMB share after the file deletion
        Try {
            if (Test-Path $Target) {
                Remove-Item $Target -Recurse -Force -ErrorAction Stop
                Write-Host "SpeedTest folder deleted from the SMB share." -ForegroundColor Green
            }
        } Catch {
            Write-Host "Failed to delete SpeedTest folder from the SMB share: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

End {
    Write-Host "Speed test completed!" -ForegroundColor Green
    Write-Host "Cleaning up local test file..." -ForegroundColor Yellow
    Try {
        if (Test-Path $TempFilePath) {
            Remove-Item $TempFilePath -ErrorAction Stop
            Write-Host "Temporary file removed successfully." -ForegroundColor Green
        } else {
            Write-Host "Temporary file was already removed." -ForegroundColor Yellow
        }
    } Catch {
        Write-Host "Failed to remove temporary file: $($_.Exception.Message)" -ForegroundColor Red
    }
}
