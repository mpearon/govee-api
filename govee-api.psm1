$goveeBaseObject = @{
	uri     = 'https://openapi.api.govee.com/router/api/v1'
	headers = @{
		'Govee-API-Key' = ([System.Environment]::GetEnvironmentVariable('Govee-API-Key'))
		'Content-Type'  = 'application/json'
	}
}
Function Get-GoveeDevice{
	$uri = ('{0}/user/devices' -f $goveeBaseObject.uri)
	$output = Invoke-RestMethod $uri -Headers $goveeBaseObject.headers
	if($output.code -eq 200){
		return $output.data
	}
}
Function Get-GoveeDeviceState{
	param(
		[Parameter( ValueFromPipeline = $true )]$goveeDevice
	)
	Begin{
		$uri = ('{0}/device/state' -f $goveeBaseObject.uri)
		$resultHash = @{}
	}
	Process{
		$goveeDevice | ForEach-Object{
			$body = [PSCustomObject]@{
				requestId = [guid]::NewGuid().Guid
				payload = @{
					sku        = $_.sku
					device     = $_.device
				}
			}
		}
		$stateHash = @{}
		$response = Invoke-RestMethod -Uri $uri -Headers $goveeBaseObject.headers -Body ($body | ConvertTo-Json) -Method Post
		$response.payload.capabilities.GetEnumerator() | ForEach-Object{
			$stateHash.($_.instance) = $_.state.value
		}
		$resultHash.($_.device) = $stateHash
	}
	End{
		return $resultHash
	}
}
Function Set-GoveeDevicePower{
	[CmdletBinding( DefaultParameterSetName = 'powerToggle' )]
	param(
		[Parameter( ValueFromPipeline = $true )]$goveeDevice,
		[Parameter( ParameterSetName = 'powerOn')][switch]$powerOn,
		[Parameter( ParameterSetName = 'powerOff')][switch]$powerOff,
		[Parameter( ParameterSetName = 'powerToggle')][switch]$toggle
	)
	Begin{
		$uri = ('{0}/device/control' -f $goveeBaseObject.uri)
		
	}
	Process{
		$goveeDevice | ForEach-Object{
			$thisDevice = $_
			switch($PSCmdlet.ParameterSetName){
				'powerOn'		{ $powerSetting = 1 }
				'powerOff'		{ $powerSetting = 0 }
				'powerToggle'	{ 
					switch ((Get-GoveeDeviceState -goveeDevice $thisDevice).Values.powerSwitch ){
						0	{ $powerSetting = 1 }
						1	{ $powerSetting = 0 }
					}
				}
			}
			$global:body = [PSCustomObject]@{
				requestId = [guid]::NewGuid().Guid
				payload = @{
					sku        = $thisDevice.sku
					device     = $thisDevice.device
					capability = @{
						type     = 'devices.capabilities.on_off'
						instance = 'powerSwitch'
						value    = $powerSetting
					}
				}
			}
		}
		Invoke-RestMethod -Uri $uri -Headers $goveeBaseObject.headers -Body ($body | ConvertTo-Json) -Method Post
	}
}
