function Get-SessionInfo {
    param (
        [IntPtr]$ServerHandle,
        [int]$SessionId,
        [KMaks.TerminalServices+WTS_INFO_CLASS] $InfoClass
    )

    $Buffer = [IntPtr]::Zero
    $BytesReturned = 0

    if ([KMaks.TerminalServices]::WTSQuerySessionInformation($ServerHandle, $SessionId, $InfoClass, [ref]$Buffer, [ref]$BytesReturned)) {
        $Info = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($Buffer)
        [KMaks.TerminalServices]::WTSFreeMemory($Buffer)
        return $Info
    }
    else {
        return $null
    }
}