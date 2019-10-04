Param(
    $PolicyName
)

Import-Module BaselineManagement

$backupId = (Backup-GPO -Name $PolicyName -Path C:\Windows\Temp).Id.Guid
ConvertFrom-GPO -Path C:\Windows\Temp\"{$backupId}" -OutputPath C:\Windows\Temp\"{$backupId}" -OutputConfigurationScript

$content = Get-Content C:\Windows\Temp\"{$backupId}"\DSCfromGPO.ps1

# a really bad dsc parser
# because my life needed more regex

$items = @()
foreach ( $line in $content ) {
    if ($line -match "^         [A-Z]" ) {
        $item = @()
        $k, $v = $line.Split("'")
        $k = "dsc_" + $k.Trim().ToLower()
        $v = $v.Split(':', 2)[1].Trim()
        $items += "$k { '$($v.Replace('\','\\'))' :"
    }
    elseif ($line -match "^              [A-Z]") {
        # parse the parmeters
        $k, $v = $line.Split('=').Replace("'","").Trim()
        $items += "  dsc_$($k.ToLower().Trim())  => '$($v.Replace('\','\\'))',"  
    }
    else {
        if ($line -match "         }" ) { $items += "}" }
    }

}

$items | Out-File "$($PolicyName.ToLower().Replace(' ','_')).pp" -Encoding ascii
& code "$($PolicyName.ToLower().Replace(' ','_')).pp"