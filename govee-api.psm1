Function Set-GoveeBaseObject{
	param(
		$endpoint
	)
	Filter Decrypt-ApiKey{
		$secureString = $_ | ConvertTo-SecureString
		$ptrString = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($secureString)
		return( [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptrString) )
	}
	if( $null -eq [System.Environment]::GetEnvironmentVariable('Govee-API-Key') ){
		$apiKey = Read-Host 'Govee API Key'
		$encryptedKey = ConvertTo-SecureString -String $apiKey -AsPlainText | ConvertFrom-SecureString
		[System.Environment]::SetEnvironmentVariable('Govee-API-Key', $encryptedKey, 'User')
		Write-Host -ForegroundColor Red 'User variables updated - please restart shell'
		break
	}
	else{
		$goveeBaseObject = @{
			uri     = ('https://openapi.api.govee.com/router/api/v1{0}' -f $endpoint)
			headers = @{
				'Govee-API-Key' = ( ([System.Environment]::GetEnvironmentVariable('Govee-API-Key') | Decrypt-ApiKey ) )
				'Content-Type'  = 'application/json'
			}
		}
		return $goveeBaseObject
	}
}
Function Get-GoveeDevice{
	[CmdletBinding( DefaultParameterSetName = 'byType' )]
	param(
		[Parameter( ParameterSetName = 'byType' )][ValidateSet('light','air_purifier','thermometer','socket','sensor','heater','humidifier','dehumidifier','ice_maker','aroma_diffuser','box')]$type = '*',
		[Parameter( ParameterSetName = 'byName' )]$name
	)
	$baseObject = Set-GoveeBaseObject -endpoint '/user/devices'
	$output = Invoke-RestMethod $baseObject.uri -Headers $baseObject.headers -ErrorVariable 'irmError'
	if($output.code -eq 200){
		switch($PSCmdlet.ParameterSetName){
			'byType'	{ $filteredResults = $output.data | Where-Object{ $_.type -like ('devices.types.{0}' -f $type) } }
			'byName'	{ $filteredResults = $output.data | Where-Object{ $_.deviceName -eq $name }}
		}
		return $filteredResults
	}
	else{
		Write-Error -Message ('RESTful response was not OK: {0}' -f $irmError)
		break
	}
}
Function Get-GoveeDeviceState{
	param(
		[Parameter( ValueFromPipeline = $true )]$goveeDevice
	)
	Begin{
		$baseObject = Set-GoveeBaseObject -endpoint '/device/state'
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
		$response = Invoke-RestMethod -Uri $baseObject.uri -Headers $baseObject.headers -Body ($body | ConvertTo-Json) -Method Post
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
		$baseObject = Set-GoveeBaseObject -endpoint '/device/control'
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
		Invoke-RestMethod -Uri $baseObject.uri -Headers $baseObject.headers -Body ($body | ConvertTo-Json) -Method Post
	}
}
