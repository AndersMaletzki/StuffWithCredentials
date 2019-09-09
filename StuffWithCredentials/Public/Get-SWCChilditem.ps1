<#
.SYNOPSIS
    Gets childitems with credentials.
.DESCRIPTION
    A wrapper for Get-ChildItem, with credentials support
.EXAMPLE
    PS C:\> Get-SWCChildItem -Path c:\
    This will get all the files in the root of the c drive.
.EXAMPLE
    PS C:\> Get-SWCChildItem -Path \\server1\c$ -Credential (Get-Credential)
    This will get the child items on the server1's c drive, it will use the provided credentials.
#>
function Get-SWCChildItem {
    [CmdletBinding()]
    Param
    (
        #Help
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,
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
            New-PSDrive -Name $PSDriveName -PSProvider FileSystem -Root $Path -Credential $Credential -ErrorAction Stop | Out-Null
            Write-Verbose "Copying the file/folder $($Path -split '\\' | Select-Object -last 1)"
            Get-ChildItem -Path "$($PSDriveName):"  -Force:$Force -Recurse:$Recurse -ErrorAction Stop
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
