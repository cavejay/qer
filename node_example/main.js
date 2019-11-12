const { Cottage, Response } = require("cottage");
const bodyParser = require("koa-bodyparser");

const app = new Cottage();
app.use(bodyParser());

let serverPort = 12012;
let serverAddress = "localhost";

process.argv.forEach((val, index, array) => {
  if (val == "-port" || val == "-p") {
    serverPort = process.argv[index + 1];
  }
  if (val == "-address" || val == "-a") {
    serverAddress = process.argv[index + 1];
  }
});

// or a simple shorthand without importing Koa.
app.listen(serverPort, serverAddress, () =>
  console.log(`Que - Listening on ${serverAddress}:${serverPort}`)
);

// just simple return would be enough
app.get(
  "/api",
  async ctx => `Welcome to Qer, the simple HTTP based queue service`
);

/**
 * Schema
 * {
 *   channelname: {
 *     passcode: "asdasd",
 *     q: []
 *   }
 * }
 */

let qs = {};

app.post("/api/:channel", async ctx => {
  const cName = ctx.request.params.channel;

  console.log(ctx.request.body);

  // Checks
  if (undefined === ctx.request.body) {
    return new Response(400, {
      status: 400,
      message: "Channel could not be created",
      error: "Request to create channel contained an empty body"
    });
  }

  // Success
  if (Object.keys(qs).includes(cName)) {
    qs[cName].q.push(ctx.request.body);
    return new Response(200, { status: 200, message: "Success" });
  } else {
    qs[cName] = { q: [] };
    qs[cName].q.push(ctx.request.body);
    return new Response(204, {
      status: 201,
      message: "Channel created successfully"
    });
  }
});

app.get("/api/:channel", async ctx => {
  const cName = ctx.request.params.channel;

  // Checks
  if (ctx.request.body && ctx.request.body.length > 0) {
    return new Response(400, {
      status: 400,
      message: "Queue pop should not include a HTTP Body",
      error: "Request to pop queue contained data in Body"
    });
  }
  if (!Object.keys(qs).includes(cName)) {
    return new Response(404, {
      status: 404,
      message: "Channel does not exist",
      error: `Channel '${cName}' does not exist`
    });
  }
  if (qs[cName].q.length == 0) {
    return new Response(204, { status: 204, message: "Queue empty" });
  }

  // Success
  return new Response(200, {
    status: 200,
    message: "bby got data",
    data: qs[cName].q.shift()
  });
});
