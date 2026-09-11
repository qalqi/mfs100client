$dlls = @(
    "C:\Program Files\Mantra\RDService\L1Device\mantra.mfs110.device.reg.aadhaar.dll",
    "C:\Program Files\Mantra\RDService\L1Device\MantraMFS110AVDMUtil.exe",
    "C:\Program Files\Mantra\RDService\L1Device\MantraMFS110AVDMHost.exe"
)

foreach ($path in $dlls) {
    try {
        $asm = [System.Reflection.Assembly]::LoadFrom($path)
        [Console]::WriteLine("=== Assembly: " + $path + " ===")
        foreach ($t in $asm.GetTypes()) {
            [Console]::WriteLine("Type: " + $t.FullName)
            $methods = $t.GetMethods([System.Reflection.BindingFlags]'Public,NonPublic,Static,Instance')
            foreach ($m in $methods) {
                if ($m.Name -match 'Capture' -or $m.Name -match 'Image' -or $m.Name -match 'Finger' -or $m.Name -match 'Raw' -or $m.Name -match 'Bmp' -or $m.Name -match 'MID') {
                    [Console]::WriteLine("    Method: " + $m.ToString())
                }
            }
        }
    } catch {
        [Console]::WriteLine("Failed to load: " + $path + " -> " + $_.Exception.Message)
    }
}
