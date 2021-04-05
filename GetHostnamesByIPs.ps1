$IPAddressReportPath = "C:\IPAdresses.csv"; $HostnameReportPath = "C:\IPAdressesReport.csv"; $HostnameReport = @()

$Adresses = Import-Csv $IPAddressReportPath

foreach($Adress in $Adresses)
{
    $HostnameInfo = New-Object -TypeName psobject
    Add-Member -MemberType NoteProperty -Name "IPAddress" -Value $Adress.'IP Adresses' -InputObject $HostnameInfo

    try {
        $Hostname = (nslookup $Adress.'IP Adresses' | Select-String "Name:    ").ToString().split(": ")[5]
        Add-Member -MemberType NoteProperty -Name "Hostname" -Value $Hostname -InputObject $HostnameInfo
    }
    catch {
        Add-Member -MemberType NoteProperty -Name "Hostname" -Value "Not-Found" -InputObject $HostnameInfo
    }
    $HostnameReport = $HostnameReport + $HostnameInfo
}

$HostnameReport | Export-Csv -Path $HostnameReportPath -NoTypeInformation
