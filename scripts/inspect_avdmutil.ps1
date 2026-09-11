$asm = [System.Reflection.Assembly]::LoadFrom("C:\Program Files\Mantra\RDService\L1Device\MantraMFS110AVDMUtil.exe")
$t = $asm.GetType("MantraAVDMUtil.AvdmUtil")
if ($t) {
    [Console]::WriteLine("Found MantraAVDMUtil.AvdmUtil!")
    foreach ($f in $t.GetFields([System.Reflection.BindingFlags]'Public,NonPublic,Instance,Static')) {
        [Console]::WriteLine("  Field: " + $f.FieldType.Name + " " + $f.Name)
    }
    foreach ($m in $t.GetMethods([System.Reflection.BindingFlags]'Public,NonPublic,Instance,Static')) {
        if ($m.DeclaringType -eq $t) {
            [Console]::WriteLine("  Method: " + $m.ReturnType.Name + " " + $m.Name + "(" + [string]::Join(", ", ($m.GetParameters() | ForEach-Object { $_.ParameterType.Name + " " + $_.Name })) + ")")
        }
    }
} else {
    [Console]::WriteLine("Type not found")
}
