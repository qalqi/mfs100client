$env:PATH = "C:\Program Files\Mantra\RDService\L1Device;" + $env:PATH

$signature = @"

using System;
using System.Runtime.InteropServices;

public class MFS110Direct {
    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_IsDeviceConnected();

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_InitDevice();

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_UninitDevice();

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_GetVersion();
}
"@

Add-Type -TypeDefinition $signature -PassThru | Out-Null

$conn = [MFS110Direct]::MIDFinger_L1_IsDeviceConnected()
[Console]::WriteLine("MIDFinger_L1_IsDeviceConnected: " + $conn)

$ver = [MFS110Direct]::MIDFinger_L1_GetVersion()
[Console]::WriteLine("MIDFinger_L1_GetVersion: " + $ver)

$init = [MFS110Direct]::MIDFinger_L1_InitDevice()
[Console]::WriteLine("MIDFinger_L1_InitDevice: " + $init)

if ($init -eq 0) {
    [Console]::WriteLine("Init SUCCESS! MFS110_Core.dll is controlling the hardware directly!")
    [MFS110Direct]::MIDFinger_L1_UninitDevice()
}
