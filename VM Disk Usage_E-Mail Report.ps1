Add-PSSnapin VMware.VimAutomation.Core

Connect-VIServer us1vcenter01

$Report = @()
$AllVMs = Get-View -ViewType VirtualMachine -Filter @{"Config.Template" = "false"} -Property Name,Config,Guest,Value,AvailableField
$SortedVMs = $AllVMs | Select *, @{N="NumDisks";E={@($_.Guest.Disk.Length)}} | Sort-Object -Descending NumDisks
	ForEach ($VM in $SortedVMs){
		$Details = New-object PSObject
		$Details | Add-Member -Name Name -Value $VM.name -Membertype NoteProperty
		<# make a comma-separated string that holds the custom field key/value pairs, like "cust0 = myValue0,cust1 = myDateInfo" #>
		$Details | Add-Member -MemberType NoteProperty -Name "ALT Tier" -Value (($VM.Value `
			| Where-Object {$_.Value -ne "VMs from S to Z" -and $_.Value -ne "VMs from J to R" -and $_.Value -ne "VMs from A to I"} `
			| %{$oCustFieldStrValue = $_; "{0} = {1}" -f ($VM.AvailableField | Where-Object {$_.Name -eq "ALT"} `
			| ?{$_.Key -eq $oCustFieldStrValue.Key}).Name, $oCustFieldStrValue.Value}) -join ",")
		$DiskNum = 0
		Foreach ($disk in $VM.Guest.Disk){
			$Details | Add-Member -Name "Disk$($DiskNum)path" -MemberType NoteProperty -Value $Disk.DiskPath
			$Details | Add-Member -Name "Disk$($DiskNum)Capacity(GB)" -MemberType NoteProperty -Value  (([math]::Round($disk.Capacity / 1GB, 3)))
			$Details | Add-Member -Name "Disk$($DiskNum)FreeSpace(GB)" -MemberType NoteProperty -Value (([math]::Round($disk.FreeSpace / 1GB, 3)))
			$DiskNum++
		}
        $Details.PSTypeNames.Clear()
		$Report += $Details
    }
$Date = (Get-Date -format "MM-dd-yyyy_hh-mm-ss")
$OutFile = "C:\scripts\output\VM Disk Report_$Date.csv"
$Report | Export-Csv -NoTypeInformation -path $OutFile
Send-MailMessage -To jason.sanderson@resmed.com -Subject "Daily VM Disk Report" `
     -From JasonsScheduledScripts@resmed.com -Body "See attached CSV file." -SmtpServer us1smtp01.corp.resmed.org -Attachments $OutFile
