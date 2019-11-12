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
    [String] $Port = '13000',
    [String] $ExecutionCommand
)

if ($ExecutionCommand) {
    Write-host "Execution command was provided. Local instance of app will be tested and launched with that."

}

Describe 'Simple' {
    It "Channel creation provides expected response" {

    }
    It "GET from newly created channel" {

    }
    It "Expected failure for GET from uncreated channel" {

    }
    It "GET from empty channel" {

    }
    It "POST to already created channel correctly queues payloads" {

    }
}

Describe 'Strict Tests' {
    Context 'GET /api/:channel' {
        It "" {

        }
        It "" {

        }
    }
}