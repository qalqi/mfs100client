$env:PATH = "C:\Program Files\Mantra\RDService\L1Device;" + $env:PATH

$signature = @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class MFS110Direct {
    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_IsDeviceConnected();

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_InitDevice();

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_UninitDevice();

    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern int MIDFinger_L1_GetErrDescription(int errCode, StringBuilder desc);
}
"@

Add-Type -TypeDefinition $signature -PassThru | Out-Null

$sb = New-Object System.Text.StringBuilder 256
$ret = [MFS110Direct]::MIDFinger_L1_GetErrDescription(-2001, $sb)
[Console]::WriteLine("Error -2001 description: " + $sb.ToString())
