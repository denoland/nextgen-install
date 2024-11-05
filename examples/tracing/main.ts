// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

Deno.serve(async (req: Request) => {
  console.log("Got request", req.url);

  const fast = await fetch("https://ddng-fast.deno.dev");
  const fastBody = await fast.text();

  const slow = await fetch("https://ddng-slow.deno.dev");
  const slowBody = await slow.text();

  return new Response(fastBody + slowBody);
});
