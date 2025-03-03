# Instance Targeting Example

The script at `main.ts` is meant to examplify how [instance targeting][1] work.
To see it in action, deploy it using the `ddng` tool.

```bash
../tools/ddng deploy -s . -d instance-id.<your domain> --s3-bucket <code bucket>
```

Once deployed, you can send a few test requests to it, you will see the output
look something like this:

```
x-deno-isolate-instance-id: null
Start time: 2024-11-11T14:54:29.860Z
Uptime: 0.004s
Random global: kqed5jhk8s
Counter: 0
```

The `x-deno-isolate-instance-id` mirrors what it receives in the request headers
for the same key. Start time and Uptime indicate when the isolate was started
and how long it has been running. Each isolate will create a random number that
it keeps in memory and reports in `Random global` that can be used to validate
which isolates handled a request. `Counter` is a simple request counter that is
local to each isolate and increments on each request.

To target a specific isolate, you can add the `x-deno-isolate-instance-id` to
your request headers, set to any arbitrary value. Each request with the same id
is guaranteed by the system to be handled by the same isolate, and that isolate
is guaranteed to only ever handle requests that have that isolate id, and no
other requests.

```bash
curl -i http://instance-id.<your domain> -H 'x-deno-isolate-instance-id: foo'
curl -i http://instance-id.<your domain> -H 'x-deno-isolate-instance-id: foo'
curl -i http://instance-id.<your domain> -H 'x-deno-isolate-instance-id: bar'
curl -i http://instance-id.<your domain> -H 'x-deno-isolate-instance-id: foo'

x-deno-isolate-instance-id: foo
Start time: 2024-11-11T14:48:14.815Z
Uptime: 0.011s
Random global: qapm1ch8oe
Counter: 0

x-deno-isolate-instance-id: foo
Start time: 2024-11-11T14:48:14.815Z
Uptime: 3.224s
Random global: qapm1ch8oe
Counter: 1

x-deno-isolate-instance-id: bar
Start time: 2024-11-11T14:48:21.720Z
Uptime: 0.005s
Random global: cano2kpddr
Counter: 0

x-deno-isolate-instance-id: foo
Start time: 2024-11-11T14:48:14.815Z
Uptime: 32.024s
Random global: qapm1ch8oe
Counter: 2
```

[1]: [https://github.com/denoland/nextgen-install/wiki/Isolate-Instance-Targeting]
