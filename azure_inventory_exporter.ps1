$vmlist=@{}; $VmReport = @();

$VmReportlocation = "C:\Reports\Azure\Azure_Virtual_Machine_Inventory.csv"

#Virtual Machine Inventory Tag Arrays
$SorumluArray = @("Owner","owner","Sorumlu","Sahip")
$OrtamArray = @("Environment","Environment ","environment","Env","env","Ortam","Circle")
$FirmaArray= @('Company','Firma','Firm','Kurulus')
$KritiklikArray = @("Criticality","Kritiklik","Criticality ","Kritiklik ")
$DRArray = @('DR','Disaster Recovery','Cokme Kurtarma')
$SQLArray = @('SQL Owner','SQLOwner','SQL', 'SQL Sorumlu','Sqlowner','sqlowner','SQLOwner ')
$HizmetArray = @('Service','Hizmet','Servis','Service Name')
$RolArray = @('Role','Rol','Role Name','RoleName','Roler')
$SAPArray =@('SAP','SAP ID','sapid','Sapid','SAPId','SAPID')
$UygulamaArray = @('Application','application','App','app','Application Name','application name','Uygulama','uygulama',
                    'Application ','application ','App ','app ','Application Name ','application name ','Uygulama ','uygulama ')

$subscriptions = Get-AzSubscription | Where-Object {$_.State -eq "Enabled"} | Sort-Object -Property Name #Get all active subscriptions

ForEach($subscription in $subscriptions)
{
    $Null=Set-AzContext -SubscriptionId $subscription #Change current subscription and put a null output
    $resourceGroups = Get-AzResourceGroup | Sort-Object -Property ResourceGroupName #Get resource groups for current subscription

    ForEach($resourceGroup in $resourceGroups)
    {     
        $nics = Get-AzNetworkInterface -resourceGroupName $resourceGroup.resourceGroupName | Where-Object {$_.VirtualMachine -ne $null} | Sort-Object -Property VirtualMachine#Get Network Interface which are being used by a vm
        
        $vms = Get-AzVm -resourceGroupName $resourceGroup.resourceGroupName | Sort-Object -Property Name #Get vms for current resource group

        ForEach($vm in $vms)
        {
            $vmlist[$vm.Name] = @{} #Creates arrays for vms and their properties
            $vmlist[$vm.Name]["tags"] = @{}
            $vmlist[$vm.Name]["nic"] = @{}
            $vmlist[$vm.Name]["status"] = @{}

            $vmlist[$vm.Name]["subscription"] = $subscription.Name
            $vmlist[$vm.Name]["resourcegroup"] = $resourceGroup.ResourceGroupName

            $vmlist[$vm.Name]["status"] = Get-AzVM -ResourceGroupName ($resourceGroup.ResourceGroupName) -Name ($vm.Name) -Status #Get and put status of vms

            $vmsizelist = Get-AzVMSize -VMName $vm.Name -ResourceGroupName $resourceGroup.resourceGroupName
            $sizeinfo = $vmsizelist | Where-Object {$_.Name -eq $vm.hardwareprofile.vmsize}

            #VM Tag Organizer
            $keys = $vm.Tags.Keys; $values = $vm.Tags.Values #Gets tags and their values
            $keylist=@{}; $valuelist=@{} #Creates arrays for tags and their values
            $i=0; $j=0; #Creates start indexes for created array above

            ForEach($key in $keys){$keylist[$i]=$key; $i++} #Gets tag names in to an array

            ForEach($value in $values){$valuelist[$j]=$value; $j++} #Gets tag values in to an array
            
            For($i=0; $i -ne $keylist.count; $i++)#Put tag names and values into key property of vm arrays
            {
                if($keylist[$i] -in $SorumluArray){$key_name="Sahip"}
                elseif($keylist[$i] -in $OrtamArray){$key_name="Ortam"}
                elseif($keylist[$i] -in $FirmaArray){$key_name="Firma"}
                elseif($keylist[$i] -in $DRArray){$key_name="DR"}
                elseif($keylist[$i] -in $SQLArray){$key_name="SQL"}
                elseif($keylist[$i] -in $HizmetArray){$key_name="Hizmet"}
                elseif($keylist[$i] -in $RolArray){$key_name="Rol"}
                elseif($keylist[$i] -in $SAPArray){$key_name="SAP"}
                elseif($keylist[$i] -in $UygulamaArray){$key_name="Uygulama"}
                elseif($keylist[$i] -in $KritiklikArray){$key_name="Kritiklik"}
                else {$key_name=$keylist[$i]}
                $vmlist[$vm.Name]["tags"][$key_name] =$valuelist[$i]
            }
            
            foreach ($nic in $nics) #Put Network Interface properties of the vm into its nic properties array
            {
                if($nic.VirtualMachine.id -eq $vm.Id){$vmlist[$vm.Name]["nic"] = $nic; break}
            }

            $VmInfo = "" | Select-Object VM, Powerstate, VMSize, vCPU, RAM, PrivateIpAddress, Subnet, DR, Firma, Hizmet, Kritiklik, Ortam, Rol, SAP, Sorumlu,
            SQL, Uygulama, Region, Subscription, ResourceGroup, OS, OsType, OSVersion, OSDiskProvisioningDate

            $VmInfo.VM = $vm.Name
            $VmInfo.Powerstate = $vmlist[$vm.Name]["status"].Statuses[1].DisplayStatus
            $VmInfo.vCPU = $sizeinfo.NumberOfCores
            $VmInfo.RAM = $sizeinfo.MemoryInMB
            $VmInfo.PrivateIpAddress = $vmlist.($vm.Name).nic.IpConfigurations.PrivateIpAddress
            $VmInfo.Subnet = $vmlist.($vm.Name).nic.IpConfigurations.subnet.Id.Split("/")[-1]
            $VmInfo.DR=$vmlist.($vm.Name).tags.DR
            #$VmInfo.Firma=$vmlist.($vm.Name).tags.Firma
            $VmInfo.Firma=$vmlist.($vm.Name).subscription
            $VmInfo.Hizmet=$vmlist.($vm.Name).tags.Hizmet  
            $VmInfo.Kritiklik=$vmlist.($vm.Name).tags.Kritiklik
            $VmInfo.Ortam=$vmlist.($vm.Name).tags.Ortam
            $VmInfo.Rol=$vmlist.($vm.Name).tags.Rol
            $VmInfo.SAP=$vmlist.($vm.Name).tags.SAP
            $VmInfo.Sorumlu=$vmlist.($vm.Name).tags.Sahip
            $VmInfo.SQL=$vmlist.($vm.Name).tags.SQL
            $VmInfo.Uygulama=$vmlist.($vm.Name).tags.Uygulama
            $VmInfo.Region = $vm.Location
            $VmInfo.Subscription =$vmlist.($vm.Name).subscription
            $VmInfo.ResourceGroup = $vmlist.($vm.Name).resourcegroup
            $VmInfo.OS = $vmlist[$vm.Name]["status"].OsName
            $VmInfo.OsType= $vm.StorageProfile.OsDisk.OsType
            $VmInfo.OSVersion = $vmlist[$vm.Name]["status"].OsVersion
            $VmInfo.OSDiskProvisioningDate = $vmlist[$vm.Name]["status"].Disks[0].Statuses[0].Time
            $VmReport+=$VmInfo
        }
    }
}

#Export created report in to an excel file
$VmReport | Export-CSV $VmReportlocation
