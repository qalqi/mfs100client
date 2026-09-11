$asm = [System.Reflection.Assembly]::LoadFrom("C:\Program Files\Mantra\RDService\L1Device\ConfigMantraMFS110RDService.exe")
$type = $asm.GetType("Config_Mantra_RD_Service.ServerInterfaceHandler")
$type.GetMethods([System.Reflection.BindingFlags]'Public,NonPublic,Static,Instance') | ForEach-Object {
    $_.ToString()
}
