$env:PATH = "C:\Program Files\Mantra\RDService\L1Device;" + $env:PATH

$signature = @"
using System;
using System.Runtime.InteropServices;

public class MFS110Direct {
    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern IntPtr MIDFinger_L1_GetErrDescription(int errCode);

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_InitDevice(string productName);

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_IsDeviceConnected(string productName);

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_UninitDevice();
}
"@

Add-Type -TypeDefinition $signature -PassThru | Out-Null

$conn = [MFS110Direct]::MIDFinger_L1_IsDeviceConnected("MFS110")
$descConn = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi([MFS110Direct]::MIDFinger_L1_GetErrDescription($conn))
[Console]::WriteLine("MIDFinger_L1_IsDeviceConnected('MFS110'): " + $conn + " -> " + $descConn)

$init = [MFS110Direct]::MIDFinger_L1_InitDevice("MFS110")
$descInit = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi([MFS110Direct]::MIDFinger_L1_GetErrDescription($init))
[Console]::WriteLine("MIDFinger_L1_InitDevice('MFS110'): " + $init + " -> " + $descInit)
