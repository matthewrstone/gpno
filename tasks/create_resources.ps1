Param(
    $data
)

$result = $data.result
# $result = $data | ConvertFrom-Json 
foreach ($resource in $result.resources) { 
    Write-Output "dsc_$($resource.resource) { '$($resource.name)' :"
    foreach ( $parameter in $resource.parameters ) {
        Write-Output "  dsc_$($parameter.Keys) => '$($parameter.Values)',"
    }
    Write-Output "}"
}

