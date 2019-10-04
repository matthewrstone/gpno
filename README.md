# GPNO

## What's all this then?

It's a hella quick and dirty powershell script to scrape DSC resources exported from group policy objects and convert them to a puppet friendly format. It leverages Microsoft's BaselineManagement script from the Powershell gallery and the GPOManagement module to backup GPO, export it to DSC, then write puppet resources based on that output. It's still very messy and I'd love some help spiffying it up.

## Usage

    > ./puppetizer.ps1 -GPO 'Default Domain Policy'

This converts the default domain policy to a list of puppet resources and opens it in VS Code. From there you can move it into a profile and check it into puppet.

![running the script](https://raw.githubusercontent.com/matthewrstone/gpno/master/img/quickvideo.gif)

## Contributing

Please!

## TO-DO

- Make it a Bolt task.
- Make a Bolt plan to do this on a DC and export the results locally.
- Capture warnings for resources that the Microsoft BaselineManagement module cannot convert.
- Find a way to convert those.