# GPNO

## What's all this then?

GPNO is an experimental set of Bolt tasks and plan to export Group Policy from domain controllers into DSC resources that can be utilized by Puppet. It requires Microsoft's BaselineManagement Powershell module to be installed on the domain controller.

This plan does the following:

- Connects to your domain controller.
- Backs up GPO to temp folder.
- Converts GPO to DSC resources.
- Exports as JSON to your localhost.
- Converts into Puppet resources using Powershell (Windows) or Python (other)

## Usage

    # Install Microsoft's BaselineManagement powershell module
    class profile::domain_controller {
        include gpno::baseline_management
    }

    # Export default domain policy
    > bolt plan run gpno::create_manifest --nodes <your domain controller> policyname='Default Domain Policy'

*Note: please refer to the [Bolt documentation](http://www.puppet.com/docs/bolt) if you need assistance setting up an inventory or connection settings for your domain controller.*

## Contributing

Please!

## TO-DO

- ~~Make it a Bolt task.~~
- ~~Create prep task for installing BaselineManagement module.~~
- ~~Make a Bolt plan to do this on a DC and export the results locally.~~
- Capture warnings for resources that the Microsoft BaselineManagement module cannot convert.
- Find a way to convert those.
- Clean up the temp folder post-conversion
- Allow for using puppet native resources to replace DSC.