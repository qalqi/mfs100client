# MFS110 Diagnostic & Research Scripts

This directory contains research, diagnostic, and reverse-engineering scripts created during the analysis of the **Mantra MFS110 (L1 Renesas USB Scanner)**.

## File Manifest

| File | Description | Usage |
| :--- | :--- | :--- |
| live_mfs110_capture.ps1 | Hits local port 11100 /rd/capture, turns on red sensor, captures finger, parses Quality Score, Minutiae points, and X.509 certificate expiry. | powershell -ExecutionPolicy Bypass -File live_mfs110_capture.ps1 |
| 	est_mfs110_direct.ps1 | Direct native P/Invoke harness loading native DLLs into memory using LoadLibrary and function pointers. | Template for calling future MFS110.dll / MFS110SDK.dll. |
| 	est_mfs110_init.ps1 | Direct native initialization test probing device entry points. | Test native hardware detection without web service. |
| inspect_mfs110.ps1 | PE export scanner that inspects exported C functions and entry points inside MFS110_Core.dll. | powershell -ExecutionPolicy Bypass -File inspect_mfs110.ps1 |
| inspect_config_exe.ps1 | Deconstructs the 32-bit .NET assembly of ConfigMantraMFS110RDService.exe to inspect server and device handlers. | C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -File inspect_config_exe.ps1 |
| inspect_avdmutil.ps1 | Decompiles and inspects MantraMFS110AVDMUtil.exe types and methods. | Reverse-engineering tool. |
| check_servico.ps1 | Live API hook testing device serial registration against Mantra's central database (servico.mantratecapp.com). | Checks whether a serial is registered as an L1 device. |
| check_servico_expiry.ps1 | Probes status and payment endpoints on Mantra Servico. | Portal endpoint diagnostic. |

## Future Client SDK Integration

When Mantra provides the non-Aadhaar enterprise Client SDK (MFS110.dll / MFS110SDK.dll):
1. 	est_mfs110_direct.ps1 will be updated with the SDK function exports (MFS110Init, MFS110StartCapture, MFS110GetRawImage).
2. The byte buffer definitions in these scripts will be ported directly into the Tanmantra React Native Nitro C++ core for raw 500 DPI BMP thumbprint generation.
