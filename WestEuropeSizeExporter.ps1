Get-AzVMSize -Location "WestEurope" 
| Select-Object -Property @{name='VM Size Name';expression={[string]$_.Name}}, 
@{name='Cores (Count)';expression={[int]$_.NumberOfCores}}, 
@{name='Memory (GB)';expression={[int]$_.MemoryInMB * 1mb / 1gb}}, 
@{name='Temp Disk (GB)';expression={[int]$_.ResourceDiskSizeInMB * 1mb / 1gb}}, 
@{name='Max Data Disk (Count)';expression={[int]$_.MaxDataDiskCount}}, 
@{name='OS Disk Size (GB)';expression={[int]$_.OSDiskSizeInMB * 1mb / 1gb}} 
| Sort-Object -Property 'Cores (Count)','Memory (GB)','VM Size Name' 
| Export-Csv "WestEurope_AzureVMSizes.csv" -NoTypeInformation
