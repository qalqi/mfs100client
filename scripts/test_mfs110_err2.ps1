$env:PATH = "C:\Program Files\Mantra\RDService\L1Device;" + $env:PATH

$signature = @"
using System;
using System.Runtime.InteropServices;

public class MFS110Direct {
    [DllImport("C:\\Program Files\\Mantra\\RDService\\L1Device\\MFS110_Core.dll", CallingConvention = CallingConvention.Cdecl, CharSet = CharSet.Ansi)]
    public static extern IntPtr MIDFinger_L1_GetErrDescription(int errCode);
}
"@

Add-Type -TypeDefinition $signature -PassThru | Out-Null

$ptr = [MFS110Direct]::MIDFinger_L1_GetErrDescription(-2001)
$str = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ptr)
[Console]::WriteLine("Error -2001: " + $str)

$ptr2 = [MFS110Direct]::MIDFinger_L1_GetErrDescription(-2044)
$str2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ptr2)
[Console]::WriteLine("Error -2044: " + $str2)
