$xmlPayload = @"
<PidOptions ver="1.0">
  <Opts fCount="1" fType="2" iCount="0" pCount="0" format="0" pidVer="2.0" timeout="20000" env="P" />
</PidOptions>
"@

[Console]::WriteLine("[*] Sending CAPTURE to MFS110 on http://127.0.0.1:11100/rd/capture...")
[Console]::WriteLine("[*] SENSOR RED LIGHT IS ON! PLACE YOUR FINGER NOW...")

$req = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:11100/rd/capture")
$req.Method = "CAPTURE"
$req.ContentType = "text/xml"
$req.Timeout = 25000

$bytes = [System.Text.Encoding]::UTF8.GetBytes($xmlPayload)
$req.ContentLength = $bytes.Length
$os = $req.GetRequestStream()
$os.Write($bytes, 0, $bytes.Length)
$os.Close()

try {
    $resp = $req.GetResponse()
    $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
    $resultXml = $sr.ReadToEnd()
    $sr.Close()
    $resp.Close()

    [System.IO.File]::WriteAllText("C:\Users\X2\.gemini\antigravity-ide\scratch\mfs110_capture_result.xml", $resultXml)

    [xml]$doc = $resultXml
    $respNode = $doc.SelectSingleNode("//Resp")
    $errCode = $respNode.GetAttribute("errCode")
    $errInfo = $respNode.GetAttribute("errInfo")
    $fCount = $respNode.GetAttribute("fCount")
    $qScore = $respNode.GetAttribute("qScore")

    [Console]::WriteLine("[+] Response errCode: " + $errCode + " (" + $errInfo + ")")
    [Console]::WriteLine("[+] Finger Count: " + $fCount + " | Quality Score: " + $qScore)

    $dataNode = $doc.SelectSingleNode("//Data")
    if ($dataNode) {
        $type = $dataNode.GetAttribute("type")
        $val = $dataNode.InnerText
        [Console]::WriteLine("[+] Captured Data Block Type: " + $type + " | Length: " + $val.Length + " characters")
        [System.IO.File]::WriteAllText("C:\Users\X2\.gemini\antigravity-ide\scratch\mfs110_data_block.txt", $val)
    }

    [Console]::WriteLine("[OK] Full result saved to mfs110_capture_result.xml")
} catch {
    [Console]::WriteLine("[-] Capture error: " + $_.Exception.Message)
}
