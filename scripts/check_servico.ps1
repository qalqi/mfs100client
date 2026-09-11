$html = curl.exe -s --connect-timeout 8 https://servico.mantratecapp.com/
$m = [regex]::Matches($html, 'href=["'']([^"'']+\.aspx[^"'']*)["'']')
$urls = @()
foreach ($match in $m) {
    $urls += $match.Groups[1].Value
}
$urls | Select-Object -Unique
