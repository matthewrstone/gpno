Param(
    $data
)

foreach ($item in $data.result.resources) { 
    Write-Output "dsc_$($item.resource) { $($item.name) :"
    foreach ($parameter in $item.parameters) {
       $parameter.Item()
    }
#         $k,$v = $parameter.split()
#         Write-Output "${k} => ${v}"
#     }
#     Write-Output "}"
}
