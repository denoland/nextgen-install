#!/usr/bin/env -S deno run -A --watch=static/,routes/
// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.


import dev from "$fresh/dev.ts";
import config from "./fresh.config.ts";

import "$std/dotenv/load.ts";

await dev(import.meta.url, "./main.ts", config);
