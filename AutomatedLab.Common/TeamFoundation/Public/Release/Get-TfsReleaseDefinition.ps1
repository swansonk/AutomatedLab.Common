function Get-TfsReleaseDefinition
{
    [CmdletBinding(DefaultParameterSetName = 'Cred')]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $InstanceName,

        [Parameter()]
        [string]
        $CollectionName = 'DefaultCollection',

        [ValidateRange(1, 65535)]
        [uint32]
        $Port,

        [string]
        $ApiVersion,

        [Parameter(Mandatory)]
        [string]
        $ProjectName,

        [switch]
        $UseSsl,

        [Parameter(Mandatory, ParameterSetName = 'Cred')]
        [pscredential]
        $Credential,
        
        [Parameter(Mandatory, ParameterSetName = 'Pat')]
        [string]
        $PersonalAccessToken
    )

    $requestUrl = if ($UseSsl) {'https://' } else {'http://'}
    $requestUrl += if ( $Port -gt 0)
    {
        '{0}{1}/{2}/{3}/_apis/release/definitions' -f $InstanceName, ":$Port", $CollectionName, $ProjectName
    }
    else
    {
        '{0}/{1}/{2}/_apis/release/definitions' -f $InstanceName, $CollectionName, $ProjectName
    }

    if ($ApiVersion)
    {
        $requestUrl += '?api-version={0}' -f $ApiVersion
    }

    $requestParameters = @{
        Uri             = $requestUrl
        Method          = 'Get'
        ErrorAction     = 'Stop'
        UseBasicParsing = $true
    }

    if ($Credential)
    {
        $requestParameters.Credential = $Credential
    }
    else
    {
        $requestParameters.Headers = @{ Authorization = Get-TfsAccessTokenString -PersonalAccessToken $PersonalAccessToken }
    }

    try
    {
        $result = Invoke-RestMethod @requestParameters
    }
    catch
    {
        if ($_.ErrorDetails.Message)
        {
            $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($errorDetails.typeKey -eq 'ProjectDoesNotExistWithNameException')
            {
                return $null
            }
        }
        
        Write-Error -ErrorRecord $_
    }
    
    return $result.value
}
