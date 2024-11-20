do {
    # Prompt the user to enter the directory to search
    $searchPath = Read-Host "Enter the directory to search for 'poster' files (or press Enter to exit)"

    # Exit if the input is empty
    if ([string]::IsNullOrWhiteSpace($searchPath)) {
        Write-Host "Exiting the script. Goodbye!" -ForegroundColor Cyan
        break
    }

    # Initialize a counter for deleted files
    $totalDeleted = 0

    # Check if the entered directory exists
    if (Test-Path -Path $searchPath) {
        Write-Host "Searching for files named 'poster' with any extension in '$searchPath'..." -ForegroundColor Cyan

        # Use Get-ChildItem to find files named 'poster' with any extension
        $files = Get-ChildItem -Path $searchPath -Recurse -File -Include "poster.*"

        if ($files.Count -gt 0) {
            Write-Host "Found $($files.Count) file(s). Deleting them now..." -ForegroundColor Cyan

            $files | ForEach-Object {
                Write-Host "Deleting: $($_.FullName)" -ForegroundColor Yellow
                try {
                    # Attempt to delete the file
                    Remove-Item -Path $_.FullName -Force
                    $totalDeleted++ # Increment the counter
                    Write-Host "Deleted: $($_.FullName)" -ForegroundColor Green
                } catch {
                    # Handle errors
                    Write-Host "Failed to delete: $($_.FullName) - $_" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "No files named 'poster' were found in '$searchPath'." -ForegroundColor Yellow
        }
    } else {
        # Inform the user if the directory does not exist
        Write-Host "The directory '$searchPath' does not exist. Please check the path and try again." -ForegroundColor Yellow
    }

    # Display the total number of files deleted
    Write-Host "Total files deleted: $totalDeleted" -ForegroundColor Magenta
} while ($true)
