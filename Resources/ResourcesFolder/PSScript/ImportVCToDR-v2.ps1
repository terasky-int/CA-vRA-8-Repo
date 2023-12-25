param
(
   [alias("f")]
   $file = $(read-host "Enter the path to input TXT file contains new Resource Pools names")
)

function Get-FolderPath{
<#
.SYNOPSIS
	Returns the folderpath for a folder
.DESCRIPTION
	The function will return the complete folderpath for
	a given folder, optionally with the "hidden" folders
	included. The function also indicats if it is a "blue"
	or "yellow" folder.
.NOTES
	Authors:	Luc Dekens
.PARAMETER Folder
	On or more folders
.PARAMETER ShowHidden
	Switch to specify if "hidden" folders should be included
	in the returned path. The default is $false.
.EXAMPLE
	PS> Get-FolderPath -Folder (Get-Folder -Name "MyFolder")
.EXAMPLE
	PS> Get-Folder | Get-FolderPath -ShowHidden:$true
#>
 
	param(
	[parameter(valuefrompipeline = $true,
	position = 0,
	HelpMessage = "Enter a folder")]
	[VMware.VimAutomation.ViCore.Impl.V1.Inventory.FolderImpl[]]$Folder,
	[switch]$ShowHidden = $false
	)
 
	begin{
		$excludedNames = "Datacenters","vm","host"
	}
 
	process{
		$Folder | %{
			#$fld = $_.Extensiondata
            $fld = $_
			$path = $fld.Name
			while($fld.Parent){
				#$fld = Get-View $fld.Parent
                $fld = $fld.Parent
				#if((!$ShowHidden -and $excludedNames -notcontains $fld.Name) -or $ShowHidden){
					$path = $fld.Name + "\" + $path
				#}
			}
			$row = "" | Select Name,Path,Type
			$row.Name = $_.Name
			$row.Path = $path
			$row.Type = $_.Type
			$row
		}
	}
}


$vc = '$Svcenter.sddc-3-73-223-67.vmwarevmc.com'
$user = 'cloudadmin@vmc.local'
$password = '1F+wYjshRDiU5-T'
$dcName = 'SDDC-Datacenter'

$directory = 'H:\My Drive\Customers\SolarEdge\VMC Scripts\Files'#customer will provide his directory location
$FolderTreesToCreate = @("Main\LABS\Adiel","Main\LABS\Refael Sachevski")
$ResourcePoollocationName = "Compute-ResourcePool"


Connect-VIServer -Server $vc -Protocol https -User $user -Password $password

#Import-Csv -Path "$($directory)\folders.csv" -UseCulture | Sort-Object -Property {(Select-String -InputObject $_.Path -Pattern '/+' -AllMatches).Matches.Count} | %{

foreach ($csvLine in (Import-Csv -Path "$($directory)\folders.csv" -UseCulture | Sort-Object -Property Path) )
{
    #Write-Host "Got CSV Line: $csvLine"
    $isCreated = $false
    foreach ($FolderTree in $FolderTreesToCreate)
    {
        $folderPathToCreate = $csvLine.Path
        if ( ($FolderTree -like "$($folderPathToCreate)*") -or ($folderPathToCreate -like "$($FolderTree)*") -and ($isCreated -eq $false))
        {
            $csvPathDcName,$rest = $csvLine.Path.Split('\')
            $location = Get-Datacenter -Name $dcName | Get-Folder -Name 'vm'
            
            if($rest.count -gt 1)
            {
                $rest[0..($rest.Count -2)] | %{
                    $location = Get-Inventory -Name $_ -Location $location -NoRecursion
                }
                $newFolder = $rest[-1]
            }
            else
            {
                $newFolder = $rest
            }
            #$folderPathToCreate = get-folder -id $location.id | get-folderPath    
            write-host "Creating folder with name: $newFolder , under folder name: $location , folder path: $rest"
            New-Folder -Name $newFolder -Location $location
            $isCreated = $true;
        }
            
    }

}



#Create Resource pool with provided name (without limits) in existing Compute-ResourcePool


$ResourcePool = Get-ResourcePool -Name $ResourcePoollocationName


foreach($line in Get-Content $file) {
    New-ResourcePool -Location $ResourcePool -Name $line
}


