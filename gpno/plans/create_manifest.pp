plan gpno::create_manifest(
  TargetSpec $nodes,
  String $policyname
){
  $resources = run_task('gpno::export', $nodes, policyname => $policyname)
  $manifest_data = run_task('gpno::create_resources', localhost, data => $resources.to_data)
  return $manifest_data
}
