$c = curl.exe -s --connect-timeout 8 https://servico.mantratecapp.com/Payment/CustomerPayment.aspx
$c -split "`n" | Select-String -Pattern "(RD Service|Warranty|Amount|Validity|Subscription|Year|Option)" -Context 1,1 | Select-Object -First 30
