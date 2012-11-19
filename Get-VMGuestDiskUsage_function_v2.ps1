function Get-VMGuestDiskUsage {

param(
	[parameter(valuefrompipeline = $true, mandatory = $true, HelpMessage = "Enter a vm entity")]
	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]$VM)

process {
	$ErrorActionPreference = "SilentlyContinue"

foreach ($disk in $VM.Guest.disks) {
    New-Object PSObject -Property @{
        VM = $VM.Name
        Volume = $disk.Path
        CapacityMB = [math]::Round($disk.Capacity / 1MB)
        FreeSpaceMB = [math]::Round($disk.FreeSpace/1MB)
        "Usage%" = "{0:p2}" -f (($disk.Capacity - $disk.FreeSpace) / $disk.Capacity)
        CustomFields = ($VM.CustomFields | %{"$($_.Key) = $($_.Value)"}) -join ","
        } ## end new-object
    } ## end foreach
  } ## end process
} ##end function

Add-PSSnapin VMware.VimAutomation.Core

Connect-VIServer us1vcenter01

Get-VM * | Get-VMGuestDiskUsage | Export-Csv -NoTypeInformation C:\Scripts\output\VMGuestStorageReport_v2.csv
