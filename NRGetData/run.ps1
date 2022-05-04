# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

##$ConfigFile = Get-Content -Path ""
$Configpath = $PSScriptRoot + "\config.json"
$ConfigFile = Get-Content -Path "$PSScriptRoot\config.json"
Write-Host $Configpath
Write-Host $PSScriptRoot
$cfg = $ConfigFile | ConvertFrom-Json 
# Replace with your Workspace ID
$CustomerId = $cfg.CustomerId

# Replace with your Primary Key
$SharedKey = $cfg.key

# Specify the name of the record type that you'll be creating
$LogType = "NewRelicEvent"

# Optional name of a field that includes the timestamp for the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
$TimeStampField = "timestamp"

$NRQLQuery = $cfg.NRQL +  " Since " + $cfg.MinutesInterval + " Minutes ago"

Write-Host $NRQLQuery 


###get data from NR

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("API-Key", $cfg.NRKey)

$body = "query {
`n   actor {
`n      account(id: 3291700) {
`n         name
`n         nrql(query: `"$NRQLQuery`") {
`n             nrql
`n             rawResponse
`n             totalResult
`n             results
`n         }
`n      }
`n   }
`n}
`n"

$response = Invoke-RestMethod 'https://api.newrelic.com/graphql' -Method 'GET' -Headers $headers -Body $body
$QueryResults = $response.data.actor.account.nrql.results

foreach ($Result in $QueryResults) {
    $Result.timestamp = (([System.DateTimeOffset]::FromUnixTimeMilliseconds($Result.timestamp)).DateTime).ToString("s")
}
$JsonQueryResults = $QueryResults | ConvertTo-Json

##$JsonResponse = $response | ConvertTo-Json
##$NREvents = $JsonResponse.data.actor.account.nrql.results


# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}



# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

# Submit the data to the API endpoint

Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($JsonQueryResults)) -logType $logType  
# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"