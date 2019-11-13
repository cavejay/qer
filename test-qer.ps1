<#
.SYNOPSIS
    A testing tool for implementations of the Qer Spec. 

.DESCRIPTION
    Use this tool to ensure your implementation of the Qer Spec is proceeding as planned.

.NOTES
    Author: cavejay@github
    Version: 0.0.1

.EXAMPLE
    

#>

PARAM (
    [String] $Address = 'localhost',
    [String] $Port = '12012',
    [String] $ExecutionCommand
)

# Check Pester Version
$pesterVersion = (Get-Module Pester).version
if (($pesterVersion.Major -eq 4 -and $pesterVersion.Minor -lt 9) -or $pesterVersion.Major -lt 4) {
    Write-error "test-qer.ps1 requires a minimum of Pester v4.9.0. Run as admin: 'Install-Module -Name Pester -Force -SkipPublisherCheck'"
}

if ($ExecutionCommand) {
    Write-host "Execution command was provided. Local instance of app will be tested and launched with that."

}

$stdResponses_String = @{
    "POST_200OK"                       = '{"status":200,"message":"Success"}';
    "POST_201Created"                  = '{"status": 201, "message": "Channel created successfully"}';
    "POST_400_NoBodyPresent"           = '{"status": 400, "message": "Channel could not be created", "error": "Request to create channel contained an empty body"}';
    "POST_400_NoGoodJSON"              = '{"status": 400, "message": "Channel could not be created", "error": "Request to create channel contained invalid JSON as body"}';
    "POST_403_MissingRequiredPasscode" = "{`"status`": 403, `"message`": `"Channel Requires API-Passcode Header`", `"error`": `"Channel has been secured with a passcode. Include a correct 'API-Passcode' header for access`"}";
    "GET_204_QueueEmpty"               = '{status: 204, message: "Queue empty"}'
}

$stdResponses = @{ }
$stdResponses_String.Keys | % {
    $stdResponses[$_] = $stdResponses_String[$_] | ConvertFrom-Json | ConvertTo-Json -Compress
}

$base = "http://$Address`:$port"

$header1 = @{
    "API-Passcode" = "secretSquirrel"
}

$header2 = @{
    "API-Passcode" = "othersecret"
}

function get-jsDate {
    return [Math]::Floor(1000 * (Get-Date ([datetime]::UtcNow) -UFormat %s))
}

Describe 'Simple' {
    It "Qer welcome message on /api is present" {
        $res = Invoke-WebRequest -UseBasicParsing -method GET -Uri "$base/api"
        $res.content | Should -BeExactly "Welcome to Qer, the simple HTTP based queue service"
        $res.StatusCode | Should -BeExactly 200
    }

    $_channel = "testChannel_$( get-jsDate )"
    $_uri = "$base/api/$_channel"
    $b = "{`"foo`": `"bar`"}"

    It "Channel creation provides expected response" {
        Write-Host "POSTing to $_uri with $b"
        
        $res = Invoke-WebRequest -UseBasicParsing -method POST -Uri $_uri -Body $b  -ContentType "application/json"
        $res.content | Should -BeExactly $stdResponses["POST_201Created"]
        $res.StatusCode | Should -BeExactly 201
    }
    It "GET from newly created channel" {
        $resBody = "{status: 200, message: `"Success`", data: $b}" | ConvertFrom-Json | ConvertTo-Json -Compress

        write-host "GETing from $_uri"
        try {
            $res = Invoke-WebRequest -UseBasicParsing -Method GET -Uri $_uri -ContentType "application/json"
        }
        catch [System.Net.WebException] {
            $res = $_.Exception.Response
        }
        $res.StatusCode | should -BeExactly 200
        $res.content | should -BeExactly $resBody
        write-host "GOT: $($res.content | ConvertFrom-Json | Select-Object -ExpandProperty data | convertTo-Json -Compress)"
    }
    It "Expects error for GET from empty channel" {
        write-host "GETing from $_uri (Should now be empty)"
        try {
            $res = Invoke-WebRequest -UseBasicParsing -Method GET -Uri $_uri -ContentType "application/json"
        }
        catch [System.Net.WebException] {
            $res = $_.Exception.Response
        }
        $res.StatusCode | should -BeExactly 204
        $res.content | should -BeExactly $stdResponses['GET_204_QueueEmpty']
    }
    It "Expects error for GET from uncreated channel" {
        $c = "testChannel_$( get-jsDate )"
        $u = "$base/api/$c"
        $resBody = "{`"status`": 404, `"message`": `"Channel does not exist`", `"error`": `"Channel ':channel' does not exist`"}" -replace ':channel', $c

        write-host "GETing from $u"
        try {
            $res = Invoke-WebRequest -UseBasicParsing -Method GET -Uri $_uri -ContentType "application/json"
        }
        catch [System.Net.WebException] {
            $res = $_.Exception.Response
        }
        $res.statusCode | should -BeExactly 404
        $res.content | Should -BeExactly $resBody
    }
    It "Supports POSTs to and GETs from multiple queues" {

    }
}

Describe 'Strict Tests' {   
    Context 'GET /api/:channel' {
        It "Support for deep JSON payloads" { }
        It "Error on GET with body" { }
        It "Error on none JSON body" { }
    }

    Context 'POST /api/:channel' {
        It "Returns expected output on 'good' input" {}
        It "Errors on empty body" {}
        It "Errors on non-JSON body" {}
        It "Posting to pre-made channel is a 200, not 201" {}
    }

    Context 'DELETE /api/:channel' {
        It "Returns expected output on 'good' input" {}
        It "Error on no reason" {}
        It "Error on short reason" {}
        It "Error on no additional passcode" {}
        It "Error on wrong additional passcode" {}
        It "Error on channel not existing" {}
        It "Does not remove other Channels" {}
        It "Works with full queues" {}
        IT "Works with empty queues" {}
    }

    Context 'GET /api/:channel/meta' {
        It "Channel Creation date is reasonable" {}
        It "Channel owner" {}
        It "Channel passcode return" {}
    }

    Context 'Channel Name' {
        It "Channel Name works with 64 Characters" { }
        It "Channel Name fails with 65 Characters" { }
        It "Channel Name Fails with special characters" { }
        It "Channel Name works with variety of supported characters" { }
    }

    Context 'Passcode' {
        It "Passcode required for protected queues" { }
        It "Correct Passcode required for protected queues" { }
        It "Passcode for one channel does not work for others" { }
    }   
}