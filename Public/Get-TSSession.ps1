function Get-TSSession {
    param (
        [Parameter(Position=0)]
        [string[]]
        $ComputerName = 'localhost'
    )

    begin {}
    process {
        foreach ($Computer in $ComputerName) {
            [TSSession]::GetTSSession($Computer)
        }
    }
    end {}
}