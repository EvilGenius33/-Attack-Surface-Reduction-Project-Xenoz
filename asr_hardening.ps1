# ===========================================================
# Attack Surface Reduction Script 
# ===========================================================

Write-Output "`n[+] Démarrage du durcissement avec auditpol adapté - $(Get-Date)"

# [1] Services désactivés
$disableServices = @("RemoteRegistry", "Fax", "XblGameSave", "MapsBroker", "DiagTrack", "WMPNetworkSvc", "WerSvc", "RetailDemo")
foreach ($svc in $disableServices) {
 try {
 Get-Service -Name $svc -ErrorAction Stop | Set-Service -StartupType Disabled
 Stop-Service -Name $svc -ErrorAction Stop
 Write-Output "[-] Service désactivé : $svc"
 } catch {
 Write-Output "[!] Échec désactivation $svc : $_"
 }
}

# [2] Ports à risque bloqués
$portsToBlock = @(135, 137, 138, 139, 445, 3389, 5985, 5986, 5357, 1900)
foreach ($port in $portsToBlock) {
 try {
 New-NetFirewallRule -DisplayName "Block Port $port" -Direction Inbound -LocalPort $port -Protocol TCP -Action Block -Profile Any -ErrorAction Stop
 Write-Output "[-] Port bloqué : $port"
 } catch {
 Write-Output "[!] Blocage port $port échoué : $_"
 }
}

# [3] SRP AppData/Temp
try {
 New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" -Force | Out-Null
 Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" -Name "DefaultLevel" -Value 0x40000
 Write-Output "[-] SRP initialisé"
} catch {
 Write-Output "[!] Erreur SRP : $_"
}
$paths = @(
 "%AppData%\*.exe", "%LocalAppData%\*.exe", "%Temp%\*.exe",
 "%AppData%\..\Local\Temp\*.bat", "%AppData%\..\Local\Temp\*.vbs"
)
$i = 0
foreach ($p in $paths) {
 try {
 $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers\0\Paths\$i"
 New-Item -Path $regPath -Force | Out-Null
 Set-ItemProperty -Path $regPath -Name "ItemData" -Value $p
 Set-ItemProperty -Path $regPath -Name "SaferFlags" -Value 0
 Write-Output "[-] Blocage SRP : $p"
 $i++
 } catch {
 Write-Output "[!] Blocage SRP échoué : $p - $_"
 }
}

# [4] ASR Rules
$asrRules = @(
 "D4F940AB-401B-4EFC-AADC-AD5F3C50688A",
 "3B576869-A4EC-4529-8536-B80A7769E899",
 "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84",
 "26190899-1602-49e8-8b27-eb1d0a1ce869",
 "B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4"
)
foreach ($rule in $asrRules) {
 try {
 Add-MpPreference -AttackSurfaceReductionRules_Ids $rule -AttackSurfaceReductionRules_Actions Enabled -ErrorAction Stop
 Write-Output "[-] ASR activée : $rule"
 } catch {
 Write-Output "[!] ASR échec : $rule - $_"
 }
}
# [5] Logging PowerShell
try {
 New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force | Out-Null
 Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1
 New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription" -Force | Out-Null
 Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription" -Name "EnableTranscripting" -Value 1
 Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription" -Name "OutputDirectory" -Value "$env:SystemDrive\PSLogs"
 Write-Output "[-] Logging PowerShell activé"
} catch {
 Write-Output "[!] Logging PowerShell erreur - $_"
}

# [6] Audit avancé via CMD pour éviter 0x00000057
$auditCommands = @(
 'auditpol /set /subcategory:"Logon" /success:enable /failure:enable',
 'auditpol /set /subcategory:"Logoff" /success:enable /failure:enable',
 'auditpol /set /subcategory:"Special Logon" /success:enable /failure:enable',
 'auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable',
 'auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable',
 'auditpol /set /subcategory:"Other System Events" /success:enable /failure:enable'
)
foreach ($cmd in $auditCommands) {
 try {
 Start-Process cmd -ArgumentList "/c $cmd" -Wait -WindowStyle Hidden
 Write-Output "[-] AUDIT OK : $cmd"
 } catch {
 Write-Output "[!] AUDIT FAIL : $cmd - $_"
 }
}

# [7] SMBv1 désactivation
try {
 Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
 Write-Output "[-] SMBv1 désactivé"
} catch {
 Write-Output "[!] SMBv1 non modifiable : $_"
}

# [8] WScript désactivation corrigée
try {
 if (!(Test-Path "HKLM:\Software\Microsoft\Windows Script Host\Settings")) {
 New-Item -Path "HKLM:\Software\Microsoft\Windows Script Host\Settings" -Force | Out-Null
 }
 Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows Script Host\Settings" -Name "Enabled" -Value 0 -Type DWord
 Write-Output "[-] WScript désactivé"
} catch {
 Write-Output "[!] Désactivation WScript échouée : $_"
}

# [9] RDP désactivation
try {
 Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1
 Write-Output "[-] RDP désactivé"
} catch {
 Write-Output "[!] Désactivation RDP échouée : $_"
}

Write-Output "`n[+] Durcissement complet avec auditpol en fallback CMD terminé - $(Get-Date)"
