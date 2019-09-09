<#
.SYNOPSIS
    Copy files with credentials.
.DESCRIPTION
    A wrapper for Copy-Item, with credentials support
.EXAMPLE
    PS C:\> Copy-SWCItem -Path .\testfile.txt -Destination C:\
    This will copy the testfile.txt from the current director to the C drive
.EXAMPLE
    PS C:\> Copy-SWCItem -Path .\testfile.txt -Destination \\server1\c$ -Credential (Get-Credential)
    This will copy the testfile.txt from the current director to C drive on the server1 where you need another set of credentials to get write access
#>
function Copy-SWCItem {
    [CmdletBinding()]
    Param
    (
        #Help
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,
        #Help
        [Parameter(Mandatory = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        #Help
        [PSCredential]$Credential,
        #Help
        [Switch]$Force = $false,
        #Help
        [Switch]$Recurse = $false

    )

    Begin {
        $PSDriveName = (([guid]::NewGuid()) -split '-')[0]

    }
    Process {


        try {
            Write-Verbose 'Creating a new PSDrive with the provide credentials'
            New-PSDrive -Name $PSDriveName -PSProvider FileSystem -Root $Destination -Credential $Credential -ErrorAction Stop | Out-Null
            Write-Verbose "Copying the file/folder $($Path -split '\\' | Select-Object -last 1)"
            Copy-Item -Path $Path -Destination "$($PSDriveName):" -Force:$Force -Recurse:$Recurse -ErrorAction Stop
        }

        catch [System.UnauthorizedAccessException] {
            if (!(isAdmin)) {
                Write-Verbose 'In [System.UnauthorizedAccessException] catch block. isAdmin -eq False'
                Write-Error -Message 'Run the cmdlet in administrator mode'
            }
            elseif (isAdmin -and $Credential -eq $null) {
                Write-Verbose 'In [System.UnauthorizedAccessException] catch block. isAdmin -eq True, no credentials is provied'
                Write-Error -Message 'Use the -Credential parameter with elevated credentials and try again'
            }
        }
        catch {
            Write-Error $Error[0]
        }
    }
    End {
        Write-Verbose 'Removes the PSDrive again'
        Remove-PSDrive -Name $PSDriveName -ErrorAction SilentlyContinue
    }
}
