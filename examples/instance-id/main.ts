// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

const randomGlobal = Math.random().toString(36).slice(2, 12).padEnd(10, "0");
const startTime = Date.now();
let counter = 0;

Deno.serve((req) =>
  new Response(
    [
      `x-deno-isolate-instance-id: ${
        req.headers.get("x-deno-isolate-instance-id")
      }`,
      `Start time: ${new Date(startTime).toISOString()}`,
      `Uptime: ${(Date.now() - startTime) / 1000}s`,
      `Random global: ${randomGlobal}`,
      `Counter: ${counter++}`,
      ``,
    ].join("\n"),
    {
      headers: { "content-type": "text/plain" },
    },
  )
);
