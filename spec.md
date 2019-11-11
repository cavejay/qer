# Specification for 'Qer' interface

Solution Name: Qer

Spec Author: cavejay@github

Spec Version: 0.0.2

## Purpose

Qer will provide a HTTP based simple Data queuing system. This in turn enables batching of tasks or delegation/load-balancing of data between stateless components.

## General Overview

The solution must be launched from the command line and support the following arguments

- _PORT_ `-p|port <portnumber>` - For specifying the port to listen on. This should default to 12012.
- _IP_ `-a|address <IP>` - For specifying the specific IP address to listen on. This should default to the local loopback: 127.0.0.1.

The Solution must log incoming requests to and answers to stdout with date-time (UTC) stamps. An example of the Logging format is:

    `20190808-0511 GET /api/channel/ - 50B Returned`

## Expected Workflow

Services will push data payloads to specific 'channels' provided by Qer. These channels work as a queue for other services that will query channels for the next/current payload.

**Example.**

A Mail service needs to send 300 emails and uses a scalable 'sending' service to batch this job. The Mail service would push the 300 emails to a specific channel on Qer (we will use 'batchEmail' here). Five instances of the sending service could be deployed to work through the queue of emails, with each instance collecting an email to send from Qer (via HTTP), actioning the email sending and then requesting another from Qer until no emails remain to be sent.

**Example 2**

1. Device A `POST /api/foo {data: "barr"}` -> 201 Created
2. Device A `POST /api/foo {data2: "text", numbers: [1,2,3,4,4]}` -> 200 OK
3. Device B `GET /api/foo ''` -> 200 OK `{data: {data: "barr"}}
4. Device C `GET /api/bar ''` -> 404 Not Found
5. Device C `GET /api/foo ''` -> 200 OK `{data: {data2: "text", numbers: [1,2,3,4,4]}}`
6. Device C `GET /api/foo ''` -> 204 No Content `{status: 204, message: "Queue empty"}`

## HTTP Endpoints and behaviour

The following sections are grouped as with the relevant HTTP methods in square brackets '[]' and the URI being specified following.

Where a dynamic URI element is used it is represented using a colon `:`. These elements will be replaced with something during run time. Eg. A Post request to `/api/:channel` represents any request to a URI that matches `^/api/[^/]+$`.

### [POST] /api/:channel

Making a `POST /api/:channel` request will either append data to a Channel's queue or create a new Channel. Where a new channel is created it can be created with a passcode that must be matched on all future interactions to that channel. There are some restrictions on Channel naming as outlined below, but incoming payloads can be any valid JSON.

**URI Parameters**

- :channel
  - Must be less than 64 characters
  - Must match regex `[a-zA-Z0-9\-\_]`

**Headers**

- API-Passcode [Optional] - <String - Alphanumeric Characters>
  - Purpose: When included in the first POST request to a channel this Header sets a passcode that all future posts and gets to that channel must include via this header. Failure to include this header with the correct passcode must return a 401 Unauthorized response (see responses below)
  - Example: `rphylenToRTY`

**Body**

The Body should be the first element added to the channel's queue

```json
{
    <json payload>
}
```

**Responses**

- Successful addition of data to the Channe's queue
  - Status = 200 OK
  - Body = `{status: 200, message: "Success"}`
- Successful creation of channel
  - Status = 201 Created
  - Body = `{status: 201, message: "Channel created successfully"}`
- Invalid Channel name
  - Status = 400 Bad Request
  - Body = `{status: 400, message: "Channel could not be created", error: "Invalid Channel name ':channel'"}`
- Request has no body
  - Status = 400 Bad Request
  - Body = `{status: 400, message: "Channel could not be created", error: "Request to create channel contained an empty body"}`
- Request has invalid JSON as body
  - Status = 400 Bad Request
  - Body = `{status: 400, message: "Channel could not be created", error: "Request to create channel contained invalid JSON as body"}`
- Request does not include the required passcode header
  - Status = 403 Forbidden
  - Body = `{status: 403, message: "Channel Requires API-Passcode Header", error: "Channel has been secured with a passcode. Include a correct 'API-Passcode' header for access"}`
- Request sent with incorrect Passcode
  - Status = 401 Unauthorized
  - Body = `{status: 401, message: "Incorrect passcode for Channel", error: "An incorrect passcode was provided for channel ':channel'"}`

### [GET] /api/:channel

Making a `GET /api/:channel` request to Qer should return the next payload in the channel's queue. The Body of the GET request should be empty. If there are no more payloads in the Channel's queue then this should be informed via a response code (below)

**URI Parameters**

- :channel
  - Must be less than 64 characters
  - Must match regex `[a-zA-Z0-9\-\_]`

**Headers**

- API-Passcode [Optional] - <String - Alphanumeric Characters>
  - Purpose: Must be included if it was set during the initial creation of the channel. Error responses will be used to inform if this is the case.
  - Example: `rphylenToRTY`

**Body**

The HTTP Body should remain empty for this request.

**Responses**

- Successful fetch of next payload in queue
  - Status = 200 OK
  - Body = `{status: 200, message: "Success", Data: <JSON Payload of next queue item>}`
- There are no more items in the Channel's queue
  - Status = 204 No Content
  - Body = `{status: 204, message: "Queue empty"}`
- Request has a body
  - Status = 400 Bad Request
  - Body = `{status: 400, message: "Queue pop should not include a HTTP Body", error: "Request to pop queue contained data in Body"}`
- Channel does not exist
  - Status = 404 Not Found
  - Body = `{status: 404, message: "Channel does not exist", error: "Channel ':channel' does not exist"}`
- Request does not include a required passcode header
  - Status = 403 Forbidden
  - Body = `{status: 403, message: "Protected Channel Requires API-Passcode Header", error: "Channel has been secured with a passcode. Include a correct 'API-Passcode' header for access"}`
- Request sent with incorrect Passcode
  - Status = 401 Unauthorized
  - Body = `{status: 401, message: "Incorrect passcode for Channel", error: "An incorrect passcode was provided for channel ':channel'"}`

### [DELETE] /api/:channel

**URI Parameters**

- :channel
  - Must be less than 64 characters
  - Must match regex `[a-zA-Z0-9\-\_]`

**Headers**

- API-Passcode [Optional] - <String - Alphanumeric Characters>
  - Purpose: Must be included if it was set during the initial creation of the channel. Error responses will be used to inform if this is the case.
  - Example: `rphylenToRTY`

**Body**

The HTTP Body must include a reason for removing this queue and also include the (if any) passcode a second time. A valid reason must be at least 5 alphanumeric characters and can include '-', '\_' and ' '.

```json
{
  "reason": "Reason for deletion of this channel",
  "passcode": "<passcode>"
}
```

**Responses**

- Successful deletion of channel
  - Status = 200 OK
  - Body = `{status: 200, message: "Success"}`
- Request Body does not include a valid reason
  - Status = 200 Bad Request
  - Body = `{status: 400, message: "DELETE requests must include a valid reason.", error: "Delete Request must include a valid reason for deletion."}`
- Request does not have a body
  - Status = 400 Bad Request
  - Body = `{status: 400, message: "DELETE requests must include a body.", error: "Delete Request must include a HTTP Body"}`
- Channel does not exist
  - Status = 404 Not Found
  - Body = `{status: 404, message: "Channel does not exist", error: "Channel ':channel' does not exist"}`
- Request does not include a required passcode header
  - Status = 403 Forbidden
  - Body = `{status: 403, message: "Protected Channel Requires API-Passcode Header", error: "Channel has been secured with a passcode. Include a correct 'API-Passcode' header for access"}`
- Request sent with incorrect Passcode
  - Status = 401 Unauthorized
  - Body = `{status: 401, message: "Incorrect passcode for Channel", error: "An incorrect passcode was provided for channel ':channel'"}`

### [*] /api/:channel

**Responses**

- Invalid method
  - Status = 405 Method Not Allowed
  - Body = ''

### [GET] /api/:channel/meta

Making a `GET /api/:channel/meta` request to Qer should return the meta data about the channel and it's queue. The Body of the GET request should be empty.

**URI Parameters**

- :channel
  - Must be less than 64 characters
  - Must match regex `[a-zA-Z0-9\-\_]`

**Headers**

- API-Passcode [Optional] - <String - Alphanumeric Characters>
  - Purpose: Must be included if it was set during the initial creation of the channel. Error responses will be used to inform if this is the case.
  - Example: `rphylenToRTY`

**Body**

The HTTP Body should remain empty for this request.

**Responses**

- Successful fetch of channel information

  - Status = 200 OK
  - Body = Outlined below

```json
{
  "channelName": "Foobar",
  "elements": "5", // Number of current elements in the Channel queue
  "creator": "0.0.0.0", // IP address of the device that started the queue
  "dateOfCreation": 1503548687687, // JS Datetime value for date of creation
  "passcode": "ad1313lkj", // Passcode if the channel has one
  "statistics": {
    "maxElements": {
      "value": 6, // Maximum number of elements this channel queue has seen
      "date": 123154354 // Date that this occured (rising edge)
    },
    "lastAction": {
      "actionType": "pop", // Should be pop or push. POP = GET, PUSH = POST
      "date": 12315123412 // Date this occured
    }
  }
}
```

- Request has a body
  - Status = 400 Bad Request
  - Body = `{status: 400, message: "Request to meta should not include a HTTP Body", error: "Request to meta should not include a HTTP Body"}`
- Channel does not exist
  - Status = 404 Not Found
  - Body = `{status: 404, message: "Channel does not exist", error: "Channel ':channel' does not exist"}`
- Request does not include a required passcode header
  - Status = 403 Forbidden
  - Body = `{status: 403, message: "Protected Channel Requires API-Passcode Header", error: "Channel has been secured with a passcode. Include a correct 'API-Passcode' header for access"}`
- Request sent with incorrect Passcode
  - Status = 401 Unauthorized
  - Body = `{status: 401, message: "Incorrect passcode for Channel", error: "An incorrect passcode was provided for channel ':channel'"}`

### [*] /api/:channel/meta

**Responses**

- Invalid method
  - Status = 405 Method Not Allowed
  - Body = ''
