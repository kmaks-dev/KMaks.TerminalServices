# Define the necessary P/Invoke signatures
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WTS
{
    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern IntPtr WTSOpenServer(string pServerName);

    [DllImport("wtsapi32.dll")]
    public static extern void WTSCloseServer(IntPtr hServer);

    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern bool WTSEnumerateSessions(
        IntPtr hServer,
        int Reserved,
        int Version,
        out IntPtr ppSessionInfo,
        out int pCount);

    [DllImport("wtsapi32.dll")]
    public static extern void WTSFreeMemory(IntPtr pointer);

    [StructLayout(LayoutKind.Sequential)]
    public struct WTS_SESSION_INFO
    {
        public int SessionId;
        [MarshalAs(UnmanagedType.LPStr)]
        public string pWinStationName;
        public WTS_CONNECTSTATE_CLASS State;
    }

    public enum WTS_CONNECTSTATE_CLASS
    {
        WTSActive,
        WTSConnected,
        WTSConnectQuery,
        WTSShadow,
        WTSDisconnected,
        WTSIdle,
        WTSListen,
        WTSReset,
        WTSDown,
        WTSInit
    }
}
"@

# Function to enumerate sessions on a remote server
function Get-RemoteSessions {
    param (
        [string]$RemoteServerName
    )

    $serverHandle = [WTS]::WTSOpenServer($RemoteServerName)

    if ($serverHandle -ne [IntPtr]::Zero) {
        $pSessionInfo = [IntPtr]::Zero
        $sessionCount = 0

        if ([WTS]::WTSEnumerateSessions($serverHandle, 0, 1, [ref]$pSessionInfo, [ref]$sessionCount)) {
            $dataSize = [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type][WTS+WTS_SESSION_INFO])
            $currentSession = $pSessionInfo

            for ($i = 0; $i -lt $sessionCount; $i++) {
                $sessionInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($currentSession, [System.Type][WTS+WTS_SESSION_INFO])
                Write-Output "Session ID: $($sessionInfo.SessionId), Station Name: $($sessionInfo.pWinStationName), State: $($sessionInfo.State)"
                $currentSession = [IntPtr]::Add($currentSession, $dataSize)
            }

            [WTS]::WTSFreeMemory($pSessionInfo)
        } else {
            Write-Output "Failed to enumerate sessions."
        }

        [WTS]::WTSCloseServer($serverHandle)
    } else {
        Write-Output "Failed to open remote server."
    }
}
