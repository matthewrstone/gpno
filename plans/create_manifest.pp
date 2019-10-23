plan gpno::create_manifest(
  TargetSpec $nodes,
  String $policyname,
  Boolean $show_warnings
){
  $resources = run_task('gpno::export', $nodes, policyname => $policyname)
  $manifest_data = run_task(
    'gpno::create_resources',
    localhost,
    data => $resources.to_data,
    show_warnings => $show_warnings
  )
  return $manifest_data
}
