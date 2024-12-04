// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

import { PageProps } from "$fresh/server.ts";

export default function Greet(props: PageProps) {
  return <div>Hello {props.params.name}</div>;
}
