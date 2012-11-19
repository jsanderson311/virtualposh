function Get-VMGuestDiskUsage {

param(
	[parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Enter a vm entity")]
	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$VM)

process {
	$ErrorActionPreference = "SilentlyContinue"

foreach ($disk in $VM.Guest.disks) {
	$objDisk = New-Object System.Object
	$objDisk | Add-Member -MemberType NoteProperty -Name VM -Value $VM.Name
	$objDisk | Add-Member -MemberType NoteProperty -Name Volume -Value $disk.Path
	$objDisk | Add-Member -MemberType NoteProperty -Name CapacityMB -Value ([math]::Round($disk.Capacity / 1MB))
    $objDisk | Add-Member -MemberType NoteProperty -Name FreeSpaceMB -Value ([math]::Round($disk.FreeSpace/1MB))
    $objDisk | Add-Member -MemberType NoteProperty -Name Usage% -Value ("{0:p2}" -f (($disk.Capacity - $disk.FreeSpace) / $disk.Capacity))
    $objDisk | Add-Member -MemberType NoteProperty -Name CustomFields -Value ($VM.CustomFields)
    $objDisk
    }
  }
}

Add-PSSnapin VMware.VimAutomation.Core

Connect-VIServer us1vcenter01

Get-VM * | Get-VMGuestDiskUsage | Format-Table | Out-File C:\Scripts\output\VMGuestStorageReport.txt
