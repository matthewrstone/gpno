#Requires -Module GPRegistryPolicyParser
#Requires -Module BaselineManagement
#Requires -Module GroupPolicy
Param(
    $PolicyName
)

function Backup-Policy {
    param($PolicyName)
    begin { Import-Module GPRegistryPolicyParser -DisableNameChecking }
    process { 
        $backupId = (Backup-GPO -Name $PolicyName -Path C:\Windows\Temp).Id.Guid
    }
    end { return $backupId }
}

function Convert-DSC {
    param (
        $backupId
    )
    begin {
        $objHash = @{
            resources = @()
            warnings = @()
        }
        ConvertFrom-GPO -Path C:\Windows\Temp\"{$backupId}" -OutputPath C:\Windows\Temp\"{$backupId}" -WarningVariable nogo -OutputConfigurationScript *>$null
        $content = Get-Content C:\Windows\Temp\"{$backupId}"\DSCfromGPO.ps1
    }
    process {

        foreach ( $line in $content ) {
            if ($line -match "^         [A-Z]" ) {
                $k, $v = $line.Split("'")
                $v = $v.Split(':', 2)[1].Trim()
                $x = @{
                    resource = $k.ToLower().Trim()
                    name = $v.ToLower()
                    parameters = @()
                }
            }
            elseif ($line -match "^              [A-Z]") {
                # parse the parmeters
                $k, $v = $line.Split('=').Replace("'","").Trim().ToLower()
                $x.Parameters += @{$k = $v}
            }
            else {
                if ($line -match "         }" ) { $objHash.resources += $x }
            }        
        }
    }
    end { 
        # Collect Warnings from conversion into object hash
        foreach ( $warning in $nogo ) { $objHash.warnings += $warning.Message }
        # Return the resources and warnings
        return $objHash
    }
}
$backupId = (Backup-Policy -PolicyName $PolicyName)
return Convert-Dsc -backupId $backupId | ConvertTo-Json -Depth 4
