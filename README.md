# govee-api
<span style="color: #FF0000; font-size: x-large;"> ⚠ ***The contents of this repository are a work in progress*** ⚠</span>

## Goal
High-level, I intend to further automate the Govee ecosystem.  Initially, this will just be an exploratory practice.  As I progress through the project, I might formalize my approach.

## Instructions
Right now, this is a simple PowerShell module, so you just need to import it via `Import-Module`.
- On first run of any functions, you will be prompted to enter your API key.  This will be encrypted and stored in an environment variable in your user scope (`Govee-API-Key`).  It will then be decrypted as required to assemble the headers.

### Examples
- Get device list: `Get-GoveeDevice`
- Turn on device(s) from list: `Get-GoveeDevice | Out-GridView -PassThru | Set-GoveeDevicePower -powerOff`
- Turn off device by name: `Get-GoveeDevice -name 'Television Lights' | Set-GoveeDevicePower -powerOff`
- Toggle device power by type: `Get-GoveeDevice -type light | Set-GoveeDevicePower -toggle`

## To-do
- [X] Poll devices
	- via `Get-GoveeDevice`
- [X] Poll device state
	- via `Get-GoveeDeviceState`
- [X] Set device power state
	- via `Set-GoveeDeviceState`
- [ ] Set other device states
- [ ] Convert to class-based implementation
- [ ] Add provisions for event subscription