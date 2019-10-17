# @summary Install dependencies for GPO export on a domain controller.
#
# gpno::baseline_management installs the prerequisites on a domain controller
# in order to successfully export and convert GPO to DSC resources. Used in 
# conjunction with the gpno::create_manifest plan you can export your group 
# policies into puppet resources.
#
# @example
#   include gpno::baseline_management
class gpno::baseline_management {
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
