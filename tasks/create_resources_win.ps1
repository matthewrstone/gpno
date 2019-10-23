Param(
    $data,
    $show_warnings
)

$result = $data.result
foreach ($resource in $result.resources) { 
    Write-Output "dsc_$($resource.resource) { '$($resource.name)' :"
    foreach ( $parameter in $resource.parameters ) {
        Write-Output "  dsc_$($parameter.Keys) => '$($parameter.Values)',"
    }
    Write-Output "}"
}
if ($show_warnings -eq 'true') {
    Write-Output "WARNINGS FROM GPO EXPORT: "
    foreach ($warning in $result.warnings) { Write-Output "  - $warning" }
    Write-Output "Note: Warnings come from the BaselineManagement powershell module."
}

