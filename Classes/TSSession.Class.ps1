class TSSession {
    $TerminalServer
    $SessionID
    $StationName
    $State
    $InitialProgram
    $ApplicationName
    $WorkingDirectory
    $OEMId
    $UserName
    $WinStationName
    $DomainName
    $ConnectState
    $ClientBuildNumber
    $ClientName
    $ClientDirectory
    $ClientProductId
    $ClientHardwareId
    $ClientAddress
    $ClientDisplay
    $ClientProtocolType
    $IdleTime
    $LogonTime
    $IncomingBytes
    $OutgoingBytes
    $IncomingFrames
    $OutgoingFrames
    $ClientInfo
    $SessionInfo
    $SessionInfoEx
    $ConfigInfo
    $ValidationInfo
    $SessionAddressV4
    $IsRemoteSession
    $SessionActivityId

    TSSession () {}
    [TSSession[]] static GetTSSession ([string] $ComputerName) {
        $ServerHandle = [KMaks.TerminalServices]::WTSOpenServer($ComputerName)

        if ($ServerHandle -ne [IntPtr]::Zero) {
            $PSessionInfo = [IntPtr]::Zero
            $SessionCount = 0
            
            if ([KMaks.TerminalServices]::WTSEnumerateSessions($ServerHandle, 0, 1, [ref]$PSessionInfo, [ref]$SessionCount)) {
                $DataSize = [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type][KMaks.TerminalServices+WTS_SESSION_INFO])
                $CurrentSession = $PSessionInfo
                
                $TSSessions = [System.Collections.Generic.List[TSSession]]::new()
                for ($i = 0; $i -lt $SessionCount; $i++) {
                    $CurrentSessionInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($CurrentSession, [System.Type] [KMaks.TerminalServices+WTS_SESSION_INFO])
                    
                    $TSSession = [TSSession]::new()
                    $TSSession.TerminalServer = $ComputerName
                    $TSSession.SessionID = $CurrentSessionInfo.SessionId
                    $TSSession.StationName = $CurrentSessionInfo.pWinStationName
                    $TSSession.State = $CurrentSessionInfo.State
                    foreach ($InfoClass in [System.Enum]::GetNames([KMaks.TerminalServices+WTS_INFO_CLASS])) {
                        if ($InfoClass -eq 'SessionID') {
                            continue
                        }
                        $TSSession.$InfoClass = $TSSession.GetTSSessionProperty($ServerHandle, $CurrentSessionInfo.SessionId, $InfoClass)
                    }
                    $TSSessions.Add($TSSession)
                    $currentSession = [IntPtr]::Add($CurrentSession, $DataSize)
                }

                [KMaks.TerminalServices]::WTSFreeMemory($PSessionInfo)

                return $TSSessions
            }
            else {
                throw "Failed to enumerate sessions."
            }

            [KMaks.TerminalServices]::WTSCloseServer($ServerHandle)
        }
        else {
            throw "Failed to open remote server."
        }
    }
    [object] GetTSSessionProperty ([IntPtr]$ServerHandle, [int]$SessionId, [KMaks.TerminalServices+WTS_INFO_CLASS] $InfoClass) {
        $Buffer = [IntPtr]::Zero
        $BytesReturned = 0
        $Info = $null
        if ([KMaks.TerminalServices]::WTSQuerySessionInformation($ServerHandle, $SessionId, $InfoClass, [ref]$Buffer, [ref]$BytesReturned)) {
            switch ($InfoClass) {
                [KMaks.TerminalServices+WTS_INFO_CLASS]::ClientBuildNumber {
                        $Info = [System.Runtime.InteropServices.Marshal]::ReadInt32($Buffer)
                }
                [KMaks.TerminalServices+WTS_INFO_CLASS]::ClientDisplay {
                        $Info = [System.Runtime.InteropServices.Marshal]::PtrtoStructure($Buffer, [System.Type] [KMaks.terminalServices+WTS_CLIENT_DISPLAY])
                }
                [KMaks.TerminalServices+WTS_INFO_CLASS]::LogonTime {
                        $LongLogonTime = [System.Runtime.InteropServices.Marshal]::ReadInt64($Buffer)
                        $Info = [datetime]::FromFileTime($LongLogonTime)
                }
                default {
                        $Info = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($Buffer)
                }
            }
            [KMaks.TerminalServices]::WTSFreeMemory($Buffer)
        }
        return $Info
        # if ([KMaks.TerminalServices]::WTSQuerySessionInformation($ServerHandle, $SessionId, $InfoClass, [ref]$Buffer, [ref]$BytesReturned)) {
        #     $Info = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($Buffer)
        #     [KMaks.TerminalServices]::WTSFreeMemory($Buffer)
        #     return $Info
        # }
        # else {
        #     return $null
        # }
    }
}