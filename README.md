# 🛡️ Attack Surface Reduction – Project Xenoz

PowerShell script to aggressively harden Windows systems using Microsoft-native controls  
while maintaining compatibility with enterprise systems and fallback audit logging.

## ✅ What it does

- 🚫 Disables legacy or risky services (RemoteRegistry, DiagTrack, SMBv1…)
- 🔒 Blocks vulnerable ports (RDP, SMB, RPC, LLMNR)
- 🧱 Enforces Software Restriction Policy (SRP) on AppData, Temp, and Local folders
- ⚔️ Enables core Attack Surface Reduction (ASR) rules:
  - Office macro abuse
  - Executables from USB/removable media
  - Credential stealing via LSASS access
- 📜 Enables full PowerShell script block and transcription logging
- 📈 Configures audit policies manually to avoid Event Log error 0x00000057
- 🔧 Disables WScript engine and RDP access
- 📂 Fully logs actions during execution

## 📂 File structure

- `asr_hardening.ps1` – main script
- `rollback/restore_asr_defaults.ps1` – (optional) to revert changes
- `docs/asr_rules_reference.md` – GUID references for all applied ASR rules

## 🚀 Usage

Run in **PowerShell as Administrator**:
```powershell
powershell -ExecutionPolicy Bypass -File .\asr_hardening.ps1
