plan gpno::prep(
  TargetSpec $nodes,
){
  apply_prep($nodes)

  apply($nodes){
    pspackageprovider {'Nuget':
      ensure   => 'present',
      provider => 'windowspowershell',
      before   => Package['BaselineManagement']
    }
    package { 'BaselineManagement' :
      ensure   => latest,
      provider => 'windowspowershell',
      source   => 'PSGallery',
    }
  }

}
